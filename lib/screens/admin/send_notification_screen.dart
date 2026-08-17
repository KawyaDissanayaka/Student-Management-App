import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import '../../services/auth_service.dart';

class SendNotificationScreen extends StatefulWidget {
  final NotificationModel? existingScheduledNotification;

  const SendNotificationScreen({super.key, this.existingScheduledNotification});

  @override
  State<SendNotificationScreen> createState() => _SendNotificationScreenState();
}

class _SendNotificationScreenState extends State<SendNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notificationService = NotificationService();
  final _authService = AuthService();

  late final TextEditingController _notificationIdCtrl;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _messageCtrl;
  late final TextEditingController _sentByCtrl;

  String _selectedType = 'general';
  String _selectedAudience = 'all_users';

  // Specific target user
  String? _targetUserDocId;
  String? _targetUserName;
  String? _targetUserEmail;
  String? _targetUserId;

  bool _isScheduled = false;
  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;

  bool _isLoading = false;
  bool _isGeneratingId = false;

  bool get _isEditMode => widget.existingScheduledNotification != null;

  final Map<String, String> _typeLabels = {
    'general': 'General Notice',
    'assignment': 'Assignment Alert',
    'task': 'Task Notice',
    'attendance': 'Attendance Warning',
    'announcement': 'Announcement',
    'system': 'System Alert',
  };

  final Map<String, IconData> _typeIcons = {
    'general': Icons.notifications_rounded,
    'assignment': Icons.assignment_rounded,
    'task': 'task' == 'task' ? Icons.task_alt_rounded : Icons.task_rounded,
    'attendance': Icons.calendar_month_rounded,
    'announcement': Icons.campaign_rounded,
    'system': Icons.settings_suggest_rounded,
  };

  final Map<String, Color> _typeColors = {
    'general': Colors.purpleAccent,
    'assignment': Colors.orangeAccent,
    'task': Colors.cyanAccent,
    'attendance': Colors.tealAccent,
    'announcement': Colors.pinkAccent,
    'system': Colors.amberAccent,
  };

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
    final n = widget.existingScheduledNotification;
    _notificationIdCtrl = TextEditingController(text: n?.notificationId ?? '');
    _titleCtrl = TextEditingController(text: n?.title ?? '');
    _messageCtrl = TextEditingController(text: n?.message ?? '');

    final currentAdmin = _authService.currentUser;
    final adminName = currentAdmin?.displayName?.isNotEmpty == true
        ? currentAdmin!.displayName!
        : (currentAdmin?.email ?? 'Admin');
    _sentByCtrl = TextEditingController(text: n?.sentBy ?? adminName);

    if (n != null) {
      _selectedType = n.type;
      _selectedAudience = n.audience;
      _targetUserDocId = n.targetUserDocId;
      _targetUserName = n.targetUserName;
      _targetUserEmail = n.targetUserEmail;
      _targetUserId = n.targetUserId;
      if (n.scheduledDate != null && n.scheduledDate!.isNotEmpty) {
        try {
          final dt = DateTime.parse(n.scheduledDate!);
          _isScheduled = true;
          _scheduledDate = dt;
          _scheduledTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
        } catch (_) {}
      }
    } else {
      _autoFillNotificationId();
    }
  }

  Future<void> _autoFillNotificationId() async {
    setState(() => _isGeneratingId = true);
    try {
      final nextId = await _notificationService.generateNextNotificationId();
      if (mounted) {
        setState(() {
          _notificationIdCtrl.text = nextId;
          _isGeneratingId = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isGeneratingId = false);
    }
  }

  @override
  void dispose() {
    _notificationIdCtrl.dispose();
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    _sentByCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickScheduledDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? now,
      firstDate: now,
      lastDate: DateTime(2035),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFA855F7),
            onPrimary: Colors.white,
            surface: Color(0xFF1E293B),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() => _scheduledDate = picked);
    }
  }

  Future<void> _pickScheduledTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _scheduledTime ?? TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFA855F7),
            onPrimary: Colors.white,
            surface: Color(0xFF1E293B),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() => _scheduledTime = picked);
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

    DateTime? finalScheduledDateTime;
    if (_isScheduled) {
      if (_scheduledDate == null || _scheduledTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select both scheduled date and time.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      finalScheduledDateTime = DateTime(
        _scheduledDate!.year,
        _scheduledDate!.month,
        _scheduledDate!.day,
        _scheduledTime!.hour,
        _scheduledTime!.minute,
      );

      if (finalScheduledDateTime.isBefore(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Scheduled time cannot be in the past.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final notification = NotificationModel(
        docId: widget.existingScheduledNotification?.docId,
        notificationId: _notificationIdCtrl.text.trim(),
        title: _titleCtrl.text.trim(),
        message: _messageCtrl.text.trim(),
        type: _selectedType,
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
        sentBy: _sentByCtrl.text.trim().isNotEmpty ? _sentByCtrl.text.trim() : 'Admin',
        sentDate: _isScheduled ? '' : DateTime.now().toIso8601String(),
        scheduledDate: _isScheduled ? finalScheduledDateTime?.toIso8601String() : null,
        createdDate: widget.existingScheduledNotification?.createdDate ?? DateTime.now().toIso8601String(),
        status: _isScheduled ? 'scheduled' : 'sent',
      );

      if (_isEditMode) {
        await _notificationService.updateNotification(notification);
      } else {
        await _notificationService.sendNotification(notification);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isScheduled
                ? 'Notification scheduled successfully!'
                : 'Notification delivered successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
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
          _isEditMode ? 'Edit Scheduled Notification' : 'Send Notification',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // 1. ID & Sender
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _notificationIdCtrl,
                    label: 'Notification ID',
                    hint: 'e.g. NTF-1001',
                    icon: Icons.tag_rounded,
                    suffix: _isGeneratingId
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.purpleAccent),
                          )
                        : null,
                    validator: (v) => v?.trim().isEmpty == true ? 'ID is required' : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildTextField(
                    controller: _sentByCtrl,
                    label: 'Sent By',
                    hint: 'Admin Name',
                    icon: Icons.admin_panel_settings_rounded,
                    validator: (v) => v?.trim().isEmpty == true ? 'Sender is required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 2. Notification Type Section
            _buildSectionHeader('Notification Type', Icons.category_rounded),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _typeLabels.entries.map((e) {
                  final isSelected = _selectedType == e.key;
                  final color = _typeColors[e.key] ?? Colors.purpleAccent;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: isSelected,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_typeIcons[e.key] ?? Icons.notifications_rounded, size: 16, color: isSelected ? Colors.white : color),
                          const SizedBox(width: 6),
                          Text(e.value),
                        ],
                      ),
                      selectedColor: color.withAlpha(200),
                      backgroundColor: const Color(0xFF1E293B),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedType = e.key);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // 3. Title
            _buildTextField(
              controller: _titleCtrl,
              label: 'Notification Title *',
              hint: 'Enter notification headline',
              icon: Icons.title_rounded,
              validator: (v) => v?.trim().isEmpty == true ? 'Title cannot be empty' : null,
            ),
            const SizedBox(height: 16),

            // 4. Message
            _buildTextField(
              controller: _messageCtrl,
              label: 'Message / Alert Body *',
              hint: 'Type notification message here...',
              icon: Icons.chat_bubble_outline_rounded,
              maxLines: 4,
              validator: (v) => v?.trim().isEmpty == true ? 'Message cannot be empty' : null,
            ),
            const SizedBox(height: 20),

            // 5. Audience Section
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

            // Specific User Dropdown (Active only)
            if (_selectedAudience == 'specific_student' || _selectedAudience == 'specific_lecturer') ...[
              _buildSpecificUserDropdown(),
              const SizedBox(height: 20),
            ] else
              const SizedBox(height: 8),

            // 6. Timing Section (Send Immediately vs Schedule)
            _buildSectionHeader('Delivery Timing', Icons.schedule_send_rounded),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildTimingRadio(
                    isScheduled: false,
                    label: 'Send Now',
                    subtitle: 'Immediate delivery',
                    icon: Icons.send_rounded,
                    color: Colors.greenAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTimingRadio(
                    isScheduled: true,
                    label: 'Schedule Later',
                    subtitle: 'Future date & time',
                    icon: Icons.schedule_rounded,
                    color: Colors.purpleAccent,
                  ),
                ),
              ],
            ),

            if (_isScheduled) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickScheduledDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.purpleAccent.withAlpha(100)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Date', style: TextStyle(color: Colors.grey, fontSize: 11)),
                            const SizedBox(height: 4),
                            Text(
                              _scheduledDate != null
                                  ? '${_scheduledDate!.day}/${_scheduledDate!.month}/${_scheduledDate!.year}'
                                  : 'Select Date',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _pickScheduledTime,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.purpleAccent.withAlpha(100)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Time', style: TextStyle(color: Colors.grey, fontSize: 11)),
                            const SizedBox(height: 4),
                            Text(
                              _scheduledTime != null
                                  ? _scheduledTime!.format(context)
                                  : 'Select Time',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA855F7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Icon(_isScheduled ? Icons.schedule_send_rounded : Icons.send_rounded, color: Colors.white),
                label: Text(
                  _isLoading
                      ? 'Processing...'
                      : (_isScheduled
                          ? (_isEditMode ? 'Update Schedule' : 'Schedule Notification')
                          : 'Send Notification Now'),
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
        Icon(icon, size: 18, color: const Color(0xFFC084FC)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTimingRadio({
    required bool isScheduled,
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _isScheduled == isScheduled;
    return InkWell(
      onTap: () => setState(() => _isScheduled = isScheduled),
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
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.purpleAccent),
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
            border: Border.all(color: Colors.purpleAccent.withAlpha(80)),
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
        prefixIcon: Icon(icon, color: const Color(0xFFC084FC), size: 20),
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
          borderSide: const BorderSide(color: Color(0xFFA855F7), width: 1.5),
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
