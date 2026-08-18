import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/exam_attendance_record_model.dart';
import '../models/exam_registration_model.dart';
import '../models/exam_seating_model.dart';

class ExamVerificationResult {
  final bool isSuccess;
  final String message;
  final ExamAttendanceRecordModel? record;
  final bool isSeatMatched;
  final String allocatedSeatNumber;
  final String? claimedSeatNumber;
  final String studentName;
  final String studentId;
  final String hallName;

  ExamVerificationResult({
    required this.isSuccess,
    required this.message,
    this.record,
    this.isSeatMatched = true,
    required this.allocatedSeatNumber,
    this.claimedSeatNumber,
    required this.studentName,
    required this.studentId,
    required this.hallName,
  });
}

class ExamAttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _attendanceRef =>
      _firestore.collection('exam_attendance_records');

  CollectionReference<Map<String, dynamic>> get _registrationsRef =>
      _firestore.collection('exam_registrations');

  CollectionReference<Map<String, dynamic>> get _seatingsRef =>
      _firestore.collection('exam_seatings');

  // Stream of attendance records for an exam
  Stream<List<ExamAttendanceRecordModel>> getAttendanceForExamStream(String examId, {String? examDocId}) {
    return _attendanceRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ExamAttendanceRecordModel.fromFirestore(doc))
          .where((r) => r.examId == examId || (examDocId != null && r.examDocId == examDocId))
          .toList();
    });
  }

  // Stream of attendance records for a specific student
  Stream<List<ExamAttendanceRecordModel>> getStudentExamAttendanceStream(String studentId, {String? studentEmail}) {
    return _attendanceRef.snapshots().map((snapshot) {
      final cleanId = studentId.trim().toUpperCase();
      final cleanEmail = studentEmail?.trim().toLowerCase();

      return snapshot.docs
          .map((doc) => ExamAttendanceRecordModel.fromFirestore(doc))
          .where((r) {
            final matchesId = r.studentId.toUpperCase() == cleanId;
            final matchesEmail = cleanEmail != null && r.studentEmail.toLowerCase() == cleanEmail;
            return matchesId || matchesEmail;
          })
          .toList();
    });
  }

  // Multi-Condition Verification & Attendance Marking
  Future<ExamVerificationResult> verifyAndMarkAttendance({
    required String examId,
    required String examDocId,
    required String studentQuery, // Student ID, Email, or Scanned Registration/QR Code
    required String verificationMethod, // 'QR' or 'Manual'
    String? currentHallId,
    String? currentHallName,
    String? claimedSeatNumber,
    String markedBy = 'Admin / Invigilator',
    String? manualReason,
  }) async {
    final query = studentQuery.trim();
    if (query.isEmpty) {
      throw Exception('Student identification query cannot be empty.');
    }

    // 1. Check Exam Details
    final examSnap = await _firestore.collection('exams').doc(examDocId).get();
    if (!examSnap.exists) {
      // Try search by examId
      final examQ = await _firestore.collection('exams').where('examId', isEqualTo: examId).limit(1).get();
      if (examQ.docs.isEmpty) {
        throw Exception('Invalid Examination: Exam $examId not found.');
      }
    }

    // 2. Resolve Valid Student Registration for this Exam
    // Check if query is Registration ID (e.g. EXREG-0001) or Student ID/Email
    final regSnap = await _registrationsRef.get();
    final validRegistrations = regSnap.docs
        .map((doc) => ExamRegistrationModel.fromFirestore(doc))
        .where((r) => r.examId == examId || r.examDocId == examDocId)
        .toList();

    final matchedRegList = validRegistrations.where((r) {
      final matchesRegId = r.registrationId.toUpperCase() == query.toUpperCase();
      final matchesStudentId = r.studentId.toUpperCase() == query.toUpperCase();
      final matchesEmail = r.studentEmail.toLowerCase() == query.toLowerCase();
      final matchesDocId = r.docId == query;
      return matchesRegId || matchesStudentId || matchesEmail || matchesDocId;
    }).toList();

    if (matchedRegList.isEmpty) {
      throw Exception('Verification Failed: No registration found for "$query" under this examination ($examId). Student must register first.');
    }

    final registration = matchedRegList.first;

    // Check registration status
    if (!registration.isApprovedOrRegistered) {
      throw Exception('Verification Rejected: Student\'s exam registration status is currently "${registration.status}". Only Approved or Confirmed registrations can be verified.');
    }

    // 3. Prevent Duplicate Attendance
    final existingAttendance = await _attendanceRef
        .where('examId', isEqualTo: examId)
        .where('studentId', isEqualTo: registration.studentId)
        .get();

    final activeRecord = existingAttendance.docs
        .map((doc) => ExamAttendanceRecordModel.fromFirestore(doc))
        .where((r) => r.isPresent)
        .toList();

    if (activeRecord.isNotEmpty) {
      final rec = activeRecord.first;
      throw Exception('Duplicate Attendance: Student ${registration.studentName} (${registration.studentId}) was already verified and marked PRESENT at ${rec.markedAt.length >= 16 ? rec.markedAt.substring(11, 16) : rec.markedAt} via ${rec.verificationMethod}.');
    }

    // 4. Resolve Allocated Seat & Hall
    final seatingSnap = await _seatingsRef
        .where('examId', isEqualTo: examId)
        .where('studentId', isEqualTo: registration.studentId)
        .limit(1)
        .get();

    String allocatedSeat = 'Unallocated';
    String hallId = currentHallId ?? registration.batch;
    String hallName = currentHallName ?? 'Exam Hall';
    bool isSeatMatched = true;

    if (seatingSnap.docs.isNotEmpty) {
      final seating = ExamSeatingModel.fromFirestore(seatingSnap.docs.first);
      allocatedSeat = seating.seatNumber;
      hallId = seating.hallId;
      hallName = seating.hallName;

      // Check Seat Mismatch if claimedSeatNumber is provided
      if (claimedSeatNumber != null && claimedSeatNumber.trim().isNotEmpty) {
        if (claimedSeatNumber.trim().toUpperCase() != allocatedSeat.toUpperCase()) {
          isSeatMatched = false;
        }
      }
    }

    // 5. Store Attendance Record in Firestore
    final timestamp = DateTime.now().toIso8601String();
    final newDocRef = _attendanceRef.doc();
    final attendanceId = 'EXATT-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    final attendanceRecord = ExamAttendanceRecordModel(
      docId: newDocRef.id,
      attendanceId: attendanceId,
      examId: examId,
      examDocId: examDocId,
      studentId: registration.studentId,
      studentName: registration.studentName,
      studentEmail: registration.studentEmail,
      hallId: hallId,
      hallName: hallName,
      seatNumber: allocatedSeat,
      status: 'Present',
      markedAt: timestamp,
      markedBy: markedBy,
      verificationMethod: verificationMethod,
      reason: manualReason,
      isSeatMatched: isSeatMatched,
    );

    await newDocRef.set(attendanceRecord.toMap());
    debugPrint('Student ${registration.studentId} verified and marked Present for exam $examId via $verificationMethod (Seat: $allocatedSeat)');

    return ExamVerificationResult(
      isSuccess: true,
      message: isSeatMatched
          ? 'Attendance Verified Successfully! Student marked Present.'
          : 'Attendance Verified! Warning: Seat Mismatch detected (Allocated: $allocatedSeat vs Claimed: $claimedSeatNumber).',
      record: attendanceRecord,
      isSeatMatched: isSeatMatched,
      allocatedSeatNumber: allocatedSeat,
      claimedSeatNumber: claimedSeatNumber,
      studentName: registration.studentName,
      studentId: registration.studentId,
      hallName: hallName,
    );
  }

  // Mark Student as Absent
  Future<void> markAbsent({
    required String examId,
    required String examDocId,
    required String studentId,
    required String studentName,
    required String studentEmail,
    required String hallId,
    required String hallName,
    required String seatNumber,
    String markedBy = 'Admin',
    String? reason,
  }) async {
    final existingSnap = await _attendanceRef
        .where('examId', isEqualTo: examId)
        .where('studentId', isEqualTo: studentId)
        .get();

    for (final doc in existingSnap.docs) {
      await doc.reference.delete();
    }

    final newDocRef = _attendanceRef.doc();
    final timestamp = DateTime.now().toIso8601String();

    final record = ExamAttendanceRecordModel(
      docId: newDocRef.id,
      attendanceId: 'EXATT-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
      examId: examId,
      examDocId: examDocId,
      studentId: studentId,
      studentName: studentName,
      studentEmail: studentEmail,
      hallId: hallId,
      hallName: hallName,
      seatNumber: seatNumber,
      status: 'Absent',
      markedAt: timestamp,
      markedBy: markedBy,
      verificationMethod: 'Manual',
      reason: reason ?? 'Marked absent by invigilator',
    );

    await newDocRef.set(record.toMap());
    debugPrint('Student $studentId marked Absent for exam $examId');
  }

  // Reset / Clear an Attendance Record
  Future<void> resetAttendanceRecord(String recordDocId) async {
    await _attendanceRef.doc(recordDocId).delete();
  }
}
