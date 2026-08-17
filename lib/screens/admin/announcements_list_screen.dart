import 'package:flutter/material.dart';
import '../../models/announcement_model.dart';
import '../../services/announcement_service.dart';
import 'add_edit_announcement_screen.dart';
import 'announcement_detail_screen.dart';

class AnnouncementsListScreen extends StatefulWidget {
  const AnnouncementsListScreen({super.key});

  @override
  State<AnnouncementsListScreen> createState() => _AnnouncementsListScreenState();
}

class _AnnouncementsListScreenState extends State<AnnouncementsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final AnnouncementService _announcementService = AnnouncementService();

  String _searchQuery = '';
  String _filterAudience = 'All';
  String _filterStatus = 'All';

  final List<String> _audienceOptions = [
    'All',
    'all_users',
    'all_students',
    'all_lecturers',
    'specific_student',
    'specific_lecturer',
  ];

  final Map<String, String> _audienceDisplayMap = {
    'All': 'All Audiences',
    'all_users': 'Students & Lecturers',
    'all_students': 'All Students',
    'all_lecturers': 'All Lecturers',
    'specific_student': 'Specific Student',
    'specific_lecturer': 'Specific Lecturer',
  };

  final List<String> _statusOptions = ['All', 'published', 'draft', 'expired', 'deactivated'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

  String _formatStatusLabel(String s) {
    final clean = s.replaceAll('_', ' ');
    return clean[0].toUpperCase() + clean.substring(1);
  }

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

  List<AnnouncementModel> _applyFilters(List<AnnouncementModel> all) {
    return all.where((a) {
      final q = _searchQuery.toLowerCase();
      final matchSearch = q.isEmpty ||
          a.announcementId.toLowerCase().contains(q) ||
          a.title.toLowerCase().contains(q) ||
          a.createdBy.toLowerCase().contains(q) ||
          (a.targetUserName?.toLowerCase().contains(q) ?? false);

      final effectiveStatus = a.effectiveStatus;
      final matchStatus = _filterStatus == 'All' ||
          (_filterStatus == 'expired'
              ? effectiveStatus == 'expired'
              : (_filterStatus == 'published'
                  ? effectiveStatus == 'published'
                  : a.status == _filterStatus));

      final matchAudience = _filterAudience == 'All' || a.audience == _filterAudience;

      return matchSearch && matchStatus && matchAudience;
    }).toList();
  }

  void _showFilterSheet() {
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
                'Filter Announcements',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildFilterDropdown(
                'Target Audience',
                tempAudience,
                _audienceOptions,
                _audienceDisplayMap,
                (v) => setSheet(() => tempAudience = v!),
              ),
              const SizedBox(height: 14),
              _buildFilterDropdown(
                'Status',
                tempStatus,
                _statusOptions,
                null,
                (v) => setSheet(() => tempStatus = v!),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() {
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
                          _filterAudience = tempAudience;
                          _filterStatus = tempStatus;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEC4899),
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

  Widget _buildFilterDropdown(
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
                        child: Text(displayMap?[opt] ?? _formatStatusLabel(opt)),
                      ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _togglePublish(AnnouncementModel announcement) async {
    final isPublished = announcement.status.toLowerCase() == 'published';
    try {
      await _announcementService.togglePublishStatus(announcement.docId!, announcement.status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isPublished ? 'Moved to Draft.' : 'Announcement published!'),
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

  Future<void> _toggleDeactivate(AnnouncementModel announcement) async {
    final isDeactivated = announcement.status.toLowerCase() == 'deactivated';
    try {
      if (isDeactivated) {
        await _announcementService.reactivateAnnouncement(announcement.docId!);
      } else {
        await _announcementService.deactivateAnnouncement(announcement.docId!);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Announcement ${isDeactivated ? "reactivated" : "deactivated"}.'),
            backgroundColor: isDeactivated ? Colors.green : Colors.orange,
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
          'Announcements',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Colors.white70),
            tooltip: 'Filter Notices',
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFEC4899),
        icon: const Icon(Icons.add_alert_rounded, color: Colors.white),
        label: const Text('Add Notice', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEditAnnouncementScreen()),
          );
        },
      ),
      body: StreamBuilder<List<AnnouncementModel>>(
        stream: _announcementService.getAnnouncementsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading notices: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFEC4899)));
          }

          final allAnnouncements = snapshot.data!;
          final filteredAnnouncements = _applyFilters(allAnnouncements);

          // Statistics: Accurate non-expired published counts
          final totalCount = allAnnouncements.length;
          final activePublishedCount = allAnnouncements.where((a) => a.effectiveStatus == 'published').length;
          final draftCount = allAnnouncements.where((a) => a.status.toLowerCase() == 'draft').length;
          final expiredCount = allAnnouncements.where((a) => a.effectiveStatus == 'expired').length;

          return CustomScrollView(
            slivers: [
              // 1. Statistics Cards Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard('Total', '$totalCount', Icons.campaign_rounded, const Color(0xFFF472B6)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard('Active Live', '$activePublishedCount', Icons.check_circle_rounded, Colors.greenAccent),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard('Drafts', '$draftCount', Icons.edit_note_rounded, Colors.amberAccent),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard('Expired', '$expiredCount', Icons.history_rounded, Colors.redAccent),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Search & Active Filter Indicators
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
                          hintText: 'Search by Notice ID, Title, Creator...',
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

                      if (_filterAudience != 'All' || _filterStatus != 'All')
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              if (_filterAudience != 'All')
                                _buildFilterChip(
                                  'Audience: ${_audienceDisplayMap[_filterAudience] ?? _filterAudience}',
                                  () => setState(() => _filterAudience = 'All'),
                                ),
                              if (_filterStatus != 'All')
                                _buildFilterChip(
                                  'Status: ${_formatStatusLabel(_filterStatus)}',
                                  () => setState(() => _filterStatus = 'All'),
                                ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
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

              // 3. Announcements List
              filteredAnnouncements.isEmpty
                  ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.campaign_rounded, size: 64, color: Colors.white24),
                            const SizedBox(height: 12),
                            Text(
                              allAnnouncements.isEmpty ? 'No announcements posted yet.' : 'No notices match your filter.',
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
                            final item = filteredAnnouncements[index];
                            return _buildAnnouncementCard(item);
                          },
                          childCount: filteredAnnouncements.length,
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

  Widget _buildAnnouncementCard(AnnouncementModel a) {
    final effectiveStatus = a.effectiveStatus;
    final isDeactivated = a.status.toLowerCase() == 'deactivated';
    final isPublished = a.status.toLowerCase() == 'published';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: effectiveStatus == 'expired'
              ? Colors.redAccent.withAlpha(70)
              : Colors.white10,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (a.docId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AnnouncementDetailScreen(announcementDocId: a.docId!)),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ID + Audience + Status Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF334155),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      a.announcementId,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEC4899).withAlpha(30),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFEC4899).withAlpha(100)),
                    ),
                    child: Text(
                      _audienceDisplayMap[a.audience] ?? a.audience,
                      style: const TextStyle(
                        color: Color(0xFFF472B6),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
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
                      _formatStatusLabel(effectiveStatus),
                      style: TextStyle(
                        color: _statusColor(effectiveStatus),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Title
              Text(
                a.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Content snippet
              Text(
                a.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 10),

              // Timeline & Creator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        a.createdBy,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 13,
                        color: effectiveStatus == 'expired' ? Colors.redAccent : Colors.white60,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Pub: ${_displayDate(a.publishDate)} • Exp: ${_displayDate(a.expiryDate)}',
                        style: TextStyle(
                          color: effectiveStatus == 'expired' ? Colors.redAccent : Colors.white60,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(color: Colors.white10, height: 1),
              const SizedBox(height: 6),

              // Actions Row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      if (a.docId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AnnouncementDetailScreen(announcementDocId: a.docId!),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.visibility_rounded, size: 16, color: Colors.cyanAccent),
                    label: const Text('View', style: TextStyle(color: Colors.cyanAccent, fontSize: 13)),
                  ),
                  const SizedBox(width: 4),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddEditAnnouncementScreen(existingAnnouncement: a)),
                      );
                    },
                    icon: const Icon(Icons.edit_rounded, size: 16, color: Colors.white70),
                    label: const Text('Edit', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ),
                  const SizedBox(width: 4),
                  TextButton.icon(
                    onPressed: () => _togglePublish(a),
                    icon: Icon(
                      isPublished ? Icons.unpublished_rounded : Icons.publish_rounded,
                      size: 16,
                      color: isPublished ? Colors.orangeAccent : Colors.greenAccent,
                    ),
                    label: Text(
                      isPublished ? 'Draft' : 'Publish',
                      style: TextStyle(
                        color: isPublished ? Colors.orangeAccent : Colors.greenAccent,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  TextButton.icon(
                    onPressed: () => _toggleDeactivate(a),
                    icon: Icon(
                      isDeactivated ? Icons.restore_rounded : Icons.block_rounded,
                      size: 16,
                      color: isDeactivated ? Colors.greenAccent : Colors.redAccent,
                    ),
                    label: Text(
                      isDeactivated ? 'Reactivate' : 'Deactivate',
                      style: TextStyle(
                        color: isDeactivated ? Colors.greenAccent : Colors.redAccent,
                        fontSize: 13,
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
}
