import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/subject_model.dart';
import '../../models/announcement_model.dart';
import '../../models/enrollment_model.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';

class LecturerAnnouncementsView extends StatefulWidget {
  final SubjectModel subject;
  final String lecturerEmail;
  final String lecturerName;
  final String? lecturerId;

  const LecturerAnnouncementsView({
    super.key,
    required this.subject,
    required this.lecturerEmail,
    required this.lecturerName,
    this.lecturerId,
  });

  @override
  State<LecturerAnnouncementsView> createState() => _LecturerAnnouncementsViewState();
}

class _LecturerAnnouncementsViewState extends State<LecturerAnnouncementsView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  String _searchQuery = '';
  String _selectedPriority = 'All';
  String _selectedStatus = 'All';

  final List<String> _priorities = ['All', 'Urgent', 'Important', 'Normal'];
  final List<String> _statuses = ['All', 'published', 'draft', 'archived', 'expired'];

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  void _showCreateEditAnnouncementModal(List<EnrollmentModel> activeStudents, {AnnouncementModel? existingNotice}) {
    final isEditing = existingNotice != null;
    final titleController = TextEditingController(text: existingNotice?.title ?? '');
    final msgController = TextEditingController(text: existingNotice?.description ?? '');

    DateTime pubDate = existingNotice != null && existingNotice.publishDate.isNotEmpty
        ? (DateTime.tryParse(existingNotice.publishDate) ?? DateTime.now())
        : DateTime.now();

    DateTime expDate = existingNotice != null && existingNotice.expiryDate.isNotEmpty
        ? (DateTime.tryParse(existingNotice.expiryDate) ?? DateTime.now().add(const Duration(days: 30)))
        : DateTime.now().add(const Duration(days: 30));

    String selectedPriority = existingNotice?.priority ?? 'Normal';
    String selectedStatus = existingNotice?.status ?? 'published';
    String attachmentUrl = existingNotice?.attachmentUrl ?? 'https://university.edu/storage/${widget.subject.subjectCode}/notice_${DateTime.now().millisecondsSinceEpoch}.pdf';
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(isEditing ? Icons.edit_notifications_rounded : Icons.campaign_rounded, color: Colors.pinkAccent),
                        const SizedBox(width: 8),
                        Text(
                          isEditing ? 'Edit Announcement' : 'Publish New Announcement',
                          style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Subject: ${widget.subject.subjectCode} - ${widget.subject.subjectName}', style: const TextStyle(color: Colors.amberAccent, fontSize: 12)),
                const SizedBox(height: 16),

                // Title
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Announcement Title *',
                    labelStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),

                // Priority & Status Selectors
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedPriority,
                        dropdownColor: const Color(0xFF0F172A),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Priority',
                          labelStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Urgent', child: Text('🚨 Urgent', style: TextStyle(color: Colors.redAccent))),
                          DropdownMenuItem(value: 'Important', child: Text('⚡ Important', style: TextStyle(color: Colors.orangeAccent))),
                          DropdownMenuItem(value: 'Normal', child: Text('📢 Normal', style: TextStyle(color: Colors.cyanAccent))),
                        ],
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedPriority = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedStatus.toLowerCase(),
                        dropdownColor: const Color(0xFF0F172A),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Status',
                          labelStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'published', child: Text('Published', style: TextStyle(color: Colors.greenAccent))),
                          DropdownMenuItem(value: 'draft', child: Text('Draft', style: TextStyle(color: Colors.orangeAccent))),
                          DropdownMenuItem(value: 'archived', child: Text('Archived', style: TextStyle(color: Colors.grey))),
                        ],
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedStatus = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Date pickers
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: pubDate,
                            firstDate: DateTime(2025, 1, 1),
                            lastDate: DateTime(2030, 12, 31),
                            builder: (context, child) => Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(primary: Colors.pinkAccent, onPrimary: Colors.black, surface: Color(0xFF1E293B)),
                              ),
                              child: child!,
                            ),
                          );
                          if (picked != null) setModalState(() => pubDate = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white10)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Publish Date', style: TextStyle(color: Colors.grey, fontSize: 10)),
                              const SizedBox(height: 4),
                              Text(_formatDate(pubDate), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: expDate,
                            firstDate: DateTime(2025, 1, 1),
                            lastDate: DateTime(2030, 12, 31),
                            builder: (context, child) => Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(primary: Colors.pinkAccent, onPrimary: Colors.black, surface: Color(0xFF1E293B)),
                              ),
                              child: child!,
                            ),
                          );
                          if (picked != null) setModalState(() => expDate = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.pinkAccent.withAlpha(80))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Expiry Date (Auto-Archive)', style: TextStyle(color: Colors.pinkAccent, fontSize: 10)),
                              const SizedBox(height: 4),
                              Text(_formatDate(expDate), style: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Message Text
                TextField(
                  controller: msgController,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Announcement Message & Details *',
                    labelStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 16),

                // Audience Information Pill
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      const Icon(Icons.groups_rounded, color: Colors.tealAccent, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Will broadcast to ${activeStudents.length} actively enrolled students in ${widget.subject.subjectCode}.',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final title = titleController.text.trim();
                            final message = msgController.text.trim();

                            if (title.isEmpty || message.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter announcement title and message.'), backgroundColor: Colors.redAccent),
                              );
                              return;
                            }

                            if (expDate.isBefore(pubDate)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Error: Expiry Date cannot be earlier than Publish Date.'), backgroundColor: Colors.redAccent),
                              );
                              return;
                            }

                            setModalState(() => isSaving = true);
                            final messenger = ScaffoldMessenger.of(context);
                            final nav = Navigator.of(ctx);

                            try {
                              final noticeData = {
                                'announcementId': existingNotice?.announcementId ?? 'ANN-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                                'title': title,
                                'description': message,
                                'message': message,
                                'audience': 'subject_students',
                                'createdBy': widget.lecturerEmail,
                                'updatedBy': widget.lecturerEmail,
                                'lecturerId': widget.lecturerId ?? 'LEC-1001',
                                'lecturerName': widget.lecturerName,
                                'subjectDocId': widget.subject.docId ?? '',
                                'subjectCode': widget.subject.subjectCode,
                                'subjectName': widget.subject.subjectName,
                                'priority': selectedPriority,
                                'publishDate': _formatDate(pubDate),
                                'expiryDate': _formatDate(expDate),
                                'createdDate': DateTime.now().toIso8601String(),
                                'updatedAt': DateTime.now().toIso8601String(),
                                'status': selectedStatus,
                                'attachmentUrl': attachmentUrl,
                                'readBy': existingNotice?.readBy ?? [],
                              };

                              if (!isEditing) {
                                await _firestore.collection('announcements').add(noticeData);

                                // Broadcast in-app notifications if published
                                if (selectedStatus == 'published') {
                                  for (var stu in activeStudents) {
                                    await _notificationService.sendNotification(
                                      NotificationModel(
                                        notificationId: 'NTF-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                                        title: '📢 [${widget.subject.subjectCode}] $title',
                                        message: message,
                                        type: 'announcement',
                                        audience: 'specific_student',
                                        targetUserEmail: stu.studentEmail,
                                        targetUserId: stu.studentId,
                                        targetUserName: stu.studentName,
                                        sentBy: widget.lecturerName,
                                        sentDate: DateTime.now().toIso8601String().substring(0, 10),
                                        createdDate: DateTime.now().toIso8601String(),
                                        status: 'sent',
                                      ),
                                    );
                                  }
                                }

                                messenger.showSnackBar(
                                  SnackBar(content: Text('Announcement "$title" published to students!'), backgroundColor: Colors.green),
                                );
                              } else {
                                await _firestore.collection('announcements').doc(existingNotice.docId).update(noticeData);
                                messenger.showSnackBar(
                                  SnackBar(content: Text('Announcement "$title" updated successfully!'), backgroundColor: Colors.green),
                                );
                              }

                              nav.pop();
                            } catch (e) {
                              setModalState(() => isSaving = false);
                              messenger.showSnackBar(
                                SnackBar(content: Text('Failed to save announcement: $e'), backgroundColor: Colors.redAccent),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.pink[700], padding: const EdgeInsets.symmetric(vertical: 14)),
                    icon: isSaving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Icon(isEditing ? Icons.save_rounded : Icons.campaign_rounded, color: Colors.white),
                    label: Text(
                      isEditing ? 'Save Changes' : 'Broadcast Announcement',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNoticeDetailsModal(BuildContext context, AnnouncementModel notice) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              notice.priority == 'Urgent' ? Icons.warning_amber_rounded : Icons.campaign_rounded,
              color: notice.priority == 'Urgent' ? Colors.redAccent : Colors.pinkAccent,
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
              Text('Subject: ${widget.subject.subjectCode} - ${widget.subject.subjectName}', style: const TextStyle(color: Colors.amberAccent, fontSize: 12)),
              const SizedBox(height: 4),
              Text('Lecturer: ${widget.lecturerName} • Published: ${notice.publishDate}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
              const SizedBox(height: 4),
              Text('Expires on: ${notice.expiryDate}', style: const TextStyle(color: Colors.pinkAccent, fontSize: 11, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              const Divider(color: Colors.white10),
              const SizedBox(height: 6),
              Text(notice.description, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
              const SizedBox(height: 14),
              Text('Read by ${notice.readBy.length} Students', style: const TextStyle(color: Colors.tealAccent, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // 1. Fetch Active Enrolled Students for this Subject
      stream: _firestore
          .collection('enrollments')
          .where('subjectCode', isEqualTo: widget.subject.subjectCode)
          .where('status', isEqualTo: 'active')
          .snapshots(),
      builder: (context, enrollSnap) {
        return StreamBuilder<QuerySnapshot>(
          // 2. Fetch Announcements for this Subject
          stream: _firestore
              .collection('announcements')
              .where('subjectCode', isEqualTo: widget.subject.subjectCode)
              .snapshots(),
          builder: (context, noticeSnap) {
            if (enrollSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.pinkAccent));
            }

            final enrollDocs = enrollSnap.data?.docs ?? [];
            final noticeDocs = noticeSnap.data?.docs ?? [];

            // Deduplicate enrollments
            final Map<String, EnrollmentModel> studentMap = {};
            for (var d in enrollDocs) {
              final e = EnrollmentModel.fromFirestore(d as DocumentSnapshot<Map<String, dynamic>>);
              studentMap[e.studentEmail.toLowerCase()] = e;
            }
            final activeStudents = studentMap.values.toList();

            final allNotices = noticeDocs
                .map((d) => AnnouncementModel.fromFirestore(d as DocumentSnapshot<Map<String, dynamic>>))
                .where((n) => n.status.toLowerCase() != 'deactivated')
                .toList();

            // Calculate KPI metrics
            final totalNotices = allNotices.length;
            final publishedNotices = allNotices.where((n) => n.effectiveStatus == 'published').length;
            final urgentNotices = allNotices.where((n) => n.priority == 'Urgent' || n.priority == 'Important').length;
            final draftNotices = allNotices.where((n) => n.effectiveStatus == 'draft').length;
            final expiredNotices = allNotices.where((n) => n.effectiveStatus == 'expired' || n.effectiveStatus == 'archived').length;

            // Filter notices
            final filteredNotices = allNotices.where((n) {
              final matchesSearch = n.title.toLowerCase().contains(_searchQuery) ||
                  n.description.toLowerCase().contains(_searchQuery) ||
                  n.announcementId.toLowerCase().contains(_searchQuery);

              final matchesPriority = _selectedPriority == 'All' || n.priority.toLowerCase() == _selectedPriority.toLowerCase();
              final matchesStatus = _selectedStatus == 'All' || n.effectiveStatus == _selectedStatus.toLowerCase();

              return matchesSearch && matchesPriority && matchesStatus;
            }).toList();

            return Scaffold(
              backgroundColor: Colors.transparent,
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () => _showCreateEditAnnouncementModal(activeStudents),
                backgroundColor: Colors.pink[700],
                icon: const Icon(Icons.campaign_rounded, color: Colors.white),
                label: const Text('New Announcement', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              body: Column(
                children: [
                  // KPI Dashboard Strip
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: const Color(0xFF1E293B),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildMetricCard('Total Notices', '$totalNotices', Colors.white, Icons.campaign_rounded)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildMetricCard('Published', '$publishedNotices', Colors.greenAccent, Icons.mark_email_read_rounded)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildMetricCard('Priority', '$urgentNotices', urgentNotices > 0 ? Colors.redAccent : Colors.grey, Icons.priority_high_rounded)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildMetricCard('Drafts', '$draftNotices', Colors.orangeAccent, Icons.edit_note_rounded)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildMetricCard('Archived', '$expiredNotices', Colors.grey, Icons.archive_rounded)),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Search Bar
                        TextField(
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Search notices by title, message or ID...',
                            hintStyle: const TextStyle(color: Colors.grey),
                            prefixIcon: const Icon(Icons.search, color: Colors.grey),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                          onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                        ),
                        const SizedBox(height: 10),

                        // Priority & Status Filters
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ..._priorities.map((p) {
                                final isSel = p == _selectedPriority;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ChoiceChip(
                                    label: Text(p == 'All' ? 'ALL PRIORITIES' : p.toUpperCase()),
                                    selected: isSel,
                                    onSelected: (val) {
                                      if (val) setState(() => _selectedPriority = p);
                                    },
                                    selectedColor: Colors.pink[700],
                                    backgroundColor: const Color(0xFF0F172A),
                                    labelStyle: TextStyle(color: isSel ? Colors.white : Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                                    side: BorderSide(color: isSel ? Colors.pinkAccent : Colors.white10),
                                  ),
                                );
                              }),
                              const SizedBox(width: 10),
                              ..._statuses.map((s) {
                                final isSel = s == _selectedStatus;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ChoiceChip(
                                    label: Text(s == 'All' ? 'ALL STATUS' : s.toUpperCase()),
                                    selected: isSel,
                                    onSelected: (val) {
                                      if (val) setState(() => _selectedStatus = s);
                                    },
                                    selectedColor: Colors.teal,
                                    backgroundColor: const Color(0xFF0F172A),
                                    labelStyle: TextStyle(color: isSel ? Colors.white : Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                                    side: BorderSide(color: isSel ? Colors.tealAccent : Colors.white10),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Announcements List
                  Expanded(
                    child: filteredNotices.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.campaign_outlined, size: 56, color: Colors.grey.withAlpha(80)),
                                const SizedBox(height: 12),
                                const Text('No announcements found matching filter.', style: TextStyle(color: Colors.grey, fontSize: 14)),
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: () => _showCreateEditAnnouncementModal(activeStudents),
                                  icon: const Icon(Icons.add_rounded, color: Colors.pinkAccent),
                                  label: const Text('Publish First Announcement', style: TextStyle(color: Colors.pinkAccent)),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredNotices.length,
                            itemBuilder: (context, index) {
                              final n = filteredNotices[index];
                              final effectiveSt = n.effectiveStatus;
                              final isPub = effectiveSt == 'published';
                              final isExp = effectiveSt == 'expired';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: n.priority == 'Urgent'
                                        ? Colors.red.withAlpha(80)
                                        : (isPub ? Colors.white10 : Colors.grey.withAlpha(30)),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(color: Colors.pink.withAlpha(30), borderRadius: BorderRadius.circular(6)),
                                              child: Text(n.announcementId, style: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: n.priority == 'Urgent'
                                                    ? Colors.red.withAlpha(30)
                                                    : (n.priority == 'Important' ? Colors.orange.withAlpha(30) : Colors.cyan.withAlpha(20)),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                n.priority.toUpperCase(),
                                                style: TextStyle(
                                                  color: n.priority == 'Urgent'
                                                      ? Colors.redAccent
                                                      : (n.priority == 'Important' ? Colors.orangeAccent : Colors.cyanAccent),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isPub
                                                ? Colors.green.withAlpha(30)
                                                : (isExp ? Colors.grey.withAlpha(30) : Colors.orange.withAlpha(30)),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            effectiveSt.toUpperCase(),
                                            style: TextStyle(
                                              color: isPub ? Colors.greenAccent : (isExp ? Colors.grey : Colors.orangeAccent),
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    Text(n.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                    const SizedBox(height: 4),
                                    Text(n.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    const SizedBox(height: 8),

                                    Row(
                                      children: [
                                        const Icon(Icons.event_available_rounded, size: 12, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text('Published: ${n.publishDate}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                        const SizedBox(width: 12),
                                        const Icon(Icons.alarm_off_rounded, size: 12, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text('Expires: ${n.expiryDate}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                        const Spacer(),
                                        Text('${n.readBy.length} Views', style: const TextStyle(color: Colors.tealAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                                      ],
                                    ),

                                    const SizedBox(height: 12),
                                    const Divider(color: Colors.white10, height: 1),
                                    const SizedBox(height: 6),

                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        TextButton.icon(
                                          onPressed: () => _showNoticeDetailsModal(context, n),
                                          icon: const Icon(Icons.visibility_rounded, size: 16, color: Colors.pinkAccent),
                                          label: const Text('Read Details', style: TextStyle(color: Colors.pinkAccent, fontSize: 12)),
                                        ),

                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit_rounded, size: 18, color: Colors.amberAccent),
                                              tooltip: 'Edit Announcement',
                                              onPressed: () => _showCreateEditAnnouncementModal(activeStudents, existingNotice: n),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                isPub ? Icons.archive_rounded : Icons.unarchive_rounded,
                                                size: 18,
                                                color: isPub ? Colors.orangeAccent : Colors.greenAccent,
                                              ),
                                              tooltip: isPub ? 'Archive Announcement' : 'Publish Announcement',
                                              onPressed: () async {
                                                if (n.docId != null) {
                                                  final newSt = isPub ? 'archived' : 'published';
                                                  await _firestore.collection('announcements').doc(n.docId).update({'status': newSt});
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMetricCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 9), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
