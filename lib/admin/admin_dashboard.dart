import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/admin/students_list_screen.dart';
import '../screens/admin/lecturers_list_screen.dart';
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
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month_rounded, color: Colors.greenAccent),
              title: const Text('Attendance', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment_rounded, color: Colors.orangeAccent),
              title: const Text('Assignments', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.task_alt_rounded, color: Colors.cyanAccent),
              title: const Text('Tasks', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_rounded, color: Colors.purpleAccent),
              title: const Text('Notifications', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.campaign_rounded, color: Colors.pinkAccent),
              title: const Text('Announcements', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart_rounded, color: Colors.lightBlueAccent),
              title: const Text('Reports', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
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
                  final studentDocs = studentsSnap.hasData ? studentsSnap.data!.docs : [];
                  final lecturerDocs = lecturersSnap.hasData ? lecturersSnap.data!.docs : [];
                  final userDocs = usersSnap.hasData ? usersSnap.data!.docs : [];

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

                  // 2. Calculate Active Lecturers Count (status == 'active' ONLY)
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

                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
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
                          value: '0',
                          color: Colors.indigoAccent,
                        ),
                        _dashboardCard(
                          icon: Icons.assignment_rounded,
                          title: 'Assignments',
                          value: '0',
                          color: Colors.orangeAccent,
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
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 28,
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
