import 'package:cloud_firestore/cloud_firestore.dart';

class TimetableModel {
  final String? docId;
  final String scheduleId;
  final String subjectCode;
  final String subjectName;
  final String lecturerDocId;
  final String lecturerId;
  final String lecturerName;
  final String lecturerEmail;
  final String batch; // e.g. '2026' or 'All'
  final String course; // e.g. 'Computer Science'
  final String semester;
  final String academicYear;
  final String dayOfWeek; // 'Monday', 'Tuesday', etc.
  final String? specificDate; // YYYY-MM-DD (optional for one-off / rescheduled)
  final String startTime; // '09:00 AM'
  final String endTime; // '11:00 AM'
  final String hallId; // e.g. 'HALL-101'
  final String hallName; // 'Lab 02'
  final String classType; // 'Lecture', 'Lab', 'Tutorial', 'Workshop'
  final String mode; // 'Physical', 'Online'
  final String? meetingLink;
  final int enrolledCount;
  final int hallCapacity;
  final String status; // 'active', 'rescheduled', 'cancelled'
  final String? rescheduleReason;
  final String? updatedAt;

  TimetableModel({
    this.docId,
    required this.scheduleId,
    required this.subjectCode,
    required this.subjectName,
    this.lecturerDocId = '',
    this.lecturerId = '',
    required this.lecturerName,
    this.lecturerEmail = '',
    this.batch = 'All',
    this.course = 'All',
    required this.semester,
    required this.academicYear,
    required this.dayOfWeek,
    this.specificDate,
    required this.startTime,
    required this.endTime,
    this.hallId = '',
    required this.hallName,
    this.classType = 'Lecture',
    this.mode = 'Physical',
    this.meetingLink,
    this.enrolledCount = 0,
    this.hallCapacity = 50,
    this.status = 'active',
    this.rescheduleReason,
    this.updatedAt,
  });

  /// Hall name alias getter for backwards compatibility
  String get hall => hallName;

  /// Helper: converts time strings like '09:00 AM' or '14:30' into minutes since midnight
  static int parseTimeToMinutes(String timeStr) {
    try {
      final clean = timeStr.trim().toUpperCase();
      final isPm = clean.contains('PM');
      final isAm = clean.contains('AM');

      final parts = clean.replaceAll('AM', '').replaceAll('PM', '').trim().split(':');
      int hour = int.parse(parts[0].trim());
      int minute = parts.length > 1 ? int.parse(parts[1].trim()) : 0;

      if (isPm && hour < 12) hour += 12;
      if (isAm && hour == 12) hour = 0;

      return hour * 60 + minute;
    } catch (_) {
      return 0;
    }
  }

  /// Determines if two time intervals [startA, endA] and [startB, endB] overlap
  static bool isTimeOverlapping(String startA, String endA, String startB, String endB) {
    final aStart = parseTimeToMinutes(startA);
    final aEnd = parseTimeToMinutes(endA);
    final bStart = parseTimeToMinutes(startB);
    final bEnd = parseTimeToMinutes(endB);

    if (aStart >= aEnd || bStart >= bEnd) return false;

    // Overlap condition: max(startA, startB) < min(endA, endB)
    final latestStart = aStart > bStart ? aStart : bStart;
    final earliestEnd = aEnd < bEnd ? aEnd : bEnd;

    return latestStart < earliestEnd;
  }

  factory TimetableModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return TimetableModel(
      docId: doc.id,
      scheduleId: data['scheduleId'] ?? doc.id,
      subjectCode: data['subjectCode'] ?? '',
      subjectName: data['subjectName'] ?? '',
      lecturerDocId: data['lecturerDocId'] ?? '',
      lecturerId: data['lecturerId'] ?? '',
      lecturerName: data['lecturerName'] ?? '',
      lecturerEmail: data['lecturerEmail'] ?? '',
      batch: data['batch'] ?? 'All',
      course: data['course'] ?? 'All',
      semester: data['semester'] ?? 'Semester 1',
      academicYear: data['academicYear'] ?? '2025/2026',
      dayOfWeek: data['dayOfWeek'] ?? 'Monday',
      specificDate: data['specificDate'],
      startTime: data['startTime'] ?? '09:00 AM',
      endTime: data['endTime'] ?? '11:00 AM',
      hallId: data['hallId'] ?? '',
      hallName: data['hallName'] ?? data['hall'] ?? 'Main Hall',
      classType: data['classType'] ?? 'Lecture',
      mode: data['mode'] ?? 'Physical',
      meetingLink: data['meetingLink'],
      enrolledCount: (data['enrolledCount'] as num?)?.toInt() ?? 0,
      hallCapacity: (data['hallCapacity'] as num?)?.toInt() ?? 50,
      status: data['status'] ?? 'active',
      rescheduleReason: data['rescheduleReason'],
      updatedAt: data['updatedAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'scheduleId': scheduleId,
      'subjectCode': subjectCode,
      'subjectName': subjectName,
      'lecturerDocId': lecturerDocId,
      'lecturerId': lecturerId,
      'lecturerName': lecturerName,
      'lecturerEmail': lecturerEmail,
      'batch': batch,
      'course': course,
      'semester': semester,
      'academicYear': academicYear,
      'dayOfWeek': dayOfWeek,
      'specificDate': specificDate,
      'startTime': startTime,
      'endTime': endTime,
      'hallId': hallId,
      'hallName': hallName,
      'classType': classType,
      'mode': mode,
      'meetingLink': meetingLink,
      'enrolledCount': enrolledCount,
      'hallCapacity': hallCapacity,
      'status': status,
      'rescheduleReason': rescheduleReason,
      'updatedAt': updatedAt,
    };
  }
}
