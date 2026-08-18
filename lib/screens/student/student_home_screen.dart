import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/attendance_service.dart';
import '../../services/student_portal_service.dart';
import '../../services/notification_service.dart';
import '../../services/announcement_service.dart';
import '../../models/attendance_model.dart';
import '../../models/timetable_model.dart';
import '../../models/result_model.dart';
import '../../models/payment_model.dart';
import '../../models/announcement_model.dart';
import 'student_modules_screen.dart';
import 'student_assignments_screen.dart';
import 'student_attendance_screen.dart';
import 'student_exams_screen.dart';
import 'student_results_screen.dart';
import 'student_credits_screen.dart';
import 'student_payments_screen.dart';
import 'student_module_registration_screen.dart';
import 'campus_map_screen.dart';
import 'campus_transport_screen.dart';
import 'student_library_screen.dart';
import 'student_profile_screen.dart';
import 'student_timetable_screen.dart';
import '../user_announcements_screen.dart';
import '../user_notifications_screen.dart';

class StudentHomeScreen extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final Function(int)? onNavigateTab;

  const StudentHomeScreen({super.key, this.userData, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final firestore = FirebaseFirestore.instance;

    final name = (userData?['fullName'] ?? userData?['name'] ?? authService.currentUser?.displayName ?? 'Student').toString();
    final email = (userData?['email'] ?? authService.currentUser?.email ?? '').toString().trim().toLowerCase();
    final studentId = (userData?['studentId'] ?? 'STU-1002').toString();
    final course = (userData?['course'] ?? userData?['programme'] ?? 'BSc (Hons) in Computing').toString();
    final batch = (userData?['batch'] ?? '2026').toString();
    final year = (userData?['year'] ?? 'Year 1').toString();
    final semester = (userData?['semester'] ?? 'Semester 1').toString();

    final portalService = StudentPortalService();
    final attendanceService = AttendanceService();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => StudentProfileScreen(userData: userData)),
            );
          },
          child: Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.teal,
                child: Icon(Icons.school_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                    Text('$studentId • $semester', style: const TextStyle(color: Colors.tealAccent, fontSize: 11), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
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
                        decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '$unreadAnnCount',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          // Unified Notifications with Live Unread Badge
          StreamBuilder<int>(
            stream: NotificationService().getUnreadCountStream(email, 'Student'),
            builder: (context, notifSnap) {
              final unreadNotifCount = notifSnap.data ?? 0;

              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_rounded, color: Colors.tealAccent),
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
                  if (unreadNotifCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '$unreadNotifCount',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: StreamBuilder<List<AttendanceModel>>(
        stream: attendanceService.getStudentAttendanceStream(email),
        builder: (context, attSnap) {
          final attendance = attSnap.data ?? [];
          final totalClasses = attendance.length;
          final presentClasses = attendance.where((a) => a.status.toLowerCase() == 'present').length;
          final lateClasses = attendance.where((a) => a.status.toLowerCase() == 'late').length;
          final absentClasses = attendance.where((a) => a.status.toLowerCase() == 'absent').length;
          final attendancePct = totalClasses > 0 ? ((presentClasses + 0.5 * lateClasses) / totalClasses) * 100 : 85.0;

          return StreamBuilder<List<ResultModel>>(
            stream: portalService.getStudentResultsStream(email),
            builder: (context, resSnap) {
              final results = resSnap.data ?? [];
              final gpa = StudentPortalService.calculateGPA(results);

              return StreamBuilder<List<PaymentModel>>(
                stream: portalService.getStudentPaymentsStream(email),
                builder: (context, paySnap) {
                  final payments = paySnap.data ?? [];
                  final paidAmount = payments.where((p) => p.status.toLowerCase() == 'completed' || p.status.toLowerCase() == 'successful').fold(0.0, (acc, p) => acc + p.amount);
                  final totalFee = 350000.0;
                  final balance = (totalFee - paidAmount).clamp(0.0, totalFee);

                  return StreamBuilder<List<TimetableModel>>(
                    stream: portalService.getTimetableStream(),
                    builder: (context, timeSnap) {
                      final timetable = timeSnap.data ?? [];

                      return StreamBuilder<QuerySnapshot>(
                        stream: firestore
                            .collection('studentModuleRegistrations')
                            .where('studentEmail', isEqualTo: email)
                            .where('status', isEqualTo: 'Approved')
                            .snapshots(),
                        builder: (context, modRegSnap) {
                          int regCredits = 0;
                          final modDocs = modRegSnap.data?.docs ?? [];
                          for (var d in modDocs) {
                            regCredits += (d.data() as Map<String, dynamic>)['credits'] as int? ?? 0;
                          }
                          final displayRegCreds = regCredits > 0 ? regCredits : 18;
                          final displayCompCreds = results.isNotEmpty ? results.length * 3 : 42;

                          return ListView(
                            padding: const EdgeInsets.all(16.0),
                            children: [
                              // 1. Student Identification & Programme Banner
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
                                  children: [
                                    CircleAvatar(
                                      radius: 30,
                                      backgroundColor: Colors.teal.withAlpha(40),
                                      child: const Icon(Icons.person_rounded, size: 36, color: Colors.tealAccent),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(name, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 2),
                                          Text('$studentId • Batch $batch', style: const TextStyle(color: Colors.tealAccent, fontSize: 12, fontWeight: FontWeight.w600)),
                                          const SizedBox(height: 2),
                                          Text('$course • $year ($semester)', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),

                              // 2. Dynamic Academic Summary KPI Grid (4 Metrics)
                              const Text('ACADEMIC SUMMARY', style: TextStyle(color: Colors.tealAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                              const SizedBox(height: 10),

                              GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: 2,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 1.45,
                                children: [
                                  _buildKpiCard('Current GPA', gpa > 0 ? gpa.toStringAsFixed(2) : '3.82', Icons.grade_rounded, Colors.amberAccent, onTap: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => StudentResultsScreen(userData: userData)));
                                  }),
                                  _buildKpiCard('Attendance', '${attendancePct.toStringAsFixed(1)}%', Icons.calendar_month_rounded, attendancePct >= 80 ? Colors.greenAccent : Colors.orangeAccent, onTap: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => StudentAttendanceScreen(userData: userData)));
                                  }),
                                  _buildKpiCard('Registered Credits', '$displayRegCreds Credits', Icons.app_registration_rounded, Colors.cyanAccent, onTap: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => StudentModuleRegistrationScreen(userData: userData)));
                                  }),
                                  _buildKpiCard('Completed Credits', '$displayCompCreds / 120', Icons.school_rounded, Colors.indigoAccent, onTap: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => StudentCreditsScreen(userData: userData)));
                                  }),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // 3. Today's Schedule (Timetable with Hall Navigation)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("TODAY'S LECTURE SCHEDULE", style: TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => StudentTimetableScreen(userData: userData)));
                                    },
                                    child: const Text('View Full Timetable', style: TextStyle(color: Colors.tealAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),

                              if (timetable.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(14)),
                                  child: const Center(child: Text('No lectures scheduled today.', style: TextStyle(color: Colors.grey, fontSize: 12))),
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
                                                      Text('${t.dayOfWeek} • ${t.startTime} - ${t.endTime} • ', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                                      Text(t.hall, style: const TextStyle(color: Colors.tealAccent, fontSize: 11, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
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
                              const SizedBox(height: 18),

                              // 4. Attendance & Finance Dual Overview Row
                              Row(
                                children: [
                                  // Attendance Summary Box
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E293B),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: Colors.white10),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('ATTENDANCE LOG', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                          const SizedBox(height: 8),
                                          Text('${attendancePct.toStringAsFixed(0)}% Present', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                          const SizedBox(height: 4),
                                          Text('Present: $presentClasses | Late: $lateClasses | Absent: $absentClasses', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Finance Summary Box with Pay Now button
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E293B),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: balance > 0 ? Colors.orangeAccent.withAlpha(100) : Colors.tealAccent.withAlpha(100)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('FINANCE & FEES', style: TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                          const SizedBox(height: 8),
                                          Text(balance > 0 ? 'Due: LKR ${balance.toStringAsFixed(0)}' : 'All Dues Cleared', style: TextStyle(color: balance > 0 ? Colors.orangeAccent : Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                                          const SizedBox(height: 6),
                                          if (balance > 0)
                                            InkWell(
                                              onTap: () {
                                                Navigator.push(context, MaterialPageRoute(builder: (context) => StudentPaymentsScreen(userData: userData)));
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(color: Colors.teal, borderRadius: BorderRadius.circular(6)),
                                                child: const Text('Pay Now ➔', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                              ),
                                            )
                                          else
                                            Text('Paid: LKR ${paidAmount.toStringAsFixed(0)}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // 5. Quick Access Grid (12 Essential Hubs)
                              const Text('QUICK ACCESS HUBS', style: TextStyle(color: Colors.tealAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                              const SizedBox(height: 10),

                              GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: 4,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 10,
                                childAspectRatio: 0.88,
                                children: [
                                  _buildHubTile('My Modules', Icons.auto_stories_rounded, Colors.cyanAccent, () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => StudentModulesScreen(userData: userData)));
                                  }),
                                  _buildHubTile('Timetable', Icons.schedule_rounded, Colors.tealAccent, () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => StudentTimetableScreen(userData: userData)));
                                  }),
                                  _buildHubTile('Assignments', Icons.assignment_rounded, Colors.orangeAccent, () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => StudentAssignmentsScreen(userData: userData)));
                                  }),
                                  _buildHubTile('Exams', Icons.assignment_turned_in_rounded, Colors.pinkAccent, () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => StudentExamsScreen(userData: userData)));
                                  }),
                                  _buildHubTile('Results', Icons.grade_rounded, Colors.amberAccent, () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => StudentResultsScreen(userData: userData)));
                                  }),
                                  _buildHubTile('Finance', Icons.payments_rounded, Colors.greenAccent, () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => StudentPaymentsScreen(userData: userData)));
                                  }),
                                  _buildHubTile('Attendance', Icons.fact_check_rounded, Colors.lightBlueAccent, () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => StudentAttendanceScreen(userData: userData)));
                                  }),
                                  _buildHubTile('Campus Map', Icons.map_rounded, Colors.tealAccent, () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => const CampusMapScreen()));
                                  }),
                                  _buildHubTile('Bus Shuttle', Icons.directions_bus_rounded, Colors.amberAccent, () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => CampusTransportScreen(userData: userData)));
                                  }),
                                  _buildHubTile('Library', Icons.local_library_rounded, Colors.purpleAccent, () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => StudentLibraryScreen(userData: userData)));
                                  }),
                                  _buildHubTile('Notices', Icons.campaign_rounded, Colors.pinkAccent, () {
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
                                  _buildHubTile('Profile', Icons.person_rounded, Colors.indigoAccent, () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => StudentProfileScreen(userData: userData)));
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
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600)),
                  Icon(icon, color: color, size: 18),
                ],
              ),
              Text(
                value,
                style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHubTile(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withAlpha(30), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
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
