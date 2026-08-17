import 'package:flutter/material.dart';
import '../models/announcement_model.dart';
import '../services/announcement_service.dart';

class UserAnnouncementsScreen extends StatelessWidget {
  final String userEmail;
  final String userName;
  final String userRole; // 'Student' | 'Lecturer'

  const UserAnnouncementsScreen({
    super.key,
    required this.userEmail,
    required this.userName,
    required this.userRole,
  });

  String _displayDate(String isoDate) {
    if (isoDate.isEmpty) return '—';
    try {
      final dt = DateTime.parse(isoDate);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final announcementService = AnnouncementService();
    final isStudent = userRole.toLowerCase() == 'student';
    final stream = isStudent
        ? announcementService.getStudentAnnouncementsStream(userEmail)
        : announcementService.getLecturerAnnouncementsStream(userEmail);

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
          '$userRole Notices & Announcements',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<List<AnnouncementModel>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading notices: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFEC4899)));
          }

          final notices = snapshot.data!;

          if (notices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.campaign_rounded, size: 64, color: Colors.white24),
                  const SizedBox(height: 16),
                  const Text(
                    'No active announcements.',
                    style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'New notices from administration will appear here.',
                    style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 13),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notices.length,
            itemBuilder: (context, index) {
              final notice = notices[index];
              return _buildNoticeCard(context, notice);
            },
          );
        },
      ),
    );
  }

  Widget _buildNoticeCard(BuildContext context, AnnouncementModel notice) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.pinkAccent.withAlpha(50)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Announcement ID + Target Badge + Date
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEC4899).withAlpha(40),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFEC4899).withAlpha(100)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.campaign_rounded, size: 13, color: Color(0xFFF472B6)),
                      const SizedBox(width: 4),
                      Text(
                        notice.announcementId,
                        style: const TextStyle(color: Color(0xFFF472B6), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      _displayDate(notice.publishDate),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              notice.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Content
            Text(
              notice.description,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 8),

            // Footer info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Posted by ${notice.createdBy}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                if (notice.expiryDate.isNotEmpty)
                  Text(
                    'Valid until: ${_displayDate(notice.expiryDate)}',
                    style: const TextStyle(color: Colors.orangeAccent, fontSize: 11),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
