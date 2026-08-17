import 'package:flutter/material.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import 'send_notification_screen.dart';
import 'notification_detail_screen.dart';

class NotificationsListScreen extends StatefulWidget {
  const NotificationsListScreen({super.key});

  @override
  State<NotificationsListScreen> createState() => _NotificationsListScreenState();
}

class _NotificationsListScreenState extends State<NotificationsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final NotificationService _notificationService = NotificationService();

  String _searchQuery = '';
  String _filterType = 'All';
  String _filterAudience = 'All';
  String _filterStatus = 'All';

  final List<String> _typeOptions = ['All', 'general', 'assignment', 'task', 'attendance', 'announcement', 'system'];
  final List<String> _audienceOptions = ['All', 'all_users', 'all_students', 'all_lecturers', 'specific_student', 'specific_lecturer'];
  final List<String> _statusOptions = ['All', 'sent', 'scheduled', 'cancelled'];

  final Map<String, String> _typeLabels = {
    'All': 'All Types',
    'general': 'General',
    'assignment': 'Assignment',
    'task': 'Task',
    'attendance': 'Attendance',
    'announcement': 'Announcement',
    'system': 'System',
  };

  final Map<String, String> _audienceLabels = {
    'All': 'All Audiences',
    'all_users': 'Students & Lecturers',
    'all_students': 'All Students',
    'all_lecturers': 'All Lecturers',
    'specific_student': 'Specific Student',
    'specific_lecturer': 'Specific Lecturer',
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
      return '${dt.day} ${months[dt.month - 1]}, $hour:$minute';
    } catch (_) {
      return isoDate;
    }
  }

  List<NotificationModel> _applyFilters(List<NotificationModel> all) {
    return all.where((n) {
      final q = _searchQuery.toLowerCase();
      final matchSearch = q.isEmpty ||
          n.notificationId.toLowerCase().contains(q) ||
          n.title.toLowerCase().contains(q) ||
          n.sentBy.toLowerCase().contains(q) ||
          (n.targetUserName?.toLowerCase().contains(q) ?? false);

      final effectiveStatus = n.effectiveStatus;
      final matchStatus = _filterStatus == 'All' || effectiveStatus == _filterStatus;
      final matchType = _filterType == 'All' || n.type == _filterType;
      final matchAudience = _filterAudience == 'All' || n.audience == _filterAudience;

      return matchSearch && matchStatus && matchType && matchAudience;
    }).toList();
  }

  void _showFilterSheet() {
    String tempType = _filterType;
    String tempAudience = _filterAudience;
    String tempStatus = _filterStatus;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheet) => Padding(
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
              const Text(
                'Filter Notifications',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 18),
              _buildDropdown('Type', tempType, _typeOptions, _typeLabels, (v) => setSheet(() => tempType = v!)),
              const SizedBox(height: 14),
              _buildDropdown('Audience', tempAudience, _audienceOptions, _audienceLabels, (v) => setSheet(() => tempAudience = v!)),
              const SizedBox(height: 14),
              _buildDropdown('Status', tempStatus, _statusOptions, null, (v) => setSheet(() => tempStatus = v!)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _filterType = 'All';
                          _filterAudience = 'All';
                          _filterStatus = 'All';
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Reset', style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _filterType = tempType;
                          _filterAudience = tempAudience;
                          _filterStatus = tempStatus;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA855F7),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text(
                        'Apply Filters',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String currentVal,
    List<String> options,
    Map<String, String>? displayMap,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentVal,
              isExpanded: true,
              dropdownColor: const Color(0xFF1E293B),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              items: options
                  .map((opt) => DropdownMenuItem(
                        value: opt,
                        child: Text(displayMap?[opt] ?? (opt[0].toUpperCase() + opt.substring(1))),
                      ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _cancelNotification(NotificationModel notification) async {
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

  Future<void> _deleteNotification(NotificationModel notification) async {
    try {
      await _notificationService.deleteNotification(notification.docId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification deleted.'), backgroundColor: Colors.redAccent),
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
            icon: const Icon(Icons.tune_rounded, color: Colors.white70),
            tooltip: 'Filter Notifications',
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFA855F7),
        icon: const Icon(Icons.send_rounded, color: Colors.white),
        label: const Text('Send Alert', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SendNotificationScreen()),
          );
        },
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _notificationService.getNotificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading notifications: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFA855F7)));
          }

          final allNotifs = snapshot.data!;
          final filtered = _applyFilters(allNotifs);

          // Statistics: accurately computed
          final totalCount = allNotifs.length;
          final sentCount = allNotifs.where((n) => n.effectiveStatus == 'sent').length;
          final scheduledCount = allNotifs.where((n) => n.effectiveStatus == 'scheduled').length;
          final cancelledCount = allNotifs.where((n) => n.status.toLowerCase() == 'cancelled').length;

          return CustomScrollView(
            slivers: [
              // 1. Statistics Cards
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard('Total', '$totalCount', Icons.notifications_rounded, Colors.purpleAccent),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard('Sent', '$sentCount', Icons.send_rounded, Colors.greenAccent),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard('Scheduled', '$scheduledCount', Icons.schedule_rounded, Colors.cyanAccent),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard('Cancelled', '$cancelledCount', Icons.cancel_outlined, Colors.redAccent),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Search & Active Filters
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search by ID, Title, Recipient...',
                          hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                          prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, color: Colors.white54, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: const Color(0xFF1E293B),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      if (_filterType != 'All' || _filterAudience != 'All' || _filterStatus != 'All')
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              if (_filterType != 'All')
                                _buildFilterChip(
                                  'Type: ${_typeLabels[_filterType] ?? _filterType}',
                                  () => setState(() => _filterType = 'All'),
                                ),
                              if (_filterAudience != 'All')
                                _buildFilterChip(
                                  'Audience: ${_audienceLabels[_filterAudience] ?? _filterAudience}',
                                  () => setState(() => _filterAudience = 'All'),
                                ),
                              if (_filterStatus != 'All')
                                _buildFilterChip(
                                  'Status: ${_filterStatus.toUpperCase()}',
                                  () => setState(() => _filterStatus = 'All'),
                                ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _filterType = 'All';
                                    _filterAudience = 'All';
                                    _filterStatus = 'All';
                                  });
                                },
                                child: const Text('Clear All', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // 3. Notification List
              filtered.isEmpty
                  ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.notifications_none_rounded, size: 64, color: Colors.white24),
                            const SizedBox(height: 12),
                            Text(
                              allNotifs.isEmpty ? 'No notifications sent yet.' : 'No notifications match your filters.',
                              style: const TextStyle(color: Colors.white60, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = filtered[index];
                            return _buildNotificationCard(item);
                          },
                          childCount: filtered.length,
                        ),
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600),
              ),
              Icon(icon, size: 15, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      child: Chip(
        label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
        backgroundColor: const Color(0xFF334155),
        deleteIcon: const Icon(Icons.close_rounded, size: 14, color: Colors.white70),
        onDeleted: onRemove,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel n) {
    final effectiveStatus = n.effectiveStatus;
    final isScheduled = effectiveStatus == 'scheduled';
    final typeColor = _typeColors[n.type] ?? Colors.purpleAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (n.docId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => NotificationDetailScreen(notificationDocId: n.docId!)),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Type badge + Audience + Status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: typeColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: typeColor.withAlpha(100)),
                    ),
                    child: Text(
                      _typeLabels[n.type]?.toUpperCase() ?? n.type.toUpperCase(),
                      style: TextStyle(color: typeColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF334155),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _audienceLabels[n.audience] ?? n.audience,
                      style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _statusColor(effectiveStatus).withAlpha(30),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _statusColor(effectiveStatus).withAlpha(100)),
                    ),
                    child: Text(
                      effectiveStatus.toUpperCase(),
                      style: TextStyle(
                        color: _statusColor(effectiveStatus),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Title
              Text(
                n.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),

              // Body snippet
              Text(
                n.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 10),

              // Footer: Sender & Time
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'By ${n.sentBy}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Row(
                    children: [
                      Icon(
                        isScheduled ? Icons.schedule_rounded : Icons.calendar_today_rounded,
                        size: 13,
                        color: isScheduled ? Colors.purpleAccent : Colors.white60,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isScheduled
                            ? 'Sched: ${_formatDateTime(n.scheduledDate ?? "")}'
                            : _formatDateTime(n.sentDate),
                        style: TextStyle(
                          color: isScheduled ? Colors.purpleAccent : Colors.white60,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(color: Colors.white10, height: 1),
              const SizedBox(height: 4),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      if (n.docId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NotificationDetailScreen(notificationDocId: n.docId!),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.visibility_rounded, size: 16, color: Colors.cyanAccent),
                    label: const Text('View', style: TextStyle(color: Colors.cyanAccent, fontSize: 12)),
                  ),
                  if (isScheduled) ...[
                    const SizedBox(width: 4),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SendNotificationScreen(existingScheduledNotification: n),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit_rounded, size: 16, color: Colors.purpleAccent),
                      label: const Text('Edit', style: TextStyle(color: Colors.purpleAccent, fontSize: 12)),
                    ),
                    const SizedBox(width: 4),
                    TextButton.icon(
                      onPressed: () => _cancelNotification(n),
                      icon: const Icon(Icons.cancel_schedule_send_rounded, size: 16, color: Colors.orangeAccent),
                      label: const Text('Cancel', style: TextStyle(color: Colors.orangeAccent, fontSize: 12)),
                    ),
                  ],
                  const SizedBox(width: 4),
                  TextButton.icon(
                    onPressed: () => _deleteNotification(n),
                    icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                    label: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
