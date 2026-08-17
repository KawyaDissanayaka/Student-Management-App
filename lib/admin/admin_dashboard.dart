import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/admin/students_list_screen.dart';
import '../screens/admin/lecturers_list_screen.dart';
import '../screens/admin/subjects_list_screen.dart';
import '../screens/admin/enrollments_list_screen.dart';
import '../screens/admin/attendance_list_screen.dart';
import '../screens/admin/assignments_list_screen.dart';
import '../screens/admin/tasks_list_screen.dart';
import '../screens/admin/announcements_list_screen.dart';
import '../screens/admin/notifications_list_screen.dart';
import '../screens/admin/reports_screen.dart';
import '../screens/admin/admin_profile_screen.dart';
import '../screens/admin/admin_settings_screen.dart';
import '../auth/login_screen.dart';
import '../services/auth_service.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: 'Sign Out',
            onPressed: () async {
              await AuthService().signOut();
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
      drawer: Drawer(
        backgroundColor: const Color(0xFF1E293B),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF3730A3)],
                ),
              ),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white24,
                child: Icon(Icons.admin_panel_settings_rounded, size: 36, color: Colors.white),
              ),
              accountName: const Text(
                'Admin Panel',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              accountEmail: const Text('admin@system.com'),
            ),
            ListTile(
              leading: const Icon(Icons.people_rounded, color: Colors.tealAccent),
              title: const Text('Students', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StudentsListScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment_ind_rounded, color: Colors.teal),
              title: const Text('Enrollments', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EnrollmentsListScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.school_rounded, color: Colors.amberAccent),
              title: const Text('Lecturers', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LecturersListScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.book_rounded, color: Colors.indigoAccent),
              title: const Text('Subjects', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SubjectsListScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month_rounded, color: Colors.greenAccent),
              title: const Text('Attendance', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AttendanceListScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment_rounded, color: Colors.orangeAccent),
              title: const Text('Assignments', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AssignmentsListScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.task_alt_rounded, color: Colors.cyanAccent),
              title: const Text('Tasks', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TasksListScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_rounded, color: Colors.purpleAccent),
              title: const Text('Notifications', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationsListScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.campaign_rounded, color: Colors.pinkAccent),
              title: const Text('Announcements', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AnnouncementsListScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart_rounded, color: Colors.lightBlueAccent),
              title: const Text('Reports', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ReportsScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('students').snapshots(),
        builder: (context, studentsSnap) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('lecturers').snapshots(),
            builder: (context, lecturersSnap) {
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, usersSnap) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('subjects').snapshots(),
                    builder: (context, subjectsSnap) {
                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('enrollments').snapshots(),
                        builder: (context, enrollmentsSnap) {
                          return StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance.collection('attendance').snapshots(),
                            builder: (context, attendanceSnap) {
                              return StreamBuilder<DocumentSnapshot>(
                                stream: FirebaseFirestore.instance.collection('settings').doc('attendance_config').snapshots(),
                                builder: (context, settingsSnap) {
                                  return StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance.collection('assignments').snapshots(),
                                    builder: (context, assignmentsSnap) {
                                       return StreamBuilder<QuerySnapshot>(
                                         stream: FirebaseFirestore.instance.collection('tasks').snapshots(),
                                         builder: (context, tasksSnap) {
                                            return StreamBuilder<QuerySnapshot>(
                                              stream: FirebaseFirestore.instance.collection('announcements').snapshots(),
                                              builder: (context, announcementsSnap) {
                                                return StreamBuilder<QuerySnapshot>(
                                                  stream: FirebaseFirestore.instance.collection('notifications').snapshots(),
                                                  builder: (context, notificationsSnap) {
                                                    final studentDocs = studentsSnap.hasData ? studentsSnap.data!.docs : [];
                                                    final lecturerDocs = lecturersSnap.hasData ? lecturersSnap.data!.docs : [];
                                                    final userDocs = usersSnap.hasData ? usersSnap.data!.docs : [];
                                                    final subjectDocs = subjectsSnap.hasData ? subjectsSnap.data!.docs : [];
                                                    final enrollmentDocs = enrollmentsSnap.hasData ? enrollmentsSnap.data!.docs : [];
                                                    final attendanceDocs = attendanceSnap.hasData ? attendanceSnap.data!.docs : [];
                                                    final assignmentDocs = assignmentsSnap.hasData ? assignmentsSnap.data!.docs : [];
                                                    final taskDocs = tasksSnap.hasData ? tasksSnap.data!.docs : [];
                                                    final announcementDocs = announcementsSnap.hasData ? announcementsSnap.data!.docs : [];
                                                    final notificationDocs = notificationsSnap.hasData ? notificationsSnap.data!.docs : [];

                                                    // Extract threshold (default to 80%)
                                                    double threshold = 80.0;
                                                    if (settingsSnap.hasData && settingsSnap.data!.exists) {
                                                      final data = settingsSnap.data!.data() as Map<String, dynamic>?;
                                                      if (data != null && data['threshold'] != null) {
                                                        threshold = (data['threshold'] as num).toDouble();
                                                      }
                                                    }

                                                    // 1. Calculate Active Students Count
                                                    final Set<String> activeStudentIdentifiers = {};

                                                    for (var doc in studentDocs) {
                                                      final data = doc.data() as Map<String, dynamic>;
                                                      final status = (data['status'] ?? 'active').toString().toLowerCase();
                                                      if (status == 'active') {
                                                        final email = data['email']?.toString().toLowerCase();
                                                        activeStudentIdentifiers.add(email ?? doc.id);
                                                      }
                                                    }

                                                    for (var doc in userDocs) {
                                                      final data = doc.data() as Map<String, dynamic>;
                                                      final role = data['role']?.toString().toUpperCase() ?? '';
                                                      final status = (data['status'] ?? 'active').toString().toLowerCase();
                                                      if (role == 'STUDENT' && status == 'active') {
                                                        final email = data['email']?.toString().toLowerCase();
                                                        activeStudentIdentifiers.add(email ?? doc.id);
                                                      }
                                                    }

                                                    // 2. Calculate Active Lecturers Count
                                                    final Set<String> activeLecturerIdentifiers = {};

                                                    for (var doc in lecturerDocs) {
                                                      final data = doc.data() as Map<String, dynamic>;
                                                      final status = (data['status'] ?? 'active').toString().toLowerCase();
                                                      if (status == 'active') {
                                                        final email = data['email']?.toString().toLowerCase();
                                                        activeLecturerIdentifiers.add(email ?? doc.id);
                                                      }
                                                    }

                                                    for (var doc in userDocs) {
                                                      final data = doc.data() as Map<String, dynamic>;
                                                      final role = data['role']?.toString().toUpperCase() ?? '';
                                                      final status = (data['status'] ?? 'active').toString().toLowerCase();
                                                      if (role == 'LECTURER' && status == 'active') {
                                                        final email = data['email']?.toString().toLowerCase();
                                                        activeLecturerIdentifiers.add(email ?? doc.id);
                                                      }
                                                    }

                                                    final totalActiveStudents = activeStudentIdentifiers.length;
                                                    final totalActiveLecturers = activeLecturerIdentifiers.length;
                                                    final totalSubjects = subjectDocs.length;

                                                    // Only count active enrollments
                                                    final totalActiveEnrollments = enrollmentDocs.where((doc) {
                                                      final data = doc.data() as Map<String, dynamic>;
                                                      return (data['status'] ?? 'active').toString().toLowerCase() == 'active';
                                                    }).length;

                                                    // Assignments count
                                                    final totalActiveAssignments = assignmentDocs.where((doc) {
                                                      final data = doc.data() as Map<String, dynamic>;
                                                      return (data['status'] ?? '').toString().toLowerCase() != 'deactivated';
                                                    }).length;

                                                    // Tasks count
                                                    final totalActiveTasks = taskDocs.where((doc) {
                                                      final data = doc.data() as Map<String, dynamic>;
                                                      return (data['status'] ?? '').toString().toLowerCase() != 'deactivated';
                                                    }).length;

                                                    // Announcements: Accurate active published count (published and non-expired)
                                                    int activePublishedAnnouncements = 0;
                                                    for (var doc in announcementDocs) {
                                                      final data = doc.data() as Map<String, dynamic>;
                                                      final status = (data['status'] ?? '').toString().toLowerCase();
                                                      if (status == 'published') {
                                                        final exp = (data['expiryDate'] ?? '').toString();
                                                        bool isExpired = false;
                                                        if (exp.isNotEmpty) {
                                                          try {
                                                            final dt = DateTime.parse(exp);
                                                            final endOfDay = DateTime(dt.year, dt.month, dt.day, 23, 59, 59);
                                                            if (DateTime.now().isAfter(endOfDay)) isExpired = true;
                                                          } catch (_) {}
                                                        }
                                                        if (!isExpired) activePublishedAnnouncements++;
                                                      }
                                                    }

                                                    // Notifications: Accurate delivered/sent count
                                                    int totalSentNotifications = 0;
                                                    for (var doc in notificationDocs) {
                                                      final data = doc.data() as Map<String, dynamic>;
                                                      final status = (data['status'] ?? '').toString().toLowerCase();
                                                      if (status == 'sent') {
                                                        totalSentNotifications++;
                                                      } else if (status == 'scheduled') {
                                                        final sched = (data['scheduledDate'] ?? '').toString();
                                                        if (sched.isNotEmpty) {
                                                          try {
                                                            if (DateTime.now().isAfter(DateTime.parse(sched))) {
                                                              totalSentNotifications++;
                                                            }
                                                          } catch (_) {}
                                                        }
                                                      }
                                                    }

                                                    // 3. Attendance metrics calculation
                                                    final validAttendanceDocs = attendanceDocs.where((doc) {
                                                      final data = doc.data() as Map<String, dynamic>;
                                                      return (data['status'] ?? '').toString().toLowerCase() != 'cancelled';
                                                    }).toList();

                                                    final totalAttendanceRecords = validAttendanceDocs.length;

                                                    final attendedCount = validAttendanceDocs.where((doc) {
                                                      final data = doc.data() as Map<String, dynamic>;
                                                      final status = (data['status'] ?? '').toString().toLowerCase();
                                                      return status == 'present' || status == 'late';
                                                    }).length;

                                                    final double avgAttendance = totalAttendanceRecords > 0
                                                        ? (attendedCount / totalAttendanceRecords) * 100
                                                        : 0.0;

                                                    // Group by studentDocId to find low attendance students
                                                    final Map<String, List<Map<String, dynamic>>> studentGroup = {};
                                                    for (var doc in validAttendanceDocs) {
                                                      final data = doc.data() as Map<String, dynamic>;
                                                      final studentId = data['studentDocId'] ?? '';
                                                      if (studentId.isNotEmpty) {
                                                        if (!studentGroup.containsKey(studentId)) {
                                                          studentGroup[studentId] = [];
                                                        }
                                                        studentGroup[studentId]!.add(data);
                                                      }
                                                    }

                                                    int lowAttendanceCount = 0;
                                                    studentGroup.forEach((studentId, records) {
                                                      final studentAttended = records.where((r) {
                                                        final status = (r['status'] ?? '').toString().toLowerCase();
                                                        return status == 'present' || status == 'late';
                                                      }).length;
                                                      final total = records.length;
                                                      if (total > 0) {
                                                        final double pct = (studentAttended / total) * 100;
                                                        if (pct < threshold) {
                                                          lowAttendanceCount++;
                                                        }
                                                      }
                                                    });

                                                    return SingleChildScrollView(
                                                      padding: const EdgeInsets.all(16),
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          GridView.count(
                                                            shrinkWrap: true,
                                                            physics: const NeverScrollableScrollPhysics(),
                                                            crossAxisCount: 2,
                                                            crossAxisSpacing: 12,
                                                            mainAxisSpacing: 12,
                                                            childAspectRatio: 1.2,
                                                            children: [
                                                              _dashboardCard(
                                                                icon: Icons.people_rounded,
                                                                title: 'Students',
                                                                value: '$totalActiveStudents',
                                                                color: Colors.tealAccent,
                                                                onTap: () {
                                                                  Navigator.push(
                                                                    context,
                                                                    MaterialPageRoute(builder: (context) => const StudentsListScreen()),
                                                                  );
                                                                },
                                                              ),
                                                              _dashboardCard(
                                                                icon: Icons.school_rounded,
                                                                title: 'Lecturers',
                                                                value: '$totalActiveLecturers',
                                                                color: Colors.amberAccent,
                                                                onTap: () {
                                                                  Navigator.push(
                                                                    context,
                                                                    MaterialPageRoute(builder: (context) => const LecturersListScreen()),
                                                                  );
                                                                },
                                                              ),
                                                              _dashboardCard(
                                                                icon: Icons.book_rounded,
                                                                title: 'Subjects',
                                                                value: '$totalSubjects',
                                                                color: Colors.indigoAccent,
                                                                onTap: () {
                                                                  Navigator.push(
                                                                    context,
                                                                    MaterialPageRoute(builder: (context) => const SubjectsListScreen()),
                                                                  );
                                                                },
                                                              ),
                                                              _dashboardCard(
                                                                icon: Icons.assignment_ind_rounded,
                                                                title: 'Enrollments',
                                                                value: '$totalActiveEnrollments',
                                                                color: Colors.teal,
                                                                onTap: () {
                                                                  Navigator.push(
                                                                    context,
                                                                    MaterialPageRoute(builder: (context) => const EnrollmentsListScreen()),
                                                                  );
                                                                },
                                                              ),
                                                              _dashboardCard(
                                                                icon: Icons.assignment_rounded,
                                                                title: 'Assignments',
                                                                value: '$totalActiveAssignments',
                                                                color: Colors.orangeAccent,
                                                                onTap: () {
                                                                  Navigator.push(
                                                                    context,
                                                                    MaterialPageRoute(builder: (context) => const AssignmentsListScreen()),
                                                                  );
                                                                },
                                                              ),
                                                              _dashboardCard(
                                                                icon: Icons.task_alt_rounded,
                                                                title: 'Tasks',
                                                                value: '$totalActiveTasks',
                                                                color: Colors.cyanAccent,
                                                                onTap: () {
                                                                  Navigator.push(
                                                                    context,
                                                                    MaterialPageRoute(builder: (context) => const TasksListScreen()),
                                                                  );
                                                                },
                                                              ),
                                                              _dashboardCard(
                                                                icon: Icons.campaign_rounded,
                                                                title: 'Announcements',
                                                                value: '$activePublishedAnnouncements',
                                                                color: Colors.pinkAccent,
                                                                onTap: () {
                                                                  Navigator.push(
                                                                    context,
                                                                    MaterialPageRoute(builder: (context) => const AnnouncementsListScreen()),
                                                                  );
                                                                },
                                                              ),
                                                              _dashboardCard(
                                                                icon: Icons.notifications_rounded,
                                                                title: 'Notifications',
                                                                value: '$totalSentNotifications',
                                                                color: Colors.purpleAccent,
                                                                onTap: () {
                                                                  Navigator.push(
                                                                    context,
                                                                    MaterialPageRoute(builder: (context) => const NotificationsListScreen()),
                                                                  );
                                                                },
                                                              ),
                                                              _dashboardCard(
                                                                icon: Icons.calendar_month_rounded,
                                                                title: 'Avg Attendance',
                                                                value: '${avgAttendance.toStringAsFixed(1)}%',
                                                                color: Colors.greenAccent,
                                                                onTap: () {
                                                                  Navigator.push(
                                                                    context,
                                                                    MaterialPageRoute(builder: (context) => const AttendanceListScreen()),
                                                                  );
                                                                },
                                                              ),
                                                              _dashboardCard(
                                                                icon: Icons.warning_amber_rounded,
                                                                title: 'Low Attendance',
                                                                value: '$lowAttendanceCount Students',
                                                                color: Colors.redAccent,
                                                                onTap: () {
                                                                  Navigator.push(
                                                                    context,
                                                                    MaterialPageRoute(builder: (context) => const AttendanceListScreen()),
                                                                  );
                                                                },
                                                              ),
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
            );
          },
        ),
      );
  }

  Widget _dashboardCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.white10),
        ),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 42, color: color),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
