import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class UserNotificationsScreen extends StatefulWidget {
  final String userEmail;
  final String userName;
  final String userRole; // 'Student' | 'Lecturer'

  const UserNotificationsScreen({
    super.key,
    required this.userEmail,
    required this.userName,
    required this.userRole,
  });

  @override
  State<UserNotificationsScreen> createState() => _UserNotificationsScreenState();
}

class _UserNotificationsScreenState extends State<UserNotificationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NotificationService _notificationService = NotificationService();

  final Map<String, String> _typeLabels = {
    'general': 'General',
    'assignment': 'Assignment',
    'task': 'Task',
    'attendance': 'Attendance',
    'announcement': 'Announcement',
    'system': 'System',
  };

  final Map<String, IconData> _typeIcons = {
    'general': Icons.notifications_rounded,
    'assignment': Icons.assignment_rounded,
    'task': Icons.task_alt_rounded,
    'attendance': Icons.calendar_month_rounded,
    'announcement': Icons.campaign_rounded,
    'system': Icons.settings_suggest_rounded,
  };

  final Map<String, Color> _typeColors = {
    'general': Colors.purpleAccent,
    'assignment': Colors.orangeAccent,
    'task': Colors.cyanAccent,
    'attendance': Colors.tealAccent,
    'announcement': Colors.pinkAccent,
    'system': Colors.amberAccent,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatDateTime(String isoDate) {
    if (isoDate.isEmpty) return '—';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} ${months[dt.month - 1]}, $hour:$minute';
    } catch (_) {
      return isoDate;
    }
  }

  void _showNotificationDetail(NotificationModel n) {
    // Automatically mark as read
    if (!n.isReadByUser(widget.userEmail) && n.docId != null) {
      _notificationService.markAsRead(n.docId!, widget.userEmail);
    }

    final typeColor = _typeColors[n.type] ?? Colors.purpleAccent;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: typeColor.withAlpha(120)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_typeIcons[n.type] ?? Icons.notifications_rounded, size: 14, color: typeColor),
                      const SizedBox(width: 6),
                      Text(
                        _typeLabels[n.type] ?? n.type,
                        style: TextStyle(color: typeColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDateTime(n.sentDate),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              n.title,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              n.message,
              style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 20),
            const Divider(color: Colors.white10),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Sent by: ${n.sentBy}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close', style: TextStyle(color: Color(0xFFA855F7), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded, color: Colors.purpleAccent),
            tooltip: 'Mark All as Read',
            onPressed: () async {
              await _notificationService.markAllAsRead(widget.userEmail, widget.userRole);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All notifications marked as read.'), backgroundColor: Colors.green),
                );
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFA855F7),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Unread'),
            Tab(text: 'Read'),
          ],
        ),
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _notificationService.getUserNotificationsStream(widget.userEmail, widget.userRole),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFA855F7)));
          }

          final allNotifs = snapshot.data!;
          final unreadNotifs = allNotifs.where((n) => !n.isReadByUser(widget.userEmail)).toList();
          final readNotifs = allNotifs.where((n) => n.isReadByUser(widget.userEmail)).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildList(allNotifs, 'No notifications found.'),
              _buildList(unreadNotifs, 'No unread notifications.'),
              _buildList(readNotifs, 'No read notifications.'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(List<NotificationModel> list, String emptyMessage) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.notifications_off_rounded, size: 64, color: Colors.white24),
            const SizedBox(height: 14),
            Text(
              emptyMessage,
              style: const TextStyle(color: Colors.white60, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        final isRead = item.isReadByUser(widget.userEmail);
        final typeColor = _typeColors[item.type] ?? Colors.purpleAccent;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isRead ? Colors.white10 : const Color(0xFFA855F7).withAlpha(120),
              width: isRead ? 1 : 1.5,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showNotificationDetail(item),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type Icon Circle
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: typeColor.withAlpha(30),
                    child: Icon(_typeIcons[item.type] ?? Icons.notifications_rounded, color: typeColor, size: 20),
                  ),
                  const SizedBox(width: 14),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _typeLabels[item.type] ?? item.type,
                              style: TextStyle(color: typeColor, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            Text(
                              _formatDateTime(item.sentDate),
                              style: const TextStyle(color: Colors.grey, fontSize: 11),
                            ),
                            if (!isRead) ...[
                              const SizedBox(width: 6),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFA855F7),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
