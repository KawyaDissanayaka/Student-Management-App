import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import 'send_notification_screen.dart';

class NotificationDetailScreen extends StatefulWidget {
  final String notificationDocId;

  const NotificationDetailScreen({super.key, required this.notificationDocId});

  @override
  State<NotificationDetailScreen> createState() => _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  final NotificationService _notificationService = NotificationService();

  final Map<String, String> _typeLabels = {
    'general': 'General Notice',
    'assignment': 'Assignment Alert',
    'task': 'Task Notice',
    'attendance': 'Attendance Warning',
    'announcement': 'Announcement',
    'system': 'System Alert',
  };

  final Map<String, Color> _typeColors = {
    'general': Colors.purpleAccent,
    'assignment': Colors.orangeAccent,
    'task': Colors.cyanAccent,
    'attendance': Colors.tealAccent,
    'announcement': Colors.pinkAccent,
    'system': Colors.amberAccent,
  };

  final Map<String, String> _audienceLabels = {
    'all_users': 'Students & Lecturers',
    'all_students': 'All Students',
    'all_lecturers': 'All Lecturers',
    'specific_student': 'Specific Student',
    'specific_lecturer': 'Specific Lecturer',
  };

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'sent':
        return Colors.greenAccent;
      case 'scheduled':
        return Colors.purpleAccent;
      case 'failed':
      case 'cancelled':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(String isoDate) {
    if (isoDate.isEmpty) return '—';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $hour:$minute';
    } catch (_) {
      return isoDate;
    }
  }

  Future<void> _cancelNotification(NotificationModel notification) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Scheduled Notification', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Are you sure you want to cancel this scheduled notification? It will not be sent to users.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Cancel Notification', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _notificationService.cancelNotification(notification.docId!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notification cancelled.'), backgroundColor: Colors.orange),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  Future<void> _deleteNotification(NotificationModel notification) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Notification', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Are you sure you want to permanently delete this notification record?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _notificationService.deleteNotification(notification.docId!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notification deleted.'), backgroundColor: Colors.redAccent),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('notifications').doc(widget.notificationDocId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: const Color(0xFF0F172A),
            appBar: AppBar(backgroundColor: const Color(0xFF1E293B)),
            body: Center(
              child: Text('Error loading notification: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            backgroundColor: const Color(0xFF0F172A),
            appBar: AppBar(backgroundColor: const Color(0xFF1E293B)),
            body: const Center(
              child: CircularProgressIndicator(color: Color(0xFFA855F7)),
            ),
          );
        }

        final notification = NotificationModel.fromFirestore(snapshot.data!);
        final effectiveStatus = notification.effectiveStatus;
        final isScheduled = effectiveStatus == 'scheduled';
        final isSpecific = notification.audience.startsWith('specific');
        final typeColor = _typeColors[notification.type] ?? Colors.purpleAccent;

        return Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E293B),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              notification.notificationId.isNotEmpty ? notification.notificationId : 'Notification Details',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            actions: [
              if (isScheduled)
                IconButton(
                  icon: const Icon(Icons.edit_rounded, color: Colors.white70),
                  tooltip: 'Edit Schedule',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SendNotificationScreen(existingScheduledNotification: notification),
                      ),
                    );
                  },
                ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                tooltip: 'Delete',
                onPressed: () => _deleteNotification(notification),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Type Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: typeColor.withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: typeColor.withAlpha(120)),
                          ),
                          child: Text(
                            _typeLabels[notification.type]?.toUpperCase() ?? notification.type.toUpperCase(),
                            style: TextStyle(color: typeColor, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statusColor(effectiveStatus).withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _statusColor(effectiveStatus).withAlpha(120)),
                          ),
                          child: Text(
                            effectiveStatus.toUpperCase(),
                            style: TextStyle(
                              color: _statusColor(effectiveStatus),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      notification.title,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.admin_panel_settings_rounded, size: 15, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          'Sender: ${notification.sentBy}',
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Audience & Target Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TARGET AUDIENCE',
                      style: TextStyle(color: Color(0xFFC084FC), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          notification.audience == 'all_users'
                              ? Icons.groups_rounded
                              : (notification.audience.contains('student')
                                  ? Icons.school_rounded
                                  : Icons.cast_for_education_rounded),
                          size: 20,
                          color: Colors.purpleAccent,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _audienceLabels[notification.audience] ?? notification.audience,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                    if (isSpecific && notification.targetUserName != null) ...[
                      const SizedBox(height: 10),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 6),
                      Text(
                        'Recipient: ${notification.targetUserName} (${notification.targetUserEmail ?? ""})',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Schedule & Timeline Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DELIVERY TIMELINE',
                      style: TextStyle(color: Color(0xFFC084FC), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          isScheduled ? Icons.schedule_rounded : Icons.send_rounded,
                          size: 16,
                          color: isScheduled ? Colors.purpleAccent : Colors.greenAccent,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isScheduled
                              ? 'Scheduled For: ${_formatDateTime(notification.scheduledDate ?? "")}'
                              : 'Delivered On: ${_formatDateTime(notification.sentDate)}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Message Body Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MESSAGE BODY',
                      style: TextStyle(color: Color(0xFFC084FC), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      notification.message.isNotEmpty ? notification.message : 'No message body.',
                      style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.6),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Read Status Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'READ STATISTICS',
                          style: TextStyle(color: Color(0xFFC084FC), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.teal.withAlpha(40),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${notification.readBy.length} Users Read',
                            style: const TextStyle(color: Colors.tealAccent, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    if (notification.readBy.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Read by: ${notification.readBy.join(", ")}',
                        style: const TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action button for scheduled notifications
              if (isScheduled) ...[
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => _cancelNotification(notification),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withAlpha(200),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.cancel_schedule_send_rounded, color: Colors.white),
                    label: const Text('Cancel Scheduled Notification', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }
}
