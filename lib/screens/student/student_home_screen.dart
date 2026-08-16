import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../auth/login_screen.dart';
import '../../services/enrollment_service.dart';
import '../../models/enrollment_model.dart';
import '../../services/attendance_service.dart';
import '../../models/attendance_model.dart';

class StudentHomeScreen extends StatelessWidget {
  final Map<String, dynamic>? userData;

  const StudentHomeScreen({super.key, this.userData});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final name = userData?['fullName'] ?? authService.currentUser?.displayName ?? 'Student';
    final email = userData?['email'] ?? authService.currentUser?.email ?? '';
    final studentId = userData?['studentId'] ?? 'STU-1002';
    final department = userData?['department'] ?? 'Computer Science';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.school_rounded, color: Colors.tealAccent),
            SizedBox(width: 8),
            Text(
              'Student Portal',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: 'Sign Out',
            onPressed: () async {
              await authService.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<EnrollmentModel>>(
        stream: EnrollmentService().getStudentActiveEnrollmentsStream(email),
        builder: (context, enrollmentsSnap) {
          return StreamBuilder<List<AttendanceModel>>(
            stream: AttendanceService().getStudentAttendanceStream(email),
            builder: (context, attendanceSnap) {
              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('settings').doc('attendance_config').snapshots(),
                builder: (context, settingsSnap) {
                  final enrollments = enrollmentsSnap.data ?? [];
                  final attendanceRecords = attendanceSnap.data ?? [];

                  // Get settings threshold
                  double threshold = 80.0;
                  if (settingsSnap.hasData && settingsSnap.data!.exists) {
                    final data = settingsSnap.data!.data() as Map<String, dynamic>?;
                    if (data != null && data['threshold'] != null) {
                      threshold = (data['threshold'] as num).toDouble();
                    }
                  }

                  // Calculate overall student attendance percentage
                  final validAllRecords = attendanceRecords
                      .where((r) => r.status.toLowerCase() != 'cancelled')
                      .toList();
                  final totalConductedAll = validAllRecords.length;
                  final totalAttendedAll = validAllRecords
                      .where((r) => r.status.toLowerCase() == 'present' || r.status.toLowerCase() == 'late')
                      .length;
                  final double overallAttendancePct = totalConductedAll > 0
                      ? (totalAttendedAll / totalConductedAll) * 100
                      : 100.0; // Default to 100 if no classes conducted yet

                  final enrollmentCountText = enrollments.length == 1 ? '1 Course' : '${enrollments.length} Courses';

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome Header Card
                        Container(
                          padding: const EdgeInsets.all(20.0),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.teal.withAlpha(50),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.white24,
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : 'S',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Welcome back, $name!',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$department • ID: $studentId',
                                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                                    ),
                                    Text(
                                      email,
                                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Quick Metrics Row
                        Row(
                          children: [
                            _buildStatCard(
                              title: 'GPA Score',
                              value: '3.82',
                              icon: Icons.auto_graph_rounded,
                              color: Colors.amberAccent,
                            ),
                            const SizedBox(width: 12),
                            _buildStatCard(
                              title: 'Attendance',
                              value: '${overallAttendancePct.toStringAsFixed(0)}%',
                              icon: Icons.check_circle_outline_rounded,
                              color: overallAttendancePct < threshold ? Colors.redAccent : Colors.tealAccent,
                            ),
                            const SizedBox(width: 12),
                            _buildStatCard(
                              title: 'Enrolled',
                              value: enrollmentCountText,
                              icon: Icons.book_rounded,
                              color: Colors.indigoAccent,
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // Enrolled Courses Title
                        const Text(
                          'My Enrolled Courses',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Course Cards Dynamic List
                        if (enrollmentsSnap.connectionState == ConnectionState.waiting)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: CircularProgressIndicator(color: Colors.tealAccent),
                            ),
                          )
                        else if (enrollments.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(14.0),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.menu_book_rounded, color: Colors.grey, size: 48),
                                SizedBox(height: 12),
                                Text(
                                  'You are not enrolled in any subjects yet.',
                                  style: TextStyle(color: Colors.white70, fontSize: 14),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        else
                          ...enrollments.map((enrollment) {
                            // Filter attendance for this subject
                            final subjectRecords = attendanceRecords
                                .where((r) => r.subjectCode == enrollment.subjectCode && r.status.toLowerCase() != 'cancelled')
                                .toList();
                            final conducted = subjectRecords.length;
                            final attended = subjectRecords
                                .where((r) => r.status.toLowerCase() == 'present' || r.status.toLowerCase() == 'late')
                                .length;
                            final double pct = conducted > 0 ? (attended / conducted) * 100 : 100.0;
                            final bool isLow = pct < threshold;

                            return _buildCourseCard(
                              code: enrollment.subjectCode,
                              title: enrollment.subjectName,
                              instructor: enrollment.lecturerName,
                              schedule: '${enrollment.semester} • ${enrollment.academicYear}',
                              attendancePercentage: conducted > 0 ? '${pct.toStringAsFixed(0)}%' : 'No classes',
                              attendanceColor: conducted > 0 ? (isLow ? Colors.redAccent : Colors.tealAccent) : Colors.grey,
                            );
                          }),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseCard({
    required String code,
    required String title,
    required String instructor,
    required String schedule,
    required String attendancePercentage,
    required Color attendanceColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.indigo.withAlpha(40),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              code,
              style: const TextStyle(
                color: Colors.indigoAccent,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$instructor • $schedule',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          // Attendance Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: attendanceColor.withAlpha(30),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: attendanceColor.withAlpha(120)),
            ),
            child: Text(
              attendancePercentage,
              style: TextStyle(
                color: attendanceColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 16),
        ],
      ),
    );
  }
}
