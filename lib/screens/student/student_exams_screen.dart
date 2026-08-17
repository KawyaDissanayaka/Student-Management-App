import 'package:flutter/material.dart';
import '../../services/student_portal_service.dart';
import '../../services/enrollment_service.dart';
import '../../models/exam_model.dart';

class StudentExamsScreen extends StatelessWidget {
  final Map<String, dynamic>? userData;

  const StudentExamsScreen({super.key, this.userData});

  @override
  Widget build(BuildContext context) {
    final email = userData?['email'] ?? '';
    final studentId = userData?['studentId'] ?? 'STU-1002';
    final studentName = userData?['fullName'] ?? 'Student';
    final portalService = StudentPortalService();
    final enrollmentService = EnrollmentService();

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
            Icon(Icons.assignment_outlined, color: Colors.amberAccent),
            SizedBox(width: 8),
            Text('Examinations & Hall Pass', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: StreamBuilder(
        stream: enrollmentService.getStudentActiveEnrollmentsStream(email),
        builder: (context, enrollSnap) {
          final enrollments = enrollSnap.data ?? [];
          final enrolledCodes = enrollments.map((e) => e.subjectCode).toList();

          return StreamBuilder<List<ExamModel>>(
            stream: portalService.getExamsForSubjects(enrolledCodes),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
              }

              final exams = snapshot.data ?? [];

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Digital Hall Pass Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF312E81), Color(0xFF1E1B4B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.indigoAccent.withAlpha(80)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.verified_rounded, color: Colors.amberAccent, size: 20),
                                SizedBox(width: 6),
                                Text('OFFICIAL EXAM ADMISSION', style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: Colors.green.withAlpha(40), borderRadius: BorderRadius.circular(6)),
                              child: const Text('VERIFIED', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(studentName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Student ID: $studentId', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 12),
                        const Divider(color: Colors.white24, height: 1),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${exams.length} Registered Exams', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            const Text('Semester 1 • 2025/2026', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text('Exam Schedule', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  if (exams.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text('No exams scheduled for your enrolled modules currently.', style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  else
                    ...exams.map((exam) {
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
                                    color: Colors.amber.withAlpha(30),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.amberAccent.withAlpha(80)),
                                  ),
                                  child: Text(
                                    exam.subjectCode,
                                    style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.withAlpha(30),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    exam.examType.toUpperCase(),
                                    style: const TextStyle(color: Colors.tealAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(exam.subjectName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.event_available_rounded, size: 14, color: Colors.tealAccent),
                                const SizedBox(width: 6),
                                Text(exam.date.isNotEmpty ? exam.date : 'TBA', style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 14),
                                const Icon(Icons.access_time_rounded, size: 14, color: Colors.amberAccent),
                                const SizedBox(width: 6),
                                Text('${exam.startTime} - ${exam.endTime}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                                const SizedBox(width: 6),
                                Text('Venue: ${exam.examHall}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                if (exam.seatNumber != null) ...[
                                  const SizedBox(width: 12),
                                  Text('• Seat: ${exam.seatNumber}', style: const TextStyle(color: Colors.tealAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Note: ${exam.instructions}', style: const TextStyle(color: Colors.white38, fontSize: 11, fontStyle: FontStyle.italic)),
                          ],
                        ),
                      );
                    }),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
