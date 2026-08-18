import 'package:cloud_firestore/cloud_firestore.dart';

class ExamModel {
  final String? docId;
  final String examId;
  final String subjectCode;
  final String subjectName;
  final String examType; // 'Midterm', 'Final', 'In-Class Quiz', 'Practical'
  final String date; // YYYY-MM-DD
  final String startTime; // '09:00 AM' or '09:00'
  final String endTime; // '12:00 PM' or '12:00'
  final String examHall; // 'Main Exam Hall 01' or 'Not Assigned'
  final String? hallId;
  final String? seatNumber;
  final String instructions;
  final String semester;
  final String academicYear;
  final String batch; // batchId
  final String registrationDeadline; // YYYY-MM-DD
  final bool registrationRequired;
  final int registeredStudentCount;
  final int? hallCapacity;
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
    this.hallId,
    this.seatNumber,
    this.instructions = 'Bring Student ID card. Electronic devices prohibited.',
    required this.semester,
    required this.academicYear,
    this.batch = '2026',
    this.registrationDeadline = '',
    this.registrationRequired = true,
    this.registeredStudentCount = 0,
    this.hallCapacity,
    this.status = 'scheduled',
  });

  bool get isPastDeadline {
    if (registrationDeadline.isEmpty) {
      if (date.isEmpty) return false;
      final examDate = DateTime.tryParse(date);
      if (examDate == null) return false;
      final endOfExamDay = DateTime(examDate.year, examDate.month, examDate.day, 23, 59, 59);
      return DateTime.now().isAfter(endOfExamDay);
    }
    final dl = DateTime.tryParse(registrationDeadline);
    if (dl == null) return false;
    final endOfDeadline = DateTime(dl.year, dl.month, dl.day, 23, 59, 59);
    return DateTime.now().isAfter(endOfDeadline);
  }

  factory ExamModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final examDate = data['date'] ?? '';
    return ExamModel(
      docId: doc.id,
      examId: data['examId'] ?? doc.id,
      subjectCode: data['subjectCode'] ?? '',
      subjectName: data['subjectName'] ?? '',
      examType: data['examType'] ?? 'Final',
      date: examDate,
      startTime: data['startTime'] ?? '09:00 AM',
      endTime: data['endTime'] ?? '12:00 PM',
      examHall: data['examHall'] ?? 'Not Assigned',
      hallId: data['hallId'],
      seatNumber: data['seatNumber'],
      instructions: data['instructions'] ?? 'Bring Student ID card.',
      semester: data['semester'] ?? 'Semester 1',
      academicYear: data['academicYear'] ?? '2025/2026',
      batch: data['batch'] ?? data['batchId'] ?? '2026',
      registrationDeadline: data['registrationDeadline'] ?? examDate,
      registrationRequired: (data['registrationRequired'] ?? true) as bool,
      registeredStudentCount: (data['registeredStudentCount'] as num?)?.toInt() ?? 0,
      hallCapacity: (data['hallCapacity'] as num?)?.toInt(),
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
      'hallId': hallId,
      'seatNumber': seatNumber,
      'instructions': instructions,
      'semester': semester,
      'academicYear': academicYear,
      'batch': batch,
      'batchId': batch,
      'registrationDeadline': registrationDeadline.isNotEmpty ? registrationDeadline : date,
      'registrationRequired': registrationRequired,
      'registeredStudentCount': registeredStudentCount,
      'hallCapacity': hallCapacity,
      'status': status,
    };
  }
}
