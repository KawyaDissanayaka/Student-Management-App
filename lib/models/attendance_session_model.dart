import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceSessionModel {
  final String? docId;
  final String sessionId;
  final String subjectCode;
  final String subjectName;
  final String lecturerId;
  final String lecturerName;
  final String lecturerEmail;
  final String hallName;
  final String batch;
  final String date;
  final String startTime;
  final String endTime;
  final String qrToken;
  final String expiresAt;
  final String status; // 'active', 'ended', 'expired'
  final int enrolledCount;
  final int presentCount;
  final double? latitude;
  final double? longitude;
  final double? allowedRadiusMeters;
  final String? createdAt;

  AttendanceSessionModel({
    this.docId,
    required this.sessionId,
    required this.subjectCode,
    required this.subjectName,
    required this.lecturerId,
    required this.lecturerName,
    required this.lecturerEmail,
    required this.hallName,
    required this.batch,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.qrToken,
    required this.expiresAt,
    this.status = 'active',
    this.enrolledCount = 0,
    this.presentCount = 0,
    this.latitude,
    this.longitude,
    this.allowedRadiusMeters = 500.0,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'subjectCode': subjectCode,
      'subjectName': subjectName,
      'lecturerId': lecturerId,
      'lecturerName': lecturerName,
      'lecturerEmail': lecturerEmail,
      'hallName': hallName,
      'batch': batch,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'qrToken': qrToken,
      'expiresAt': expiresAt,
      'status': status,
      'enrolledCount': enrolledCount,
      'presentCount': presentCount,
      'latitude': latitude,
      'longitude': longitude,
      'allowedRadiusMeters': allowedRadiusMeters,
      'createdAt': createdAt ?? DateTime.now().toIso8601String(),
    };
  }

  factory AttendanceSessionModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AttendanceSessionModel(
      docId: doc.id,
      sessionId: data['sessionId'] ?? '',
      subjectCode: data['subjectCode'] ?? '',
      subjectName: data['subjectName'] ?? '',
      lecturerId: data['lecturerId'] ?? '',
      lecturerName: data['lecturerName'] ?? '',
      lecturerEmail: data['lecturerEmail'] ?? '',
      hallName: data['hallName'] ?? '',
      batch: data['batch'] ?? '',
      date: data['date'] ?? '',
      startTime: data['startTime'] ?? '',
      endTime: data['endTime'] ?? '',
      qrToken: data['qrToken'] ?? '',
      expiresAt: data['expiresAt'] ?? '',
      status: data['status'] ?? 'active',
      enrolledCount: (data['enrolledCount'] as num?)?.toInt() ?? 0,
      presentCount: (data['presentCount'] as num?)?.toInt() ?? 0,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      allowedRadiusMeters: (data['allowedRadiusMeters'] as num?)?.toDouble() ?? 500.0,
      createdAt: data['createdAt']?.toString(),
    );
  }
}
