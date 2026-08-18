import 'package:flutter/material.dart';
import '../../services/attendance_service.dart';
import '../../models/attendance_model.dart';
import 'student_qr_scan_screen.dart';

class StudentAttendanceScreen extends StatelessWidget {
  final Map<String, dynamic>? userData;

  const StudentAttendanceScreen({super.key, this.userData});

  @override
  Widget build(BuildContext context) {
    final email = userData?['email'] ?? '';
    final attendanceService = AttendanceService();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          children: [
            Icon(Icons.calendar_month_rounded, color: Colors.greenAccent),
            SizedBox(width: 8),
            Text('My Attendance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.tealAccent),
            tooltip: 'Scan QR Code',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => StudentQrScanScreen(userData: userData)),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
        label: const Text('Scan QR Code', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => StudentQrScanScreen(userData: userData)),
          );
        },
      ),
      body: StreamBuilder<List<AttendanceModel>>(
        stream: attendanceService.getStudentAttendanceStream(email),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
          }

          final allRecords = (snapshot.data ?? []).where((r) => r.status != 'cancelled').toList();

          if (allRecords.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.event_busy_rounded, size: 56, color: Colors.grey),
                    const SizedBox(height: 14),
                    const Text('No attendance records logged yet.', style: TextStyle(color: Colors.white70, fontSize: 16)),
                    const SizedBox(height: 8),
                    const Text('Scan the lecturer\'s dynamic QR code to mark your attendance.', style: TextStyle(color: Colors.grey, fontSize: 13), textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => StudentQrScanScreen(userData: userData)),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                      icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
                      label: const Text('Scan Classroom QR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          }

          // Calculate overall attendance
          final totalConducted = allRecords.length;
          final totalAttended = allRecords.where((r) => r.status.toLowerCase() == 'present' || r.status.toLowerCase() == 'late').length;
          final double overallPct = totalConducted > 0 ? (totalAttended / totalConducted) * 100 : 0.0;

          // Group by Subject Code
          final Map<String, List<AttendanceModel>> subjectMap = {};
          for (var r in allRecords) {
            final key = r.subjectCode.isNotEmpty ? r.subjectCode : 'General';
            if (!subjectMap.containsKey(key)) {
              subjectMap[key] = [];
            }
            subjectMap[key]!.add(r);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Scan QR Quick Action Banner
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF064E3B), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.tealAccent.withAlpha(100)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.teal.withAlpha(50),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.qr_code_2_rounded, size: 30, color: Colors.tealAccent),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Dynamic QR Attendance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 2),
                          const Text('Scan session QR on lecturer\'s screen to verify presence', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => StudentQrScanScreen(userData: userData)),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.tealAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Scan Now', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              ),

              // Overall Summary Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF334155)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: overallPct >= 80 ? Colors.green.withAlpha(30) : Colors.red.withAlpha(30),
                      child: Text(
                        '${overallPct.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: overallPct >= 80 ? Colors.greenAccent : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Overall Attendance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('$totalAttended Present / $totalConducted Total Sessions', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          const SizedBox(height: 6),
                          Text(
                            overallPct >= 80 ? 'Status: Good Standing (Eligible for Exams)' : 'Warning: Below 80% Threshold',
                            style: TextStyle(
                              color: overallPct >= 80 ? Colors.greenAccent : Colors.redAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Text('Module-Wise Attendance', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              ...subjectMap.entries.map((entry) {
                final records = entry.value;
                final total = records.length;
                final present = records.where((r) => r.status == 'present' || r.status == 'late').length;
                final pct = total > 0 ? (present / total) * 100 : 0.0;
                final isGood = pct >= 80;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isGood ? Colors.white10 : Colors.redAccent.withAlpha(60)),
                  ),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: isGood ? Colors.green.withAlpha(20) : Colors.red.withAlpha(20),
                      child: Text(
                        '${pct.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: isGood ? Colors.greenAccent : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    title: Text(entry.key, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    subtitle: Text('Present: $present / Total: $total classes', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    children: [
                      const Divider(color: Colors.white10, height: 1),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: records.map((r) {
                            final isP = r.status == 'present' || r.status == 'late';
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(r.date, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isP ? Colors.green.withAlpha(30) : Colors.red.withAlpha(30),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      r.status.toUpperCase(),
                                      style: TextStyle(color: isP ? Colors.greenAccent : Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
