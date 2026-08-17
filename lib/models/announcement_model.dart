import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementModel {
  final String? docId;
  final String announcementId;
  final String title;
  final String description;
  final String audience; // 'all_students' | 'all_lecturers' | 'all_users' | 'specific_student' | 'specific_lecturer'
  final String? targetUserDocId;
  final String? targetUserName;
  final String? targetUserEmail;
  final String? targetUserId; // Student ID or Lecturer ID
  final String createdBy;
  final String publishDate; // YYYY-MM-DD
  final String expiryDate; // YYYY-MM-DD
  final String createdDate; // ISO string
  final String? updatedAt; // ISO string when modified after publishing
  final String status; // 'draft' | 'published' | 'expired' | 'deactivated'

  AnnouncementModel({
    this.docId,
    required this.announcementId,
    required this.title,
    required this.description,
    required this.audience,
    this.targetUserDocId,
    this.targetUserName,
    this.targetUserEmail,
    this.targetUserId,
    required this.createdBy,
    required this.publishDate,
    required this.expiryDate,
    required this.createdDate,
    this.updatedAt,
    this.status = 'draft',
  });

  /// Computed dynamic status:
  /// If status is 'draft' or 'deactivated', keep it.
  /// If status is 'published', but today is after expiryDate (end of day), return 'expired'.
  String get effectiveStatus {
    final s = status.toLowerCase();
    if (s == 'draft' || s == 'deactivated') {
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
      'publishDate': publishDate,
      'expiryDate': expiryDate,
      'createdDate': createdDate,
      'updatedAt': updatedAt,
      'status': status,
    };
  }

  factory AnnouncementModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AnnouncementModel(
      docId: doc.id,
      announcementId: data['announcementId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      audience: data['audience'] ?? 'all_users',
      targetUserDocId: data['targetUserDocId'],
      targetUserName: data['targetUserName'],
      targetUserEmail: data['targetUserEmail'],
      targetUserId: data['targetUserId'],
      createdBy: data['createdBy'] ?? 'Admin',
      publishDate: data['publishDate'] ?? '',
      expiryDate: data['expiryDate'] ?? '',
      createdDate: data['createdDate'] ?? '',
      updatedAt: data['updatedAt'],
      status: data['status'] ?? 'draft',
    );
  }

  factory AnnouncementModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return AnnouncementModel(
      docId: id,
      announcementId: map['announcementId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      audience: map['audience'] ?? 'all_users',
      targetUserDocId: map['targetUserDocId'],
      targetUserName: map['targetUserName'],
      targetUserEmail: map['targetUserEmail'],
      targetUserId: map['targetUserId'],
      createdBy: map['createdBy'] ?? 'Admin',
      publishDate: map['publishDate'] ?? '',
      expiryDate: map['expiryDate'] ?? '',
      createdDate: map['createdDate'] ?? '',
      updatedAt: map['updatedAt'],
      status: map['status'] ?? 'draft',
    );
  }

  AnnouncementModel copyWith({
    String? docId,
    String? announcementId,
    String? title,
    String? description,
    String? audience,
    String? targetUserDocId,
    String? targetUserName,
    String? targetUserEmail,
    String? targetUserId,
    String? createdBy,
    String? publishDate,
    String? expiryDate,
    String? createdDate,
    String? updatedAt,
    String? status,
  }) {
    return AnnouncementModel(
      docId: docId ?? this.docId,
      announcementId: announcementId ?? this.announcementId,
      title: title ?? this.title,
      description: description ?? this.description,
      audience: audience ?? this.audience,
      targetUserDocId: targetUserDocId ?? this.targetUserDocId,
      targetUserName: targetUserName ?? this.targetUserName,
      targetUserEmail: targetUserEmail ?? this.targetUserEmail,
      targetUserId: targetUserId ?? this.targetUserId,
      createdBy: createdBy ?? this.createdBy,
      publishDate: publishDate ?? this.publishDate,
      expiryDate: expiryDate ?? this.expiryDate,
      createdDate: createdDate ?? this.createdDate,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
    );
  }
}
