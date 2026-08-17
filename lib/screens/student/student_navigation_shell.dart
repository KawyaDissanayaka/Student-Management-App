import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import '../../services/student_portal_service.dart';
import 'student_home_screen.dart';
import 'student_modules_screen.dart';
import 'student_timetable_screen.dart';
import 'student_profile_screen.dart';
import '../user_notifications_screen.dart';

class StudentNavigationShell extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const StudentNavigationShell({super.key, this.userData});

  @override
  State<StudentNavigationShell> createState() => _StudentNavigationShellState();
}

class _StudentNavigationShellState extends State<StudentNavigationShell> {
  int _currentIndex = 0;
  final StudentPortalService _portalService = StudentPortalService();

  @override
  void initState() {
    super.initState();
    _portalService.ensureCampusDataInitialized();
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.userData?['email'] ?? '';
    final name = widget.userData?['fullName'] ?? 'Student';

    final List<Widget> pages = [
      StudentHomeScreen(
        userData: widget.userData,
        onNavigateTab: (index) {
          setState(() => _currentIndex = index);
        },
      ),
      StudentModulesScreen(userData: widget.userData),
      StudentTimetableScreen(userData: widget.userData),
      UserNotificationsScreen(
        userEmail: email,
        userName: name,
        userRole: 'Student',
      ),
      StudentProfileScreen(userData: widget.userData),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: StreamBuilder<int>(
        stream: NotificationService().getUnreadCountStream(email, 'Student'),
        builder: (context, notifSnap) {
          final unreadCount = notifSnap.data ?? 0;

          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              backgroundColor: const Color(0xFF1E293B),
              selectedItemColor: Colors.tealAccent,
              unselectedItemColor: Colors.grey,
              type: BottomNavigationBarType.fixed,
              selectedFontSize: 12,
              unselectedFontSize: 11,
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.book_rounded),
                  label: 'Modules',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_month_rounded),
                  label: 'Timetable',
                ),
                BottomNavigationBarItem(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.notifications_rounded),
                      if (unreadCount > 0)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  label: 'Alerts',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.person_rounded),
                  label: 'Profile',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
