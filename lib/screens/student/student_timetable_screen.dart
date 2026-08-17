import 'package:flutter/material.dart';
import '../../services/student_portal_service.dart';
import '../../services/enrollment_service.dart';
import '../../models/timetable_model.dart';

class StudentTimetableScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const StudentTimetableScreen({super.key, this.userData});

  @override
  State<StudentTimetableScreen> createState() => _StudentTimetableScreenState();
}

class _StudentTimetableScreenState extends State<StudentTimetableScreen> {
  final StudentPortalService _portalService = StudentPortalService();
  final EnrollmentService _enrollmentService = EnrollmentService();

  String _selectedDay = 'Monday';
  final List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  @override
  void initState() {
    super.initState();
    // Default to current day of week if weekday
    final now = DateTime.now();
    const weekDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final today = weekDays[now.weekday - 1];
    if (_days.contains(today)) {
      _selectedDay = today;
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.userData?['email'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.calendar_month_rounded, color: Colors.cyanAccent),
            SizedBox(width: 8),
            Text('Class Timetable', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Day Selector Tabs
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: const Color(0xFF1E293B),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _days.map((day) {
                  final isSelected = day == _selectedDay;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(day),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedDay = day);
                      },
                      selectedColor: Colors.teal,
                      backgroundColor: const Color(0xFF0F172A),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      side: BorderSide(color: isSelected ? Colors.tealAccent : Colors.white10),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Timetable List
          Expanded(
            child: StreamBuilder(
              stream: _enrollmentService.getStudentActiveEnrollmentsStream(email),
              builder: (context, enrollSnap) {
                final enrollments = enrollSnap.data ?? [];
                final enrolledCodes = enrollments.map((e) => e.subjectCode).toList();

                return StreamBuilder<List<TimetableModel>>(
                  stream: _portalService.getTimetableForSubjects(enrolledCodes),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
                    }

                    final allSchedules = snapshot.data ?? [];
                    final dailySchedules = allSchedules.where((s) => s.dayOfWeek.toLowerCase() == _selectedDay.toLowerCase()).toList();

                    if (dailySchedules.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy_rounded, size: 54, color: Colors.grey.withAlpha(100)),
                            const SizedBox(height: 14),
                            Text('No lectures scheduled for $_selectedDay.', style: const TextStyle(color: Colors.white70, fontSize: 16)),
                            const SizedBox(height: 4),
                            const Text('Enjoy your free study day!', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: dailySchedules.length,
                      itemBuilder: (context, index) {
                        final s = dailySchedules[index];
                        final isOnline = s.mode.toLowerCase() == 'online';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.cyan.withAlpha(30),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.cyanAccent.withAlpha(80)),
                                    ),
                                    child: Text(
                                      s.subjectCode,
                                      style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isOnline ? Colors.indigo.withAlpha(40) : Colors.green.withAlpha(30),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(isOnline ? Icons.videocam_rounded : Icons.location_on_rounded, size: 12, color: isOnline ? Colors.indigoAccent : Colors.greenAccent),
                                        const SizedBox(width: 4),
                                        Text(
                                          s.mode.toUpperCase(),
                                          style: TextStyle(color: isOnline ? Colors.indigoAccent : Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(s.subjectName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, size: 14, color: Colors.amberAccent),
                                  const SizedBox(width: 6),
                                  Text('${s.startTime} - ${s.endTime}', style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 16),
                                  const Icon(Icons.meeting_room_rounded, size: 14, color: Colors.tealAccent),
                                  const SizedBox(width: 6),
                                  Text(s.hall, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Text('Lecturer: ${s.lecturerName.isNotEmpty ? s.lecturerName : "Faculty Staff"}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
