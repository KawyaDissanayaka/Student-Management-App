import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/task_model.dart';
import '../../services/task_service.dart';
import '../../services/auth_service.dart';

class AddEditTaskScreen extends StatefulWidget {
  final TaskModel? existingTask;

  const AddEditTaskScreen({super.key, this.existingTask});

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _taskService = TaskService();
  final _authService = AuthService();

  late final TextEditingController _taskIdCtrl;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _assignedByCtrl;

  // Selected Assigned User details
  String _assignedToType = 'student'; // 'student' | 'lecturer'
  String? _selectedUserDocId;
  String? _selectedUserName;
  String? _selectedUserEmail;
  String? _selectedUserId; // e.g. STU-1001 or LEC-1001

  String _selectedPriority = 'medium'; // 'low', 'medium', 'high', 'urgent'
  String _selectedStatus = 'pending'; // 'pending', 'in_progress', 'completed', 'overdue'

  DateTime? _startDate;
  DateTime? _dueDate;
  bool _isLoading = false;
  bool _isGeneratingId = false;

  bool get _isEditMode => widget.existingTask != null;
  bool get _isCompletedTask => widget.existingTask?.status.toLowerCase() == 'completed';

  final List<String> _priorityOptions = ['low', 'medium', 'high', 'urgent'];
  final List<String> _statusOptions = ['pending', 'in_progress', 'completed', 'overdue'];

  @override
  void initState() {
    super.initState();
    final t = widget.existingTask;
    _taskIdCtrl = TextEditingController(text: t?.taskId ?? '');
    _titleCtrl = TextEditingController(text: t?.title ?? '');
    _descriptionCtrl = TextEditingController(text: t?.description ?? '');
    
    final currentAdmin = _authService.currentUser;
    final adminName = currentAdmin?.displayName?.isNotEmpty == true
        ? currentAdmin!.displayName!
        : (currentAdmin?.email ?? 'Admin');
    _assignedByCtrl = TextEditingController(text: t?.assignedBy ?? adminName);

    if (t != null) {
      _assignedToType = t.assignedToType.toLowerCase() == 'lecturer' ? 'lecturer' : 'student';
      _selectedUserDocId = t.assignedToDocId;
      _selectedUserName = t.assignedToName;
      _selectedUserEmail = t.assignedToEmail;
      _selectedUserId = t.assignedToId;
      _selectedPriority = t.priority.toLowerCase();
      _selectedStatus = t.status.toLowerCase();
      if (t.startDate.isNotEmpty) _startDate = DateTime.tryParse(t.startDate);
      if (t.dueDate.isNotEmpty) _dueDate = DateTime.tryParse(t.dueDate);
    } else {
      _startDate = DateTime.now();
      _dueDate = DateTime.now().add(const Duration(days: 7));
      _autoFillTaskId();
    }
  }

  Future<void> _autoFillTaskId() async {
    setState(() => _isGeneratingId = true);
    try {
      final nextId = await _taskService.generateNextTaskId();
      if (mounted) {
        setState(() {
          _taskIdCtrl.text = nextId;
          _isGeneratingId = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isGeneratingId = false);
    }
  }

  @override
  void dispose() {
    _taskIdCtrl.dispose();
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _assignedByCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  String _displayDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  Color _priorityColor(String p) {
    switch (p.toLowerCase()) {
      case 'urgent':
        return Colors.redAccent;
      case 'high':
        return Colors.orangeAccent;
      case 'medium':
        return Colors.amberAccent;
      case 'low':
      default:
        return Colors.cyanAccent;
    }
  }

  Future<void> _pickDate({required bool isDue}) async {
    final now = DateTime.now();
    final firstDate = isDue ? (_startDate ?? DateTime(2020)) : DateTime(2020);
    final initial = isDue ? (_dueDate ?? _startDate ?? now) : (_startDate ?? now);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(firstDate) ? firstDate : initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF6366F1),
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
        if (isDue) {
          _dueDate = picked;
        } else {
          _startDate = picked;
          // If due date is earlier than start date, automatically adjust due date
          if (_dueDate != null && _dueDate!.isBefore(picked)) {
            _dueDate = picked;
          }
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedUserDocId == null || _selectedUserName == null || _selectedUserName!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select an assigned ${_assignedToType == 'student' ? 'Student' : 'Lecturer'}.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_startDate == null || _dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both Start Date and Due Date.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Due Date Validation
    if (_dueDate!.isBefore(DateTime(_startDate!.year, _startDate!.month, _startDate!.day))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Due Date cannot be earlier than Start Date.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final task = TaskModel(
        docId: widget.existingTask?.docId,
        taskId: _taskIdCtrl.text.trim(),
        title: _titleCtrl.text.trim(),
        description: _descriptionCtrl.text.trim(),
        assignedToType: _assignedToType,
        assignedToDocId: _selectedUserDocId!,
        assignedToName: _selectedUserName!,
        assignedToEmail: _selectedUserEmail ?? '',
        assignedToId: _selectedUserId ?? '',
        assignedBy: _assignedByCtrl.text.trim().isNotEmpty ? _assignedByCtrl.text.trim() : 'Admin',
        priority: _selectedPriority,
        startDate: _formatDate(_startDate!),
        dueDate: _formatDate(_dueDate!),
        createdDate: widget.existingTask?.createdDate ?? DateTime.now().toIso8601String(),
        status: _selectedStatus,
      );

      if (_isEditMode) {
        await _taskService.updateTask(task);
      } else {
        await _taskService.addTask(task);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? 'Task updated successfully!' : 'Task created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving task: $e'),
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
          _isEditMode ? 'Edit Task' : 'Add New Task',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Completed Task Warning Banner if editing completed task
            if (_isEditMode && _isCompletedTask)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.greenAccent.withAlpha(100)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_rounded, color: Colors.greenAccent, size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This task is marked as Completed. Assigned user cannot be altered.',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            // 1. Task ID & Assigned By Row
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _taskIdCtrl,
                    label: 'Task ID',
                    hint: 'e.g. TSK-1001',
                    icon: Icons.tag_rounded,
                    suffix: _isGeneratingId
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent),
                          )
                        : null,
                    validator: (v) => v?.trim().isEmpty == true ? 'Task ID is required' : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildTextField(
                    controller: _assignedByCtrl,
                    label: 'Assigned By',
                    hint: 'Admin Name',
                    icon: Icons.admin_panel_settings_rounded,
                    validator: (v) => v?.trim().isEmpty == true ? 'Creator is required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 2. Task Title
            _buildTextField(
              controller: _titleCtrl,
              label: 'Task Title *',
              hint: 'Enter task title or objective',
              icon: Icons.title_rounded,
              validator: (v) => v?.trim().isEmpty == true ? 'Task title is required' : null,
            ),
            const SizedBox(height: 16),

            // 3. Description
            _buildTextField(
              controller: _descriptionCtrl,
              label: 'Task Description *',
              hint: 'Describe instructions, deliverables, or checklist...',
              icon: Icons.notes_rounded,
              maxLines: 4,
              validator: (v) => v?.trim().isEmpty == true ? 'Description is required' : null,
            ),
            const SizedBox(height: 20),

            // 4. Assign To User Section
            _buildSectionHeader('Assign To', Icons.person_add_alt_1_rounded),
            const SizedBox(height: 10),

            // Toggle Role: Student / Lecturer
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: (_isEditMode && _isCompletedTask)
                          ? null
                          : () {
                              if (_assignedToType != 'student') {
                                setState(() {
                                  _assignedToType = 'student';
                                  _selectedUserDocId = null;
                                  _selectedUserName = null;
                                  _selectedUserEmail = null;
                                  _selectedUserId = null;
                                });
                              }
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _assignedToType == 'student'
                              ? const Color(0xFF0D9488)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.school_rounded,
                              size: 18,
                              color: _assignedToType == 'student' ? Colors.white : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Student',
                              style: TextStyle(
                                color: _assignedToType == 'student' ? Colors.white : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: (_isEditMode && _isCompletedTask)
                          ? null
                          : () {
                              if (_assignedToType != 'lecturer') {
                                setState(() {
                                  _assignedToType = 'lecturer';
                                  _selectedUserDocId = null;
                                  _selectedUserName = null;
                                  _selectedUserEmail = null;
                                  _selectedUserId = null;
                                });
                              }
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _assignedToType == 'lecturer'
                              ? const Color(0xFFD97706)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cast_for_education_rounded,
                              size: 18,
                              color: _assignedToType == 'lecturer' ? Colors.white : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Lecturer',
                              style: TextStyle(
                                color: _assignedToType == 'lecturer' ? Colors.white : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // User Dropdown Stream (Active only)
            _buildUserDropdown(),
            const SizedBox(height: 20),

            // 5. Priority & Status Row
            _buildSectionHeader('Priority & Status', Icons.flag_rounded),
            const SizedBox(height: 10),
            Row(
              children: [
                // Priority
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedPriority,
                        dropdownColor: const Color(0xFF1E293B),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                        isExpanded: true,
                        items: _priorityOptions.map((p) {
                          final color = _priorityColor(p);
                          return DropdownMenuItem<String>(
                            value: p,
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  p[0].toUpperCase() + p.substring(1),
                                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedPriority = val);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Status
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedStatus,
                        dropdownColor: const Color(0xFF1E293B),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                        isExpanded: true,
                        items: _statusOptions.map((s) {
                          String label = s.replaceAll('_', ' ');
                          label = label[0].toUpperCase() + label.substring(1);
                          return DropdownMenuItem<String>(
                            value: s,
                            child: Text(
                              label,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedStatus = val);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 6. Dates Section (Start Date & Due Date)
            _buildSectionHeader('Schedule & Deadline', Icons.calendar_today_rounded),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildDateTile(
                    label: 'Start Date',
                    date: _startDate,
                    onTap: () => _pickDate(isDue: false),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildDateTile(
                    label: 'Due Date *',
                    date: _dueDate,
                    isDue: true,
                    onTap: () => _pickDate(isDue: true),
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
                  backgroundColor: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded, color: Colors.white),
                label: Text(
                  _isLoading
                      ? 'Saving...'
                      : (_isEditMode ? 'Update Task' : 'Create Task'),
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
        Icon(icon, size: 18, color: const Color(0xFF818CF8)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildUserDropdown() {
    if (_isEditMode && _isCompletedTask) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Icon(
              _assignedToType == 'student' ? Icons.school_rounded : Icons.cast_for_education_rounded,
              color: _assignedToType == 'student' ? Colors.tealAccent : Colors.amberAccent,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$_selectedUserName (${_selectedUserId ?? ''})',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.lock_rounded, color: Colors.grey, size: 18),
          ],
        ),
      );
    }

    final collection = _assignedToType == 'student' ? 'students' : 'lecturers';
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Error loading users', style: TextStyle(color: Colors.redAccent));
        }
        if (!snapshot.hasData) {
          return Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: const Center(
              child: SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.indigoAccent),
              ),
            ),
          );
        }

        // Filter: ONLY ACTIVE USERS
        final rawDocs = snapshot.data!.docs;
        final docs = rawDocs.where((d) {
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
              'No active ${_assignedToType == 'student' ? 'students' : 'lecturers'} found.',
              style: const TextStyle(color: Colors.grey),
            ),
          );
        }

        // Check if current selection is still in the active list
        final hasSelected = docs.any((d) => d.id == _selectedUserDocId);
        if (!hasSelected && _selectedUserDocId != null && !_isEditMode) {
          _selectedUserDocId = null;
          _selectedUserName = null;
          _selectedUserEmail = null;
          _selectedUserId = null;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedUserDocId,
              hint: Text(
                'Select Active ${_assignedToType == 'student' ? 'Student' : 'Lecturer'}',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              dropdownColor: const Color(0xFF1E293B),
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
              items: docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = (data['name'] ?? data['fullName'] ?? 'Unnamed').toString();
                final id = (_assignedToType == 'student'
                    ? (data['studentId'] ?? '')
                    : (data['lecturerId'] ?? '')).toString();

                return DropdownMenuItem<String>(
                  value: doc.id,
                  child: Row(
                    children: [
                      Icon(
                        _assignedToType == 'student' ? Icons.person_rounded : Icons.person_pin_rounded,
                        size: 18,
                        color: _assignedToType == 'student' ? Colors.tealAccent : Colors.amberAccent,
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
                  _selectedUserDocId = docId;
                  _selectedUserName = (data['name'] ?? data['fullName'] ?? 'Unnamed').toString();
                  _selectedUserEmail = (data['email'] ?? '').toString().toLowerCase();
                  _selectedUserId = (_assignedToType == 'student'
                      ? (data['studentId'] ?? '')
                      : (data['lecturerId'] ?? '')).toString();
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
    bool isDue = false,
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
                  color: isDue ? Colors.orangeAccent : Colors.tealAccent,
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
        prefixIcon: Icon(icon, color: const Color(0xFF818CF8), size: 20),
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
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
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
