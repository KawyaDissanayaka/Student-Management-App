import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/exam_model.dart';
import '../models/exam_hall_model.dart';
import '../models/exam_registration_model.dart';
import '../models/exam_seating_model.dart';

class ExamSeatingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _seatingsRef =>
      _firestore.collection('exam_seatings');

  CollectionReference<Map<String, dynamic>> get _registrationsRef =>
      _firestore.collection('exam_registrations');

  // Stream of seating allocations for an exam
  Stream<List<ExamSeatingModel>> getSeatingForExamStream(String examId, {String? examDocId}) {
    return _seatingsRef.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ExamSeatingModel.fromFirestore(doc))
          .where((s) => s.examId == examId || (examDocId != null && s.examDocId == examDocId))
          .toList();

      // Sort naturally by seat number (e.g. SEAT-001, SEAT-002)
      list.sort((a, b) => _compareSeatNumbers(a.seatNumber, b.seatNumber));
      return list;
    });
  }

  // Stream of seating for a specific student across their exams
  Stream<List<ExamSeatingModel>> getSeatingForStudentStream(String studentId, {String? studentEmail}) {
    return _seatingsRef.snapshots().map((snapshot) {
      final cleanId = studentId.trim().toUpperCase();
      final cleanEmail = studentEmail?.trim().toLowerCase();

      return snapshot.docs
          .map((doc) => ExamSeatingModel.fromFirestore(doc))
          .where((s) {
            final matchesId = s.studentId.toUpperCase() == cleanId;
            final matchesEmail = cleanEmail != null && s.studentEmail.toLowerCase() == cleanEmail;
            return matchesId || matchesEmail;
          })
          .toList();
    });
  }

  // Natural seat comparison helper
  static int _compareSeatNumbers(String a, String b) {
    try {
      final numA = int.tryParse(a.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      final numB = int.tryParse(b.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      return numA.compareTo(numB);
    } catch (_) {
      return a.compareTo(b);
    }
  }

  // Deterministic mixed student seating generator
  static List<ExamRegistrationModel> deterministicMixStudents(
    List<ExamRegistrationModel> originalList,
    String seedString,
  ) {
    final list = List<ExamRegistrationModel>.from(originalList);
    // 1. Initial canonical sort by studentId for guaranteed determinism
    list.sort((a, b) => a.studentId.compareTo(b.studentId));

    if (list.length <= 1) return list;

    // 2. Compute integer seed from string hash
    int seed = 5381;
    for (int i = 0; i < seedString.length; i++) {
      seed = ((seed << 5) + seed) + seedString.codeUnitAt(i);
      seed = seed & 0x7FFFFFFF;
    }

    final random = math.Random(seed);

    // 3. Shuffle using the deterministic seeded Random
    for (int i = list.length - 1; i > 0; i--) {
      int j = random.nextInt(i + 1);
      final temp = list[i];
      list[i] = list[j];
      list[j] = temp;
    }

    return list;
  }

  // Generate Automatic Seating Arrangement for Valid Registered Students
  Future<List<ExamSeatingModel>> generateSeatingArrangement({
    required ExamModel exam,
    required ExamHallModel hall,
    String allocatedBy = 'Admin',
  }) async {
    // 1. Validate Exam Status
    if (exam.status.toLowerCase() == 'cancelled') {
      throw Exception('Cannot generate seating: Examination has been CANCELLED.');
    }

    // 2. Validate Hall Availability Status
    if (!hall.isAvailable) {
      throw Exception('Cannot allocate seating: Exam Hall "${hall.hallName}" is currently marked as ${hall.status}. Only Available halls can be assigned.');
    }

    // 3. Fetch all valid / registered / approved students for this exam
    final regSnap = await _registrationsRef.get();
    final validRegistrations = regSnap.docs
        .map((doc) => ExamRegistrationModel.fromFirestore(doc))
        .where((r) =>
            (r.examId == exam.examId || (exam.docId != null && r.examDocId == exam.docId)) &&
            (r.status.toLowerCase() == 'registered' || r.status.toLowerCase() == 'approved'))
        .toList();

    if (validRegistrations.isEmpty) {
      throw Exception(
        'No registered students found for ${exam.subjectCode} (${exam.examType}). Students must register and have their registrations confirmed before seating can be generated.',
      );
    }

    // 4. Capacity Verification: Registered Students vs Hall Capacity
    if (validRegistrations.length > hall.capacity) {
      throw Exception(
        'Capacity Exceeded! Registered students count (${validRegistrations.length}) exceeds hall "${hall.hallName}" capacity (${hall.capacity} seats). Please assign a larger examination hall or split the batch.',
      );
    }

    // 5. Apply Deterministic Mixed Student Distribution
    final mixedStudents = deterministicMixStudents(validRegistrations, '${exam.examId}_${hall.hallId}');

    final timestamp = DateTime.now().toIso8601String();
    final List<ExamSeatingModel> newAllocations = [];

    for (int i = 0; i < mixedStudents.length; i++) {
      final student = mixedStudents[i];
      final seatIndex = (i + 1).toString().padLeft(3, '0');
      final seatNumber = 'SEAT-$seatIndex';

      final seatingModel = ExamSeatingModel(
        seatingId: 'EXS-${exam.examId}-$seatIndex',
        examId: exam.examId,
        examDocId: exam.docId ?? exam.examId,
        studentId: student.studentId,
        studentName: student.studentName,
        studentEmail: student.studentEmail,
        hallId: hall.hallId,
        hallName: hall.hallName,
        seatNumber: seatNumber,
        allocatedAt: timestamp,
        allocatedBy: allocatedBy,
      );

      newAllocations.add(seatingModel);
    }

    // 6. Atomic Firestore Replacement: Delete Previous Seating + Write New Allocations
    final batch = _firestore.batch();

    // Query existing seating records for this exam
    final existingSeatings = await _seatingsRef
        .where('examId', isEqualTo: exam.examId)
        .get();

    for (final doc in existingSeatings.docs) {
      batch.delete(doc.reference);
    }

    // Insert new seating allocations
    for (final alloc in newAllocations) {
      final docRef = _seatingsRef.doc();
      batch.set(docRef, alloc.toMap());
    }

    // Update Exam document with hall link & allocated count
    if (exam.docId != null) {
      batch.update(_firestore.collection('exams').doc(exam.docId), {
        'hallId': hall.hallId,
        'examHall': hall.hallName,
        'hallCapacity': hall.capacity,
        'allocatedCount': newAllocations.length,
        'seatingGeneratedAt': timestamp,
      });
    }

    await batch.commit();
    debugPrint('Successfully generated and committed ${newAllocations.length} seat allocations for ${exam.subjectCode} in ${hall.hallName}');
    return newAllocations;
  }

  // Clear / Reset Seating Arrangement
  Future<void> clearSeatingArrangement(String examId, {String? examDocId}) async {
    final batch = _firestore.batch();
    final existingSeatings = await _seatingsRef
        .where('examId', isEqualTo: examId)
        .get();

    for (final doc in existingSeatings.docs) {
      batch.delete(doc.reference);
    }

    if (examDocId != null && examDocId.isNotEmpty) {
      batch.update(_firestore.collection('exams').doc(examDocId), {
        'allocatedCount': 0,
        'seatingGeneratedAt': null,
      });
    }

    await batch.commit();
    debugPrint('Cleared seating allocations for exam $examId');
  }
}
