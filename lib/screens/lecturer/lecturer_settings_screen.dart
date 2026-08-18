import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../auth/login_screen.dart';
import 'lecturer_profile_screen.dart';

class LecturerSettingsScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const LecturerSettingsScreen({super.key, this.userData});

  @override
  State<LecturerSettingsScreen> createState() => _LecturerSettingsScreenState();
}

class _LecturerSettingsScreenState extends State<LecturerSettingsScreen> {
  final AuthService _authService = AuthService();

  // Notification Preferences
  bool _lectureReminders = true;
  bool _assignmentAlerts = true;
  bool _studentInquiries = true;
  bool _facultyBroadcasts = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() {
    final user = _authService.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      });
    }
  }

  void _showChangePasswordDialog() {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    bool isSubmitting = false;
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.lock_reset_rounded, color: Colors.amberAccent),
              SizedBox(width: 10),
              Text(
                'Change Password',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter your current password to set a secure new password.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 16),

                // Current Password
                TextField(
                  controller: currentPassController,
                  obscureText: obscureCurrent,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    labelStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                    suffixIcon: IconButton(
                      icon: Icon(obscureCurrent ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                      onPressed: () => setDialogState(() => obscureCurrent = !obscureCurrent),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),

                // New Password
                TextField(
                  controller: newPassController,
                  obscureText: obscureNew,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'New Password (min 6 characters)',
                    labelStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.key_rounded, color: Colors.grey),
                    suffixIcon: IconButton(
                      icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                      onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),

                // Confirm Password
                TextField(
                  controller: confirmPassController,
                  obscureText: obscureConfirm,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    labelStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.check_circle_outline, color: Colors.grey),
                    suffixIcon: IconButton(
                      icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                      onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final currentPass = currentPassController.text.trim();
                      final newPass = newPassController.text.trim();
                      final confirmPass = confirmPassController.text.trim();

                      if (currentPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill all password fields.'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        return;
                      }

                      if (newPass.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('New password must be at least 6 characters.'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        return;
                      }

                      if (newPass == currentPass) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('New password cannot be the same as current password.'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        return;
                      }

                      if (newPass != confirmPass) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Confirm password does not match new password.'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isSubmitting = true);
                      final messenger = ScaffoldMessenger.of(context);
                      final nav = Navigator.of(ctx);

                      try {
                        await _authService.changePassword(
                          currentPassword: currentPass,
                          newPassword: newPass,
                        );
                        if (ctx.mounted) nav.pop();
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Password changed successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Failed: $e'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent),
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Text('Update Password', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
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
            Text('Sign Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Are you sure you want to securely sign out from the Lecturer Portal?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final nav = Navigator.of(context);
              Navigator.pop(ctx);
              await _authService.signOut();
              if (mounted) {
                nav.pushAndRemoveUntil(
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
    final email = (widget.userData?['email'] ?? _authService.currentUser?.email ?? '').trim().toLowerCase();

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
            Icon(Icons.settings_rounded, color: Colors.amberAccent),
            SizedBox(width: 8),
            Text(
              'Lecturer Settings',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Section 1: Notification Preferences
          _buildSectionHeader('NOTIFICATION PREFERENCES'),
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
                  value: _lectureReminders,
                  onChanged: (val) => setState(() => _lectureReminders = val),
                  activeThumbColor: Colors.amberAccent,
                  title: const Text('Upcoming Lecture Alerts', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Get notified 15 minutes before your scheduled lectures', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
                const Divider(color: Colors.white10, height: 1),
                SwitchListTile(
                  value: _assignmentAlerts,
                  onChanged: (val) => setState(() => _assignmentAlerts = val),
                  activeThumbColor: Colors.amberAccent,
                  title: const Text('Assignment Submissions', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Receive notifications when students submit coursework', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
                const Divider(color: Colors.white10, height: 1),
                SwitchListTile(
                  value: _studentInquiries,
                  onChanged: (val) => setState(() => _studentInquiries = val),
                  activeThumbColor: Colors.amberAccent,
                  title: const Text('Student Inquiries & Queries', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Direct alerts for messages and student support requests', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
                const Divider(color: Colors.white10, height: 1),
                SwitchListTile(
                  value: _facultyBroadcasts,
                  onChanged: (val) => setState(() => _facultyBroadcasts = val),
                  activeThumbColor: Colors.amberAccent,
                  title: const Text('Faculty & Admin Announcements', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Institutional notices and university administrative circulars', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 2: Account & Security
          _buildSectionHeader('ACCOUNT & SECURITY'),
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
                  leading: const Icon(Icons.person_outline_rounded, color: Colors.amberAccent),
                  title: const Text('Lecturer Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: Text(email.isNotEmpty ? email : 'View and update profile details', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LecturerProfileScreen(userData: widget.userData)),
                    );
                  },
                ),
                const Divider(color: Colors.white10, height: 1),
                ListTile(
                  leading: const Icon(Icons.key_rounded, color: Colors.amberAccent),
                  title: const Text('Change Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Update your Firebase Authentication password', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                  onTap: _showChangePasswordDialog,
                ),
                const Divider(color: Colors.white10, height: 1),
                ListTile(
                  leading: const Icon(Icons.security_rounded, color: Colors.greenAccent),
                  title: const Text('Role-Based Security Guard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Authenticated as Lecturer • Protected Data Scoping', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.green.withAlpha(40), borderRadius: BorderRadius.circular(6)),
                    child: const Text('ACTIVE', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
                const Divider(color: Colors.white10, height: 1),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                  title: const Text('Sign Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Log out and terminate current lecturer session', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.redAccent),
                  onTap: _confirmLogout,
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // App Info Footer
          const Center(
            child: Column(
              children: [
                Text('Lecturer Portal • Student Management System', style: TextStyle(color: Colors.grey, fontSize: 12)),
                SizedBox(height: 2),
                Text('Version 1.0.0 • Role-Based Access Enforced', style: TextStyle(color: Colors.white38, fontSize: 11)),
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
        color: Colors.amberAccent,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
    );
  }
}
