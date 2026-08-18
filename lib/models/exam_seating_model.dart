import 'package:cloud_firestore/cloud_firestore.dart';

class ExamSeatingModel {
  final String? docId;
  final String seatingId;
  final String examId;
  final String examDocId;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String hallId;
  final String hallName;
  final String seatNumber; // e.g. 'SEAT-001'
  final String allocatedAt;
  final String allocatedBy;

  ExamSeatingModel({
    this.docId,
    required this.seatingId,
    required this.examId,
    required this.examDocId,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.hallId,
    required this.hallName,
    required this.seatNumber,
    required this.allocatedAt,
    required this.allocatedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'seatingId': seatingId,
      'examId': examId,
      'examDocId': examDocId,
      'studentId': studentId,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'hallId': hallId,
      'hallName': hallName,
      'seatNumber': seatNumber,
      'allocatedAt': allocatedAt,
      'allocatedBy': allocatedBy,
    };
  }

  factory ExamSeatingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ExamSeatingModel(
      docId: doc.id,
      seatingId: data['seatingId'] ?? doc.id,
      examId: data['examId'] ?? '',
      examDocId: data['examDocId'] ?? '',
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      studentEmail: data['studentEmail'] ?? '',
      hallId: data['hallId'] ?? '',
      hallName: data['hallName'] ?? '',
      seatNumber: data['seatNumber'] ?? '',
      allocatedAt: data['allocatedAt'] ?? DateTime.now().toIso8601String(),
      allocatedBy: data['allocatedBy'] ?? 'Admin',
    );
  }
}
