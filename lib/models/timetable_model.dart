import 'package:cloud_firestore/cloud_firestore.dart';

class TimetableModel {
  final String? docId;
  final String scheduleId;
  final String subjectCode;
  final String subjectName;
  final String lecturerName;
  final String dayOfWeek; // 'Monday', 'Tuesday', etc.
  final String startTime; // '09:00 AM'
  final String endTime; // '11:00 AM'
  final String hall; // 'Hall A-101'
  final String classType; // 'Lecture', 'Lab', 'Tutorial'
  final String mode; // 'Physical', 'Online'
  final String? meetingLink;
  final String semester;
  final String academicYear;
  final String status; // 'active', 'cancelled'

  TimetableModel({
    this.docId,
    required this.scheduleId,
    required this.subjectCode,
    required this.subjectName,
    required this.lecturerName,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.hall,
    this.classType = 'Lecture',
    this.mode = 'Physical',
    this.meetingLink,
    required this.semester,
    required this.academicYear,
    this.status = 'active',
  });

  factory TimetableModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return TimetableModel(
      docId: doc.id,
      scheduleId: data['scheduleId'] ?? doc.id,
      subjectCode: data['subjectCode'] ?? '',
      subjectName: data['subjectName'] ?? '',
      lecturerName: data['lecturerName'] ?? '',
      dayOfWeek: data['dayOfWeek'] ?? 'Monday',
      startTime: data['startTime'] ?? '09:00 AM',
      endTime: data['endTime'] ?? '11:00 AM',
      hall: data['hall'] ?? 'Main Hall',
      classType: data['classType'] ?? 'Lecture',
      mode: data['mode'] ?? 'Physical',
      meetingLink: data['meetingLink'],
      semester: data['semester'] ?? 'Semester 1',
      academicYear: data['academicYear'] ?? '2025/2026',
      status: data['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'scheduleId': scheduleId,
      'subjectCode': subjectCode,
      'subjectName': subjectName,
      'lecturerName': lecturerName,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'hall': hall,
      'classType': classType,
      'mode': mode,
      'meetingLink': meetingLink,
      'semester': semester,
      'academicYear': academicYear,
      'status': status,
    };
  }
}
