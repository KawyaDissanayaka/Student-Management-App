import 'package:flutter/material.dart';
import '../../admin/admin_dashboard.dart';

class AdminDashboardScreen extends StatelessWidget {
  final Map<String, dynamic>? userData;

  const AdminDashboardScreen({super.key, this.userData});

  @override
  Widget build(BuildContext context) {
    return const AdminDashboard();
  }
}
