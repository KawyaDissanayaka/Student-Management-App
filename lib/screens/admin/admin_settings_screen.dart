import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/attendance_service.dart';
import '../../auth/login_screen.dart';
import 'admin_profile_screen.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  final AuthService _authService = AuthService();

  double _threshold = 80.0;
  bool _isLoading = true;
  bool _isSaving = false;

  // Notification Preferences
  bool _appNotifications = true;
  bool _lowAttendanceAlerts = true;
  bool _taskDueAlerts = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('settings').doc('attendance_config').get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data['threshold'] != null) {
          _threshold = (data['threshold'] as num).toDouble();
        }
        if (data['appNotifications'] != null) {
          _appNotifications = data['appNotifications'] as bool;
        }
        if (data['lowAttendanceAlerts'] != null) {
          _lowAttendanceAlerts = data['lowAttendanceAlerts'] as bool;
        }
        if (data['taskDueAlerts'] != null) {
          _taskDueAlerts = data['taskDueAlerts'] as bool;
        }
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('settings').doc('attendance_config').set({
        'threshold': _threshold,
        'appNotifications': _appNotifications,
        'lowAttendanceAlerts': _lowAttendanceAlerts,
        'taskDueAlerts': _taskDueAlerts,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Settings saved successfully! Required threshold: ${_threshold.toStringAsFixed(0)}%'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save settings: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.redAccent),
            SizedBox(width: 10),
            Text('Confirm Sign Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Are you sure you want to sign out from the Administrator console?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _authService.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Sign Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            Icon(Icons.settings_rounded, color: Colors.lightBlueAccent),
            SizedBox(width: 8),
            Text(
              'Admin Settings',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.tealAccent))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // 1. Attendance Configuration Card
                _buildSectionHeader('ACADEMIC & ATTENDANCE CONFIGURATION'),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(18),
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
                          const Text(
                            'Required Attendance Threshold',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.teal.withAlpha(40),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.tealAccent),
                            ),
                            child: Text(
                              '${_threshold.toStringAsFixed(0)}%',
                              style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Students whose attendance percentage drops below this value will be flagged in Low Attendance reports and trigger warning alerts.',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: Colors.tealAccent,
                          inactiveTrackColor: Colors.white12,
                          thumbColor: Colors.tealAccent,
                          overlayColor: Colors.tealAccent.withAlpha(40),
                          valueIndicatorColor: Colors.teal,
                        ),
                        child: Slider(
                          value: _threshold,
                          min: 50.0,
                          max: 100.0,
                          divisions: 10,
                          label: '${_threshold.toStringAsFixed(0)}%',
                          onChanged: (val) {
                            setState(() => _threshold = val);
                          },
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('50% (Lenient)', style: TextStyle(color: Colors.grey, fontSize: 11)),
                          Text('Recommended: 80%', style: TextStyle(color: Colors.tealAccent.withAlpha(200), fontSize: 11, fontWeight: FontWeight.bold)),
                          const Text('100% (Strict)', style: TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 2. Notification Preferences
                _buildSectionHeader('NOTIFICATION & ALERT PREFERENCES'),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: _appNotifications,
                        onChanged: (val) => setState(() => _appNotifications = val),
                        activeColor: Colors.tealAccent,
                        title: const Text('In-App Notification Alerts', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                        subtitle: const Text('Broadcast live announcements and notices to users', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ),
                      const Divider(color: Colors.white10, height: 1),
                      SwitchListTile(
                        value: _lowAttendanceAlerts,
                        onChanged: (val) => setState(() => _lowAttendanceAlerts = val),
                        activeColor: Colors.tealAccent,
                        title: const Text('Low Attendance Auto Warnings', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                        subtitle: const Text('Notify students when falling below threshold', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ),
                      const Divider(color: Colors.white10, height: 1),
                      SwitchListTile(
                        value: _taskDueAlerts,
                        onChanged: (val) => setState(() => _taskDueAlerts = val),
                        activeColor: Colors.tealAccent,
                        title: const Text('Task Due Date Reminders', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                        subtitle: const Text('Alert assignees 24h before task due deadline', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Save Settings Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: _isSaving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle_rounded, color: Colors.white),
                    label: const Text('Apply & Save Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 28),

                // 3. System & Account Actions
                _buildSectionHeader('ACCOUNT & SYSTEM'),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person_outline, color: Colors.tealAccent),
                        title: const Text('Admin Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Manage your name and account info', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AdminProfileScreen()),
                          );
                        },
                      ),
                      const Divider(color: Colors.white10, height: 1),
                      ListTile(
                        leading: const Icon(Icons.security_rounded, color: Colors.greenAccent),
                        title: const Text('Security Rules & Access Control', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Role-based access rules active (Admin, Lecturer, Student)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: Colors.green.withAlpha(40), borderRadius: BorderRadius.circular(6)),
                          child: const Text('ENFORCED', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const Divider(color: Colors.white10, height: 1),
                      ListTile(
                        leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                        title: const Text('Sign Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        subtitle: const Text('Terminate current administrator session', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.redAccent),
                        onTap: _confirmLogout,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // App Version Footer
                const Center(
                  child: Column(
                    children: [
                      Text('Student Management App • Enterprise Edition', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      SizedBox(height: 2),
                      Text('Version 1.0.0 • Cloud Firestore Connected', style: TextStyle(color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.lightBlueAccent,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
    );
  }
}
