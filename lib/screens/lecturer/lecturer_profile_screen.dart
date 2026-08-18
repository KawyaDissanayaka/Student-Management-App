import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/lecturer_service.dart';
import '../../auth/login_screen.dart';
import 'lecturer_settings_screen.dart';

class LecturerProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const LecturerProfileScreen({super.key, this.userData});

  @override
  State<LecturerProfileScreen> createState() => _LecturerProfileScreenState();
}

class _LecturerProfileScreenState extends State<LecturerProfileScreen> {
  final AuthService _authService = AuthService();
  final LecturerService _lecturerService = LecturerService();
  final _formKey = GlobalKey<FormState>();

  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _photoUrlController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  Map<String, dynamic> _profile = {};

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadProfile();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  void _checkAuthAndLoadProfile() {
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
      return;
    }
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = _authService.currentUser;
      final email = (widget.userData?['email'] ?? user?.email ?? '').trim().toLowerCase();

      if (email.isNotEmpty) {
        final query = await FirebaseFirestore.instance
            .collection('lecturers')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          _profile = query.docs.first.data();
          _profile['docId'] = query.docs.first.id;
        } else {
          _profile = Map<String, dynamic>.from(widget.userData ?? {});
        }

        // Populate editable controllers
        _phoneController.text = _profile['phone'] ?? _profile['contactNo'] ?? '+94 77 345 6789';
        _addressController.text = _profile['address'] ?? 'Faculty of Computing, University Main Campus';
        _photoUrlController.text = _profile['photoUrl'] ?? _profile['profilePicUrl'] ?? user?.photoURL ?? '';
      }
    } catch (e) {
      debugPrint('Error loading lecturer profile: $e');
      _errorMessage = 'Failed to load profile details: $e';
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    final user = _authService.currentUser;

    if (user == null) {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
      return;
    }

    try {
      final docId = _profile['docId'];
      final phone = _phoneController.text.trim();
      final address = _addressController.text.trim();
      final photoUrl = _photoUrlController.text.trim();

      final updateData = {
        'phone': phone,
        'address': address,
        'photoUrl': photoUrl,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (docId != null && docId.toString().isNotEmpty) {
        await _lecturerService.updateLecturerProfile(
          docId: docId.toString(),
          updateData: updateData,
          uid: user.uid,
        );
      } else {
        // Update users collection if docId not yet found
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(updateData, SetOptions(merge: true));
      }

      // Update Firebase Auth profile
      final name = _profile['name'] ?? _profile['fullName'] ?? user.displayName ?? 'Lecturer';
      await _authService.updateUserProfile(
        fullName: name,
        photoUrl: photoUrl.isNotEmpty ? photoUrl : null,
      );

      setState(() {
        _profile['phone'] = phone;
        _profile['address'] = address;
        _profile['photoUrl'] = photoUrl;
      });

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Lecturer profile updated successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showEditPhotoDialog() {
    final tempController = TextEditingController(text: _photoUrlController.text);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.add_photo_alternate_rounded, color: Colors.amberAccent),
            SizedBox(width: 10),
            Text('Profile Picture', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter an image URL or Firebase Storage public URL to set your avatar:',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: tempController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Image URL',
                labelStyle: const TextStyle(color: Colors.grey),
                hintText: 'https://...',
                hintStyle: const TextStyle(color: Colors.white30),
                prefixIcon: const Icon(Icons.link_rounded, color: Colors.amberAccent),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Preset Academic Avatars:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPresetAvatar(ctx, tempController, 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&auto=format&fit=crop'),
                _buildPresetAvatar(ctx, tempController, 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&auto=format&fit=crop'),
                _buildPresetAvatar(ctx, tempController, 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=200&auto=format&fit=crop'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _photoUrlController.text = tempController.text.trim();
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent),
            child: const Text('Apply Photo', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetAvatar(BuildContext ctx, TextEditingController controller, String url) {
    return GestureDetector(
      onTap: () => controller.text = url,
      child: CircleAvatar(
        radius: 22,
        backgroundImage: NetworkImage(url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final name = _profile['name'] ?? _profile['fullName'] ?? widget.userData?['fullName'] ?? user?.displayName ?? 'Dr. Lecturer';
    final lecturerId = _profile['lecturerId'] ?? widget.userData?['lecturerId'] ?? 'LEC-1001';
    final email = _profile['email'] ?? widget.userData?['email'] ?? user?.email ?? '';
    final department = _profile['department'] ?? widget.userData?['department'] ?? 'Department of Computing';
    final designation = _profile['designation'] ?? widget.userData?['designation'] ?? 'Senior Lecturer';
    final joinedDate = _profile['joinedDate'] ?? _profile['createdAt']?.toString().substring(0, 10) ?? '2024-01-15';
    final photoUrl = _photoUrlController.text.trim();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Lecturer Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: Colors.amberAccent),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LecturerSettingsScreen(userData: widget.userData),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amberAccent))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 54),
                        const SizedBox(height: 16),
                        Text(_errorMessage!, style: const TextStyle(color: Colors.white, fontSize: 14), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadProfileData,
                          icon: const Icon(Icons.refresh_rounded, color: Colors.black),
                          label: const Text('Try Again', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Profile Card
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
                            border: Border.all(color: Colors.amberAccent.withAlpha(90)),
                          ),
                          child: Column(
                            children: [
                              Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  CircleAvatar(
                                    radius: 50,
                                    backgroundColor: Colors.amber.withAlpha(40),
                                    backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                                    child: photoUrl.isEmpty
                                        ? const Icon(Icons.cast_for_education_rounded, size: 52, color: Colors.amberAccent)
                                        : null,
                                  ),
                                  GestureDetector(
                                    onTap: _showEditPhotoDialog,
                                    child: Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: Colors.amberAccent,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: const Color(0xFF0F172A), width: 2),
                                      ),
                                      child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.black),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text(
                                name,
                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                designation,
                                style: const TextStyle(color: Colors.amberAccent, fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                email,
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withAlpha(30),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.amberAccent.withAlpha(80)),
                                ),
                                child: Text(
                                  '$lecturerId • $department',
                                  style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Section 1: Official & Admin-Controlled Information (Read-Only)
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
                                  Icon(Icons.lock_rounded, color: Colors.amberAccent, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Institutional Credentials (Admin-Controlled)',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'These fields are managed by University Administration and cannot be edited by the lecturer.',
                                style: TextStyle(color: Colors.grey, fontSize: 11),
                              ),
                              const SizedBox(height: 16),
                              _buildReadOnlyRow('Lecturer ID', lecturerId, Icons.badge_outlined),
                              _buildReadOnlyRow('Assigned Department', department, Icons.business_rounded),
                              _buildReadOnlyRow('Academic Designation', designation, Icons.military_tech_rounded),
                              _buildReadOnlyRow('Joined Date', joinedDate, Icons.calendar_today_rounded),
                              _buildReadOnlyRow('Primary Email Key', email, Icons.email_outlined),
                              _buildReadOnlyRow('Account Status', 'Active Academic Staff', Icons.verified_user_rounded, isGood: true),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Section 2: Contact & Personal Details (Permitted Editable Fields)
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
                                  Icon(Icons.edit_note_rounded, color: Colors.tealAccent, size: 22),
                                  SizedBox(width: 8),
                                  Text(
                                    'Contact Information (Editable)',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'You may update your contact number, office/residential address, and profile photo.',
                                style: TextStyle(color: Colors.grey, fontSize: 11),
                              ),
                              const SizedBox(height: 18),

                              // Phone Number
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Phone Number *',
                                  labelStyle: const TextStyle(color: Colors.grey),
                                  prefixIcon: const Icon(Icons.phone_outlined, color: Colors.tealAccent),
                                  filled: true,
                                  fillColor: const Color(0xFF0F172A),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Colors.tealAccent),
                                  ),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Please enter your phone number';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),

                              // Residential / Office Address
                              TextFormField(
                                controller: _addressController,
                                maxLines: 2,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Office / Campus Address *',
                                  labelStyle: const TextStyle(color: Colors.grey),
                                  prefixIcon: const Icon(Icons.location_on_outlined, color: Colors.tealAccent),
                                  filled: true,
                                  fillColor: const Color(0xFF0F172A),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Colors.tealAccent),
                                  ),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Please enter your address';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),

                              // Profile Picture URL
                              TextFormField(
                                controller: _photoUrlController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Profile Photo URL (Firebase Storage / Web)',
                                  labelStyle: const TextStyle(color: Colors.grey),
                                  prefixIcon: const Icon(Icons.image_outlined, color: Colors.tealAccent),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.edit_rounded, color: Colors.amberAccent, size: 18),
                                    tooltip: 'Select or edit avatar',
                                    onPressed: _showEditPhotoDialog,
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFF0F172A),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Colors.tealAccent),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Save Profile Button
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton.icon(
                                  onPressed: _isSaving ? null : _saveProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  icon: _isSaving
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Icon(Icons.save_rounded, color: Colors.white),
                                  label: Text(
                                    _isSaving ? 'Saving Changes...' : 'Save Profile Changes',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildReadOnlyRow(String label, String value, IconData icon, {bool isGood = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: Colors.amberAccent.withAlpha(180)),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: isGood ? Colors.greenAccent : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.lock_outline_rounded, size: 13, color: Colors.white38),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
