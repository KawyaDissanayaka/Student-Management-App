import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/subject_model.dart';
import '../../models/attendance_model.dart';
import '../../services/subject_service.dart';
import '../../services/attendance_service.dart';
import '../../services/auth_service.dart';

class MarkAttendanceScreen extends StatefulWidget {
  const MarkAttendanceScreen({super.key});

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  final _attendanceService = AttendanceService();
  final _subjectService = SubjectService();
  final _authService = AuthService();

  String? _selectedSubjectDocId;
  SubjectModel? _selectedSubject;
  DateTime _selectedDate = DateTime.now();

  List<Map<String, dynamic>> _enrolledStudents = [];
  Map<String, String> _attendanceStatuses = {}; // studentDocId -> status (Present, Absent, Late)
  bool _isLoadingStudents = false;
  bool _isSaving = false;

  String _formatDate(DateTime dt) {
    final y = dt.year;
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  // Load students enrolled in the selected subject, and load any existing marked attendance
  Future<void> _loadSubjectData() async {
    if (_selectedSubject == null) return;

    setState(() {
      _isLoadingStudents = true;
      _enrolledStudents = [];
      _attendanceStatuses = {};
    });

    try {
      // 1. Fetch active enrollments for this subject
      final enrollmentQuery = await FirebaseFirestore.instance
          .collection('enrollments')
          .where('subjectCode', isEqualTo: _selectedSubject!.subjectCode)
          .where('status', isEqualTo: 'active')
          .get();

      final List<Map<String, dynamic>> students = [];
      for (var doc in enrollmentQuery.docs) {
        final data = doc.data();
        students.add({
          'studentDocId': data['studentDocId'],
          'studentId': data['studentId'],
          'studentName': data['studentName'],
          'batch': data['batch'] ?? 'N/A',
          'semester': data['semester'] ?? 'Semester 1',
        });
        // Default status is Present
        _attendanceStatuses[data['studentDocId']] = 'Present';
      }

      // 2. Query existing attendance for this subject + date
      final dateStr = _formatDate(_selectedDate);
      final attendanceQuery = await FirebaseFirestore.instance
          .collection('attendance')
          .where('subjectCode', isEqualTo: _selectedSubject!.subjectCode)
          .where('date', isEqualTo: dateStr)
          .get();

      // Overwrite default statuses with existing ones
      for (var doc in attendanceQuery.docs) {
        final data = doc.data();
        final studentDocId = data['studentDocId'];
        final status = data['status'];
        if (_attendanceStatuses.containsKey(studentDocId)) {
          _attendanceStatuses[studentDocId] = status;
        }
      }

      setState(() {
        _enrolledStudents = students;
        _isLoadingStudents = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingStudents = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading student list: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
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
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadSubjectData();
    }
  }

  Future<void> _saveAttendance() async {
    if (_selectedSubject == null || _enrolledStudents.isEmpty) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final dateStr = _formatDate(_selectedDate);
      final marker = _authService.currentUser?.email ?? 'Admin';

      final List<AttendanceModel> records = _enrolledStudents.map((s) {
        final docId = s['studentDocId'];
        final status = _attendanceStatuses[docId] ?? 'Present';
        return AttendanceModel(
          studentDocId: docId,
          studentId: s['studentId'],
          studentName: s['studentName'],
          subjectCode: _selectedSubject!.subjectCode,
          subjectName: _selectedSubject!.subjectName,
          date: dateStr,
          status: status,
          markedBy: marker,
          batch: s['batch'],
          semester: s['semester'],
        );
      }).toList();

      await _attendanceService.saveAttendance(records);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance saved successfully!'),
            backgroundColor: Colors.teal,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = _formatDate(_selectedDate);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text(
          'Mark Attendance',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Selectors Panel
          Container(
            color: const Color(0xFF1E293B),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Subject Dropdown
                StreamBuilder<List<SubjectModel>>(
                  stream: _subjectService.getSubjectsStream(),
                  builder: (context, snapshot) {
                    final activeSubjects = (snapshot.data ?? [])
                        .where((s) => s.status.toLowerCase() == 'active')
                        .toList();

                    return DropdownButtonFormField<String>(
                      initialValue: _selectedSubjectDocId,
                      dropdownColor: const Color(0xFF1E293B),
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Select Subject', Icons.book_rounded),
                      items: activeSubjects.map((sub) {
                        return DropdownMenuItem(
                          value: sub.docId,
                          child: Text('${sub.subjectName} (${sub.subjectCode})'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedSubjectDocId = val;
                            _selectedSubject = activeSubjects.firstWhere((s) => s.docId == val);
                          });
                          _loadSubjectData();
                        }
                      },
                    );
                  },
                ),
                const SizedBox(height: 14),

                // Date Picker field
                InkWell(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded, color: Colors.tealAccent),
                            const SizedBox(width: 12),
                            Text(
                              'Date: $dateStr',
                              style: const TextStyle(color: Colors.white, fontSize: 15),
                            ),
                          ],
                        ),
                        const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Enrolled Students List
          Expanded(
            child: _selectedSubject == null
                ? const Center(
                    child: Text(
                      'Please select a subject to load students.',
                      style: TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                  )
                : _isLoadingStudents
                    ? const Center(child: CircularProgressIndicator(color: Colors.tealAccent))
                    : _enrolledStudents.isEmpty
                        ? const Center(
                            child: Text(
                              'No active student enrollments for this subject.',
                              style: TextStyle(color: Colors.grey, fontSize: 15),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _enrolledStudents.length,
                            padding: const EdgeInsets.all(16),
                            itemBuilder: (context, index) {
                              final student = _enrolledStudents[index];
                              final docId = student['studentDocId'] as String;
                              final currentStatus = _attendanceStatuses[docId] ?? 'Present';

                              return Card(
                                color: const Color(0xFF1E293B),
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(color: Colors.white10),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              student['studentName'],
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'ID: ${student['studentId']} • Batch: ${student['batch']}',
                                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Custom Present / Absent / Late toggle row
                                      Row(
                                        children: [
                                          _buildStatusButton(docId, 'Present', Colors.green, currentStatus),
                                          const SizedBox(width: 6),
                                          _buildStatusButton(docId, 'Absent', Colors.red, currentStatus),
                                          const SizedBox(width: 6),
                                          _buildStatusButton(docId, 'Late', Colors.amber, currentStatus),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),

          // Save Button Panel
          if (_selectedSubject != null && _enrolledStudents.isNotEmpty && !_isLoadingStudents)
            Container(
              padding: const EdgeInsets.all(16.0),
              color: const Color(0xFF1E293B),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveAttendance,
                  icon: _isSaving
                      ? const SizedBox.shrink()
                      : const Icon(Icons.save_rounded, color: Colors.white),
                  label: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Save Attendance',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusButton(String studentDocId, String status, MaterialColor color, String currentStatus) {
    final bool isSelected = currentStatus == status;
    return GestureDetector(
      onTap: () {
        setState(() {
          _attendanceStatuses[studentDocId] = status;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(50) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? color : Colors.white10,
            width: 1.2,
          ),
        ),
        child: Text(
          status[0], // P, A, L
          style: TextStyle(
            color: isSelected ? color : Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
      prefixIcon: Icon(icon, color: Colors.tealAccent),
      filled: true,
      fillColor: const Color(0xFF0F172A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }
}
