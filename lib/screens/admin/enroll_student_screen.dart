import 'package:flutter/material.dart';
import '../../models/student_model.dart';
import '../../models/subject_model.dart';
import '../../models/enrollment_model.dart';
import '../../services/student_service.dart';
import '../../services/subject_service.dart';
import '../../services/enrollment_service.dart';

class EnrollStudentScreen extends StatefulWidget {
  const EnrollStudentScreen({super.key});

  @override
  State<EnrollStudentScreen> createState() => _EnrollStudentScreenState();
}

class _EnrollStudentScreenState extends State<EnrollStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _enrollmentService = EnrollmentService();

  String? _selectedStudentDocId;
  StudentModel? _selectedStudent;

  String? _selectedSubjectDocId;
  SubjectModel? _selectedSubject;

  String _selectedSemester = 'Semester 1';
  String _selectedAcademicYear = '2026'; // Default as per user's example
  bool _isLoading = false;

  final List<String> _semesters = ['Semester 1', 'Semester 2'];
  final List<String> _academicYears = ['2025', '2026', '2027', '2028', 'Year 1', 'Year 2', 'Year 3', 'Year 4'];

  Future<void> _submitEnrollment() async {
    if (!_formKey.currentState!.validate() || _selectedStudent == null || _selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both a student and a subject.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final newEnrollment = EnrollmentModel(
        studentDocId: _selectedStudent!.docId ?? '',
        studentId: _selectedStudent!.studentId,
        studentName: _selectedStudent!.name,
        studentEmail: _selectedStudent!.email,
        subjectDocId: _selectedSubject!.docId ?? '',
        subjectCode: _selectedSubject!.subjectCode,
        subjectName: _selectedSubject!.subjectName,
        lecturerName: _selectedSubject!.lecturerName,
        semester: _selectedSemester,
        academicYear: _selectedAcademicYear,
        enrollmentDate: DateTime.now().toIso8601String(),
        status: 'active',
      );

      await _enrollmentService.enrollStudent(newEnrollment);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Enrolled ${_selectedStudent!.name} in ${_selectedSubject!.subjectName} successfully!'),
            backgroundColor: Colors.teal,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Enrollment failed: ${e.toString().replaceAll('Exception:', '')}'),
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
          'Enroll Student',
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
                  color: Colors.teal.withAlpha(35),
                  borderRadius: BorderRadius.circular(14.0),
                  border: Border.all(color: Colors.teal.withAlpha(80)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.grade_rounded, color: Colors.tealAccent, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Assign Subject to Student',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Enroll students in subjects for specific semesters & academic years.',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Select Student Dropdown (Only Active Students)
              StreamBuilder<List<StudentModel>>(
                stream: StudentService().getStudentsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: CircularProgressIndicator(color: Colors.tealAccent),
                    );
                  }
                  final activeStudents = (snapshot.data ?? [])
                      .where((s) => s.status.toLowerCase() == 'active')
                      .toList();

                  return DropdownButtonFormField<String>(
                    initialValue: _selectedStudentDocId,
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Select Student', Icons.person_rounded),
                    items: activeStudents.map((student) {
                      return DropdownMenuItem(
                        value: student.docId,
                        child: Text('${student.name} (${student.studentId})'),
                      );
                    }).toList(),
                    validator: (val) => val == null ? 'Please select a student' : null,
                    onChanged: (val) {
                      setState(() {
                        _selectedStudentDocId = val;
                        _selectedStudent = activeStudents.firstWhere((s) => s.docId == val);
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 16),

              // Select Subject Dropdown (Only Active Subjects)
              StreamBuilder<List<SubjectModel>>(
                stream: SubjectService().getSubjectsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: CircularProgressIndicator(color: Colors.tealAccent),
                    );
                  }
                  final activeSubjects = (snapshot.data ?? [])
                      .where((sub) => sub.status.toLowerCase() == 'active')
                      .toList();

                  return DropdownButtonFormField<String>(
                    initialValue: _selectedSubjectDocId,
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Select Subject', Icons.menu_book_rounded),
                    items: activeSubjects.map((sub) {
                      return DropdownMenuItem(
                        value: sub.docId,
                        child: Text('${sub.subjectName} (${sub.subjectCode})'),
                      );
                    }).toList(),
                    validator: (val) => val == null ? 'Please select a subject' : null,
                    onChanged: (val) {
                      setState(() {
                        _selectedSubjectDocId = val;
                        _selectedSubject = activeSubjects.firstWhere((sub) => sub.docId == val);
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 16),

              // Semester Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedSemester,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Select Semester', Icons.bookmark_rounded),
                items: _semesters.map((sem) {
                  return DropdownMenuItem(
                    value: sem,
                    child: Text(sem),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedSemester = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Academic Year Dropdown / Autocomplete
              DropdownButtonFormField<String>(
                initialValue: _selectedAcademicYear,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Academic Year', Icons.calendar_today_rounded),
                items: _academicYears.map((year) {
                  return DropdownMenuItem(
                    value: year,
                    child: Text(year),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedAcademicYear = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 32),

              // Confirm/Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitEnrollment,
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
                          'Confirm Enrollment',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
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

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
      prefixIcon: Icon(icon, color: Colors.tealAccent),
      filled: true,
      fillColor: const Color(0xFF1E293B),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.tealAccent, width: 1.5),
      ),
    );
  }
}
