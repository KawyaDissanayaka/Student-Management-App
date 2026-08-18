import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/exam_result_model.dart';
import '../models/result_model.dart';

class ExamResultsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _examResultsRef =>
      _firestore.collection('exam_results');

  CollectionReference<Map<String, dynamic>> get _officialResultsRef =>
      _firestore.collection('results');

  // ─── 1. FETCH DYNAMIC GRADING SCALES ────────────────────────────────────────
  Future<List<GradingScale>> getGradingScales() async {
    try {
      final doc = await _firestore.collection('settings').doc('grading_config').get();
      if (doc.exists && doc.data() != null && doc.data()!['scales'] != null) {
        final List list = doc.data()!['scales'] as List;
        return list.map((item) => GradingScale.fromMap(Map<String, dynamic>.from(item))).toList();
      }
    } catch (e) {
      debugPrint('Error loading dynamic grading scales: $e');
    }
    return ExamResultModel.defaultGradingScales;
  }

  // ─── 2. STREAMS ─────────────────────────────────────────────────────────────
  // Stream of results for a specific exam
  Stream<List<ExamResultModel>> getExamResultsStream(String examId, {String? examDocId}) {
    return _examResultsRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ExamResultModel.fromFirestore(doc))
          .where((r) => r.examId == examId || (examDocId != null && r.examDocId == examDocId))
          .toList();
    });
  }

  // Stream of pending approval result batches for Admin
  Stream<List<ExamResultModel>> getPendingApprovalResultsStream() {
    return _examResultsRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ExamResultModel.fromFirestore(doc))
          .where((r) => r.isSubmitted)
          .toList();
    });
  }

  // Stream of published results for a student (Students only see published results!)
  Stream<List<ExamResultModel>> getStudentPublishedResultsStream(String studentId, {String? studentEmail}) {
    final cleanId = studentId.trim().toUpperCase();
    final cleanEmail = studentEmail?.trim().toLowerCase();

    return _examResultsRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ExamResultModel.fromFirestore(doc))
          .where((r) {
            final matchesId = r.studentId.toUpperCase() == cleanId;
            final matchesEmail = cleanEmail != null && r.studentEmail.toLowerCase() == cleanEmail;
            return (matchesId || matchesEmail) && r.isPublished;
          })
          .toList();
    });
  }

  // ─── 3. SAVE DRAFT OR SUBMIT FOR APPROVAL ───────────────────────────────────
  Future<void> saveOrSubmitResults({
    required String examId,
    required String examDocId,
    required String moduleId,
    required String subjectName,
    required List<ExamResultModel> results,
    required String targetStatus, // 'Draft' or 'Submitted'
    String? submittedBy,
  }) async {
    final scales = await getGradingScales();
    final batch = _firestore.batch();
    final timestamp = DateTime.now().toIso8601String();

    for (final res in results) {
      // Validate marks
      if (!res.isAbsent && (res.marks < 0 || res.marks > res.maxMarks)) {
        throw Exception('Invalid marks for student ${res.studentName} (${res.studentId}): Marks (${res.marks}) must be between 0 and ${res.maxMarks}.');
      }

      // Dynamic grade calculation
      final gradeMap = ExamResultModel.calculateGradeAndPoint(
        marks: res.marks,
        isAbsent: res.isAbsent,
        scales: scales,
      );

      final docRef = res.docId != null && res.docId!.isNotEmpty
          ? _examResultsRef.doc(res.docId)
          : _examResultsRef.doc();

      final updatedResult = ExamResultModel(
        docId: docRef.id,
        resultId: res.resultId.isNotEmpty ? res.resultId : 'EXRES-${docRef.id.substring(0, 6).toUpperCase()}',
        examId: examId,
        examDocId: examDocId,
        moduleId: moduleId,
        subjectName: subjectName,
        studentId: res.studentId,
        studentName: res.studentName,
        studentEmail: res.studentEmail,
        marks: res.isAbsent ? 0.0 : res.marks,
        maxMarks: res.maxMarks,
        grade: gradeMap['grade'] as String,
        gradePoint: (gradeMap['gradePoint'] as num).toDouble(),
        status: targetStatus,
        isAbsent: res.isAbsent,
        submittedBy: targetStatus == 'Submitted' ? (submittedBy ?? res.submittedBy) : res.submittedBy,
        submittedAt: targetStatus == 'Submitted' ? timestamp : res.submittedAt,
        approvedBy: res.approvedBy,
        approvedAt: res.approvedAt,
        publishedAt: res.publishedAt,
        rejectionReason: targetStatus == 'Submitted' ? null : res.rejectionReason,
        updatedAt: timestamp,
      );

      batch.set(docRef, updatedResult.toMap());
    }

    await batch.commit();
    debugPrint('Successfully saved ${results.length} exam results with status $targetStatus for $moduleId');
  }

  // ─── 4. ADMIN APPROVE RESULTS ───────────────────────────────────────────────
  Future<void> approveResults({
    required String examId,
    required String examDocId,
    required String approvedBy,
  }) async {
    final querySnap = await _examResultsRef
        .where('examId', isEqualTo: examId)
        .get();

    final batch = _firestore.batch();
    final timestamp = DateTime.now().toIso8601String();

    for (final doc in querySnap.docs) {
      batch.update(doc.reference, {
        'status': 'Approved',
        'approvedBy': approvedBy,
        'approvedAt': timestamp,
        'rejectionReason': null,
        'updatedAt': timestamp,
      });
    }

    await batch.commit();
    debugPrint('Admin $approvedBy approved results for exam $examId');
  }

  // ─── 5. ADMIN REJECT RESULTS (WITH REASON & NOTIFICATION) ───────────────────
  Future<void> rejectResults({
    required String examId,
    required String examDocId,
    required String rejectionReason,
    required String rejectedBy,
    String? lecturerEmail,
    String? subjectName,
  }) async {
    if (rejectionReason.trim().isEmpty) {
      throw Exception('A clear reason is required to reject submitted results.');
    }

    final querySnap = await _examResultsRef
        .where('examId', isEqualTo: examId)
        .get();

    final batch = _firestore.batch();
    final timestamp = DateTime.now().toIso8601String();

    for (final doc in querySnap.docs) {
      batch.update(doc.reference, {
        'status': 'Rejected',
        'rejectionReason': rejectionReason.trim(),
        'rejectedBy': rejectedBy,
        'rejectedAt': timestamp,
        'updatedAt': timestamp,
      });
    }

    // Send notification to lecturer
    if (lecturerEmail != null && lecturerEmail.isNotEmpty) {
      final notifRef = _firestore.collection('notifications').doc();
      batch.set(notifRef, {
        'title': 'Exam Results Returned for Revision',
        'message': 'Results for ${subjectName ?? examId} were returned by Admin. Reason: ${rejectionReason.trim()}',
        'recipientEmail': lecturerEmail.toLowerCase(),
        'type': 'result_rejected',
        'examId': examId,
        'createdAt': timestamp,
        'status': 'sent',
      });
    }

    await batch.commit();
    debugPrint('Admin $rejectedBy rejected results for exam $examId: $rejectionReason');
  }

  // ─── 6. ADMIN PUBLISH RESULTS & LOCK ────────────────────────────────────────
  Future<void> publishResults({
    required String examId,
    required String examDocId,
    required String publishedBy,
    String? semester,
    String? academicYear,
  }) async {
    final querySnap = await _examResultsRef
        .where('examId', isEqualTo: examId)
        .get();

    final batch = _firestore.batch();
    final timestamp = DateTime.now().toIso8601String();

    for (final doc in querySnap.docs) {
      final resultModel = ExamResultModel.fromFirestore(doc);

      // 1. Lock & mark as Published in exam_results
      batch.update(doc.reference, {
        'status': 'Published',
        'publishedBy': publishedBy,
        'publishedAt': timestamp,
        'updatedAt': timestamp,
      });

      // 2. Sync to official results collection so GPA calculations and student transcripts immediately update!
      final officialDocRef = _officialResultsRef.doc('EX_${resultModel.studentId}_${resultModel.moduleId}');
      final officialResult = ResultModel(
        docId: officialDocRef.id,
        resultId: resultModel.resultId,
        studentDocId: resultModel.studentEmail,
        studentOfficialId: resultModel.studentId,
        studentEmail: resultModel.studentEmail,
        studentName: resultModel.studentName,
        subjectCode: resultModel.moduleId,
        subjectName: resultModel.subjectName,
        credits: 3,
        marks: resultModel.marks,
        grade: resultModel.grade,
        gradePoint: resultModel.gradePoint,
        semester: semester ?? 'Semester 1',
        academicYear: academicYear ?? '2025/2026',
        publishedDate: timestamp.substring(0, 10),
        status: 'published',
        finalExamMarks: resultModel.marks,
        lockedAt: timestamp,
        lockedBy: publishedBy,
      );

      batch.set(officialDocRef, officialResult.toMap(), SetOptions(merge: true));
    }

    await batch.commit();
    debugPrint('Admin $publishedBy successfully published and locked results for exam $examId');
  }

  // ─── 7. ADMIN UNLOCK FOR CORRECTION FLOW ────────────────────────────────────
  Future<void> unlockResultsForCorrection({
    required String examId,
    required String examDocId,
    required String unlockedBy,
    required String unlockReason,
  }) async {
    final querySnap = await _examResultsRef
        .where('examId', isEqualTo: examId)
        .get();

    final batch = _firestore.batch();
    final timestamp = DateTime.now().toIso8601String();

    for (final doc in querySnap.docs) {
      batch.update(doc.reference, {
        'status': 'Unlocked',
        'unlockedBy': unlockedBy,
        'unlockReason': unlockReason.trim(),
        'unlockedAt': timestamp,
        'updatedAt': timestamp,
      });
    }

    await batch.commit();
    debugPrint('Admin $unlockedBy unlocked results for exam $examId for correction.');
  }
}
