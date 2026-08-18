import 'package:cloud_firestore/cloud_firestore.dart';

class ExamAttendanceRecordModel {
  final String? docId;
  final String attendanceId;
  final String examId;
  final String examDocId;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String hallId;
  final String hallName;
  final String seatNumber;
  final String status; // 'Present', 'Absent', 'Late'
  final String markedAt;
  final String markedBy;
  final String verificationMethod; // 'QR' or 'Manual'
  final String? reason;
  final bool isSeatMatched;

  ExamAttendanceRecordModel({
    this.docId,
    required this.attendanceId,
    required this.examId,
    required this.examDocId,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.hallId,
    required this.hallName,
    required this.seatNumber,
    this.status = 'Present',
    required this.markedAt,
    required this.markedBy,
    required this.verificationMethod,
    this.reason,
    this.isSeatMatched = true,
  });

  bool get isPresent => status.toLowerCase() == 'present';
  bool get isAbsent => status.toLowerCase() == 'absent';

  Map<String, dynamic> toMap() {
    return {
      'attendanceId': attendanceId,
      'examId': examId,
      'examDocId': examDocId,
      'studentId': studentId,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'hallId': hallId,
      'hallName': hallName,
      'seatNumber': seatNumber,
      'status': status,
      'markedAt': markedAt,
      'markedBy': markedBy,
      'verificationMethod': verificationMethod,
      'reason': reason,
      'isSeatMatched': isSeatMatched,
    };
  }

  factory ExamAttendanceRecordModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ExamAttendanceRecordModel(
      docId: doc.id,
      attendanceId: data['attendanceId'] ?? doc.id,
      examId: data['examId'] ?? '',
      examDocId: data['examDocId'] ?? '',
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      studentEmail: data['studentEmail'] ?? '',
      hallId: data['hallId'] ?? '',
      hallName: data['hallName'] ?? '',
      seatNumber: data['seatNumber'] ?? '',
      status: data['status'] ?? 'Present',
      markedAt: data['markedAt'] ?? DateTime.now().toIso8601String(),
      markedBy: data['markedBy'] ?? 'Admin',
      verificationMethod: data['verificationMethod'] ?? 'QR',
      reason: data['reason'],
      isSeatMatched: (data['isSeatMatched'] ?? true) as bool,
    );
  }
}
