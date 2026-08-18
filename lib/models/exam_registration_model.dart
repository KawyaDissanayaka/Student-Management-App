import 'package:cloud_firestore/cloud_firestore.dart';

class ExamRegistrationModel {
  final String? docId;
  final String registrationId;
  final String studentDocId;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String examId;
  final String examDocId;
  final String subjectCode; // moduleId
  final String subjectName;
  final String batch; // batchId
  final String registeredAt;
  final String status; // 'Pending', 'Registered', 'Approved', 'Rejected', 'Cancelled'
  final String? approvedBy;
  final String? approvedAt;
  final String? rejectionReason;

  ExamRegistrationModel({
    this.docId,
    required this.registrationId,
    required this.studentDocId,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.examId,
    required this.examDocId,
    required this.subjectCode,
    required this.subjectName,
    required this.batch,
    required this.registeredAt,
    this.status = 'Registered',
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
  });

  bool get isApprovedOrRegistered =>
      status.toLowerCase() == 'registered' || status.toLowerCase() == 'approved';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isRejected => status.toLowerCase() == 'rejected';
  bool get isCancelled => status.toLowerCase() == 'cancelled';

  Map<String, dynamic> toMap() {
    return {
      'registrationId': registrationId,
      'studentDocId': studentDocId,
      'studentId': studentId,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'examId': examId,
      'examDocId': examDocId,
      'subjectCode': subjectCode,
      'moduleId': subjectCode,
      'subjectName': subjectName,
      'batch': batch,
      'batchId': batch,
      'registeredAt': registeredAt,
      'status': status,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt,
      'rejectionReason': rejectionReason,
    };
  }

  factory ExamRegistrationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ExamRegistrationModel(
      docId: doc.id,
      registrationId: data['registrationId'] ?? doc.id,
      studentDocId: data['studentDocId'] ?? '',
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      studentEmail: data['studentEmail'] ?? '',
      examId: data['examId'] ?? '',
      examDocId: data['examDocId'] ?? '',
      subjectCode: data['subjectCode'] ?? data['moduleId'] ?? '',
      subjectName: data['subjectName'] ?? '',
      batch: data['batch'] ?? data['batchId'] ?? '',
      registeredAt: data['registeredAt'] ?? DateTime.now().toIso8601String(),
      status: data['status'] ?? 'Registered',
      approvedBy: data['approvedBy'],
      approvedAt: data['approvedAt'],
      rejectionReason: data['rejectionReason'],
    );
  }
}
