import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _notificationsRef =>
      _firestore.collection('notifications');

  /// Real-time stream of all notifications ordered by createdDate descending (Admin view)
  Stream<List<NotificationModel>> getNotificationsStream() {
    return _notificationsRef
        .orderBy('createdDate', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => NotificationModel.fromFirestore(d)).toList());
  }

  /// Real-time stream of notifications for a specific student or lecturer
  Stream<List<NotificationModel>> getUserNotificationsStream(String userEmail, String userRole) {
    final cleanEmail = userEmail.trim().toLowerCase();
    final role = userRole.toLowerCase();

    return _notificationsRef
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => NotificationModel.fromFirestore(d))
              .where((n) {
                // Must be delivered (effective status is 'sent') and not cancelled
                if (n.effectiveStatus != 'sent' || n.status.toLowerCase() == 'cancelled') {
                  return false;
                }

                // Check audience targeting
                if (n.audience == 'all_users') return true;
                if (role == 'student' && n.audience == 'all_students') return true;
                if (role == 'lecturer' && n.audience == 'all_lecturers') return true;

                if (role == 'student' &&
                    n.audience == 'specific_student' &&
                    n.targetUserEmail?.trim().toLowerCase() == cleanEmail) {
                  return true;
                }
                if (role == 'lecturer' &&
                    n.audience == 'specific_lecturer' &&
                    n.targetUserEmail?.trim().toLowerCase() == cleanEmail) {
                  return true;
                }

                return false;
              })
              .toList();

          // Sort by sentDate/createdDate descending
          list.sort((a, b) => b.createdDate.compareTo(a.createdDate));
          return list;
        });
  }

  /// Stream of unread notification count for badge rendering
  Stream<int> getUnreadCountStream(String userEmail, String userRole) {
    return getUserNotificationsStream(userEmail, userRole).map((list) {
      return list.where((n) => !n.isReadByUser(userEmail)).length;
    });
  }

  /// Auto-generate next Notification ID (e.g. NTF-1001, NTF-1002)
  Future<String> generateNextNotificationId() async {
    try {
      final snap = await _notificationsRef.get();
      if (snap.docs.isEmpty) {
        return 'NTF-1001';
      }

      int maxNum = 1000;
      for (var doc in snap.docs) {
        final data = doc.data();
        final rawId = data['notificationId']?.toString() ?? '';
        final match = RegExp(r'NTF-(\d+)').firstMatch(rawId);
        if (match != null) {
          final numVal = int.tryParse(match.group(1) ?? '0') ?? 0;
          if (numVal > maxNum) {
            maxNum = numVal;
          }
        }
      }
      return 'NTF-${maxNum + 1}';
    } catch (e) {
      debugPrint('Error generating next notificationId: $e');
      return 'NTF-1001';
    }
  }

  /// Send / Create a notification
  Future<void> sendNotification(NotificationModel notification) async {
    try {
      final docRef = await _notificationsRef.add(notification.toMap());
      debugPrint('Notification sent with Doc ID: ${docRef.id}');
    } catch (e) {
      debugPrint('Error sending notification: $e');
      throw Exception('Failed to send notification: $e');
    }
  }

  /// Update an existing scheduled notification
  Future<void> updateNotification(NotificationModel notification) async {
    if (notification.docId == null) return;
    try {
      await _notificationsRef.doc(notification.docId).update(notification.toMap());
      debugPrint('Notification updated: ${notification.docId}');
    } catch (e) {
      debugPrint('Error updating notification: $e');
      throw Exception('Failed to update notification: $e');
    }
  }

  /// Cancel a scheduled notification
  Future<void> cancelNotification(String docId) async {
    try {
      await _notificationsRef.doc(docId).update({'status': 'cancelled'});
      debugPrint('Notification $docId cancelled');
    } catch (e) {
      debugPrint('Error cancelling notification: $e');
      throw Exception('Failed to cancel notification: $e');
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String docId) async {
    try {
      await _notificationsRef.doc(docId).delete();
      debugPrint('Notification $docId deleted');
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      throw Exception('Failed to delete notification: $e');
    }
  }

  /// Mark single notification as read by user
  Future<void> markAsRead(String docId, String userEmail) async {
    final clean = userEmail.trim().toLowerCase();
    if (clean.isEmpty) return;
    try {
      await _notificationsRef.doc(docId).update({
        'readBy': FieldValue.arrayUnion([clean]),
      });
      debugPrint('Notification $docId marked as read by $clean');
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(String userEmail, String userRole) async {
    final clean = userEmail.trim().toLowerCase();
    if (clean.isEmpty) return;
    try {
      final snap = await _notificationsRef.get();
      final batch = _firestore.batch();
      int count = 0;

      for (var doc in snap.docs) {
        final notif = NotificationModel.fromFirestore(doc);
        if (notif.effectiveStatus == 'sent' && !notif.isReadByUser(clean)) {
          // Check audience
          bool matches = false;
          if (notif.audience == 'all_users') matches = true;
          if (userRole.toLowerCase() == 'student' && notif.audience == 'all_students') matches = true;
          if (userRole.toLowerCase() == 'lecturer' && notif.audience == 'all_lecturers') matches = true;
          if (notif.targetUserEmail?.trim().toLowerCase() == clean) matches = true;

          if (matches) {
            batch.update(doc.reference, {
              'readBy': FieldValue.arrayUnion([clean]),
            });
            count++;
          }
        }
      }

      if (count > 0) {
        await batch.commit();
        debugPrint('Marked $count notifications as read for $clean');
      }
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // SYSTEM AUTOMATIC NOTIFICATION TRIGGERS
  // ---------------------------------------------------------------------------

  /// Automatic trigger for New Task assignment
  Future<void> triggerNewTaskNotification({
    required String taskId,
    required String taskTitle,
    required String userEmail,
    required String userName,
    required String userRole,
    required String priority,
    required String dueDate,
  }) async {
    try {
      final notifId = await generateNextNotificationId();
      final notification = NotificationModel(
        notificationId: notifId,
        title: 'New Task Assigned: $taskTitle',
        message: 'You have been assigned task "$taskTitle" with $priority priority. Due date: $dueDate.',
        type: 'task',
        audience: userRole.toLowerCase() == 'student' ? 'specific_student' : 'specific_lecturer',
        targetUserName: userName,
        targetUserEmail: userEmail.trim().toLowerCase(),
        sentBy: 'System',
        sentDate: DateTime.now().toIso8601String(),
        createdDate: DateTime.now().toIso8601String(),
        status: 'sent',
      );
      await sendNotification(notification);
    } catch (e) {
      debugPrint('Failed to trigger automatic task notification: $e');
    }
  }

  /// Automatic trigger for New Assignment
  Future<void> triggerNewAssignmentNotification({
    required String assignmentId,
    required String title,
    required String subjectName,
    required String dueDate,
  }) async {
    try {
      final notifId = await generateNextNotificationId();
      final notification = NotificationModel(
        notificationId: notifId,
        title: 'New Assignment: $title',
        message: 'A new assignment "$title" has been published for $subjectName. Submission deadline is $dueDate.',
        type: 'assignment',
        audience: 'all_students',
        sentBy: 'System',
        sentDate: DateTime.now().toIso8601String(),
        createdDate: DateTime.now().toIso8601String(),
        status: 'sent',
      );
      await sendNotification(notification);
    } catch (e) {
      debugPrint('Failed to trigger automatic assignment notification: $e');
    }
  }

  /// Automatic trigger for New Announcement
  Future<void> triggerNewAnnouncementNotification({
    required String announcementId,
    required String title,
    required String audience,
    String? targetUserEmail,
    String? targetUserName,
  }) async {
    try {
      final notifId = await generateNextNotificationId();
      final notification = NotificationModel(
        notificationId: notifId,
        title: 'Notice: $title',
        message: 'A new administrative announcement "$title" has been published.',
        type: 'announcement',
        audience: audience,
        targetUserEmail: targetUserEmail,
        targetUserName: targetUserName,
        sentBy: 'System',
        sentDate: DateTime.now().toIso8601String(),
        createdDate: DateTime.now().toIso8601String(),
        status: 'sent',
      );
      await sendNotification(notification);
    } catch (e) {
      debugPrint('Failed to trigger automatic announcement notification: $e');
    }
  }

  /// Automatic trigger for Low Attendance warning
  Future<void> triggerLowAttendanceAlert({
    required String studentEmail,
    required String studentName,
    required double currentAttendance,
    required double threshold,
  }) async {
    try {
      final notifId = await generateNextNotificationId();
      final notification = NotificationModel(
        notificationId: notifId,
        title: '⚠️ Low Attendance Alert',
        message: 'Dear $studentName, your overall attendance is ${currentAttendance.toStringAsFixed(1)}%, which is below the required threshold of ${threshold.toStringAsFixed(0)}%. Please attend upcoming classes to avoid academic penalties.',
        type: 'attendance',
        audience: 'specific_student',
        targetUserName: studentName,
        targetUserEmail: studentEmail.trim().toLowerCase(),
        sentBy: 'System',
        sentDate: DateTime.now().toIso8601String(),
        createdDate: DateTime.now().toIso8601String(),
        status: 'sent',
      );
      await sendNotification(notification);
    } catch (e) {
      debugPrint('Failed to trigger automatic low attendance alert: $e');
    }
  }
}
