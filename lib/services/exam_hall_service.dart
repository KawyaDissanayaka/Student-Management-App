import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/exam_hall_model.dart';
import '../models/exam_model.dart';

class ExamHallService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _hallsRef =>
      _firestore.collection('examHalls');

  CollectionReference<Map<String, dynamic>> get _examsRef =>
      _firestore.collection('exams');

  // Stream of all Exam Halls
  Stream<List<ExamHallModel>> getExamHallsStream() {
    return _hallsRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ExamHallModel.fromFirestore(doc)).toList();
    });
  }

  // Stream of only Available Exam Halls
  Stream<List<ExamHallModel>> getAvailableExamHallsStream() {
    return _hallsRef
        .where('status', isEqualTo: 'Available')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ExamHallModel.fromFirestore(doc)).toList();
    });
  }

  // Stream of all Exams
  Stream<List<ExamModel>> getExamsStream() {
    return _examsRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ExamModel.fromFirestore(doc)).toList();
    });
  }

  // Generate Unique Hall ID
  Future<String> generateUniqueHallId() async {
    try {
      final snap = await _hallsRef.get();
      final count = snap.docs.length + 1;
      final autoId = 'EXH-${count.toString().padLeft(4, '0')}';
      return autoId;
    } catch (e) {
      return 'EXH-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    }
  }

  // Add Exam Hall
  Future<void> addExamHall(ExamHallModel hall) async {
    try {
      final docRef = _hallsRef.doc();
      final finalHallId = hall.hallId.isNotEmpty ? hall.hallId : await generateUniqueHallId();

      final newHall = ExamHallModel(
        docId: docRef.id,
        hallId: finalHallId,
        hallName: hall.hallName.trim(),
        building: hall.building.trim(),
        floor: hall.floor.trim(),
        capacity: hall.capacity,
        facilities: hall.facilities,
        status: hall.status,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      await docRef.set(newHall.toMap());
      debugPrint('Exam Hall created: $finalHallId (${hall.hallName})');
    } catch (e) {
      debugPrint('Error adding exam hall: $e');
      throw Exception('Failed to create examination hall: $e');
    }
  }

  // Update Exam Hall
  Future<void> updateExamHall(String docId, ExamHallModel hall) async {
    try {
      await _hallsRef.doc(docId).update({
        'hallName': hall.hallName.trim(),
        'building': hall.building.trim(),
        'floor': hall.floor.trim(),
        'capacity': hall.capacity,
        'facilities': hall.facilities,
        'status': hall.status,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      debugPrint('Exam Hall updated: ${hall.hallId}');
    } catch (e) {
      debugPrint('Error updating exam hall: $e');
      throw Exception('Failed to update examination hall: $e');
    }
  }

  // Toggle Hall Status (Available, Maintenance, Inactive)
  Future<void> updateHallStatus(String docId, String newStatus) async {
    try {
      await _hallsRef.doc(docId).update({
        'status': newStatus,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      debugPrint('Exam Hall status changed to: $newStatus');
    } catch (e) {
      debugPrint('Error updating hall status: $e');
      throw Exception('Failed to update hall status: $e');
    }
  }

  // Delete Exam Hall
  Future<void> deleteExamHall(String docId) async {
    try {
      await _hallsRef.doc(docId).delete();
      debugPrint('Exam Hall deleted: $docId');
    } catch (e) {
      debugPrint('Error deleting exam hall: $e');
      throw Exception('Failed to delete examination hall: $e');
    }
  }

  // Time Overlap / Conflict Detection Logic
  static bool hasTimeConflict({
    required String startA,
    required String endA,
    required String startB,
    required String endB,
  }) {
    int toMinutes(String timeStr) {
      final clean = timeStr.trim().toUpperCase();
      final isPm = clean.contains('PM');
      final isAm = clean.contains('AM');
      final digits = clean.replaceAll('AM', '').replaceAll('PM', '').trim();
      final parts = digits.split(':');
      if (parts.isEmpty) return 0;
      int h = int.tryParse(parts[0]) ?? 0;
      int m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

      if (isPm && h < 12) h += 12;
      if (isAm && h == 12) h = 0;
      return (h * 60) + m;
    }

    final int a1 = toMinutes(startA);
    final int a2 = toMinutes(endA);
    final int b1 = toMinutes(startB);
    final int b2 = toMinutes(endB);

    // Overlap condition: max(a1, b1) < min(a2, b2)
    return (a1 < b2) && (b1 < a2);
  }

  // Check if hall has a conflicting exam booked on the same date and overlapping hours
  Future<String?> checkHallConflict({
    required String hallId,
    required String examDate,
    required String startTime,
    required String endTime,
    String? excludeExamDocId,
  }) async {
    try {
      final snap = await _examsRef
          .where('date', isEqualTo: examDate.trim())
          .where('hallId', isEqualTo: hallId.trim())
          .get();

      for (var doc in snap.docs) {
        if (excludeExamDocId != null && doc.id == excludeExamDocId) continue;
        final data = doc.data();
        final status = (data['status'] ?? 'scheduled').toString().toLowerCase();
        if (status == 'cancelled') continue;

        final existingStart = data['startTime'] ?? '';
        final existingEnd = data['endTime'] ?? '';
        final subjectCode = data['subjectCode'] ?? '';
        final subjectName = data['subjectName'] ?? 'Exam';

        if (hasTimeConflict(
          startA: startTime,
          endA: endTime,
          startB: existingStart,
          endB: existingEnd,
        )) {
          return 'Hall conflict detected! Already allocated for "$subjectCode - $subjectName" on $examDate ($existingStart - $existingEnd).';
        }
      }
    } catch (e) {
      debugPrint('Error checking hall conflicts: $e');
    }
    return null;
  }

  // Assign Hall to Exam with Multi-Layer Validations
  Future<void> assignHallToExam({
    required String examDocId,
    required ExamHallModel hall,
    required int registeredStudentCount,
    required String examDate,
    required String startTime,
    required String endTime,
  }) async {
    // 1. Status Check: Only Available halls can be assigned
    if (!hall.isAvailable) {
      throw Exception('Cannot assign hall: "${hall.hallName}" is currently marked as ${hall.status.toUpperCase()}. Only "Available" halls can be assigned.');
    }

    // 2. Capacity Check: registeredStudentCount <= hall.capacity
    if (registeredStudentCount > hall.capacity) {
      throw Exception('Capacity exceeded! Registered students ($registeredStudentCount) exceeds hall capacity (${hall.capacity}). Please choose a larger hall.');
    }

    // 3. Time Conflict & Overlap Check
    final conflictError = await checkHallConflict(
      hallId: hall.hallId,
      examDate: examDate,
      startTime: startTime,
      endTime: endTime,
      excludeExamDocId: examDocId,
    );

    if (conflictError != null) {
      throw Exception(conflictError);
    }

    // 4. Save hallId and hall details to the exam document
    try {
      await _examsRef.doc(examDocId).update({
        'hallId': hall.hallId,
        'examHall': hall.hallName,
        'hallCapacity': hall.capacity,
        'hallBuilding': hall.building,
        'hallFloor': hall.floor,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      debugPrint('Hall ${hall.hallName} (${hall.hallId}) assigned successfully to exam $examDocId');
    } catch (e) {
      debugPrint('Error saving hall assignment in exam: $e');
      throw Exception('Failed to assign hall to exam: $e');
    }
  }

  // Unassign hall from Exam
  Future<void> unassignHall(String examDocId) async {
    try {
      await _examsRef.doc(examDocId).update({
        'hallId': FieldValue.delete(),
        'examHall': 'Not Assigned',
        'hallCapacity': FieldValue.delete(),
        'hallBuilding': FieldValue.delete(),
        'hallFloor': FieldValue.delete(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      debugPrint('Hall unassigned from exam $examDocId');
    } catch (e) {
      debugPrint('Error unassigning hall: $e');
      throw Exception('Failed to unassign hall: $e');
    }
  }
}
