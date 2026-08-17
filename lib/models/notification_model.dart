import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String? docId;
  final String notificationId;
  final String title;
  final String message;
  final String type; // 'general' | 'assignment' | 'task' | 'attendance' | 'announcement' | 'system'
  final String audience; // 'all_students' | 'all_lecturers' | 'all_users' | 'specific_student' | 'specific_lecturer'
  final String? targetUserDocId;
  final String? targetUserName;
  final String? targetUserEmail;
  final String? targetUserId; // Student ID or Lecturer ID
  final String sentBy;
  final String sentDate; // ISO timestamp string
  final String? scheduledDate; // ISO timestamp string if scheduled for future
  final String createdDate; // ISO timestamp string
  final String status; // 'sent' | 'scheduled' | 'failed' | 'cancelled'
  final List<String> readBy; // List of user emails who have marked this notification as read

  NotificationModel({
    this.docId,
    required this.notificationId,
    required this.title,
    required this.message,
    this.type = 'general',
    required this.audience,
    this.targetUserDocId,
    this.targetUserName,
    this.targetUserEmail,
    this.targetUserId,
    required this.sentBy,
    required this.sentDate,
    this.scheduledDate,
    required this.createdDate,
    this.status = 'sent',
    this.readBy = const [],
  });

  /// Dynamically computes effective status:
  /// If status is 'scheduled', check if scheduledDate has arrived or passed. If so, return 'sent'.
  String get effectiveStatus {
    final s = status.toLowerCase();
    if (s == 'scheduled' && scheduledDate != null && scheduledDate!.isNotEmpty) {
      try {
        final parsed = DateTime.parse(scheduledDate!);
        if (DateTime.now().isAfter(parsed)) {
          return 'sent';
        }
      } catch (_) {}
    }
    return s;
  }

  /// Checks if a user (by email) has read this notification
  bool isReadByUser(String userEmail) {
    final clean = userEmail.trim().toLowerCase();
    return readBy.any((email) => email.trim().toLowerCase() == clean);
  }

  Map<String, dynamic> toMap() {
    return {
      'notificationId': notificationId,
      'title': title,
      'message': message,
      'type': type,
      'audience': audience,
      'targetUserDocId': targetUserDocId,
      'targetUserName': targetUserName,
      'targetUserEmail': targetUserEmail,
      'targetUserId': targetUserId,
      'sentBy': sentBy,
      'sentDate': sentDate,
      'scheduledDate': scheduledDate,
      'createdDate': createdDate,
      'status': status,
      'readBy': readBy,
    };
  }

  factory NotificationModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return NotificationModel(
      docId: doc.id,
      notificationId: data['notificationId'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: data['type'] ?? 'general',
      audience: data['audience'] ?? 'all_users',
      targetUserDocId: data['targetUserDocId'],
      targetUserName: data['targetUserName'],
      targetUserEmail: data['targetUserEmail'],
      targetUserId: data['targetUserId'],
      sentBy: data['sentBy'] ?? 'Admin',
      sentDate: data['sentDate'] ?? '',
      scheduledDate: data['scheduledDate'],
      createdDate: data['createdDate'] ?? '',
      status: data['status'] ?? 'sent',
      readBy: List<String>.from(data['readBy'] ?? []),
    );
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return NotificationModel(
      docId: id,
      notificationId: map['notificationId'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: map['type'] ?? 'general',
      audience: map['audience'] ?? 'all_users',
      targetUserDocId: map['targetUserDocId'],
      targetUserName: map['targetUserName'],
      targetUserEmail: map['targetUserEmail'],
      targetUserId: map['targetUserId'],
      sentBy: map['sentBy'] ?? 'Admin',
      sentDate: map['sentDate'] ?? '',
      scheduledDate: map['scheduledDate'],
      createdDate: map['createdDate'] ?? '',
      status: map['status'] ?? 'sent',
      readBy: List<String>.from(map['readBy'] ?? []),
    );
  }

  NotificationModel copyWith({
    String? docId,
    String? notificationId,
    String? title,
    String? message,
    String? type,
    String? audience,
    String? targetUserDocId,
    String? targetUserName,
    String? targetUserEmail,
    String? targetUserId,
    String? sentBy,
    String? sentDate,
    String? scheduledDate,
    String? createdDate,
    String? status,
    List<String>? readBy,
  }) {
    return NotificationModel(
      docId: docId ?? this.docId,
      notificationId: notificationId ?? this.notificationId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      audience: audience ?? this.audience,
      targetUserDocId: targetUserDocId ?? this.targetUserDocId,
      targetUserName: targetUserName ?? this.targetUserName,
      targetUserEmail: targetUserEmail ?? this.targetUserEmail,
      targetUserId: targetUserId ?? this.targetUserId,
      sentBy: sentBy ?? this.sentBy,
      sentDate: sentDate ?? this.sentDate,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      createdDate: createdDate ?? this.createdDate,
      status: status ?? this.status,
      readBy: readBy ?? this.readBy,
    );
  }
}
