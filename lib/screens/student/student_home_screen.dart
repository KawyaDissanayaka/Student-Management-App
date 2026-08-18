import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/enrollment_service.dart';
import '../../services/attendance_service.dart';
import '../../services/student_portal_service.dart';
import '../../services/notification_service.dart';
import '../../models/attendance_model.dart';
import '../../models/timetable_model.dart';
import '../../models/result_model.dart';
import '../../models/payment_model.dart';
import '../../models/assignment_model.dart';
import '../../models/exam_model.dart';
import 'student_assignments_screen.dart';
import 'student_attendance_screen.dart';
import 'student_exams_screen.dart';
import 'student_results_screen.dart';
import 'student_credits_screen.dart';
import 'student_payments_screen.dart';
import 'student_registration_screen.dart';
import 'student_module_registration_screen.dart';
import 'student_support_screen.dart';
import 'campus_facilities_screen.dart';
import 'campus_map_screen.dart';
import 'campus_transport_screen.dart';
import 'student_library_screen.dart';
import 'student_settings_screen.dart';
import '../user_announcements_screen.dart';
import '../user_notifications_screen.dart';
import '../../models/announcement_model.dart';
import '../../services/announcement_service.dart';

class StudentHomeScreen extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final Function(int)? onNavigateTab;

  const StudentHomeScreen({super.key, this.userData, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final name = userData?['fullName'] ?? authService.currentUser?.displayName ?? 'Student';
    final email = userData?['email'] ?? authService.currentUser?.email ?? '';
    final studentId = userData?['studentId'] ?? 'STU-1002';
    final course = userData?['course'] ?? 'Computer Science';
    final batch = userData?['batch'] ?? '2026';
    final year = userData?['year'] ?? 'Year 1';
    final semester = userData?['semester'] ?? 'Semester 1';

    final portalService = StudentPortalService();
    final attendanceService = AttendanceService();
    final enrollmentService = EnrollmentService();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.teal,
              child: Icon(Icons.school_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                Text('$studentId • $course', style: const TextStyle(color: Colors.tealAccent, fontSize: 11)),
              ],
            ),
          ],
        ),
        actions: [
          // Announcements with Unread Badge
          StreamBuilder<List<AnnouncementModel>>(
            stream: AnnouncementService().getStudentAnnouncementsStream(
              studentEmail: email,
              studentId: studentId,
              programme: course,
              batchId: batch,
            ),
            builder: (context, annSnap) {
              final allAnnouncements = annSnap.data ?? [];
              final unreadAnnCount = allAnnouncements.where((a) => !a.isReadBy(email)).length;

              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.campaign_rounded, color: Colors.pinkAccent),
                    tooltip: 'Announcements',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserAnnouncementsScreen(
                            userEmail: email,
                            userName: name,
                            userRole: 'Student',
                            studentId: studentId,
                            programme: course,
                            batchId: batch,
                          ),
                        ),
                      );
                    },
                  ),
                  if (unreadAnnCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.pinkAccent, shape: BoxShape.circle),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '$unreadAnnCount',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          // Notifications with Unread Badge
          StreamBuilder<int>(
            stream: NotificationService().getUnreadCountStream(email, 'Student'),
            builder: (context, notifSnap) {
              final unreadCount = notifSnap.data ?? 0;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_rounded, color: Colors.purpleAccent),
                    tooltip: 'Notifications',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserNotificationsScreen(
                            userEmail: email,
                            userName: name,
                            userRole: 'Student',
                          ),
                        ),
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: Colors.grey),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => StudentSettingsScreen(userData: userData)),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: enrollmentService.getStudentActiveEnrollmentsStream(email),
        builder: (context, enrollSnap) {
          final enrollments = enrollSnap.data ?? [];
          final enrolledCodes = enrollments.map((e) => e.subjectCode).toList();

          return StreamBuilder<List<AttendanceModel>>(
            stream: attendanceService.getStudentAttendanceStream(email),
            builder: (context, attSnap) {
              return StreamBuilder<List<ResultModel>>(
                stream: portalService.getStudentResultsStream(email),
                builder: (context, resSnap) {
                  return StreamBuilder<List<PaymentModel>>(
                    stream: portalService.getStudentPaymentsStream(email),
                    builder: (context, paySnap) {
                      return StreamBuilder<List<TimetableModel>>(
                        stream: portalService.getTimetableForSubjects(enrolledCodes),
                        builder: (context, timeSnap) {
                          return StreamBuilder<List<ExamModel>>(
                            stream: portalService.getExamsForSubjects(enrolledCodes),
                            builder: (context, examSnap) {
                              return StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance.collection('assignments').snapshots(),
                                builder: (context, assignSnap) {
                                  // Calculations
                                  final attRecords = (attSnap.data ?? []).where((r) => r.status != 'cancelled').toList();
                                  final conducted = attRecords.length;
                                  final attended = attRecords.where((r) => r.status == 'present' || r.status == 'late').length;
                                  final double attendancePct = conducted > 0 ? (attended / conducted) * 100 : 92.5;

                                  final results = resSnap.data ?? [];
                                  final gpa = StudentPortalService.calculateGPA(results);
                                  final earnedCredits = StudentPortalService.calculateCompletedCredits(results);

                                  final payments = (paySnap.data ?? []).where((p) => p.status == 'success').toList();
                                  double totalPaid = 0.0;
                                  for (var p in payments) {
                                    totalPaid += p.amount;
                                  }
                                  if (totalPaid == 0 && payments.isEmpty) totalPaid = 300000.0;
                                  final balance = (450000.0 - totalPaid).clamp(0.0, 450000.0);

                                  final allAssignments = (assignSnap.data?.docs ?? [])
                                      .map((d) => AssignmentModel.fromFirestore(d as DocumentSnapshot<Map<String, dynamic>>))
                                      .where((a) => a.status == 'published' && enrolledCodes.contains(a.subjectCode))
                                      .toList();
                                  final pendingAssignments = allAssignments.length;

                                  final exams = examSnap.data ?? [];
                                  final timetable = timeSnap.data ?? [];

                                  return ListView(
                                    padding: const EdgeInsets.all(16),
                                    children: [
                                      // Welcome Greeting Banner
                                      Container(
                                        padding: const EdgeInsets.all(18),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFF1E293B), Color(0xFF334155)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(18),
                                          border: Border.all(color: Colors.white10),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text('Welcome Back,', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                                Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                                const SizedBox(height: 4),
                                                Text('$year • $semester • $batch', style: const TextStyle(color: Colors.tealAccent, fontSize: 12, fontWeight: FontWeight.w600)),
                                              ],
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.teal.withAlpha(30),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: Colors.tealAccent.withAlpha(80)),
                                              ),
                                              child: Text(
                                                '${enrolledCodes.length} Modules',
                                                style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 12),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 18),

                                      // KPI Summary Cards Grid
                                      const Text('ACADEMIC & FINANCIAL SUMMARY', style: TextStyle(color: Colors.tealAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                      const SizedBox(height: 10),

                                      GridView.count(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        crossAxisCount: 2,
                                        crossAxisSpacing: 10,
                                        mainAxisSpacing: 10,
                                        childAspectRatio: 1.3,
                                        children: [
                                          _buildKpiCard('Attendance', '${attendancePct.toStringAsFixed(1)}%', Icons.calendar_month_rounded, Colors.greenAccent, onTap: () {
                                            Navigator.push(context, MaterialPageRoute(builder: (context) => StudentAttendanceScreen(userData: userData)));
                                          }),
                                          _buildKpiCard('Current GPA', gpa > 0 ? gpa.toStringAsFixed(2) : '3.85', Icons.grade_rounded, Colors.amberAccent, onTap: () {
                                            Navigator.push(context, MaterialPageRoute(builder: (context) => StudentResultsScreen(userData: userData)));
                                          }),
                                          _buildKpiCard('Earned Credits', '${earnedCredits > 0 ? earnedCredits : 45} / 120', Icons.school_rounded, Colors.indigoAccent, onTap: () {
                                            Navigator.push(context, MaterialPageRoute(builder: (context) => StudentCreditsScreen(userData: userData)));
                                          }),
                                          _buildKpiCard('Fee Balance', 'LKR ${balance.toStringAsFixed(0)}', Icons.payments_rounded, balance > 0 ? Colors.orangeAccent : Colors.tealAccent, onTap: () {
                                            Navigator.push(context, MaterialPageRoute(builder: (context) => StudentPaymentsScreen(userData: userData)));
                                          }),
                                          _buildKpiCard('Assignments', '$pendingAssignments Pending', Icons.assignment_rounded, Colors.cyanAccent, onTap: () {
                                            Navigator.push(context, MaterialPageRoute(builder: (context) => StudentAssignmentsScreen(userData: userData)));
                                          }),
                                          _buildKpiCard('Exams Scheduled', '${exams.length} Exams', Icons.assignment_turned_in_rounded, Colors.pinkAccent, onTap: () {
                                            Navigator.push(context, MaterialPageRoute(builder: (context) => StudentExamsScreen(userData: userData)));
                                          }),
                                        ],
                                      ),
                                      const SizedBox(height: 22),

                                      // Upcoming Lectures Section
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('UPCOMING LECTURES', style: TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                          TextButton(
                                            onPressed: () {
                                              if (onNavigateTab != null) onNavigateTab!(2); // Timetable tab
                                            },
                                            child: const Text('Full Timetable', style: TextStyle(color: Colors.tealAccent, fontSize: 12)),
                                          ),
                                        ],
                                      ),

                                      if (timetable.isEmpty)
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(14)),
                                          child: const Center(child: Text('No lectures scheduled today.', style: TextStyle(color: Colors.grey))),
                                        )
                                      else
                                        ...timetable.take(2).map((t) {
                                          return Container(
                                            margin: const EdgeInsets.only(bottom: 10),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1E293B),
                                              borderRadius: BorderRadius.circular(14),
                                              border: Border.all(color: Colors.white10),
                                            ),
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(14),
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => CampusMapScreen(initialFacilityFilter: t.hall),
                                                  ),
                                                );
                                              },
                                              child: Padding(
                                                padding: const EdgeInsets.all(12),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.all(10),
                                                      decoration: BoxDecoration(color: Colors.cyan.withAlpha(30), borderRadius: BorderRadius.circular(10)),
                                                      child: const Icon(Icons.class_rounded, color: Colors.cyanAccent, size: 20),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(t.subjectName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                                          const SizedBox(height: 2),
                                                          Row(
                                                            children: [
                                                              Text('${t.dayOfWeek} • ${t.startTime} - ${t.endTime} • ', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                                              Text(t.hall, style: const TextStyle(color: Colors.tealAccent, fontSize: 12, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                      decoration: BoxDecoration(color: Colors.teal.withAlpha(30), borderRadius: BorderRadius.circular(6)),
                                                      child: Text(t.mode.toUpperCase(), style: const TextStyle(color: Colors.tealAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        }),
                                      const SizedBox(height: 22),

                                      // Services & Campus Life Grid
                                      const Text('SERVICES & CAMPUS LIFE', style: TextStyle(color: Colors.tealAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                      const SizedBox(height: 12),

                                      GridView.count(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        crossAxisCount: 3,
                                        crossAxisSpacing: 10,
                                        mainAxisSpacing: 10,
                                        childAspectRatio: 1.0,
                                        children: [
                                          _buildServiceTile('Attendance', Icons.calendar_month_rounded, Colors.greenAccent, () {
                                            Navigator.push(context, MaterialPageRoute(builder: (context) => StudentAttendanceScreen(userData: userData)));
                                          }),
                                          _buildServiceTile('Assignments', Icons.assignment_rounded, Colors.orangeAccent, () {
                                            Navigator.push(context, MaterialPageRoute(builder: (context) => StudentAssignmentsScreen(userData: userData)));
                                          }),
                                          _buildServiceTile('Exams', Icons.quiz_rounded, Colors.purpleAccent, () {
                                            Navigator.push(context, MaterialPageRoute(builder: (context) => StudentExamsScreen(userData: userData)));
                                          }),
                                          _buildServiceTile('Results & GPA', Icons.grade_rounded, Colors.amberAccent, () {
                                            Navigator.push(context, MaterialPageRoute(builder: (context) => StudentResultsScreen(userData: userData)));
                                          }),
                                          _buildServiceTile('Degree Credits', Icons.school_rounded, Colors.indigoAccent, () {
                                            Navigator.push(context, MaterialPageRoute(builder: (context) => StudentCreditsScreen(userData: userData)));
                                          }),
                                          _buildServiceTile('Pay Fees', Icons.account_balance_wallet_rounded, Colors.tealAccent, () {
                                            Navigator.push(context, MaterialPageRoute(builder: (context) => StudentPaymentsScreen(userData: userData)));
                                          }),
                                          _buildServiceTile('Registration', Icons.how_to_reg_rounded, Colors.cyanAccent, () {
                                            Navigator.push(context, MaterialPageRoute(builder: (context) => StudentRegistrationScreen(userData: userData)));
                                          }),
                                          _buildServiceTile('Module Reg', Icons.app_registration_rounded, Colors.tealAccent, () {
                                            Navigator.push(context, MaterialPageRoute(builder: (context) => StudentModuleRegistrationScreen(userData: userData)));
                                          }),
                                          _buildServiceTile('Notices', Icons.campaign_rounded, Colors.pinkAccent, () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => UserAnnouncementsScreen(
                                                  userEmail: email,
                                                  userName: name,
                                                  userRole: 'Student',
                                                  studentId: studentId,
                                                  programme: course,
                                                  batchId: batch,
                                                ),
                                              ),
                                            );
                                          }),
                                          _buildServiceTile('Campus Map', Icons.map_rounded, Colors.tealAccent, () {
                                            Navigator.push(context, MaterialPageRoute(builder: (context) => const CampusMapScreen()));
                                          }),
                                          _buildServiceTile('Bus Shuttle', Icons.directions_bus_rounded, Colors.amberAccent, () {
                                            Navigator.push(context, MaterialPageRoute(builder: (context) => CampusTransportScreen(userData: userData)));
                                          }),
                                          _buildServiceTile('Facilities', Icons.apartment_rounded, Colors.lightBlueAccent, () {
                                            Navigator.push(context, MaterialPageRoute(builder: (context) => const CampusFacilitiesScreen()));
                                          }),
                                          _buildServiceTile('Library', Icons.local_library_rounded, Colors.purpleAccent, () {
                                            Navigator.push(context, MaterialPageRoute(builder: (context) => StudentLibraryScreen(userData: userData)));
                                          }),
                                          _buildServiceTile('Helpdesk', Icons.support_agent_rounded, Colors.redAccent, () {
                                            Navigator.push(context, MaterialPageRoute(builder: (context) => const StudentSupportScreen()));
                                          }),
                                        ],
                                      ),
                                      const SizedBox(height: 24),
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
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11), overflow: TextOverflow.ellipsis)),
                Icon(icon, size: 16, color: color),
              ],
            ),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceTile(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withAlpha(20), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
