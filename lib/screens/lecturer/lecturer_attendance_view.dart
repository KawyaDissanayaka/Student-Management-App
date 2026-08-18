import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/subject_model.dart';
import '../../models/enrollment_model.dart';
import '../../models/attendance_model.dart';
import '../../models/timetable_model.dart';
import '../../services/attendance_service.dart';
import 'lecturer_qr_session_screen.dart';

class LecturerAttendanceView extends StatefulWidget {
  final SubjectModel subject;
  final String lecturerEmail;
  final String lecturerName;

  const LecturerAttendanceView({
    super.key,
    required this.subject,
    required this.lecturerEmail,
    required this.lecturerName,
  });

  @override
  State<LecturerAttendanceView> createState() => _LecturerAttendanceViewState();
}

class _LecturerAttendanceViewState extends State<LecturerAttendanceView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AttendanceService _attendanceService = AttendanceService();

  DateTime _selectedDate = DateTime.now();
  TimetableModel? _selectedSession;

  // Map of studentDocId -> status ('Present', 'Late', 'Absent')
  final Map<String, String> _studentStatusMap = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime(2030, 12, 31),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: Colors.tealAccent, onPrimary: Colors.black, surface: Color(0xFF1E293B)),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _studentStatusMap.clear(); // Reset map for new date so it loads from DB
      });
    }
  }

  void _markAll(String status, List<EnrollmentModel> enrollments) {
    setState(() {
      for (var e in enrollments) {
        _studentStatusMap[e.studentDocId] = status;
      }
    });
  }

  Future<void> _saveAttendanceBatch(List<EnrollmentModel> enrollments) async {
    if (enrollments.isEmpty) return;

    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    final dateStr = _formatDate(_selectedDate);

    try {
      // Check Admin Attendance Configuration
      final config = await _attendanceService.getAttendanceConfig();
      final bool enableManual = config['enableManualAttendance'] as bool? ?? true;

      if (!enableManual) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Manual Attendance recording is restricted by Administrator Policy. Please start a Dynamic QR Session.'),
            backgroundColor: Colors.orangeAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final List<AttendanceModel> records = [];

      for (var e in enrollments) {
        final status = _studentStatusMap[e.studentDocId] ?? 'Present';

        records.add(AttendanceModel(
          studentDocId: e.studentDocId,
          studentId: e.studentId,
          studentName: e.studentName,
          subjectCode: widget.subject.subjectCode,
          subjectName: widget.subject.subjectName,
          date: dateStr,
          status: status,
          markedBy: widget.lecturerName,
          batch: e.academicYear,
          semester: widget.subject.semester,
          sessionTime: _selectedSession != null ? '${_selectedSession!.startTime} - ${_selectedSession!.endTime}' : 'Regular Class',
          hallName: _selectedSession?.hallName ?? 'Main Lecture Hall',
          createdBy: widget.lecturerEmail,
          updatedBy: widget.lecturerEmail,
        ));
      }

      await _attendanceService.saveAttendance(records);

      messenger.showSnackBar(
        SnackBar(
          content: Text('Attendance for $dateStr saved successfully (${records.length} students recorded)!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to save attendance: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = _formatDate(_selectedDate);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<QuerySnapshot>(
        // 1. Fetch Active Enrolled Students for this Subject
        stream: _firestore
            .collection('enrollments')
            .where('subjectCode', isEqualTo: widget.subject.subjectCode)
            .where('status', isEqualTo: 'active')
            .snapshots(),
        builder: (context, enrollSnap) {
          return StreamBuilder<QuerySnapshot>(
            // 2. Fetch All Attendance for this Subject (History & Stats)
            stream: _firestore
                .collection('attendance')
                .where('subjectCode', isEqualTo: widget.subject.subjectCode)
                .snapshots(),
            builder: (context, attendSnap) {
              return StreamBuilder<QuerySnapshot>(
                // 3. Fetch Timetable Sessions for this Subject
                stream: _firestore
                    .collection('timetable')
                    .where('subjectCode', isEqualTo: widget.subject.subjectCode)
                    .snapshots(),
                builder: (context, timeSnap) {
                  return StreamBuilder<QuerySnapshot>(
                    // 4. Fetch Students Profile
                    stream: _firestore.collection('students').snapshots(),
                    builder: (context, studentSnap) {
                      return StreamBuilder<DocumentSnapshot>(
                        // 5. Fetch Attendance Threshold Config
                        stream: _firestore.collection('settings').doc('attendance_config').snapshots(),
                        builder: (context, configSnap) {
                          if (enrollSnap.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
                          }

                          final configData = configSnap.data?.data() as Map<String, dynamic>?;
                          final double minThreshold = (configData?['minAttendancePercentage'] as num?)?.toDouble() ?? 80.0;

                          // Parse distinct enrollments
                          final allEnrollDocs = enrollSnap.data?.docs ?? [];
                          final Map<String, EnrollmentModel> uniqueEnrollMap = {};
                          for (var d in allEnrollDocs) {
                            final e = EnrollmentModel.fromFirestore(d as DocumentSnapshot<Map<String, dynamic>>);
                            uniqueEnrollMap[e.studentEmail.toLowerCase()] = e;
                          }
                          final activeEnrollments = uniqueEnrollMap.values.toList();

                          // Timetable schedules
                          final schedules = (timeSnap.data?.docs ?? [])
                              .map((d) => TimetableModel.fromFirestore(d))
                              .where((s) => s.status != 'cancelled')
                              .toList();

                          if (_selectedSession == null && schedules.isNotEmpty) {
                            _selectedSession = schedules.first;
                          }

                          // All Attendance records for this subject (excluding cancelled)
                          final allAttendDocs = attendSnap.data?.docs ?? [];
                          final attendanceRecords = allAttendDocs
                              .map((d) => AttendanceModel.fromFirestore(d as DocumentSnapshot<Map<String, dynamic>>))
                              .where((r) => r.status.toLowerCase() != 'cancelled')
                              .toList();

                          // Pre-fill existing records for selected date into _studentStatusMap
                          final todayRecords = attendanceRecords.where((r) => r.date == dateStr).toList();
                          for (var r in todayRecords) {
                            _studentStatusMap.putIfAbsent(r.studentDocId, () => r.status);
                          }

                          // Calculate Subject Attendance Statistics
                          final totalLogs = attendanceRecords.length;
                          final totalPresentOrLate = attendanceRecords.where((r) => r.status.toLowerCase() == 'present' || r.status.toLowerCase() == 'late').length;
                          final double avgAttendance = totalLogs > 0 ? (totalPresentOrLate / totalLogs) * 100 : 100.0;

                          // Calculate Low Attendance Students (< minThreshold)
                          final Map<String, List<AttendanceModel>> studentLogsMap = {};
                          for (var r in attendanceRecords) {
                            studentLogsMap.putIfAbsent(r.studentId.toLowerCase(), () => []).add(r);
                          }

                          int lowAttendanceCount = 0;
                          for (var e in activeEnrollments) {
                            final sLogs = studentLogsMap[e.studentId.toLowerCase()] ?? [];
                            if (sLogs.isNotEmpty) {
                              final pCount = sLogs.where((r) => r.status.toLowerCase() == 'present' || r.status.toLowerCase() == 'late').length;
                              final pRate = (pCount / sLogs.length) * 100;
                              if (pRate < minThreshold) lowAttendanceCount++;
                            }
                          }

                          final todayPresent = todayRecords.where((r) => r.status.toLowerCase() == 'present' || r.status.toLowerCase() == 'late').length;
                          final todayAbsent = todayRecords.where((r) => r.status.toLowerCase() == 'absent').length;

                          return Column(
                            children: [
                              // KPI Cards Summary
                              Container(
                                padding: const EdgeInsets.all(16),
                                color: const Color(0xFF1E293B),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildMetricMiniCard(
                                            'Avg Attendance',
                                            '${avgAttendance.toStringAsFixed(1)}%',
                                            avgAttendance >= minThreshold ? Colors.greenAccent : Colors.orangeAccent,
                                            Icons.analytics_rounded,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _buildMetricMiniCard(
                                            'Present on Date',
                                            '$todayPresent Students',
                                            Colors.tealAccent,
                                            Icons.how_to_reg_rounded,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _buildMetricMiniCard(
                                            'Absent on Date',
                                            '$todayAbsent Students',
                                            todayAbsent > 0 ? Colors.redAccent : Colors.grey,
                                            Icons.person_off_rounded,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _buildMetricMiniCard(
                                            'Low Att. (<${minThreshold.toInt()}%)',
                                            '$lowAttendanceCount Students',
                                            lowAttendanceCount > 0 ? Colors.amberAccent : Colors.greenAccent,
                                            Icons.warning_amber_rounded,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    // Dynamic QR Attendance Session Trigger Banner
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF064E3B), Color(0xFF0F172A)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.tealAccent.withAlpha(90)),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(color: Colors.teal.withAlpha(50), shape: BoxShape.circle),
                                            child: const Icon(Icons.qr_code_2_rounded, size: 24, color: Colors.tealAccent),
                                          ),
                                          const SizedBox(width: 12),
                                          const Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Dynamic QR Attendance',
                                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                                ),
                                                Text(
                                                  'Broadcast live QR for students to scan on their app',
                                                  style: TextStyle(color: Colors.white70, fontSize: 11),
                                                ),
                                              ],
                                            ),
                                          ),
                                          ElevatedButton.icon(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => LecturerQrSessionScreen(
                                                    subject: widget.subject,
                                                    lecturerEmail: widget.lecturerEmail,
                                                    lecturerName: widget.lecturerName,
                                                    lecturerId: 'LEC-1001',
                                                    preselectedSession: _selectedSession,
                                                  ),
                                                ),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.tealAccent,
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                            icon: const Icon(Icons.sensors_rounded, color: Colors.black, size: 16),
                                            label: const Text(
                                              'Start QR',
                                              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // Secondary Tab Bar (Mark Session / History)
                                    Container(
                                      height: 38,
                                      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(10)),
                                      child: TabBar(
                                        controller: _tabController,
                                        indicator: BoxDecoration(color: Colors.teal, borderRadius: BorderRadius.circular(8)),
                                        labelColor: Colors.white,
                                        unselectedLabelColor: Colors.grey,
                                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                        tabs: const [
                                          Tab(text: 'Mark Attendance Session'),
                                          Tab(text: 'Attendance Log History'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Expanded(
                                child: TabBarView(
                                  controller: _tabController,
                                  children: [
                                    _buildMarkSessionTab(activeEnrollments, schedules, dateStr),
                                    _buildHistoryTab(attendanceRecords),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // ─── 1. MARK SESSION TAB ───────────────────────────────────────────────────
  Widget _buildMarkSessionTab(List<EnrollmentModel> enrollments, List<TimetableModel> schedules, String dateStr) {
    if (enrollments.isEmpty) {
      return const Center(
        child: Text('No active students enrolled to mark attendance.', style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      children: [
        // Date & Timetable Session Selector Strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            border: Border(top: BorderSide(color: Colors.white10)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Date Picker Trigger
                  Expanded(
                    flex: 1,
                    child: InkWell(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.tealAccent.withAlpha(80)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(dateStr, style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                            const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.tealAccent),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Session Picker
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: DropdownButton<TimetableModel>(
                        value: _selectedSession,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF0F172A),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        underline: const SizedBox(),
                        hint: const Text('Select Class Session', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        items: schedules.map((s) {
                          return DropdownMenuItem(
                            value: s,
                            child: Text('${s.dayOfWeek} ${s.startTime} (${s.hallName})', overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedSession = val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Batch Quick Actions: Mark All Present / Absent
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Class Roster (${enrollments.length} Students)', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () => _markAll('Present', enrollments),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.withAlpha(40),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        child: const Text('All Present', style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton(
                        onPressed: () => _markAll('Absent', enrollments),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.withAlpha(40),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        child: const Text('All Absent', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        // Students Marking List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: enrollments.length,
            itemBuilder: (context, index) {
              final e = enrollments[index];
              final currentStatus = _studentStatusMap[e.studentDocId] ?? 'Present';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.teal.withAlpha(30),
                      child: Text(
                        e.studentName.isNotEmpty ? e.studentName[0].toUpperCase() : 'S',
                        style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.studentName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('${e.studentId} • Batch ${e.academicYear}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                    ),

                    // Present / Late / Absent Toggle
                    Container(
                      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          _buildStatusToggleOption(e.studentDocId, 'Present', 'P', currentStatus, Colors.greenAccent),
                          _buildStatusToggleOption(e.studentDocId, 'Late', 'L', currentStatus, Colors.orangeAccent),
                          _buildStatusToggleOption(e.studentDocId, 'Absent', 'A', currentStatus, Colors.redAccent),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Bottom Save Action Bar
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF1E293B),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : () => _saveAttendanceBatch(enrollments),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: _isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_rounded, color: Colors.white),
              label: Text(
                _isSaving ? 'Saving Records...' : 'Save Attendance ($dateStr)',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusToggleOption(String studentDocId, String statusValue, String label, String currentStatus, Color activeColor) {
    final isSelected = currentStatus.toLowerCase() == statusValue.toLowerCase();

    return InkWell(
      onTap: () => setState(() => _studentStatusMap[studentDocId] = statusValue),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withAlpha(40) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? activeColor : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // ─── 2. ATTENDANCE HISTORY TAB ─────────────────────────────────────────────
  Widget _buildHistoryTab(List<AttendanceModel> records) {
    // Group records by Date
    final Map<String, List<AttendanceModel>> groupedByDate = {};
    for (var r in records) {
      groupedByDate.putIfAbsent(r.date, () => []).add(r);
    }

    final sortedDates = groupedByDate.keys.toList()..sort((a, b) => b.compareTo(a));

    if (sortedDates.isEmpty) {
      return const Center(
        child: Text('No past attendance sessions logged yet.', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final dateKey = sortedDates[index];
        final list = groupedByDate[dateKey]!;
        final presentCount = list.where((r) => r.status.toLowerCase() == 'present' || r.status.toLowerCase() == 'late').length;
        final absentCount = list.where((r) => r.status.toLowerCase() == 'absent').length;
        final double rate = list.isNotEmpty ? (presentCount / list.length) * 100 : 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.event_available_rounded, size: 16, color: Colors.tealAccent),
                      const SizedBox(width: 8),
                      Text(dateKey, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: rate >= 80 ? Colors.green.withAlpha(30) : Colors.orange.withAlpha(30),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${rate.toStringAsFixed(0)}% RATE',
                      style: TextStyle(color: rate >= 80 ? Colors.greenAccent : Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total: ${list.length} • Present: $presentCount • Absent: $absentCount', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  TextButton.icon(
                    onPressed: () {
                      final parsed = DateTime.tryParse(dateKey) ?? DateTime.now();
                      setState(() {
                        _selectedDate = parsed;
                        _tabController.animateTo(0); // Switch to mark tab
                      });
                    },
                    icon: const Icon(Icons.edit_rounded, size: 14, color: Colors.tealAccent),
                    label: const Text('Edit Session', style: TextStyle(color: Colors.tealAccent, fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricMiniCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 10), overflow: TextOverflow.ellipsis)),
              Icon(icon, size: 12, color: color),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
