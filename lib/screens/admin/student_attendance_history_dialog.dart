import 'package:flutter/material.dart';
import '../../models/attendance_model.dart';

class StudentAttendanceHistoryDialog extends StatelessWidget {
  final String studentName;
  final String studentId;
  final List<AttendanceModel> attendanceRecords;
  final double threshold;

  const StudentAttendanceHistoryDialog({
    super.key,
    required this.studentName,
    required this.studentId,
    required this.attendanceRecords,
    required this.threshold,
  });

  @override
  Widget build(BuildContext context) {
    // Group records by subjectCode
    final Map<String, List<AttendanceModel>> grouped = {};
    for (var rec in attendanceRecords) {
      final code = rec.subjectCode;
      if (!grouped.containsKey(code)) {
        grouped[code] = [];
      }
      grouped[code]!.add(rec);
    }

    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studentName,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ID: $studentId • Attendance Summary',
                        style: const TextStyle(color: Colors.tealAccent, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(color: Colors.white10, height: 24),

            // Subject list with percentage & details
            Expanded(
              child: grouped.isEmpty
                  ? const Center(
                      child: Text(
                        'No attendance records marked yet.',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    )
                  : ListView(
                      children: grouped.entries.map((entry) {
                        final subjectCode = entry.key;
                        final records = entry.value;
                        final subjectName = records.first.subjectName;

                        // Calculate attendance %
                        // Skip cancelled classes
                        final validRecords = records.where((r) => r.status.toLowerCase() != 'cancelled').toList();
                        final totalConducted = validRecords.length;
                        final attended = validRecords.where((r) =>
                            r.status.toLowerCase() == 'present' || r.status.toLowerCase() == 'late').length;

                        final double percentage = totalConducted > 0 ? (attended / totalConducted) * 100 : 0.0;
                        final bool isLow = percentage < threshold;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Theme(
                            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          subjectName,
                                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          subjectCode,
                                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${percentage.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          color: isLow ? Colors.redAccent : Colors.tealAccent,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '$attended/$totalConducted Classes',
                                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              children: [
                                const Divider(color: Colors.white10),
                                ...records.map((rec) {
                                  final bool isPresent = rec.status.toLowerCase() == 'present';
                                  final bool isAbsent = rec.status.toLowerCase() == 'absent';

                                  final statusColor = isPresent
                                      ? Colors.greenAccent
                                      : isAbsent
                                          ? Colors.redAccent
                                          : Colors.amberAccent;

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          rec.date,
                                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                                        ),
                                        Text(
                                          rec.status.toUpperCase(),
                                          style: TextStyle(
                                            color: statusColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
