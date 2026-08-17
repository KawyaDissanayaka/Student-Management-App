import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementModel {
  final String? docId;
  final String announcementId;
  final String title;
  final String description; // message/content
  final String audience; // 'all_students' | 'all_lecturers' | 'all_users' | 'subject_students'
  final String? targetUserDocId;
  final String? targetUserName;
  final String? targetUserEmail;
  final String? targetUserId; // Student ID or Lecturer ID
  final String createdBy;
  final String? updatedBy;
  final String publishDate; // YYYY-MM-DD
  final String expiryDate; // YYYY-MM-DD
  final String createdDate; // ISO string
  final String? updatedAt; // ISO string when modified
  final String status; // 'draft' | 'published' | 'archived' | 'expired' | 'deactivated'
  final String priority; // 'Normal' | 'Important' | 'Urgent'
  final String? subjectCode;
  final String? subjectName;
  final String? subjectDocId;
  final String? lecturerId;
  final String? lecturerName;
  final String? attachmentUrl;
  final List<String> readBy;

  AnnouncementModel({
    this.docId,
    required this.announcementId,
    required this.title,
    required this.description,
    this.audience = 'all_users',
    this.targetUserDocId,
    this.targetUserName,
    this.targetUserEmail,
    this.targetUserId,
    required this.createdBy,
    this.updatedBy,
    required this.publishDate,
    required this.expiryDate,
    required this.createdDate,
    this.updatedAt,
    this.status = 'draft',
    this.priority = 'Normal',
    this.subjectCode,
    this.subjectName,
    this.subjectDocId,
    this.lecturerId,
    this.lecturerName,
    this.attachmentUrl,
    this.readBy = const [],
  });

  /// Message alias
  String get message => description;

  /// Computed dynamic status:
  /// If status is 'draft' or 'archived' or 'deactivated', keep it.
  /// If status is 'published', but today is after expiryDate (end of day), return 'expired'.
  String get effectiveStatus {
    final s = status.toLowerCase();
    if (s == 'draft' || s == 'archived' || s == 'deactivated') {
      return s;
    }
    if (expiryDate.isNotEmpty) {
      try {
        final parsedExpiry = DateTime.parse(expiryDate);
        final endOfExpiryDay = DateTime(parsedExpiry.year, parsedExpiry.month, parsedExpiry.day, 23, 59, 59);
        if (DateTime.now().isAfter(endOfExpiryDay)) {
          return 'expired';
        }
      } catch (_) {}
    }
    return s;
  }

  Map<String, dynamic> toMap() {
    return {
      'announcementId': announcementId,
      'title': title,
      'description': description,
      'audience': audience,
      'targetUserDocId': targetUserDocId,
      'targetUserName': targetUserName,
      'targetUserEmail': targetUserEmail,
      'targetUserId': targetUserId,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'publishDate': publishDate,
      'expiryDate': expiryDate,
      'createdDate': createdDate,
      'updatedAt': updatedAt,
      'status': status,
      'priority': priority,
      'subjectCode': subjectCode,
      'subjectName': subjectName,
      'subjectDocId': subjectDocId,
      'lecturerId': lecturerId,
      'lecturerName': lecturerName,
      'attachmentUrl': attachmentUrl,
      'readBy': readBy,
    };
  }

  factory AnnouncementModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AnnouncementModel(
      docId: doc.id,
      announcementId: data['announcementId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? (data['message'] ?? ''),
      audience: data['audience'] ?? 'all_users',
      targetUserDocId: data['targetUserDocId'],
      targetUserName: data['targetUserName'],
      targetUserEmail: data['targetUserEmail'],
      targetUserId: data['targetUserId'],
      createdBy: data['createdBy'] ?? 'Admin',
      updatedBy: data['updatedBy'],
      publishDate: data['publishDate'] ?? '',
      expiryDate: data['expiryDate'] ?? '',
      createdDate: data['createdDate'] ?? '',
      updatedAt: data['updatedAt'],
      status: data['status'] ?? 'draft',
      priority: data['priority'] ?? 'Normal',
      subjectCode: data['subjectCode'],
      subjectName: data['subjectName'],
      subjectDocId: data['subjectDocId'],
      lecturerId: data['lecturerId'],
      lecturerName: data['lecturerName'],
      attachmentUrl: data['attachmentUrl'],
      readBy: List<String>.from(data['readBy'] ?? []),
    );
  }

  factory AnnouncementModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return AnnouncementModel(
      docId: id,
      announcementId: map['announcementId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? (map['message'] ?? ''),
      audience: map['audience'] ?? 'all_users',
      targetUserDocId: map['targetUserDocId'],
      targetUserName: map['targetUserName'],
      targetUserEmail: map['targetUserEmail'],
      targetUserId: map['targetUserId'],
      createdBy: map['createdBy'] ?? 'Admin',
      updatedBy: map['updatedBy'],
      publishDate: map['publishDate'] ?? '',
      expiryDate: map['expiryDate'] ?? '',
      createdDate: map['createdDate'] ?? '',
      updatedAt: map['updatedAt'],
      status: map['status'] ?? 'draft',
      priority: map['priority'] ?? 'Normal',
      subjectCode: map['subjectCode'],
      subjectName: map['subjectName'],
      subjectDocId: map['subjectDocId'],
      lecturerId: map['lecturerId'],
      lecturerName: map['lecturerName'],
      attachmentUrl: map['attachmentUrl'],
      readBy: List<String>.from(map['readBy'] ?? []),
    );
  }
}
