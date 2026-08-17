import 'package:flutter/material.dart';
import '../../models/assignment_model.dart';
import '../../services/assignment_service.dart';
import 'add_edit_assignment_screen.dart';
import 'assignment_detail_screen.dart';

class AssignmentsListScreen extends StatefulWidget {
  const AssignmentsListScreen({super.key});

  @override
  State<AssignmentsListScreen> createState() => _AssignmentsListScreenState();
}

class _AssignmentsListScreenState extends State<AssignmentsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final AssignmentService _assignmentService = AssignmentService();

  String _searchQuery = '';
  String _filterStatus = 'All';
  String _filterSubject = 'All';
  String _filterSemester = 'All';
  String _filterYear = 'All';

  final List<String> _statusOptions = ['All', 'draft', 'published', 'closed', 'deactivated'];
  final List<String> _semesterOptions = ['All', 'Semester 1', 'Semester 2'];
  final List<String> _yearOptions = ['All', 'Year 1', 'Year 2', 'Year 3', 'Year 4'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'published': return Colors.greenAccent;
      case 'closed': return Colors.amberAccent;
      case 'deactivated': return Colors.redAccent;
      default: return Colors.grey;
    }
  }

  String _displayDate(String isoDate) {
    if (isoDate.isEmpty) return '—';
    try {
      final dt = DateTime.parse(isoDate);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return isoDate;
    }
  }

  bool _isDuePast(String dueDate) {
    if (dueDate.isEmpty) return false;
    try {
      return DateTime.now().isAfter(DateTime.parse(dueDate));
    } catch (_) {
      return false;
    }
  }

  List<String> _extractSubjects(List<AssignmentModel> assignments) {
    final subjects = assignments.map((a) => a.subjectName).toSet().toList();
    subjects.sort();
    return ['All', ...subjects];
  }

  List<AssignmentModel> _applyFilters(List<AssignmentModel> all) {
    return all.where((a) {
      final q = _searchQuery;
      final matchSearch = q.isEmpty ||
          a.title.toLowerCase().contains(q) ||
          a.assignmentId.toLowerCase().contains(q) ||
          a.subjectName.toLowerCase().contains(q) ||
          a.subjectCode.toLowerCase().contains(q);
      final matchStatus = _filterStatus == 'All' || a.status == _filterStatus;
      final matchSubject = _filterSubject == 'All' || a.subjectName == _filterSubject;
      final matchSemester = _filterSemester == 'All' || a.semester == _filterSemester;
      final matchYear = _filterYear == 'All' || a.academicYear == _filterYear;
      return matchSearch && matchStatus && matchSubject && matchSemester && matchYear;
    }).toList();
  }

  void _showFilterSheet(List<AssignmentModel> allAssignments) {
    String tempStatus = _filterStatus;
    String tempSubject = _filterSubject;
    String tempSemester = _filterSemester;
    String tempYear = _filterYear;
    final subjectOptions = _extractSubjects(allAssignments);

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
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Filter Assignments',
                  style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _filterDrop('Status', tempStatus, _statusOptions, (v) => setSheet(() => tempStatus = v!)),
              const SizedBox(height: 12),
              _filterDrop('Subject', tempSubject, subjectOptions, (v) => setSheet(() => tempSubject = v!)),
              const SizedBox(height: 12),
              _filterDrop('Semester', tempSemester, _semesterOptions, (v) => setSheet(() => tempSemester = v!)),
              const SizedBox(height: 12),
              _filterDrop('Academic Year', tempYear, _yearOptions, (v) => setSheet(() => tempYear = v!)),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _filterStatus = 'All';
                        _filterSubject = 'All';
                        _filterSemester = 'All';
                        _filterYear = 'All';
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
                        _filterStatus = tempStatus;
                        _filterSubject = tempSubject;
                        _filterSemester = tempSemester;
                        _filterYear = tempYear;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Apply', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _changeStatus(AssignmentModel assignment) {
    final options = ['draft', 'published', 'closed', 'deactivated']
        .where((s) => s != assignment.status)
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Change Status',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              '"${assignment.title}"',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
            const Divider(color: Colors.white10, height: 24),
            ...options.map((s) => ListTile(
              leading: Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                  color: _statusColor(s),
                  shape: BoxShape.circle,
                ),
              ),
              title: Text(
                s[0].toUpperCase() + s.substring(1),
                style: TextStyle(color: _statusColor(s), fontWeight: FontWeight.bold),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                await _assignmentService.updateAssignmentStatus(assignment.docId!, s);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('"${assignment.title}" → ${s.toUpperCase()}'),
                      backgroundColor: _statusColor(s).withAlpha(200),
                    ),
                  );
                }
              },
            )),
            const SizedBox(height: 8),
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
        title: const Text(
          'Assignments',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.orangeAccent,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Assignment',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditAssignmentScreen()),
        ),
      ),
      body: StreamBuilder<List<AssignmentModel>>(
        stream: _assignmentService.getAssignmentsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.orangeAccent));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent)));
          }

          final allAssignments = snapshot.data ?? [];
          final filtered = _applyFilters(allAssignments);
          final hasActiveFilters = _filterStatus != 'All' || _filterSubject != 'All'
              || _filterSemester != 'All' || _filterYear != 'All';

          return Column(
            children: [
              // Search + Filter row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search by ID, Title, Subject...',
                          hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                          prefixIcon: const Icon(Icons.search_rounded, color: Colors.orangeAccent),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                                  onPressed: () => setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                  }),
                                )
                              : null,
                          filled: true,
                          fillColor: const Color(0xFF1E293B),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: hasActiveFilters
                            ? Colors.orangeAccent.withAlpha(40)
                            : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: hasActiveFilters ? Colors.orangeAccent : Colors.white10,
                        ),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.filter_list_rounded,
                          color: hasActiveFilters ? Colors.orangeAccent : Colors.grey,
                        ),
                        tooltip: 'Filter',
                        onPressed: () => _showFilterSheet(allAssignments),
                      ),
                    ),
                  ],
                ),
              ),

              // Active filter chips
              if (hasActiveFilters)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      if (_filterStatus != 'All') _chip(_filterStatus, () => setState(() => _filterStatus = 'All')),
                      if (_filterSubject != 'All') _chip(_filterSubject, () => setState(() => _filterSubject = 'All')),
                      if (_filterSemester != 'All') _chip(_filterSemester, () => setState(() => _filterSemester = 'All')),
                      if (_filterYear != 'All') _chip(_filterYear, () => setState(() => _filterYear = 'All')),
                    ],
                  ),
                ),

              // Summary counts
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    Text(
                      '${filtered.length} assignment${filtered.length == 1 ? '' : 's'}',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const Spacer(),
                    ...['published', 'draft', 'closed'].map((s) {
                      final count = allAssignments.where((a) => a.status == s).length;
                      return Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          '$count ${s[0].toUpperCase()}${s.substring(1)}',
                          style: TextStyle(color: _statusColor(s), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              // List
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[700]),
                            const SizedBox(height: 12),
                            Text(
                              allAssignments.isEmpty
                                  ? 'No assignments yet. Create one!'
                                  : 'No assignments match your filters.',
                              style: const TextStyle(color: Colors.grey, fontSize: 15),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) => _assignmentCard(ctx, filtered[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _assignmentCard(BuildContext context, AssignmentModel assignment) {
    final isPastDue = _isDuePast(assignment.dueDate);
    final isActive = assignment.status == 'published';

    return StreamBuilder<List<dynamic>>(
      // Count submissions for this assignment
      stream: AssignmentService()
          .getSubmissionsForAssignment(assignment.docId ?? '')
          .map((list) => list),
      builder: (context, subSnap) {
        final submissionCount = subSnap.data?.length ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive
                  ? Colors.orangeAccent.withAlpha(50)
                  : Colors.white10,
            ),
          ),
          child: Column(
            children: [
              // Main row
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + Status
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange.withAlpha(30),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.assignment_rounded,
                              color: Colors.orangeAccent, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                assignment.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${assignment.assignmentId} • ${assignment.subjectCode}',
                                style: const TextStyle(color: Colors.grey, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _statusColor(assignment.status).withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _statusColor(assignment.status).withAlpha(150)),
                          ),
                          child: Text(
                            assignment.status.toUpperCase(),
                            style: TextStyle(
                              color: _statusColor(assignment.status),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Meta info
                    Row(
                      children: [
                        Expanded(
                          child: _metaTag(
                            Icons.person_rounded,
                            assignment.lecturerName,
                            Colors.amberAccent,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _metaTag(
                          Icons.alarm_rounded,
                          'Due: ${_displayDate(assignment.dueDate)}',
                          isPastDue && assignment.status == 'published'
                              ? Colors.redAccent
                              : Colors.orangeAccent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _metaTag(Icons.check_circle_outline_rounded,
                            '$submissionCount submission${submissionCount == 1 ? '' : 's'}',
                            Colors.tealAccent),
                        const Spacer(),
                        _metaTag(Icons.calendar_today_rounded,
                            _displayDate(assignment.createdDate), Colors.grey),
                      ],
                    ),
                  ],
                ),
              ),

              // Action Buttons
              Container(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.white10)),
                ),
                child: Row(
                  children: [
                    _actionBtn(Icons.visibility_outlined, 'View', Colors.indigoAccent, () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => AssignmentDetailScreen(assignment: assignment),
                      ));
                    }),
                    _vDivider(),
                    _actionBtn(Icons.edit_outlined, 'Edit', Colors.orangeAccent, () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => AddEditAssignmentScreen(existingAssignment: assignment),
                      ));
                    }),
                    _vDivider(),
                    _actionBtn(Icons.swap_horiz_rounded, 'Status', Colors.tealAccent, () {
                      if (assignment.docId != null) _changeStatus(assignment);
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _vDivider() => Container(width: 1, height: 36, color: Colors.white10);

  Widget _metaTag(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 4),
        Flexible(
          child: Text(text,
              style: TextStyle(color: color, fontSize: 11),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Widget _chip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
      deleteIcon: const Icon(Icons.close, size: 14, color: Colors.white70),
      onDeleted: onRemove,
      backgroundColor: Colors.orange.withAlpha(80),
      side: BorderSide(color: Colors.orangeAccent.withAlpha(120)),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _filterDrop(String label, String current, List<String> options, void Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: current,
      dropdownColor: const Color(0xFF1E293B),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
        filled: true,
        fillColor: const Color(0xFF0F172A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
      onChanged: onChanged,
    );
  }
}
