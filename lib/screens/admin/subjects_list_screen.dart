import 'package:flutter/material.dart';
import '../../models/subject_model.dart';
import '../../models/lecturer_model.dart';
import '../../services/subject_service.dart';
import '../../services/lecturer_service.dart';
import 'add_subject_screen.dart';

class SubjectsListScreen extends StatefulWidget {
  const SubjectsListScreen({super.key});

  @override
  State<SubjectsListScreen> createState() => _SubjectsListScreenState();
}

class _SubjectsListScreenState extends State<SubjectsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SubjectService _subjectService = SubjectService();
  String _searchQuery = '';
  String _filterStatus = 'All';
  String _filterYear = 'All';
  String _filterSemester = 'All';

  final List<String> _statusOptions = ['All', 'active', 'inactive'];
  final List<String> _yearOptions = ['All', 'Year 1', 'Year 2', 'Year 3', 'Year 4'];
  final List<String> _semesterOptions = ['All', 'Semester 1', 'Semester 2'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text(
          'Subjects Management',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded, color: Colors.indigoAccent),
            tooltip: 'Filter Subjects',
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.indigoAccent,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add Subject',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddSubjectScreen()),
          );
        },
      ),
      body: Column(
        children: [
          // Search + Filter Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by Name, Code, or Lecturer...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.indigoAccent),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
            ),
          ),

          // Active Filter Chips
          if (_filterStatus != 'All' || _filterYear != 'All' || _filterSemester != 'All')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Wrap(
                spacing: 8,
                children: [
                  if (_filterStatus != 'All')
                    _buildChip(_filterStatus.toUpperCase(), () {
                      setState(() => _filterStatus = 'All');
                    }),
                  if (_filterYear != 'All')
                    _buildChip(_filterYear, () {
                      setState(() => _filterYear = 'All');
                    }),
                  if (_filterSemester != 'All')
                    _buildChip(_filterSemester, () {
                      setState(() => _filterSemester = 'All');
                    }),
                  TextButton(
                    onPressed: () => setState(() {
                      _filterStatus = 'All';
                      _filterYear = 'All';
                      _filterSemester = 'All';
                    }),
                    child: const Text('Clear All', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                  ),
                ],
              ),
            ),

          // Subjects Live Stream List
          Expanded(
            child: StreamBuilder<List<SubjectModel>>(
              stream: _subjectService.getSubjectsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.indigoAccent),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  );
                }

                final allSubjects = snapshot.data ?? [];
                final filtered = allSubjects.where((s) {
                  final q = _searchQuery;
                  final matchSearch = q.isEmpty ||
                      s.subjectName.toLowerCase().contains(q) ||
                      s.subjectCode.toLowerCase().contains(q) ||
                      s.subjectId.toLowerCase().contains(q) ||
                      s.lecturerName.toLowerCase().contains(q);
                  final matchStatus = _filterStatus == 'All' || s.status.toLowerCase() == _filterStatus;
                  final matchYear = _filterYear == 'All' || s.academicYear == _filterYear;
                  final matchSemester = _filterSemester == 'All' || s.semester == _filterSemester;
                  return matchSearch && matchStatus && matchYear && matchSemester;
                }).toList();

                // Sort: active first
                filtered.sort((a, b) {
                  if (a.status == b.status) return a.subjectName.compareTo(b.subjectName);
                  return a.status == 'active' ? -1 : 1;
                });

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.book_outlined, size: 64, color: Colors.grey[700]),
                        const SizedBox(height: 12),
                        Text(
                          allSubjects.isEmpty
                              ? 'No subjects added yet.'
                              : 'No subjects matching your filters.',
                          style: const TextStyle(color: Colors.grey, fontSize: 15),
                        ),
                        const SizedBox(height: 16),
                        if (allSubjects.isEmpty)
                          ElevatedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AddSubjectScreen()),
                            ),
                            icon: const Icon(Icons.add_rounded, color: Colors.white),
                            label: const Text('Add First Subject', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigoAccent),
                          ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => _buildSubjectCard(context, filtered[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
      deleteIcon: const Icon(Icons.close, size: 14, color: Colors.white70),
      onDeleted: onRemove,
      backgroundColor: Colors.indigo.withAlpha(100),
      side: BorderSide(color: Colors.indigoAccent.withAlpha(120)),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildSubjectCard(BuildContext context, SubjectModel subject) {
    final isActive = subject.status.toLowerCase() == 'active';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? Colors.indigoAccent.withAlpha(60) : Colors.white10,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.indigo.withAlpha(40),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            subject.subjectCode.length >= 2
                ? subject.subjectCode.substring(0, 2).toUpperCase()
                : subject.subjectCode.toUpperCase(),
            style: const TextStyle(
              color: Colors.indigoAccent,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                subject.subjectName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isActive ? Colors.green.withAlpha(50) : Colors.red.withAlpha(50),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isActive ? Colors.greenAccent : Colors.redAccent,
                ),
              ),
              child: Text(
                isActive ? 'ACTIVE' : 'INACTIVE',
                style: TextStyle(
                  color: isActive ? Colors.greenAccent : Colors.redAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.code_rounded, size: 13, color: Colors.indigoAccent),
                const SizedBox(width: 4),
                Text(
                  '${subject.subjectCode} • ${subject.academicYear} • ${subject.semester}',
                  style: const TextStyle(color: Colors.indigoAccent, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.person_outline_rounded, size: 13, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    subject.lecturerName,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () => _showSubjectDetails(context, subject),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.indigoAccent, size: 20),
              tooltip: 'Edit Subject',
              onPressed: () => _showEditDialog(context, subject),
            ),
            IconButton(
              icon: Icon(
                isActive ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
                color: isActive ? Colors.greenAccent : Colors.grey,
                size: 30,
              ),
              tooltip: isActive ? 'Deactivate' : 'Activate',
              onPressed: () async {
                if (subject.docId != null) {
                  await _subjectService.toggleSubjectStatus(subject.docId!, subject.status);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '"${subject.subjectName}" is now ${isActive ? 'INACTIVE' : 'ACTIVE'}',
                        ),
                        backgroundColor: isActive ? Colors.orange : Colors.green,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSubjectDetails(BuildContext context, SubjectModel subject) {
    final isActive = subject.status.toLowerCase() == 'active';
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withAlpha(40),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.book_rounded, color: Colors.indigoAccent, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject.subjectName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subject.subjectCode,
                        style: const TextStyle(color: Colors.indigoAccent, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green.withAlpha(50) : Colors.red.withAlpha(50),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isActive ? Colors.greenAccent : Colors.redAccent),
                  ),
                  child: Text(
                    isActive ? 'ACTIVE' : 'INACTIVE',
                    style: TextStyle(
                      color: isActive ? Colors.greenAccent : Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 28),
            _detailRow(Icons.numbers_rounded, 'Subject ID', subject.subjectId),
            _detailRow(Icons.code_rounded, 'Subject Code', subject.subjectCode),
            _detailRow(Icons.calendar_today_rounded, 'Academic Year', subject.academicYear),
            _detailRow(Icons.bookmark_rounded, 'Semester', subject.semester),
            _detailRow(Icons.person_rounded, 'Assigned Lecturer', subject.lecturerName),
            if (subject.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Description', style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 4),
              Text(subject.description, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.indigoAccent),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    String tempStatus = _filterStatus;
    String tempYear = _filterYear;
    String tempSemester = _filterSemester;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Filter Subjects',
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _filterDropdown('Status', tempStatus, _statusOptions, (val) {
                setSheetState(() => tempStatus = val!);
              }),
              const SizedBox(height: 14),
              _filterDropdown('Academic Year', tempYear, _yearOptions, (val) {
                setSheetState(() => tempYear = val!);
              }),
              const SizedBox(height: 14),
              _filterDropdown('Semester', tempSemester, _semesterOptions, (val) {
                setSheetState(() => tempSemester = val!);
              }),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _filterStatus = 'All';
                          _filterYear = 'All';
                          _filterSemester = 'All';
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
                          _filterYear = tempYear;
                          _filterSemester = tempSemester;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigoAccent,
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
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterDropdown(
    String label,
    String currentValue,
    List<String> options,
    void Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: currentValue,
      dropdownColor: const Color(0xFF1E293B),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
        filled: true,
        fillColor: const Color(0xFF0F172A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      items: options
          .map((o) => DropdownMenuItem(
                value: o,
                child: Text(o == 'active'
                    ? 'Active'
                    : o == 'inactive'
                        ? 'Inactive'
                        : o),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  void _showEditDialog(BuildContext context, SubjectModel subject) {
    final nameCtrl = TextEditingController(text: subject.subjectName);
    final descCtrl = TextEditingController(text: subject.description);
    String selectedYear = subject.academicYear;
    String selectedSemester = subject.semester;
    String selectedStatus = subject.status.toLowerCase();
    String selectedLecturerName = subject.lecturerName;
    String? selectedLecturerId = subject.lecturerId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text(
            'Edit Subject',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Subject Name
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: _fieldDecoration('Subject Name'),
                  ),
                  const SizedBox(height: 12),
                  // Description
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white),
                    decoration: _fieldDecoration('Description'),
                  ),
                  const SizedBox(height: 12),
                  // Assign Lecturer
                  StreamBuilder<List<LecturerModel>>(
                    stream: LecturerService().getLecturersStream(),
                    builder: (context, snap) {
                      final activeLecturers = (snap.data ?? [])
                          .where((l) => l.status.toLowerCase() == 'active')
                          .toList();
                      return DropdownButtonFormField<String>(
                        value: selectedLecturerId ?? 'none',
                        dropdownColor: const Color(0xFF1E293B),
                        style: const TextStyle(color: Colors.white),
                        decoration: _fieldDecoration('Assign Lecturer'),
                        items: [
                          const DropdownMenuItem(
                            value: 'none',
                            child: Text('Unassigned'),
                          ),
                          ...activeLecturers.map((lec) => DropdownMenuItem(
                                value: lec.docId ?? lec.lecturerId,
                                child: Text('${lec.name} (${lec.department})',
                                    overflow: TextOverflow.ellipsis),
                              )),
                        ],
                        onChanged: (val) {
                          if (val == 'none' || val == null) {
                            setDialogState(() {
                              selectedLecturerId = null;
                              selectedLecturerName = 'Unassigned';
                            });
                          } else {
                            final found = activeLecturers.firstWhere(
                              (l) => (l.docId == val || l.lecturerId == val),
                              orElse: () => LecturerModel(
                                lecturerId: '',
                                name: 'Unassigned',
                                email: '',
                                department: '',
                              ),
                            );
                            setDialogState(() {
                              selectedLecturerId = val;
                              selectedLecturerName = found.name;
                            });
                          }
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  // Academic Year
                  DropdownButtonFormField<String>(
                    value: selectedYear,
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Colors.white),
                    decoration: _fieldDecoration('Academic Year'),
                    items: _yearOptions
                        .where((y) => y != 'All')
                        .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedYear = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  // Semester
                  DropdownButtonFormField<String>(
                    value: selectedSemester,
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Colors.white),
                    decoration: _fieldDecoration('Semester'),
                    items: _semesterOptions
                        .where((s) => s != 'All')
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedSemester = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  // Status
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Colors.white),
                    decoration: _fieldDecoration('Status'),
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedStatus = val);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigoAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                final updated = SubjectModel(
                  docId: subject.docId,
                  subjectId: subject.subjectId,
                  subjectCode: subject.subjectCode,
                  subjectName: nameCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  semester: selectedSemester,
                  academicYear: selectedYear,
                  lecturerName: selectedLecturerName,
                  lecturerId: selectedLecturerId,
                  status: selectedStatus,
                  createdAt: subject.createdAt,
                );
                await _subjectService.updateSubject(updated);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('"${updated.subjectName}" updated successfully!'),
                      backgroundColor: Colors.indigo,
                    ),
                  );
                }
              },
              child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
      filled: true,
      fillColor: const Color(0xFF0F172A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.indigoAccent, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}
