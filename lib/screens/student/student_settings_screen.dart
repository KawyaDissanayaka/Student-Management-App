import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../auth/login_screen.dart';

class StudentSettingsScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const StudentSettingsScreen({super.key, this.userData});

  @override
  State<StudentSettingsScreen> createState() => _StudentSettingsScreenState();
}

class _StudentSettingsScreenState extends State<StudentSettingsScreen> {
  final AuthService _authService = AuthService();

  bool _lectureReminders = true;
  bool _assignmentDeadlines = true;
  bool _examNotices = true;

  void _showChangePasswordDialog() {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.lock_reset_rounded, color: Colors.amberAccent),
              SizedBox(width: 8),
              Text('Change Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPassController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    labelStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPassController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    labelStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPassController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    labelStyle: const TextStyle(color: Colors.grey),
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
                          const SnackBar(content: Text('Please fill all fields.'), backgroundColor: Colors.redAccent),
                        );
                        return;
                      }

                      if (newPass.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('New password must be at least 6 characters.'), backgroundColor: Colors.redAccent),
                        );
                        return;
                      }

                      if (newPass != confirmPass) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Confirm password does not match.'), backgroundColor: Colors.redAccent),
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
                          const SnackBar(content: Text('Password updated successfully!'), backgroundColor: Colors.green),
                        );
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        messenger.showSnackBar(
                          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.redAccent),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent),
              child: isSubmitting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Text('Update', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
            SizedBox(width: 8),
            Text('Sign Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: const Text('Are you sure you want to sign out from the Student Portal?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
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
            Icon(Icons.settings_rounded, color: Colors.tealAccent),
            SizedBox(width: 8),
            Text('Student Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('NOTIFICATION PREFERENCES', style: TextStyle(color: Colors.tealAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
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
                  activeThumbColor: Colors.tealAccent,
                  title: const Text('Upcoming Lecture Alerts', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Reminders 15 minutes before scheduled lectures', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
                const Divider(color: Colors.white10, height: 1),
                SwitchListTile(
                  value: _assignmentDeadlines,
                  onChanged: (val) => setState(() => _assignmentDeadlines = val),
                  activeThumbColor: Colors.tealAccent,
                  title: const Text('Assignment Deadlines', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Alerts 24 hours before submission deadline', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
                const Divider(color: Colors.white10, height: 1),
                SwitchListTile(
                  value: _examNotices,
                  onChanged: (val) => setState(() => _examNotices = val),
                  activeThumbColor: Colors.tealAccent,
                  title: const Text('Exam & Results Notices', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Instant alerts when exam timetables or grades are published', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text('ACCOUNT SECURITY', style: TextStyle(color: Colors.tealAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
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
                  leading: const Icon(Icons.key_rounded, color: Colors.amberAccent),
                  title: const Text('Change Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Update your portal password', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                  onTap: _showChangePasswordDialog,
                ),
                const Divider(color: Colors.white10, height: 1),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                  title: const Text('Sign Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Log out from this device', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.redAccent),
                  onTap: _confirmLogout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
