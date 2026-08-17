import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/announcement_model.dart';
import '../../services/announcement_service.dart';
import '../../services/auth_service.dart';

class AddEditAnnouncementScreen extends StatefulWidget {
  final AnnouncementModel? existingAnnouncement;

  const AddEditAnnouncementScreen({super.key, this.existingAnnouncement});

  @override
  State<AddEditAnnouncementScreen> createState() => _AddEditAnnouncementScreenState();
}

class _AddEditAnnouncementScreenState extends State<AddEditAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _announcementService = AnnouncementService();
  final _authService = AuthService();

  late final TextEditingController _announcementIdCtrl;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _createdByCtrl;

  // Selected Audience: 'all_students' | 'all_lecturers' | 'all_users' | 'specific_student' | 'specific_lecturer'
  String _selectedAudience = 'all_users';

  // Target User details if specific
  String? _targetUserDocId;
  String? _targetUserName;
  String? _targetUserEmail;
  String? _targetUserId;

  DateTime? _publishDate;
  DateTime? _expiryDate;
  String _selectedStatus = 'published';
  bool _isLoading = false;
  bool _isGeneratingId = false;

  bool get _isEditMode => widget.existingAnnouncement != null;

  final Map<String, String> _audienceLabels = {
    'all_users': 'Students & Lecturers',
    'all_students': 'All Students',
    'all_lecturers': 'All Lecturers',
    'specific_student': 'Specific Student',
    'specific_lecturer': 'Specific Lecturer',
  };

  @override
  void initState() {
    super.initState();
    final a = widget.existingAnnouncement;
    _announcementIdCtrl = TextEditingController(text: a?.announcementId ?? '');
    _titleCtrl = TextEditingController(text: a?.title ?? '');
    _descriptionCtrl = TextEditingController(text: a?.description ?? '');

    final currentAdmin = _authService.currentUser;
    final adminName = currentAdmin?.displayName?.isNotEmpty == true
        ? currentAdmin!.displayName!
        : (currentAdmin?.email ?? 'Admin');
    _createdByCtrl = TextEditingController(text: a?.createdBy ?? adminName);

    if (a != null) {
      _selectedAudience = a.audience;
      _targetUserDocId = a.targetUserDocId;
      _targetUserName = a.targetUserName;
      _targetUserEmail = a.targetUserEmail;
      _targetUserId = a.targetUserId;
      _selectedStatus = a.status.toLowerCase() == 'draft' ? 'draft' : 'published';
      if (a.publishDate.isNotEmpty) _publishDate = DateTime.tryParse(a.publishDate);
      if (a.expiryDate.isNotEmpty) _expiryDate = DateTime.tryParse(a.expiryDate);
    } else {
      _publishDate = DateTime.now();
      _expiryDate = DateTime.now().add(const Duration(days: 14));
      _autoFillAnnouncementId();
    }
  }

  Future<void> _autoFillAnnouncementId() async {
    setState(() => _isGeneratingId = true);
    try {
      final nextId = await _announcementService.generateNextAnnouncementId();
      if (mounted) {
        setState(() {
          _announcementIdCtrl.text = nextId;
          _isGeneratingId = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isGeneratingId = false);
    }
  }

  @override
  void dispose() {
    _announcementIdCtrl.dispose();
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _createdByCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  String _displayDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  Future<void> _pickDate({required bool isExpiry}) async {
    final now = DateTime.now();
    final firstDate = isExpiry ? (_publishDate ?? DateTime(2020)) : DateTime(2020);
    final initial = isExpiry ? (_expiryDate ?? _publishDate ?? now) : (_publishDate ?? now);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(firstDate) ? firstDate : initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFEC4899),
            onPrimary: Colors.white,
            surface: Color(0xFF1E293B),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        if (isExpiry) {
          _expiryDate = picked;
        } else {
          _publishDate = picked;
          if (_expiryDate != null && _expiryDate!.isBefore(picked)) {
            _expiryDate = picked;
          }
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if ((_selectedAudience == 'specific_student' || _selectedAudience == 'specific_lecturer') &&
        (_targetUserDocId == null || _targetUserName == null || _targetUserName!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a specific ${_selectedAudience == "specific_student" ? "student" : "lecturer"}.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_publishDate == null || _expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both Publish Date and Expiry Date.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Expiry Date Validation
    if (_expiryDate!.isBefore(DateTime(_publishDate!.year, _publishDate!.month, _publishDate!.day))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expiry Date cannot be earlier than Publish Date.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final announcement = AnnouncementModel(
        docId: widget.existingAnnouncement?.docId,
        announcementId: _announcementIdCtrl.text.trim(),
        title: _titleCtrl.text.trim(),
        description: _descriptionCtrl.text.trim(),
        audience: _selectedAudience,
        targetUserDocId: (_selectedAudience == 'specific_student' || _selectedAudience == 'specific_lecturer')
            ? _targetUserDocId
            : null,
        targetUserName: (_selectedAudience == 'specific_student' || _selectedAudience == 'specific_lecturer')
            ? _targetUserName
            : null,
        targetUserEmail: (_selectedAudience == 'specific_student' || _selectedAudience == 'specific_lecturer')
            ? _targetUserEmail
            : null,
        targetUserId: (_selectedAudience == 'specific_student' || _selectedAudience == 'specific_lecturer')
            ? _targetUserId
            : null,
        createdBy: _createdByCtrl.text.trim().isNotEmpty ? _createdByCtrl.text.trim() : 'Admin',
        publishDate: _formatDate(_publishDate!),
        expiryDate: _formatDate(_expiryDate!),
        createdDate: widget.existingAnnouncement?.createdDate ?? DateTime.now().toIso8601String(),
        updatedAt: _isEditMode ? DateTime.now().toIso8601String() : null,
        status: _selectedStatus,
      );

      if (_isEditMode) {
        await _announcementService.updateAnnouncement(announcement);
      } else {
        await _announcementService.addAnnouncement(announcement);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? 'Announcement updated successfully!' : 'Announcement created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving announcement: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
        title: Text(
          _isEditMode ? 'Edit Announcement' : 'Add Announcement',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // 1. ID & Creator Row
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _announcementIdCtrl,
                    label: 'Announcement ID',
                    hint: 'e.g. ANN-1001',
                    icon: Icons.tag_rounded,
                    suffix: _isGeneratingId
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.pinkAccent),
                          )
                        : null,
                    validator: (v) => v?.trim().isEmpty == true ? 'ID is required' : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildTextField(
                    controller: _createdByCtrl,
                    label: 'Created By',
                    hint: 'Admin Name',
                    icon: Icons.admin_panel_settings_rounded,
                    validator: (v) => v?.trim().isEmpty == true ? 'Creator is required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 2. Title
            _buildTextField(
              controller: _titleCtrl,
              label: 'Announcement Title *',
              hint: 'Enter notice headline or topic',
              icon: Icons.campaign_rounded,
              validator: (v) => v?.trim().isEmpty == true ? 'Title cannot be empty' : null,
            ),
            const SizedBox(height: 16),

            // 3. Description
            _buildTextField(
              controller: _descriptionCtrl,
              label: 'Announcement Content / Notice *',
              hint: 'Type full notice content, instructions, or details here...',
              icon: Icons.notes_rounded,
              maxLines: 5,
              validator: (v) => v?.trim().isEmpty == true ? 'Description cannot be empty' : null,
            ),
            const SizedBox(height: 20),

            // 4. Audience Selection Section
            _buildSectionHeader('Target Audience', Icons.group_rounded),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedAudience,
                  dropdownColor: const Color(0xFF1E293B),
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                  items: _audienceLabels.entries.map((e) {
                    return DropdownMenuItem<String>(
                      value: e.key,
                      child: Row(
                        children: [
                          Icon(
                            e.key == 'all_users'
                                ? Icons.groups_rounded
                                : (e.key.contains('student') ? Icons.school_rounded : Icons.cast_for_education_rounded),
                            size: 18,
                            color: e.key.contains('student') ? Colors.tealAccent : Colors.amberAccent,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            e.value,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedAudience = val;
                        if (!_selectedAudience.startsWith('specific')) {
                          _targetUserDocId = null;
                          _targetUserName = null;
                          _targetUserEmail = null;
                          _targetUserId = null;
                        }
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Conditional Specific User Dropdown
            if (_selectedAudience == 'specific_student' || _selectedAudience == 'specific_lecturer') ...[
              _buildSpecificUserDropdown(),
              const SizedBox(height: 20),
            ] else
              const SizedBox(height: 8),

            // 5. Schedule & Expiry Dates
            _buildSectionHeader('Publish & Expiry Schedule', Icons.calendar_month_rounded),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildDateTile(
                    label: 'Publish Date *',
                    date: _publishDate,
                    onTap: () => _pickDate(isExpiry: false),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildDateTile(
                    label: 'Expiry Date *',
                    date: _expiryDate,
                    isExpiry: true,
                    onTap: () => _pickDate(isExpiry: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 6. Status Picker (Draft vs Published)
            _buildSectionHeader('Publication Status', Icons.publish_rounded),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildStatusRadio(
                    value: 'published',
                    label: 'Published',
                    subtitle: 'Visible to target audience immediately',
                    icon: Icons.check_circle_rounded,
                    color: Colors.greenAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatusRadio(
                    value: 'draft',
                    label: 'Draft',
                    subtitle: 'Hidden from students and lecturers',
                    icon: Icons.edit_note_rounded,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEC4899),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.campaign_rounded, color: Colors.white),
                label: Text(
                  _isLoading
                      ? 'Saving...'
                      : (_isEditMode ? 'Update Announcement' : 'Publish Announcement'),
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFFF472B6)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSpecificUserDropdown() {
    final isStudent = _selectedAudience == 'specific_student';
    final collection = isStudent ? 'students' : 'lecturers';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Error loading users', style: TextStyle(color: Colors.redAccent));
        }
        if (!snapshot.hasData) {
          return Container(
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.pinkAccent),
              ),
            ),
          );
        }

        // Active only
        final docs = snapshot.data!.docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          final status = (data['status'] ?? 'active').toString().toLowerCase();
          return status == 'active';
        }).toList();

        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Text(
              'No active ${isStudent ? "students" : "lecturers"} found.',
              style: const TextStyle(color: Colors.grey),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.pinkAccent.withAlpha(80)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _targetUserDocId,
              hint: Text(
                'Select Active ${isStudent ? "Student" : "Lecturer"} *',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              dropdownColor: const Color(0xFF1E293B),
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
              items: docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = (data['name'] ?? data['fullName'] ?? 'Unnamed').toString();
                final id = (isStudent ? (data['studentId'] ?? '') : (data['lecturerId'] ?? '')).toString();

                return DropdownMenuItem<String>(
                  value: doc.id,
                  child: Row(
                    children: [
                      Icon(
                        isStudent ? Icons.school_rounded : Icons.cast_for_education_rounded,
                        size: 18,
                        color: isStudent ? Colors.tealAccent : Colors.amberAccent,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '$name ${id.isNotEmpty ? "($id)" : ""}',
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (docId) {
                if (docId == null) return;
                final selectedDoc = docs.firstWhere((d) => d.id == docId);
                final data = selectedDoc.data() as Map<String, dynamic>;
                setState(() {
                  _targetUserDocId = docId;
                  _targetUserName = (data['name'] ?? data['fullName'] ?? 'Unnamed').toString();
                  _targetUserEmail = (data['email'] ?? '').toString().toLowerCase();
                  _targetUserId = (isStudent ? (data['studentId'] ?? '') : (data['lecturerId'] ?? '')).toString();
                });
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateTile({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    bool isExpiry = false,
  }) {
    final dateStr = date != null ? _displayDate(date) : 'Select Date';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: isExpiry ? Colors.orangeAccent : Colors.pinkAccent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dateStr,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRadio({
    required String value,
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedStatus == value;
    return InkWell(
      onTap: () => setState(() => _selectedStatus = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.white10,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: isSelected ? color : Colors.grey, size: 18),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFFF472B6), size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEC4899), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
      validator: validator,
    );
  }
}
