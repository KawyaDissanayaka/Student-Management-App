import 'package:flutter/material.dart';
import '../../models/attendance_model.dart';
import '../../services/attendance_service.dart';
import 'mark_attendance_screen.dart';
import 'student_attendance_history_dialog.dart';

class AttendanceListScreen extends StatefulWidget {
  const AttendanceListScreen({super.key});

  @override
  State<AttendanceListScreen> createState() => _AttendanceListScreenState();
}

class _AttendanceListScreenState extends State<AttendanceListScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  String _searchQuery = '';
  String _selectedSubjectFilter = 'All';
  String _selectedStatusFilter = 'All';
  String _selectedSemesterFilter = 'All';
  String _selectedBatchFilter = 'All';
  String? _selectedDateFilter; // Format: yyyy-MM-dd

  double _threshold = 80.0;

  @override
  void initState() {
    super.initState();
    _loadThreshold();
  }

  Future<void> _loadThreshold() async {
    final val = await _attendanceService.getAttendanceThreshold();
    setState(() {
      _threshold = val;
    });
  }

  Future<void> _selectDateFilter(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.tealAccent,
              onPrimary: Colors.black,
              surface: Color(0xFF1E293B),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final y = picked.year;
      final m = picked.month.toString().padLeft(2, '0');
      final d = picked.day.toString().padLeft(2, '0');
      setState(() {
        _selectedDateFilter = '$y-$m-$d';
      });
    }
  }

  void _showThresholdSettings() {
    final controller = TextEditingController(text: _threshold.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('Attendance Settings', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Define the Low Attendance threshold percentage (%). Students below this threshold will be flagged.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Threshold (%)',
                  labelStyle: TextStyle(color: Colors.tealAccent),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.tealAccent)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              onPressed: () async {
                final double? val = double.tryParse(controller.text);
                if (val != null && val >= 0 && val <= 100) {
                  await _attendanceService.updateAttendanceThreshold(val);
                  setState(() {
                    _threshold = val;
                  });
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Threshold updated to $val%'), backgroundColor: Colors.teal),
                    );
                  }
                }
              },
              child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
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
          'Attendance Records',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: Colors.tealAccent),
            tooltip: 'Threshold Settings',
            onPressed: _showThresholdSettings,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.edit_calendar_rounded, color: Colors.white),
        label: const Text('Mark Attendance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MarkAttendanceScreen()),
          );
        },
      ),
      body: StreamBuilder<List<AttendanceModel>>(
        stream: _attendanceService.getAttendanceStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.teal));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
          }

          final records = snapshot.data ?? [];

          // Collect unique attributes for filter dropdowns
          final subjects = {'All', ...records.map((r) => r.subjectName)};
          final semesters = {'All', ...records.map((r) => r.semester)};
          final batches = {'All', ...records.map((r) => r.batch)};
          final statuses = {'All', 'Present', 'Absent', 'Late'};

          final filteredRecords = records.where((rec) {
            final matchesSearch = rec.studentId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                rec.studentName.toLowerCase().contains(_searchQuery.toLowerCase());

            final matchesSubject = _selectedSubjectFilter == 'All' || rec.subjectName == _selectedSubjectFilter;
            final matchesSemester = _selectedSemesterFilter == 'All' || rec.semester == _selectedSemesterFilter;
            final matchesBatch = _selectedBatchFilter == 'All' || rec.batch == _selectedBatchFilter;
            final matchesStatus = _selectedStatusFilter == 'All' || rec.status.toLowerCase() == _selectedStatusFilter.toLowerCase();
            final matchesDate = _selectedDateFilter == null || rec.date == _selectedDateFilter;

            return matchesSearch && matchesSubject && matchesSemester && matchesBatch && matchesStatus && matchesDate;
          }).toList();

          return Column(
            children: [
              // Filters panel
              Container(
                color: const Color(0xFF1E293B),
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            onChanged: (val) => setState(() => _searchQuery = val),
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Search student...',
                              hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                              prefixIcon: const Icon(Icons.search, color: Colors.tealAccent, size: 20),
                              filled: true,
                              fillColor: const Color(0xFF0F172A),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Date selector filter
                        InkWell(
                          onTap: () => _selectDateFilter(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_month_rounded, color: Colors.tealAccent, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  _selectedDateFilter ?? 'All Dates',
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                ),
                                if (_selectedDateFilter != null) ...[
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () => setState(() => _selectedDateFilter = null),
                                    child: const Icon(Icons.close, color: Colors.redAccent, size: 16),
                                  )
                                ]
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Filters row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterDropdown('Subject', _selectedSubjectFilter, subjects.toList(), (val) {
                            setState(() => _selectedSubjectFilter = val!);
                          }),
                          const SizedBox(width: 8),
                          _buildFilterDropdown('Semester', _selectedSemesterFilter, semesters.toList(), (val) {
                            setState(() => _selectedSemesterFilter = val!);
                          }),
                          const SizedBox(width: 8),
                          _buildFilterDropdown('Batch', _selectedBatchFilter, batches.toList(), (val) {
                            setState(() => _selectedBatchFilter = val!);
                          }),
                          const SizedBox(width: 8),
                          _buildFilterDropdown('Status', _selectedStatusFilter, statuses.toList(), (val) {
                            setState(() => _selectedStatusFilter = val!);
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Records list
              Expanded(
                child: filteredRecords.isEmpty
                    ? const Center(
                        child: Text(
                          'No attendance records found.',
                          style: TextStyle(color: Colors.grey, fontSize: 15),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredRecords.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final rec = filteredRecords[index];
                          final isPresent = rec.status.toLowerCase() == 'present';
                          final isAbsent = rec.status.toLowerCase() == 'absent';

                          return Card(
                            color: const Color(0xFF1E293B),
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Colors.white10),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    rec.studentName,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isPresent
                                          ? Colors.green.withAlpha(40)
                                          : isAbsent
                                              ? Colors.red.withAlpha(40)
                                              : Colors.amber.withAlpha(40),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      rec.status.toUpperCase(),
                                      style: TextStyle(
                                        color: isPresent
                                            ? Colors.greenAccent
                                            : isAbsent
                                                ? Colors.redAccent
                                                : Colors.amberAccent,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ID: ${rec.studentId} • Subject: ${rec.subjectName} (${rec.subjectCode})',
                                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Date: ${rec.date} • Semester: ${rec.semester} • Marked By: ${rec.markedBy}',
                                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              onTap: () {
                                // Filter this student's records to view history
                                final studentRecords = records
                                    .where((r) => r.studentDocId == rec.studentDocId)
                                    .toList();

                                showDialog(
                                  context: context,
                                  builder: (context) => StudentAttendanceHistoryDialog(
                                    studentName: rec.studentName,
                                    studentId: rec.studentId,
                                    attendanceRecords: studentRecords,
                                    threshold: _threshold,
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    final currentValue = items.contains(value) ? value : 'All';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          dropdownColor: const Color(0xFF1E293B),
          style: const TextStyle(color: Colors.white, fontSize: 12),
          onChanged: onChanged,
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text('$label: $item'),
            );
          }).toList(),
        ),
      ),
    );
  }
}
