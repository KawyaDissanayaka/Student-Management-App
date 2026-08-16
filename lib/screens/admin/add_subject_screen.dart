import 'package:flutter/material.dart';
import '../../models/subject_model.dart';
import '../../models/lecturer_model.dart';
import '../../services/subject_service.dart';
import '../../services/lecturer_service.dart';

class AddSubjectScreen extends StatefulWidget {
  const AddSubjectScreen({super.key});

  @override
  State<AddSubjectScreen> createState() => _AddSubjectScreenState();
}

class _AddSubjectScreenState extends State<AddSubjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _subjectIdController = TextEditingController();
  final TextEditingController _subjectCodeController = TextEditingController();
  final TextEditingController _subjectNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _selectedAcademicYear = 'Year 1';
  String _selectedSemester = 'Semester 1';
  String _selectedStatus = 'active';
  String _selectedLecturerName = 'Unassigned';
  String? _selectedLecturerId;
  bool _isLoading = false;

  final List<String> _years = ['Year 1', 'Year 2', 'Year 3', 'Year 4'];
  final List<String> _semesters = ['Semester 1', 'Semester 2'];

  @override
  void dispose() {
    _subjectIdController.dispose();
    _subjectCodeController.dispose();
    _subjectNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveSubject() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newSubject = SubjectModel(
        subjectId: _subjectIdController.text.trim(),
        subjectCode: _subjectCodeController.text.trim().toUpperCase(),
        subjectName: _subjectNameController.text.trim(),
        description: _descriptionController.text.trim(),
        semester: _selectedSemester,
        academicYear: _selectedAcademicYear,
        lecturerName: _selectedLecturerName,
        lecturerId: _selectedLecturerId,
        status: _selectedStatus,
      );

      await SubjectService().addSubject(newSubject);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Subject "${newSubject.subjectName}" created successfully!'),
            backgroundColor: Colors.indigo,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating subject: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text(
          'Add New Subject',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Badge
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.indigo.withAlpha(35),
                  borderRadius: BorderRadius.circular(14.0),
                  border: Border.all(color: Colors.indigo.withAlpha(80)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.book_rounded, color: Colors.indigoAccent, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create Course Module',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Assign active lecturers to subjects',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Subject ID & Code Row
              Row(
                children: [
                  Expanded(
                    child: _buildInputField(
                      controller: _subjectIdController,
                      label: 'Subject ID (e.g. SUB-301)',
                      icon: Icons.numbers_rounded,
                      validator: (val) => val == null || val.trim().isEmpty ? 'Enter ID' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInputField(
                      controller: _subjectCodeController,
                      label: 'Subject Code (e.g. CS204)',
                      icon: Icons.code_rounded,
                      validator: (val) => val == null || val.trim().isEmpty ? 'Enter Code' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Subject Name
              _buildInputField(
                controller: _subjectNameController,
                label: 'Subject Name',
                icon: Icons.menu_book_rounded,
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter subject name' : null,
              ),
              const SizedBox(height: 14),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Subject Description', Icons.description_rounded),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter description' : null,
              ),
              const SizedBox(height: 14),

              // Assign Lecturer Dropdown (Streams active lecturers from Firestore)
              StreamBuilder<List<LecturerModel>>(
                stream: LecturerService().getLecturersStream(),
                builder: (context, snapshot) {
                  final activeLecturers = (snapshot.data ?? [])
                      .where((l) => l.status.toLowerCase() == 'active')
                      .toList();

                  return DropdownButtonFormField<String>(
                    initialValue: _selectedLecturerId ?? 'none',
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Assign Lecturer', Icons.person_search_rounded),
                    items: [
                      const DropdownMenuItem(
                        value: 'none',
                        child: Text('Unassigned (Select Later)'),
                      ),
                      ...activeLecturers.map((lec) => DropdownMenuItem(
                            value: lec.docId ?? lec.lecturerId,
                            child: Text('${lec.name} (${lec.department})'),
                          )),
                    ],
                    onChanged: (val) {
                      if (val == 'none' || val == null) {
                        setState(() {
                          _selectedLecturerId = null;
                          _selectedLecturerName = 'Unassigned';
                        });
                      } else {
                        final found = activeLecturers.firstWhere(
                          (l) => (l.docId == val || l.lecturerId == val),
                          orElse: () => LecturerModel(lecturerId: '', name: 'Unassigned', email: '', department: ''),
                        );
                        setState(() {
                          _selectedLecturerId = val;
                          _selectedLecturerName = found.name;
                        });
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: 14),

              // Year & Semester Row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedAcademicYear,
                      dropdownColor: const Color(0xFF1E293B),
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Academic Year', Icons.calendar_today_rounded),
                      items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedAcademicYear = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedSemester,
                      dropdownColor: const Color(0xFF1E293B),
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Semester', Icons.bookmark_rounded),
                      items: _semesters.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedSemester = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Status Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedStatus,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Status', Icons.check_circle_outline_rounded),
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('Active (Visible for Enrollment)')),
                  DropdownMenuItem(value: 'inactive', child: Text('Inactive (Hidden from Enrollment)')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedStatus = val);
                },
              ),
              const SizedBox(height: 28),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveSubject,
                  icon: _isLoading
                      ? const SizedBox.shrink()
                      : const Icon(Icons.check_circle_rounded, color: Colors.white),
                  label: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          'Create Subject',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigoAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(label, icon),
      validator: validator,
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
      prefixIcon: Icon(icon, color: Colors.indigoAccent),
      filled: true,
      fillColor: const Color(0xFF1E293B),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.indigoAccent, width: 1.5),
      ),
    );
  }
}
