import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/announcement_model.dart';
import '../../services/announcement_service.dart';
import 'add_edit_announcement_screen.dart';

class AnnouncementDetailScreen extends StatefulWidget {
  final String announcementDocId;

  const AnnouncementDetailScreen({super.key, required this.announcementDocId});

  @override
  State<AnnouncementDetailScreen> createState() => _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends State<AnnouncementDetailScreen> {
  final AnnouncementService _announcementService = AnnouncementService();

  final Map<String, String> _audienceLabels = {
    'all_users': 'Students & Lecturers',
    'all_students': 'All Students',
    'all_lecturers': 'All Lecturers',
    'specific_student': 'Specific Student',
    'specific_lecturer': 'Specific Lecturer',
  };

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'published':
        return Colors.greenAccent;
      case 'expired':
        return Colors.redAccent;
      case 'draft':
        return Colors.amberAccent;
      case 'deactivated':
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String isoDate) {
    if (isoDate.isEmpty) return '—';
    try {
      final dt = DateTime.parse(isoDate);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return isoDate;
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

  Future<void> _togglePublish(AnnouncementModel announcement) async {
    final isPublished = announcement.status.toLowerCase() == 'published';
    try {
      await _announcementService.togglePublishStatus(announcement.docId!, announcement.status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isPublished ? 'Announcement moved to Draft.' : 'Announcement published successfully!'),
            backgroundColor: isPublished ? Colors.orange : Colors.green,
          ),
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

  Future<void> _confirmDeactivate(AnnouncementModel announcement) async {
    final isDeactivated = announcement.status.toLowerCase() == 'deactivated';
    final action = isDeactivated ? 'Reactivate' : 'Deactivate';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '$action Announcement',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          isDeactivated
              ? 'Are you sure you want to reactivate "${announcement.title}"?'
              : 'Are you sure you want to deactivate "${announcement.title}"? It will be archived and hidden from all students and lecturers.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDeactivated ? Colors.green : Colors.redAccent,
            ),
            child: Text(action, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        if (isDeactivated) {
          await _announcementService.reactivateAnnouncement(announcement.docId!);
        } else {
          await _announcementService.deactivateAnnouncement(announcement.docId!);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Announcement ${isDeactivated ? "reactivated" : "deactivated"} successfully.'),
              backgroundColor: isDeactivated ? Colors.green : Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Action failed: $e'), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('announcements').doc(widget.announcementDocId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: const Color(0xFF0F172A),
            appBar: AppBar(backgroundColor: const Color(0xFF1E293B)),
            body: Center(
              child: Text('Error loading announcement: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            backgroundColor: const Color(0xFF0F172A),
            appBar: AppBar(backgroundColor: const Color(0xFF1E293B)),
            body: const Center(
              child: CircularProgressIndicator(color: Color(0xFFEC4899)),
            ),
          );
        }

        final announcement = AnnouncementModel.fromFirestore(snapshot.data!);
        final effectiveStatus = announcement.effectiveStatus;
        final isDeactivated = announcement.status.toLowerCase() == 'deactivated';
        final isPublished = announcement.status.toLowerCase() == 'published';
        final isSpecific = announcement.audience.startsWith('specific');

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
              announcement.announcementId.isNotEmpty ? announcement.announcementId : 'Notice Details',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: Colors.white70),
                tooltip: 'Edit Notice',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddEditAnnouncementScreen(existingAnnouncement: announcement),
                    ),
                  );
                },
              ),
              IconButton(
                icon: Icon(
                  isDeactivated ? Icons.restore_rounded : Icons.block_rounded,
                  color: isDeactivated ? Colors.greenAccent : Colors.redAccent,
                ),
                tooltip: isDeactivated ? 'Reactivate Notice' : 'Deactivate Notice',
                onPressed: () => _confirmDeactivate(announcement),
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
                        // Audience Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEC4899).withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFEC4899).withAlpha(120)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                announcement.audience == 'all_users'
                                    ? Icons.groups_rounded
                                    : (announcement.audience.contains('student')
                                        ? Icons.school_rounded
                                        : Icons.cast_for_education_rounded),
                                size: 14,
                                color: const Color(0xFFF472B6),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _audienceLabels[announcement.audience] ?? announcement.audience,
                                style: const TextStyle(
                                  color: Color(0xFFF472B6),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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
                      announcement.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.admin_panel_settings_rounded, size: 15, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          'Created By: ${announcement.createdBy}',
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Specific Target User details if applicable
              if (isSpecific && announcement.targetUserName != null) ...[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.pinkAccent.withAlpha(50)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFFEC4899).withAlpha(40),
                        child: Icon(
                          announcement.audience.contains('student') ? Icons.school_rounded : Icons.cast_for_education_rounded,
                          color: const Color(0xFFF472B6),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              announcement.targetUserName!,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${announcement.targetUserEmail ?? ""} ${announcement.targetUserId != null ? "• ${announcement.targetUserId}" : ""}',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Schedule & Timeline Card
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
                      'SCHEDULE & TIMELINE',
                      style: TextStyle(
                        color: Color(0xFFF472B6),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.calendar_today_rounded, size: 15, color: Colors.greenAccent),
                                  SizedBox(width: 6),
                                  Text('Publish Date', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _formatDate(announcement.publishDate),
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 40, color: Colors.white10),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.alarm_rounded,
                                    size: 15,
                                    color: effectiveStatus == 'expired' ? Colors.redAccent : Colors.orangeAccent,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Expiry Date',
                                    style: TextStyle(
                                      color: effectiveStatus == 'expired' ? Colors.redAccent : Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _formatDate(announcement.expiryDate),
                                style: TextStyle(
                                  color: effectiveStatus == 'expired' ? Colors.redAccent : Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (announcement.updatedAt != null) ...[
                      const SizedBox(height: 12),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.update_rounded, size: 14, color: Colors.amberAccent),
                          const SizedBox(width: 6),
                          Text(
                            'Last Edited: ${_formatDateTime(announcement.updatedAt!)}',
                            style: const TextStyle(color: Colors.amberAccent, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Content / Description Card
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
                      'NOTICE CONTENT',
                      style: TextStyle(
                        color: Color(0xFFF472B6),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      announcement.description.isNotEmpty ? announcement.description : 'No content available.',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              if (!isDeactivated) ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _togglePublish(announcement),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isPublished ? const Color(0xFF334155) : const Color(0xFF10B981),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: Icon(
                          isPublished ? Icons.unpublished_rounded : Icons.publish_rounded,
                          color: Colors.white,
                        ),
                        label: Text(
                          isPublished ? 'Unpublish (Draft)' : 'Publish Notice',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
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
