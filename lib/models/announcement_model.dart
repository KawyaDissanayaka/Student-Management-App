import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementModel {
  final String? docId;
  final String announcementId;
  final String title;
  final String description; // message/content
  final String audience; // 'all_students' | 'specific_programme' | 'specific_batch' | 'specific_module' | 'lecturers' | 'everyone' | 'all_users' | 'subject_students'
  final String? programme;
  final String? batchId;
  final String? moduleId; // subjectCode
  final String? targetUserDocId;
  final String? targetUserName;
  final String? targetUserEmail;
  final String? targetUserId; // Student ID or Lecturer ID
  final String createdBy;
  final String createdByName;
  final String? updatedBy;
  final String publishDate; // YYYY-MM-DD
  final String expiryDate; // YYYY-MM-DD
  final String createdDate; // ISO string
  final String? updatedAt; // ISO string when modified
  final String status; // 'Draft' | 'Published' | 'Expired' | 'draft' | 'published' | 'expired' | 'archived' | 'deactivated'
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
    this.audience = 'everyone',
    this.programme,
    this.batchId,
    String? moduleId,
    String? subjectCode,
    this.targetUserDocId,
    this.targetUserName,
    this.targetUserEmail,
    this.targetUserId,
    required this.createdBy,
    this.createdByName = 'Administration',
    this.updatedBy,
    required this.publishDate,
    required this.expiryDate,
    String? createdDate,
    String? createdAt,
    this.updatedAt,
    this.status = 'Published',
    this.priority = 'Normal',
    this.subjectName,
    this.subjectDocId,
    this.lecturerId,
    this.lecturerName,
    this.attachmentUrl,
    this.readBy = const [],
  })  : moduleId = moduleId ?? subjectCode,
        subjectCode = subjectCode ?? moduleId,
        createdDate = createdDate ?? createdAt ?? DateTime.now().toIso8601String();

  /// Message alias
  String get message => description;
  String get createdAt => createdDate;

  bool get isDraft => status.toLowerCase() == 'draft';
  bool get isPublished => status.toLowerCase() == 'published';
  bool get isExpired => effectiveStatus.toLowerCase() == 'expired';

  /// Check if marked read by specific student
  bool isReadBy(String userIdentifier) {
    final clean = userIdentifier.trim().toLowerCase();
    return readBy.map((e) => e.trim().toLowerCase()).contains(clean);
  }

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

  /// Evaluates whether an announcement is targeted to a specific student
  static bool isTargetedToStudent({
    required AnnouncementModel announcement,
    required String studentId,
    required String studentEmail,
    required String programme,
    required String batchId,
    required List<String> enrolledModuleIds,
  }) {
    final aud = announcement.audience.toLowerCase();

    // Universal broadcasts
    if (aud == 'everyone' || aud == 'all_users' || aud == 'all_students') {
      return true;
    }

    // Programme-specific
    if (aud == 'specific_programme' && announcement.programme != null) {
      return announcement.programme!.trim().toLowerCase() == programme.trim().toLowerCase();
    }

    // Batch-specific
    if (aud == 'specific_batch' && announcement.batchId != null) {
      return announcement.batchId!.trim().toLowerCase() == batchId.trim().toLowerCase();
    }

    // Module-specific
    if ((aud == 'specific_module' || aud == 'subject_students') && announcement.moduleId != null) {
      return enrolledModuleIds
          .map((m) => m.trim().toUpperCase())
          .contains(announcement.moduleId!.trim().toUpperCase());
    }

    // Direct student
    if (announcement.targetUserId == studentId || announcement.targetUserEmail?.toLowerCase() == studentEmail.toLowerCase()) {
      return true;
    }

    return false;
  }

  Map<String, dynamic> toMap() {
    return {
      'announcementId': announcementId,
      'title': title,
      'description': description,
      'message': description,
      'audience': audience,
      'programme': programme,
      'batchId': batchId,
      'moduleId': moduleId,
      'targetUserDocId': targetUserDocId,
      'targetUserName': targetUserName,
      'targetUserEmail': targetUserEmail,
      'targetUserId': targetUserId,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'updatedBy': updatedBy,
      'publishDate': publishDate,
      'expiryDate': expiryDate,
      'createdDate': createdDate,
      'createdAt': createdDate,
      'updatedAt': updatedAt,
      'status': status,
      'priority': priority,
      'subjectCode': moduleId,
      'subjectName': subjectName,
      'subjectDocId': subjectDocId,
      'lecturerId': lecturerId,
      'lecturerName': lecturerName,
      'attachmentUrl': attachmentUrl,
      'readBy': readBy,
    };
  }

  factory AnnouncementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final mod = data['moduleId'] ?? data['subjectCode'];

    return AnnouncementModel(
      docId: doc.id,
      announcementId: data['announcementId'] ?? doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? (data['message'] ?? ''),
      audience: data['audience'] ?? 'everyone',
      programme: data['programme'],
      batchId: data['batchId'] ?? data['batch'],
      moduleId: mod,
      subjectCode: mod,
      targetUserDocId: data['targetUserDocId'],
      targetUserName: data['targetUserName'],
      targetUserEmail: data['targetUserEmail'],
      targetUserId: data['targetUserId'],
      createdBy: data['createdBy'] ?? 'Admin',
      createdByName: data['createdByName'] ?? 'Administration',
      updatedBy: data['updatedBy'],
      publishDate: data['publishDate'] ?? '',
      expiryDate: data['expiryDate'] ?? '',
      createdDate: data['createdDate'] ?? (data['createdAt'] ?? ''),
      updatedAt: data['updatedAt'],
      status: data['status'] ?? 'Published',
      priority: data['priority'] ?? 'Normal',
      subjectName: data['subjectName'],
      subjectDocId: data['subjectDocId'],
      lecturerId: data['lecturerId'],
      lecturerName: data['lecturerName'],
      attachmentUrl: data['attachmentUrl'],
      readBy: List<String>.from(data['readBy'] ?? []),
    );
  }

  factory AnnouncementModel.fromMap(Map<String, dynamic> map, {String? id}) {
    final mod = map['moduleId'] ?? map['subjectCode'];
    return AnnouncementModel(
      docId: id,
      announcementId: map['announcementId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? (map['message'] ?? ''),
      audience: map['audience'] ?? 'everyone',
      programme: map['programme'],
      batchId: map['batchId'] ?? map['batch'],
      moduleId: mod,
      subjectCode: mod,
      targetUserDocId: map['targetUserDocId'],
      targetUserName: map['targetUserName'],
      targetUserEmail: map['targetUserEmail'],
      targetUserId: map['targetUserId'],
      createdBy: map['createdBy'] ?? 'Admin',
      createdByName: map['createdByName'] ?? 'Administration',
      updatedBy: map['updatedBy'],
      publishDate: map['publishDate'] ?? '',
      expiryDate: map['expiryDate'] ?? '',
      createdDate: map['createdDate'] ?? (map['createdAt'] ?? ''),
      updatedAt: map['updatedAt'],
      status: map['status'] ?? 'Published',
      priority: map['priority'] ?? 'Normal',
      subjectName: map['subjectName'],
      subjectDocId: map['subjectDocId'],
      lecturerId: map['lecturerId'],
      lecturerName: map['lecturerName'],
      attachmentUrl: map['attachmentUrl'],
      readBy: List<String>.from(map['readBy'] ?? []),
    );
  }
}
