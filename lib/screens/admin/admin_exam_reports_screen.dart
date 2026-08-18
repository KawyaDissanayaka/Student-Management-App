import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/exam_reports_service.dart';

class AdminExamReportsScreen extends StatefulWidget {
  const AdminExamReportsScreen({super.key});

  @override
  State<AdminExamReportsScreen> createState() => _AdminExamReportsScreenState();
}

class _AdminExamReportsScreenState extends State<AdminExamReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ExamReportsService _reportsService = ExamReportsService();

  // Filters
  final String _selectedBatch = 'All';
  String _selectedStatus = 'All';
  final String _selectedModule = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── CSV EXPORT MODAL ───────────────────────────────────────────────────────
  void _showCsvExportModal(String title, String csvContent) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.download_rounded, color: Colors.tealAccent),
                    const SizedBox(width: 8),
                    Text('$title (CSV Export)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Data formatted in standard CSV (Comma Separated Values) format for Excel / Google Sheets:', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 10),

            // Raw CSV Code Container
            Container(
              height: 200,
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: SingleChildScrollView(
                child: Text(
                  csvContent,
                  style: const TextStyle(color: Colors.tealAccent, fontSize: 11, fontFamily: 'monospace'),
                ),
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: csvContent));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('CSV copied to clipboard! You can paste into Excel or Google Sheets.'), backgroundColor: Colors.green),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                icon: const Icon(Icons.copy_rounded, color: Colors.white),
                label: const Text('Copy CSV to Clipboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Examination Reports & Analytics', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.tealAccent,
          labelColor: Colors.tealAccent,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          isScrollable: true,
          tabs: const [
            Tab(text: 'Registration', icon: Icon(Icons.how_to_reg_rounded, size: 16)),
            Tab(text: 'Attendance', icon: Icon(Icons.fact_check_rounded, size: 16)),
            Tab(text: 'Seating Allocation', icon: Icon(Icons.event_seat_rounded, size: 16)),
            Tab(text: 'Result & Grades', icon: Icon(Icons.analytics_rounded, size: 16)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ─── TAB 1: REGISTRATION REPORT ─────────────────────────────────────
          _buildRegistrationReportTab(),

          // ─── TAB 2: ATTENDANCE REPORT ───────────────────────────────────────
          _buildAttendanceReportTab(),

          // ─── TAB 3: SEATING ALLOCATION REPORT ───────────────────────────────
          _buildSeatingReportTab(),

          // ─── TAB 4: RESULT & MODERATION REPORT ──────────────────────────────
          _buildResultReportTab(),
        ],
      ),
    );
  }

  // ─── 1. REGISTRATION REPORT TAB ─────────────────────────────────────────────
  Widget _buildRegistrationReportTab() {
    return FutureBuilder<ExamRegistrationReportData>(
      future: _reportsService.getRegistrationReport(
        batch: _selectedBatch,
        status: _selectedStatus,
        subjectCode: _selectedModule,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
        }

        final data = snapshot.data;
        if (data == null || data.records.isEmpty) {
          return const Center(child: Text('No registration records found.', style: TextStyle(color: Colors.grey)));
        }

        return ListView(
          padding: const EdgeInsets.all(14),
          children: [
            // Status Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Approved', 'Pending', 'Rejected', 'Cancelled'].map((status) {
                  final isSelected = _selectedStatus == status;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(status, style: TextStyle(color: isSelected ? Colors.black : Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                      selected: isSelected,
                      selectedColor: Colors.tealAccent,
                      backgroundColor: const Color(0xFF1E293B),
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedStatus = status);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),

            // KPI Summary Cards
            Row(
              children: [
                Expanded(child: _metricCard('Total', '${data.total}', Colors.white, Icons.groups_rounded)),
                const SizedBox(width: 6),
                Expanded(child: _metricCard('Approved', '${data.approved}', Colors.greenAccent, Icons.check_circle_rounded)),
                const SizedBox(width: 6),
                Expanded(child: _metricCard('Pending', '${data.pending}', Colors.amberAccent, Icons.hourglass_top_rounded)),
                const SizedBox(width: 6),
                Expanded(child: _metricCard('Rejected', '${data.rejected}', Colors.redAccent, Icons.cancel_rounded)),
                const SizedBox(width: 6),
                Expanded(child: _metricCard('Cancelled', '${data.cancelled}', Colors.grey, Icons.block_rounded)),
              ],
            ),
            const SizedBox(height: 12),

            // Export Button Strip
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${data.records.length} Registered Students', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ElevatedButton.icon(
                  onPressed: () => _showCsvExportModal('Exam Registration Report', data.toCsv()),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                  icon: const Icon(Icons.download_rounded, size: 14, color: Colors.white),
                  label: const Text('Export CSV', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Records List
            ...data.records.map((r) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.studentName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            Text('${r.studentId} • ${r.subjectCode} (${r.subjectName})', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: _statusColor(r.status).withAlpha(30), borderRadius: BorderRadius.circular(4)),
                        child: Text(r.status.toUpperCase(), style: TextStyle(color: _statusColor(r.status), fontWeight: FontWeight.bold, fontSize: 10)),
                      ),
                    ],
                  ),
                )),
          ],
        );
      },
    );
  }

  // ─── 2. ATTENDANCE REPORT TAB ───────────────────────────────────────────────
  Widget _buildAttendanceReportTab() {
    return FutureBuilder<ExamAttendanceReportData>(
      future: _reportsService.getAttendanceReport(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
        }

        final data = snapshot.data;
        if (data == null || data.records.isEmpty) {
          return const Center(child: Text('No attendance records logged yet.', style: TextStyle(color: Colors.grey)));
        }

        return ListView(
          padding: const EdgeInsets.all(14),
          children: [
            Row(
              children: [
                Expanded(child: _metricCard('Verified', '${data.registered}', Colors.white, Icons.fact_check_rounded)),
                const SizedBox(width: 6),
                Expanded(child: _metricCard('Present', '${data.present}', Colors.greenAccent, Icons.check_circle_rounded)),
                const SizedBox(width: 6),
                Expanded(child: _metricCard('Absent', '${data.absent}', Colors.redAccent, Icons.cancel_rounded)),
                const SizedBox(width: 6),
                Expanded(child: _metricCard('Late', '${data.late}', Colors.amberAccent, Icons.schedule_rounded)),
                const SizedBox(width: 6),
                Expanded(child: _metricCard('Rate', '${data.attendancePercentage.toStringAsFixed(1)}%', Colors.tealAccent, Icons.percent_rounded)),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${data.records.length} Attendance Entries', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ElevatedButton.icon(
                  onPressed: () => _showCsvExportModal('Exam Attendance Report', data.toCsv()),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                  icon: const Icon(Icons.download_rounded, size: 14, color: Colors.white),
                  label: const Text('Export CSV', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            ...data.records.map((r) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.studentName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            Text('${r.studentId} • Hall: ${r.hallName} • Seat: ${r.seatNumber}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: (r.isPresent ? Colors.green : Colors.red).withAlpha(30), borderRadius: BorderRadius.circular(4)),
                        child: Text(r.status.toUpperCase(), style: TextStyle(color: r.isPresent ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 10)),
                      ),
                    ],
                  ),
                )),
          ],
        );
      },
    );
  }

  // ─── 3. SEATING ALLOCATION REPORT TAB ───────────────────────────────────────
  Widget _buildSeatingReportTab() {
    return FutureBuilder<ExamSeatingReportData>(
      future: _reportsService.getSeatingReport(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
        }

        final data = snapshot.data;
        if (data == null || data.records.isEmpty) {
          return const Center(child: Text('No seating allocations generated yet.', style: TextStyle(color: Colors.grey)));
        }

        return ListView(
          padding: const EdgeInsets.all(14),
          children: [
            Row(
              children: [
                Expanded(child: _metricCard('Hall Capacity', '${data.capacity}', Colors.white, Icons.meeting_room_rounded)),
                const SizedBox(width: 8),
                Expanded(child: _metricCard('Allocated', '${data.allocatedStudents}', Colors.amberAccent, Icons.event_seat_rounded)),
                const SizedBox(width: 8),
                Expanded(child: _metricCard('Available Seats', '${data.availableSeats}', Colors.tealAccent, Icons.airline_seat_recline_extra_rounded)),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${data.records.length} Seating Assignments', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ElevatedButton.icon(
                  onPressed: () => _showCsvExportModal('Seating Allocation Report', data.toCsv()),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                  icon: const Icon(Icons.download_rounded, size: 14, color: Colors.white),
                  label: const Text('Export CSV', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            ...data.records.map((r) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.teal.withAlpha(30), borderRadius: BorderRadius.circular(4)),
                        child: Text(r.seatNumber, style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'monospace')),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.studentName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            Text('${r.studentId} • ${r.hallName}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        );
      },
    );
  }

  // ─── 4. RESULT & MODERATION REPORT TAB ──────────────────────────────────────
  Widget _buildResultReportTab() {
    return FutureBuilder<ExamResultReportData>(
      future: _reportsService.getResultReport(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
        }

        final data = snapshot.data;
        if (data == null || data.records.isEmpty) {
          return const Center(child: Text('No exam results submitted or published yet.', style: TextStyle(color: Colors.grey)));
        }

        return ListView(
          padding: const EdgeInsets.all(14),
          children: [
            Row(
              children: [
                Expanded(child: _metricCard('Students', '${data.totalStudents}', Colors.white, Icons.people_rounded)),
                const SizedBox(width: 6),
                Expanded(child: _metricCard('Passed', '${data.passed}', Colors.greenAccent, Icons.check_circle_rounded)),
                const SizedBox(width: 6),
                Expanded(child: _metricCard('Failed', '${data.failed}', Colors.redAccent, Icons.cancel_rounded)),
                const SizedBox(width: 6),
                Expanded(child: _metricCard('Average', data.averageMarks.toStringAsFixed(1), Colors.amberAccent, Icons.analytics_rounded)),
                const SizedBox(width: 6),
                Expanded(child: _metricCard('Hi / Lo', '${data.highestMarks.toInt()}/${data.lowestMarks.toInt()}', Colors.tealAccent, Icons.swap_vert_rounded)),
              ],
            ),
            const SizedBox(height: 14),

            // Grade Distribution Bar Summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('GRADE DISTRIBUTION SUMMARY', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: data.gradeDistribution.entries.map((e) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(6)),
                        child: Text('${e.key}: ${e.value}', style: const TextStyle(color: Colors.tealAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${data.records.length} Student Results', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ElevatedButton.icon(
                  onPressed: () => _showCsvExportModal('Exam Results Report', data.toCsv()),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                  icon: const Icon(Icons.download_rounded, size: 14, color: Colors.white),
                  label: const Text('Export CSV', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            ...data.records.map((r) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.studentName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            Text('${r.studentId} • ${r.moduleId} • Marks: ${r.marks}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.teal.withAlpha(30), borderRadius: BorderRadius.circular(4)),
                        child: Text(r.grade, style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                )),
          ],
        );
      },
    );
  }

  Widget _metricCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 9), overflow: TextOverflow.ellipsis)),
              Icon(icon, size: 10, color: color),
            ],
          ),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'registered':
      case 'present':
        return Colors.greenAccent;
      case 'pending':
      case 'late':
        return Colors.amberAccent;
      case 'rejected':
      case 'absent':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }
}
