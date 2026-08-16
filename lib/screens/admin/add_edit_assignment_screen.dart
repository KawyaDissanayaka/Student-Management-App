import 'package:flutter/material.dart';
import '../../models/assignment_model.dart';
import '../../models/subject_model.dart';
import '../../services/assignment_service.dart';
import '../../services/subject_service.dart';
import '../../services/auth_service.dart';

class AddEditAssignmentScreen extends StatefulWidget {
  final AssignmentModel? existingAssignment;

  const AddEditAssignmentScreen({super.key, this.existingAssignment});

  @override
  State<AddEditAssignmentScreen> createState() => _AddEditAssignmentScreenState();
}

class _AddEditAssignmentScreenState extends State<AddEditAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _assignmentService = AssignmentService();
  final _subjectService = SubjectService();
  final _authService = AuthService();

  // Controllers
  late final TextEditingController _assignmentIdCtrl;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _attachmentCtrl;

  // State
  SubjectModel? _selectedSubject;
  String? _selectedSubjectDocId;
  DateTime? _startDate;
  DateTime? _dueDate;
  String _selectedStatus = 'draft';
  bool _isLoading = false;
  bool _hasSubmissions = false;

  bool get _isEditMode => widget.existingAssignment != null;

  final List<String> _statusOptions = ['draft', 'published', 'closed', 'deactivated'];

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  String _displayDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  void initState() {
    super.initState();
    final e = widget.existingAssignment;
    _assignmentIdCtrl = TextEditingController(text: e?.assignmentId ?? '');
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _descriptionCtrl = TextEditingController(text: e?.description ?? '');
    _attachmentCtrl = TextEditingController(text: e?.attachmentUrl ?? '');
    _selectedStatus = e?.status ?? 'draft';
    _selectedSubjectDocId = e?.subjectDocId.isNotEmpty == true ? e?.subjectDocId : null;

    if (e != null) {
      if (e.startDate.isNotEmpty) _startDate = DateTime.tryParse(e.startDate);
      if (e.dueDate.isNotEmpty) _dueDate = DateTime.tryParse(e.dueDate);
      _checkExistingSubmissions();
    }
  }

  Future<void> _checkExistingSubmissions() async {
    if (widget.existingAssignment?.docId == null) return;
    try {
      final count = await AssignmentService()
          .getSubmissionsForAssignment(widget.existingAssignment!.docId!)
          .first
          .then((list) => list.length);
      if (mounted) setState(() => _hasSubmissions = count > 0);
    } catch (_) {}
  }

  @override
  void dispose() {
    _assignmentIdCtrl.dispose();
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _attachmentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isDue}) async {
    final now = DateTime.now();
    final firstDate = isDue ? (_startDate ?? now) : now;
    final initial = isDue
        ? (_dueDate ?? _startDate ?? now)
        : (_startDate ?? now);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(firstDate) ? firstDate : initial,
      firstDate: firstDate,
      lastDate: DateTime(2035),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Colors.orangeAccent,
            onPrimary: Colors.black,
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
          // Reset due date if it's now before start date
          if (_dueDate != null && _dueDate!.isBefore(picked)) {
            _dueDate = null;
          }
        }
      });
    }
  }

  Future<void> _save(SubjectModel? subjectFromStream) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSubject == null && subjectFromStream == null && _selectedSubjectDocId == null) {
      _showSnack('Please select a subject.', Colors.orangeAccent);
      return;
    }
    if (_startDate == null) {
      _showSnack('Please select a start date.', Colors.orangeAccent);
      return;
    }
    if (_dueDate == null) {
      _showSnack('Please select a due date.', Colors.orangeAccent);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final subject = _selectedSubject ?? subjectFromStream;
      final now = DateTime.now().toIso8601String();
      final adminEmail = _authService.currentUser?.email ?? 'admin@system.com';

      final assignment = AssignmentModel(
        docId: widget.existingAssignment?.docId,
        assignmentId: _assignmentIdCtrl.text.trim(),
        title: _titleCtrl.text.trim(),
        description: _descriptionCtrl.text.trim(),
        subjectDocId: subject?.docId ?? widget.existingAssignment?.subjectDocId ?? '',
        subjectCode: subject?.subjectCode ?? widget.existingAssignment?.subjectCode ?? '',
        subjectName: subject?.subjectName ?? widget.existingAssignment?.subjectName ?? '',
        lecturerName: subject?.lecturerName ?? widget.existingAssignment?.lecturerName ?? '',
        createdBy: _isEditMode
            ? (widget.existingAssignment?.createdBy ?? adminEmail)
            : adminEmail,
        createdDate: _isEditMode
            ? (widget.existingAssignment?.createdDate ?? now)
            : now,
        startDate: _formatDate(_startDate!),
        dueDate: _formatDate(_dueDate!),
        attachmentUrl: _attachmentCtrl.text.trim().isEmpty ? null : _attachmentCtrl.text.trim(),
        status: _selectedStatus,
        semester: subject?.semester ?? widget.existingAssignment?.semester ?? '',
        academicYear: subject?.academicYear ?? widget.existingAssignment?.academicYear ?? '',
      );

      if (_isEditMode) {
        await _assignmentService.updateAssignment(assignment);
        _showSnack('"${assignment.title}" updated!', Colors.indigo);
      } else {
        await _assignmentService.addAssignment(assignment);
        _showSnack('"${assignment.title}" created!', Colors.orange[800]!);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showSnack('Error: $e', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SubjectModel>>(
      stream: _subjectService.getSubjectsStream(),
      builder: (context, subjectsSnap) {
        final activeSubjects = (subjectsSnap.data ?? [])
            .where((s) => s.status.toLowerCase() == 'active')
            .toList();

        // Resolve subject in edit mode from stream
        SubjectModel? resolvedSubject;
        if (_selectedSubjectDocId != null && _selectedSubject == null) {
          try {
            resolvedSubject = activeSubjects.firstWhere(
              (s) => s.docId == _selectedSubjectDocId,
            );
          } catch (_) {}
        }
        final displaySubject = _selectedSubject ?? resolvedSubject;

        return Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E293B),
            elevation: 0,
            title: Text(
              _isEditMode ? 'Edit Assignment' : 'Add Assignment',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(25),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.orangeAccent.withAlpha(80)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.assignment_rounded, color: Colors.orangeAccent, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isEditMode ? 'Edit Assignment' : 'Create New Assignment',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Published assignments are visible to enrolled students',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Assignment ID & Status Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _assignmentIdCtrl,
                          label: 'Assignment ID (e.g. ASN-001)',
                          icon: Icons.tag_rounded,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedStatus,
                          dropdownColor: const Color(0xFF1E293B),
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDeco('Status', Icons.info_outline_rounded),
                          items: _statusOptions.map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(
                              s[0].toUpperCase() + s.substring(1),
                              style: TextStyle(color: _statusColor(s)),
                            ),
                          )).toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _selectedStatus = v);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Title
                  _buildTextField(
                    controller: _titleCtrl,
                    label: 'Assignment Title',
                    icon: Icons.title_rounded,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Title required' : null,
                  ),
                  const SizedBox(height: 14),

                  // Description
                  TextFormField(
                    controller: _descriptionCtrl,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDeco('Description', Icons.description_rounded),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Description required' : null,
                  ),
                  const SizedBox(height: 14),

                  // Subject Dropdown
                  if (_isEditMode && _hasSubmissions)
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.amber.withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amberAccent.withAlpha(100)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.amberAccent, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Subject cannot be changed — existing submissions found.',
                              style: TextStyle(color: Colors.amber, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),

                  DropdownButtonFormField<String>(
                    initialValue: _selectedSubjectDocId,
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDeco('Select Subject (Active Only)', Icons.book_rounded),
                    items: activeSubjects.map((sub) => DropdownMenuItem(
                      value: sub.docId,
                      child: Text('${sub.subjectName} (${sub.subjectCode})'),
                    )).toList(),
                    onChanged: (_isEditMode && _hasSubmissions)
                        ? null
                        : (val) {
                            if (val != null) {
                              final found = activeSubjects.firstWhere((s) => s.docId == val);
                              setState(() {
                                _selectedSubjectDocId = val;
                                _selectedSubject = found;
                              });
                            }
                          },
                    validator: (v) => v == null ? 'Please select a subject' : null,
                  ),
                  const SizedBox(height: 14),

                  // Auto-filled fields from subject
                  if (displaySubject != null) ...[
                    _infoTile(Icons.person_rounded, 'Lecturer', displaySubject.lecturerName),
                    const SizedBox(height: 8),
                    _infoTile(Icons.bookmark_rounded, 'Semester', '${displaySubject.semester} • ${displaySubject.academicYear}'),
                    const SizedBox(height: 14),
                  ],

                  // Admin info
                  _infoTile(
                    Icons.admin_panel_settings_rounded,
                    'Created By',
                    _isEditMode
                        ? (widget.existingAssignment?.createdBy ?? _authService.currentUser?.email ?? 'Admin')
                        : (_authService.currentUser?.email ?? 'Admin'),
                  ),
                  const SizedBox(height: 14),

                  // Start & Due Date Pickers
                  Row(
                    children: [
                      Expanded(child: _buildDatePicker(
                        label: 'Start Date',
                        icon: Icons.play_arrow_rounded,
                        date: _startDate,
                        color: Colors.tealAccent,
                        onTap: () => _pickDate(isDue: false),
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _buildDatePicker(
                        label: 'Due Date',
                        icon: Icons.alarm_rounded,
                        date: _dueDate,
                        color: Colors.orangeAccent,
                        onTap: () => _pickDate(isDue: true),
                      )),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Attachment URL
                  _buildTextField(
                    controller: _attachmentCtrl,
                    label: 'Attachment URL (optional)',
                    icon: Icons.link_rounded,
                    isRequired: false,
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : () => _save(displaySubject),
                      icon: _isLoading
                          ? const SizedBox.shrink()
                          : Icon(
                              _isEditMode ? Icons.save_rounded : Icons.check_circle_rounded,
                              color: Colors.white,
                            ),
                      label: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : Text(
                              _isEditMode ? 'Save Changes' : 'Create Assignment',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    bool isRequired = true,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDeco(label, icon),
      validator: isRequired
          ? (validator ?? (v) => v == null || v.trim().isEmpty ? 'Required' : null)
          : null,
    );
  }

  Widget _buildDatePicker({
    required String label,
    required IconData icon,
    required DateTime? date,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: date != null ? color.withAlpha(120) : Colors.white10,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(
                    date != null ? _displayDate(date) : 'Select date',
                    style: TextStyle(
                      color: date != null ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.orangeAccent, size: 18),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
      prefixIcon: Icon(icon, color: Colors.orangeAccent),
      filled: true,
      fillColor: const Color(0xFF1E293B),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.orangeAccent, width: 1.5),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'published': return Colors.greenAccent;
      case 'closed': return Colors.amberAccent;
      case 'deactivated': return Colors.redAccent;
      default: return Colors.grey;
    }
  }
}
