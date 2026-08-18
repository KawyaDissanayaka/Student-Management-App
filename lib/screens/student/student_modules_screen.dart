import 'package:flutter/material.dart';
import '../../services/enrollment_service.dart';
import '../../models/enrollment_model.dart';
import 'module_detail_screen.dart';
import 'student_module_registration_screen.dart';

class StudentModulesScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const StudentModulesScreen({super.key, this.userData});

  @override
  State<StudentModulesScreen> createState() => _StudentModulesScreenState();
}

class _StudentModulesScreenState extends State<StudentModulesScreen> {
  final EnrollmentService _enrollmentService = EnrollmentService();
  String _selectedSemester = 'All';

  @override
  Widget build(BuildContext context) {
    final email = widget.userData?['email'] ?? '';
    final name = widget.userData?['fullName'] ?? 'Student';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.book_rounded, color: Colors.tealAccent),
            SizedBox(width: 8),
            Text('My Enrolled Modules', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StudentModuleRegistrationScreen(userData: widget.userData),
                ),
              );
            },
            icon: const Icon(Icons.add_task_rounded, color: Colors.tealAccent, size: 16),
            label: const Text('Register', style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF1E293B),
            child: Row(
              children: [
                const Icon(Icons.filter_list_rounded, color: Colors.grey, size: 18),
                const SizedBox(width: 8),
                const Text('Semester: ', style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedSemester,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 13),
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All Semesters')),
                    DropdownMenuItem(value: 'Semester 1', child: Text('Semester 1')),
                    DropdownMenuItem(value: 'Semester 2', child: Text('Semester 2')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedSemester = val);
                  },
                ),
              ],
            ),
          ),

          // Enrolled Modules List
          Expanded(
            child: StreamBuilder<List<EnrollmentModel>>(
              stream: _enrollmentService.getStudentActiveEnrollmentsStream(email),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
                }

                final allEnrollments = snapshot.data ?? [];
                final enrollments = allEnrollments.where((e) {
                  if (_selectedSemester == 'All') return true;
                  return e.semester == _selectedSemester;
                }).toList();

                if (enrollments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.menu_book_rounded, size: 56, color: Colors.grey.withAlpha(100)),
                        const SizedBox(height: 14),
                        const Text('No enrolled modules found.', style: TextStyle(color: Colors.white70, fontSize: 16)),
                        const SizedBox(height: 6),
                        const Text('Register for subjects in Module Registration.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: enrollments.length,
                  itemBuilder: (context, index) {
                    final e = enrollments[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ModuleDetailScreen(
                              subjectCode: e.subjectCode,
                              subjectName: e.subjectName,
                              lecturerName: e.lecturerName,
                              semester: e.semester,
                              studentEmail: email,
                              studentName: name,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.withAlpha(30),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.tealAccent.withAlpha(80)),
                                  ),
                                  child: Text(
                                    e.subjectCode,
                                    style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withAlpha(30),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    e.status.toUpperCase(),
                                    style: const TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              e.subjectName,
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  e.lecturerName.isNotEmpty ? e.lecturerName : 'Faculty Staff',
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                                const Spacer(),
                                Text(
                                  '${e.semester} • ${e.academicYear}',
                                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(color: Colors.white10, height: 1),
                            const SizedBox(height: 8),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text('View Materials & Assignments', style: TextStyle(color: Colors.tealAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward_ios_rounded, color: Colors.tealAccent, size: 12),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
