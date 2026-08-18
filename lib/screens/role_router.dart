import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin/admin_dashboard_screen.dart';
import 'lecturer/lecturer_dashboard_screen.dart';
import 'student/student_navigation_shell.dart';
import '../auth/login_screen.dart';

class RoleRouterScreen extends StatefulWidget {
  const RoleRouterScreen({super.key});

  @override
  State<RoleRouterScreen> createState() => _RoleRouterScreenState();
}

class _RoleRouterScreenState extends State<RoleRouterScreen> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const LoginScreen();
    }

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0F172A),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.indigoAccent),
                  SizedBox(height: 16),
                  Text(
                    'Verifying User Credentials & Role...',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          // Fallback to Student Shell if Firestore fails or offline
          return StudentNavigationShell(userData: {
            'fullName': user.displayName ?? user.email?.split('@').first,
            'email': user.email,
          });
        }

        final data = snapshot.data?.data();
        final rawRole = data?['role']?.toString().toUpperCase() ?? 'STUDENT';

        if (rawRole == 'ADMIN' || rawRole == 'FINANCESTAFF' || rawRole == 'FINANCE_STAFF' || rawRole == 'LIBRARYSTAFF' || rawRole == 'LIBRARY_STAFF') {
          return AdminDashboardScreen(userData: data);
        } else if (rawRole == 'LECTURER') {
          return LecturerDashboardScreen(userData: data);
        } else {
          return StudentNavigationShell(userData: data);
        }
      },
    );
  }
}
