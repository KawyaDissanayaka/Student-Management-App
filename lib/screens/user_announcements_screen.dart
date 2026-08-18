import 'package:flutter/material.dart';
import '../models/announcement_model.dart';
import '../services/announcement_service.dart';

class UserAnnouncementsScreen extends StatefulWidget {
  final String userEmail;
  final String userName;
  final String userRole; // 'Student' | 'Lecturer'
  final String studentId;
  final String programme;
  final String batchId;

  const UserAnnouncementsScreen({
    super.key,
    required this.userEmail,
    required this.userName,
    required this.userRole,
    this.studentId = 'STU-1002',
    this.programme = 'BSc Computing',
    this.batchId = '2026',
  });

  @override
  State<UserAnnouncementsScreen> createState() => _UserAnnouncementsScreenState();
}

class _UserAnnouncementsScreenState extends State<UserAnnouncementsScreen> {
  final AnnouncementService _announcementService = AnnouncementService();
  String _searchQuery = '';
  String _selectedPriority = 'All';

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

  void _showNoticeDetailDialog(BuildContext context, AnnouncementModel notice) {
    // Mark as read immediately upon opening
    if (notice.docId != null) {
      _announcementService.markAsRead(notice.docId!, widget.userEmail);
    }

    Color priorityColor = Colors.cyanAccent;
    if (notice.priority.toLowerCase() == 'urgent') {
      priorityColor = Colors.redAccent;
    } else if (notice.priority.toLowerCase() == 'important') {
      priorityColor = Colors.orangeAccent;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: priorityColor.withAlpha(30), borderRadius: BorderRadius.circular(4)),
              child: Text(notice.priority.toUpperCase(), style: TextStyle(color: priorityColor, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                notice.title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Published: ${_displayDate(notice.publishDate)} by ${notice.createdByName.isNotEmpty ? notice.createdByName : notice.createdBy}',
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
              if (notice.expiryDate.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text('Valid until: ${_displayDate(notice.expiryDate)}', style: const TextStyle(color: Colors.amberAccent, fontSize: 11)),
              ],
              const SizedBox(height: 12),
              const Divider(color: Colors.white10),
              const SizedBox(height: 8),
              Text(
                notice.description,
                style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isStudent = widget.userRole.toLowerCase() == 'student';
    final stream = isStudent
        ? _announcementService.getStudentAnnouncementsStream(
            studentEmail: widget.userEmail,
            studentId: widget.studentId,
            programme: widget.programme,
            batchId: widget.batchId,
          )
        : _announcementService.getLecturerAnnouncementsStream(widget.userEmail);

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
          '${widget.userRole} Notices & Announcements',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF1E293B),
            child: Column(
              children: [
                TextField(
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search announcements by keyword...',
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 18),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                ),
                const SizedBox(height: 8),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Urgent', 'Important', 'Normal'].map((p) {
                      final isSel = _selectedPriority == p;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(p, style: TextStyle(color: isSel ? Colors.black : Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                          selected: isSel,
                          selectedColor: Colors.pinkAccent,
                          backgroundColor: const Color(0xFF0F172A),
                          onSelected: (sel) {
                            if (sel) setState(() => _selectedPriority = p);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Announcements List
          Expanded(
            child: StreamBuilder<List<AnnouncementModel>>(
              stream: stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.pinkAccent));
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error loading notices: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
                }

                final allNotices = snapshot.data ?? [];
                final notices = allNotices.where((n) {
                  final matchesSearch = n.title.toLowerCase().contains(_searchQuery) ||
                      n.description.toLowerCase().contains(_searchQuery);
                  final matchesPriority = _selectedPriority == 'All' || n.priority.toLowerCase() == _selectedPriority.toLowerCase();

                  return matchesSearch && matchesPriority;
                }).toList();

                if (notices.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.campaign_rounded, size: 64, color: Colors.white.withAlpha(50)),
                        const SizedBox(height: 14),
                        const Text('No active announcements.', style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text('Notices matching your search or filters will appear here.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: notices.length,
                  itemBuilder: (context, index) {
                    final notice = notices[index];
                    final isRead = notice.isReadBy(widget.userEmail);

                    Color priorityColor = Colors.cyanAccent;
                    if (notice.priority.toLowerCase() == 'urgent') {
                      priorityColor = Colors.redAccent;
                    } else if (notice.priority.toLowerCase() == 'important') {
                      priorityColor = Colors.orangeAccent;
                    }

                    return GestureDetector(
                      onTap: () => _showNoticeDetailDialog(context, notice),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isRead ? Colors.white10 : Colors.pinkAccent.withAlpha(120), width: isRead ? 1 : 1.5),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: priorityColor.withAlpha(30), borderRadius: BorderRadius.circular(4)),
                                    child: Text(notice.priority.toUpperCase(), style: TextStyle(color: priorityColor, fontSize: 9, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(4)),
                                    child: Text(notice.announcementId, style: const TextStyle(color: Colors.white70, fontSize: 9, fontFamily: 'monospace')),
                                  ),
                                  const Spacer(),

                                  if (!isRead)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.pinkAccent.withAlpha(30), borderRadius: BorderRadius.circular(4)),
                                      child: const Text('NEW / UNREAD', style: TextStyle(color: Colors.pinkAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              Text(
                                notice.title,
                                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: isRead ? FontWeight.w600 : FontWeight.bold),
                              ),
                              const SizedBox(height: 4),

                              Text(
                                notice.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                              ),
                              const SizedBox(height: 10),
                              const Divider(color: Colors.white10, height: 1),
                              const SizedBox(height: 6),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'By ${notice.createdByName.isNotEmpty ? notice.createdByName : notice.createdBy}',
                                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                                  ),
                                  Text(
                                    _displayDate(notice.publishDate),
                                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
