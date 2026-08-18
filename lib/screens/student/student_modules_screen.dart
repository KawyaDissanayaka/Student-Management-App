import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/student_module_registration_service.dart';
import '../../services/attendance_service.dart';
import '../../models/student_module_registration_model.dart';
import '../../models/attendance_model.dart';
import '../../models/exam_result_model.dart';
import 'module_detail_screen.dart';
import 'student_module_registration_screen.dart';

class StudentModulesScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const StudentModulesScreen({super.key, this.userData});

  @override
  State<StudentModulesScreen> createState() => _StudentModulesScreenState();
}

class _StudentModulesScreenState extends State<StudentModulesScreen> {
  final StudentModuleRegistrationService _regService = StudentModuleRegistrationService();
  final AttendanceService _attendanceService = AttendanceService();
  String _selectedSemester = 'All';

  @override
  Widget build(BuildContext context) {
    final email = widget.userData?['email'] ?? '';
    final studentId = widget.userData?['studentId'] ?? 'STU-1002';
    final name = widget.userData?['fullName'] ?? widget.userData?['name'] ?? 'Student';

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

          // Enrolled Modules List (Approved Only)
          Expanded(
            child: StreamBuilder<List<StudentModuleRegistrationModel>>(
              stream: _regService.getStudentRegistrationsStream(
                studentId: studentId,
                studentEmail: email,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
                }

                final allRegistrations = snapshot.data ?? [];
                // Security rule: Only display modules that have an Approved registration status
                final approvedModules = allRegistrations.where((r) {
                  final isApproved = r.isApproved;
                  final matchesSem = _selectedSemester == 'All' || r.semester.toLowerCase() == _selectedSemester.toLowerCase();
                  return isApproved && matchesSem;
                }).toList();

                if (approvedModules.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.menu_book_rounded, size: 56, color: Colors.grey.withAlpha(100)),
                          const SizedBox(height: 14),
                          const Text('No Approved Modules Found', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 6),
                          Text(
                            allRegistrations.any((r) => r.isPending)
                                ? 'Your module registrations are currently awaiting Admin approval.'
                                : 'You have not registered for any modules in this semester.\nTap "Register" above to enroll.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return StreamBuilder<List<AttendanceModel>>(
                  stream: _attendanceService.getStudentAttendanceStream(email),
                  builder: (context, attSnapshot) {
                    final allAttendance = attSnapshot.data ?? [];

                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('exam_results')
                          .where('studentId', isEqualTo: studentId)
                          .where('isPublished', isEqualTo: true)
                          .snapshots(),
                      builder: (context, resultSnapshot) {
                        final publishedResults = (resultSnapshot.data?.docs ?? [])
                            .map((d) => ExamResultModel.fromFirestore(d))
                            .toList();

                        return ListView.builder(
                          padding: const EdgeInsets.all(14),
                          itemCount: approvedModules.length,
                          itemBuilder: (context, index) {
                            final reg = approvedModules[index];

                            // 1. Calculate live module attendance percentage
                            final moduleAttendance = allAttendance.where((a) => a.subjectCode.toUpperCase() == reg.moduleId.toUpperCase() && a.status != 'cancelled').toList();
                            final totalClasses = moduleAttendance.length;
                            final attendedCount = moduleAttendance.where((a) => a.status == 'present' || a.status == 'late').length;
                            final attPct = totalClasses > 0 ? (attendedCount / totalClasses) * 100 : 100.0;

                            // 2. Find published exam grade if available
                            final examResult = publishedResults.cast<ExamResultModel?>().firstWhere(
                                  (r) => r?.moduleCode.toUpperCase() == reg.moduleId.toUpperCase(),
                                  orElse: () => null,
                                );

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ModuleDetailScreen(
                                      subjectCode: reg.moduleId,
                                      subjectName: reg.moduleName,
                                      lecturerName: 'Assigned Faculty Lecturer',
                                      semester: reg.semester,
                                      credits: reg.credits,
                                      studentEmail: email,
                                      studentName: name,
                                      studentId: studentId,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.teal.withAlpha(50)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(4)),
                                              child: Text(reg.moduleId, style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'monospace')),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(color: Colors.cyan.withAlpha(30), borderRadius: BorderRadius.circular(4)),
                                              child: Text(reg.moduleType, style: const TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(color: Colors.green.withAlpha(30), borderRadius: BorderRadius.circular(4)),
                                          child: const Text('APPROVED', style: TextStyle(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    Text(reg.moduleName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                    const SizedBox(height: 4),
                                    Text('${reg.credits} Credits • ${reg.semester} (${reg.academicYear})', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                    const SizedBox(height: 10),

                                    // Metrics Row: Attendance % and Published Grade
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.pie_chart_rounded, size: 14, color: attPct >= 80 ? Colors.greenAccent : Colors.redAccent),
                                              const SizedBox(width: 4),
                                              Text('Attendance: ${totalClasses > 0 ? "${attPct.toStringAsFixed(0)}%" : "100% (New)"}', style: TextStyle(color: attPct >= 80 ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              const Icon(Icons.grade_rounded, size: 14, color: Colors.amberAccent),
                                              const SizedBox(width: 4),
                                              Text(
                                                examResult != null ? 'Grade: ${examResult.grade} (${examResult.gradePoint.toStringAsFixed(1)})' : 'Grade: Pending',
                                                style: TextStyle(color: examResult != null ? Colors.amberAccent : Colors.white60, fontWeight: FontWeight.bold, fontSize: 11),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    const Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text('View Module Details', style: TextStyle(color: Colors.tealAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                                        SizedBox(width: 4),
                                        Icon(Icons.arrow_forward_ios_rounded, color: Colors.tealAccent, size: 10),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
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
