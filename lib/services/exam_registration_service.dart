import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/exam_registration_model.dart';
import '../models/exam_model.dart';

class ExamRegistrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _registrationsRef =>
      _firestore.collection('exam_registrations');

  CollectionReference<Map<String, dynamic>> get _examsRef =>
      _firestore.collection('exams');

  // Stream of all registrations (for Admin)
  Stream<List<ExamRegistrationModel>> getAllRegistrationsStream() {
    return _registrationsRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ExamRegistrationModel.fromFirestore(doc)).toList();
    });
  }

  // Stream of registrations for a specific exam (for Admin)
  Stream<List<ExamRegistrationModel>> getRegistrationsForExamStream(String examId, {String? examDocId}) {
    return _registrationsRef
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ExamRegistrationModel.fromFirestore(doc))
          .where((r) => (r.examId == examId || (examDocId != null && r.examDocId == examDocId)) && r.status.toLowerCase() != 'cancelled')
          .toList();
    });
  }

  // Stream of registrations for a specific student (for Student Portal)
  Stream<List<ExamRegistrationModel>> getStudentRegistrationsStream(String studentId, {String? studentEmail}) {
    return _registrationsRef
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ExamRegistrationModel.fromFirestore(doc))
          .where((r) {
            final matchesId = r.studentId.toUpperCase() == studentId.trim().toUpperCase();
            final matchesEmail = studentEmail != null && r.studentEmail.toLowerCase() == studentEmail.trim().toLowerCase();
            return (matchesId || matchesEmail) && r.status.toLowerCase() != 'cancelled';
          })
          .toList();
    });
  }

  // Auto-generate Unique Registration ID
  Future<String> generateUniqueRegistrationId() async {
    try {
      final snap = await _registrationsRef.get();
      final count = snap.docs.length + 1;
      return 'EXREG-${count.toString().padLeft(4, '0')}';
    } catch (e) {
      return 'EXREG-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    }
  }

  // 7-Point Eligibility Verification & Registration Submission
  Future<ExamRegistrationModel> registerForExam({
    required ExamModel exam,
    required String studentDocId,
    required String studentId,
    required String studentName,
    required String studentEmail,
    required String studentBatch,
  }) async {
    final cleanEmail = studentEmail.trim().toLowerCase();
    final cleanStudentId = studentId.trim().toUpperCase();

    // 1. Authenticated Student Verification
    if (cleanEmail.isEmpty || cleanStudentId.isEmpty) {
      throw Exception('Authentication required. Please log in as an authorized student.');
    }

    // 2. Active Student Status Verification
    final studentQuery = await _firestore
        .collection('students')
        .where('email', isEqualTo: cleanEmail)
        .limit(1)
        .get();

    if (studentQuery.docs.isNotEmpty) {
      final studentData = studentQuery.docs.first.data();
      final status = (studentData['status'] ?? 'active').toString().toLowerCase();
      if (status != 'active') {
        throw Exception('Registration rejected: Your student profile is currently marked as $status.');
      }
    }

    // 3. Active Module Enrollment Verification
    final enrollQuery = await _firestore
        .collection('enrollments')
        .where('subjectCode', isEqualTo: exam.subjectCode)
        .where('status', isEqualTo: 'active')
        .get();

    final isEnrolled = enrollQuery.docs.any((doc) {
      final data = doc.data();
      final eEmail = (data['studentEmail'] ?? '').toString().toLowerCase();
      final eId = (data['studentId'] ?? '').toString().toUpperCase();
      return eEmail == cleanEmail || eId == cleanStudentId;
    });

    if (!isEnrolled) {
      throw Exception('Eligibility Check Failed: You are not actively enrolled in module "${exam.subjectCode} - ${exam.subjectName}".');
    }

    // 4. Non-Cancelled Exam Check
    if (exam.status.toLowerCase() == 'cancelled') {
      throw Exception('This examination has been marked as CANCELLED by the Academic Division.');
    }

    // 5. Registration Deadline Verification
    if (exam.isPastDeadline) {
      throw Exception('Registration Closed! The registration deadline for this examination (${exam.registrationDeadline}) has passed.');
    }

    // 6. Duplicate Registration Check (Student ID + Exam ID)
    final duplicateQuery = await _registrationsRef
        .where('studentId', isEqualTo: cleanStudentId)
        .where('examId', isEqualTo: exam.examId)
        .get();

    final hasActiveReg = duplicateQuery.docs.any((d) => (d.data()['status'] ?? '').toString().toLowerCase() != 'cancelled');
    if (hasActiveReg) {
      throw Exception('Duplicate Registration: You have already submitted a registration for this examination (${exam.subjectCode}).');
    }

    // 7. Check Admin Approval Policy Configuration
    bool requireAdminApproval = false;
    try {
      final configDoc = await _firestore.collection('settings').doc('exam_config').get();
      if (configDoc.exists && configDoc.data() != null) {
        requireAdminApproval = (configDoc.data()!['requireApproval'] ?? false) as bool;
      }
    } catch (e) {
      debugPrint('Error reading exam config: $e');
    }

    final initialStatus = requireAdminApproval ? 'Pending' : 'Registered';
    final registrationId = await generateUniqueRegistrationId();
    final nowTimestamp = DateTime.now().toIso8601String();
    final newDocRef = _registrationsRef.doc();

    final registration = ExamRegistrationModel(
      docId: newDocRef.id,
      registrationId: registrationId,
      studentDocId: studentDocId,
      studentId: cleanStudentId,
      studentName: studentName.trim(),
      studentEmail: cleanEmail,
      examId: exam.examId,
      examDocId: exam.docId ?? exam.examId,
      subjectCode: exam.subjectCode,
      subjectName: exam.subjectName,
      batch: studentBatch,
      registeredAt: nowTimestamp,
      status: initialStatus,
      approvedBy: requireAdminApproval ? null : 'System Auto-Approved',
      approvedAt: requireAdminApproval ? null : nowTimestamp,
    );

    await newDocRef.set(registration.toMap());

    // Increment registered student count in exam doc if examDocId exists
    if (exam.docId != null) {
      try {
        await _examsRef.doc(exam.docId).update({
          'registeredStudentCount': FieldValue.increment(1),
        });
      } catch (e) {
        debugPrint('Could not increment registeredStudentCount in exam: $e');
      }
    }

    debugPrint('Student $cleanStudentId successfully registered for exam ${exam.examId} ($initialStatus)');
    return registration;
  }

  // Update Registration Status (Approve / Reject / Cancel)
  Future<void> updateRegistrationStatus({
    required String regDocId,
    required String newStatus,
    String? approvedBy,
    String? rejectionReason,
    required String examDocId,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': newStatus,
        'approvedBy': approvedBy ?? 'Admin',
        'approvedAt': DateTime.now().toIso8601String(),
        ...?rejectionReason == null ? null : {'rejectionReason': rejectionReason},
      };

      await _registrationsRef.doc(regDocId).update(updateData);
      debugPrint('Registration $regDocId updated to $newStatus');
    } catch (e) {
      debugPrint('Error updating registration status: $e');
      throw Exception('Failed to update registration status: $e');
    }
  }

  // Cancel Registration
  Future<void> cancelRegistration({
    required String regDocId,
    required String examDocId,
  }) async {
    try {
      await _registrationsRef.doc(regDocId).update({
        'status': 'Cancelled',
        'cancelledAt': DateTime.now().toIso8601String(),
      });

      if (examDocId.isNotEmpty) {
        await _examsRef.doc(examDocId).update({
          'registeredStudentCount': FieldValue.increment(-1),
        });
      }
      debugPrint('Registration $regDocId cancelled');
    } catch (e) {
      debugPrint('Error cancelling registration: $e');
      throw Exception('Failed to cancel registration: $e');
    }
  }
}
