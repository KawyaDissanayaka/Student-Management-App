import 'package:cloud_firestore/cloud_firestore.dart';

class ExamModel {
  final String? docId;
  final String examId;
  final String subjectCode;
  final String subjectName;
  final String examType; // 'Midterm', 'Final', 'In-Class Quiz', 'Practical'
  final String date; // YYYY-MM-DD
  final String startTime; // '09:00 AM'
  final String endTime; // '12:00 PM'
  final String examHall; // 'Main Exam Hall 01'
  final String? seatNumber;
  final String instructions;
  final String semester;
  final String academicYear;
  final bool registrationRequired;
  final String status; // 'scheduled', 'completed', 'cancelled'

  ExamModel({
    this.docId,
    required this.examId,
    required this.subjectCode,
    required this.subjectName,
    required this.examType,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.examHall,
    this.seatNumber,
    this.instructions = 'Bring Student ID card. Electronic devices prohibited.',
    required this.semester,
    required this.academicYear,
    this.registrationRequired = false,
    this.status = 'scheduled',
  });

  factory ExamModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ExamModel(
      docId: doc.id,
      examId: data['examId'] ?? doc.id,
      subjectCode: data['subjectCode'] ?? '',
      subjectName: data['subjectName'] ?? '',
      examType: data['examType'] ?? 'Final',
      date: data['date'] ?? '',
      startTime: data['startTime'] ?? '09:00 AM',
      endTime: data['endTime'] ?? '12:00 PM',
      examHall: data['examHall'] ?? 'Exam Hall A',
      seatNumber: data['seatNumber'],
      instructions: data['instructions'] ?? 'Bring Student ID card.',
      semester: data['semester'] ?? 'Semester 1',
      academicYear: data['academicYear'] ?? '2025/2026',
      registrationRequired: (data['registrationRequired'] ?? false) as bool,
      status: data['status'] ?? 'scheduled',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'examId': examId,
      'subjectCode': subjectCode,
      'subjectName': subjectName,
      'examType': examType,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'examHall': examHall,
      'seatNumber': seatNumber,
      'instructions': instructions,
      'semester': semester,
      'academicYear': academicYear,
      'registrationRequired': registrationRequired,
      'status': status,
    };
  }
}
