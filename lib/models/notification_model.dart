import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String? docId;
  final String notificationId;
  final String recipientId; // email or studentId or userId
  final String title;
  final String message;
  final String type; // 'Assignment' | 'Task' | 'Attendance' | 'Timetable' | 'Examination' | 'Result' | 'Payment' | 'Announcement' | 'System'
  final String priority; // 'Normal' | 'Important' | 'Urgent'
  final String? relatedId; // Assignment ID, Task ID, Payment ID, Exam ID, Announcement ID
  final String? relatedModuleId; // Subject code e.g. CS101
  final bool isRead;
  final String createdAt; // ISO string
  final String? expiresAt; // ISO string or YYYY-MM-DD
  final String audience; // 'all_students' | 'all_lecturers' | 'all_users' | 'specific_student' | 'specific_lecturer'
  final String? targetUserDocId;
  final String? targetUserName;
  final String? targetUserEmail;
  final String? targetUserId;
  final String sentBy;
  final String sentDate;
  final String? scheduledDate;
  final String createdDate;
  final String status;
  final List<String> readBy;

  NotificationModel({
    this.docId,
    required this.notificationId,
    String? recipientId,
    required this.title,
    required this.message,
    this.type = 'System',
    this.priority = 'Normal',
    this.relatedId,
    this.relatedModuleId,
    this.isRead = false,
    String? createdAt,
    this.expiresAt,
    this.audience = 'all_users',
    this.targetUserDocId,
    this.targetUserName,
    this.targetUserEmail,
    this.targetUserId,
    this.sentBy = 'System',
    String? sentDate,
    this.scheduledDate,
    String? createdDate,
    this.status = 'sent',
    this.readBy = const [],
  })  : recipientId = recipientId ?? targetUserEmail ?? targetUserId ?? '',
        createdAt = createdAt ?? createdDate ?? DateTime.now().toIso8601String(),
        createdDate = createdDate ?? createdAt ?? DateTime.now().toIso8601String(),
        sentDate = sentDate ?? createdAt ?? DateTime.now().toIso8601String();

  // Supported notification types
  static const List<String> supportedTypes = [
    'Assignment',
    'Task',
    'Attendance',
    'Timetable',
    'Examination',
    'Result',
    'Payment',
    'Announcement',
    'System',
  ];

  /// Automatic expiry check
  bool get isExpired {
    if (expiresAt == null || expiresAt!.isEmpty) return false;
    try {
      final parsed = DateTime.parse(expiresAt!);
      final endOfDay = DateTime(parsed.year, parsed.month, parsed.day, 23, 59, 59);
      return DateTime.now().isAfter(endOfDay);
    } catch (_) {
      return false;
    }
  }

  /// Checks if a user (by email or ID) has read this notification
  bool isReadByUser(String userIdentifier) {
    if (isRead) return true;
    final clean = userIdentifier.trim().toLowerCase();
    return readBy.any((e) => e.trim().toLowerCase() == clean);
  }

  Map<String, dynamic> toMap() {
    return {
      'notificationId': notificationId,
      'recipientId': recipientId,
      'title': title,
      'message': message,
      'type': type,
      'priority': priority,
      'relatedId': relatedId,
      'relatedModuleId': relatedModuleId,
      'isRead': isRead,
      'createdAt': createdAt,
      'createdDate': createdDate,
      'expiresAt': expiresAt,
      'audience': audience,
      'targetUserDocId': targetUserDocId,
      'targetUserName': targetUserName,
      'targetUserEmail': targetUserEmail ?? recipientId,
      'targetUserId': targetUserId ?? recipientId,
      'sentBy': sentBy,
      'sentDate': sentDate,
      'scheduledDate': scheduledDate,
      'status': status,
      'readBy': readBy,
    };
  }

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final recId = data['recipientId'] ?? data['targetUserEmail'] ?? data['targetUserId'] ?? '';
    final isR = data['isRead'] == true;

    return NotificationModel(
      docId: doc.id,
      notificationId: data['notificationId'] ?? doc.id,
      recipientId: recId,
      title: data['title'] ?? '',
      message: data['message'] ?? (data['body'] ?? ''),
      type: data['type'] ?? 'System',
      priority: data['priority'] ?? 'Normal',
      relatedId: data['relatedId'],
      relatedModuleId: data['relatedModuleId'] ?? data['subjectCode'],
      isRead: isR,
      createdAt: data['createdAt'] ?? (data['createdDate'] ?? ''),
      expiresAt: data['expiresAt'],
      audience: data['audience'] ?? 'all_users',
      targetUserDocId: data['targetUserDocId'],
      targetUserName: data['targetUserName'],
      targetUserEmail: data['targetUserEmail'],
      targetUserId: data['targetUserId'],
      sentBy: data['sentBy'] ?? 'System',
      sentDate: data['sentDate'] ?? '',
      scheduledDate: data['scheduledDate'],
      createdDate: data['createdDate'] ?? '',
      status: data['status'] ?? 'sent',
      readBy: List<String>.from(data['readBy'] ?? []),
    );
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map, {String? id}) {
    final recId = map['recipientId'] ?? map['targetUserEmail'] ?? map['targetUserId'] ?? '';
    final isR = map['isRead'] == true;

    return NotificationModel(
      docId: id,
      notificationId: map['notificationId'] ?? '',
      recipientId: recId,
      title: map['title'] ?? '',
      message: map['message'] ?? (map['body'] ?? ''),
      type: map['type'] ?? 'System',
      priority: map['priority'] ?? 'Normal',
      relatedId: map['relatedId'],
      relatedModuleId: map['relatedModuleId'] ?? map['subjectCode'],
      isRead: isR,
      createdAt: map['createdAt'] ?? (map['createdDate'] ?? ''),
      expiresAt: map['expiresAt'],
      audience: map['audience'] ?? 'all_users',
      targetUserDocId: map['targetUserDocId'],
      targetUserName: map['targetUserName'],
      targetUserEmail: map['targetUserEmail'],
      targetUserId: map['targetUserId'],
      sentBy: map['sentBy'] ?? 'System',
      sentDate: map['sentDate'] ?? '',
      scheduledDate: map['scheduledDate'],
      createdDate: map['createdDate'] ?? '',
      status: map['status'] ?? 'sent',
      readBy: List<String>.from(map['readBy'] ?? []),
    );
  }
}
