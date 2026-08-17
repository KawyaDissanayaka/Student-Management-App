import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import 'student_settings_screen.dart';

class StudentProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const StudentProfileScreen({super.key, this.userData});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final AuthService _authService = AuthService();

  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  Map<String, dynamic> _profile = {};

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    _emergencyController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final email = widget.userData?['email'] ?? _authService.currentUser?.email ?? '';
      if (email.isNotEmpty) {
        final query = await FirebaseFirestore.instance
            .collection('students')
            .where('email', isEqualTo: email.trim().toLowerCase())
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          _profile = query.docs.first.data();
          _profile['docId'] = query.docs.first.id;
        } else {
          _profile = widget.userData ?? {};
        }

        _phoneController.text = _profile['phone'] ?? _profile['contactNo'] ?? '+94 77 123 4567';
        _addressController.text = _profile['address'] ?? 'Colombo, Sri Lanka';
        _emergencyController.text = _profile['emergencyContact'] ?? '+94 71 987 6543 (Parent)';
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final docId = _profile['docId'];

      final updateData = {
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'emergencyContact': _emergencyController.text.trim(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (docId != null) {
        await FirebaseFirestore.instance.collection('students').doc(docId).update(updateData);
      }

      final uid = _authService.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set(updateData, SetOptions(merge: true));
      }

      messenger.showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _profile['name'] ?? _profile['fullName'] ?? widget.userData?['fullName'] ?? 'Student';
    final studentId = _profile['studentId'] ?? widget.userData?['studentId'] ?? 'STU-1002';
    final email = _profile['email'] ?? widget.userData?['email'] ?? _authService.currentUser?.email ?? '';
    final course = _profile['course'] ?? widget.userData?['course'] ?? 'Computer Science';
    final batch = _profile['batch'] ?? widget.userData?['batch'] ?? '2026';
    final year = _profile['year'] ?? widget.userData?['year'] ?? 'Year 1';
    final semester = _profile['semester'] ?? widget.userData?['semester'] ?? 'Semester 1';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text('My Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: Colors.tealAccent),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => StudentSettingsScreen(userData: widget.userData)),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.tealAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Student Header Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E293B), Color(0xFF334155)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 46,
                          backgroundColor: Colors.teal.withAlpha(40),
                          child: const Icon(Icons.school_rounded, size: 50, color: Colors.tealAccent),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          name,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          studentId,
                          style: const TextStyle(color: Colors.tealAccent, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.teal.withAlpha(30),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.tealAccent.withAlpha(80)),
                          ),
                          child: Text(
                            '$course • $batch',
                            style: const TextStyle(color: Colors.tealAccent, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Academic Information (Protected Read-Only)
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
                        const Row(
                          children: [
                            Icon(Icons.verified_user_rounded, color: Colors.lightBlueAccent, size: 18),
                            SizedBox(width: 8),
                            Text('Academic Credentials (Official)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _buildInfoRow('Degree Program', course),
                        _buildInfoRow('Batch Allocation', batch),
                        _buildInfoRow('Current Stage', '$year • $semester'),
                        _buildInfoRow('Enrollment Status', 'Active Student', isGood: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Contact & Personal Details (Editable)
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
                        const Row(
                          children: [
                            Icon(Icons.edit_note_rounded, color: Colors.tealAccent, size: 20),
                            SizedBox(width: 8),
                            Text('Contact Details (Editable)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: _phoneController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            labelStyle: const TextStyle(color: Colors.grey),
                            prefixIcon: const Icon(Icons.phone_outlined, color: Colors.tealAccent),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 14),

                        TextField(
                          controller: _addressController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Residential Address',
                            labelStyle: const TextStyle(color: Colors.grey),
                            prefixIcon: const Icon(Icons.home_outlined, color: Colors.tealAccent),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 14),

                        TextField(
                          controller: _emergencyController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Emergency Contact Person & Phone',
                            labelStyle: const TextStyle(color: Colors.grey),
                            prefixIcon: const Icon(Icons.contact_phone_outlined, color: Colors.tealAccent),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: _isSaving
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.save_rounded, color: Colors.white),
                            label: const Text('Save Contact Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isGood = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              color: isGood ? Colors.greenAccent : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
