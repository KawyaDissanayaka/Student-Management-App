import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/student_portal_service.dart';
import '../../services/enrollment_service.dart';
import '../../models/subject_model.dart';
import '../../models/enrollment_model.dart';

class StudentRegistrationScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const StudentRegistrationScreen({super.key, this.userData});

  @override
  State<StudentRegistrationScreen> createState() => _StudentRegistrationScreenState();
}

class _StudentRegistrationScreenState extends State<StudentRegistrationScreen> {
  final StudentPortalService _portalService = StudentPortalService();
  final EnrollmentService _enrollmentService = EnrollmentService();

  String _selectedSemester = 'Semester 1';
  bool _isRegistering = false;

  @override
  Widget build(BuildContext context) {
    final email = widget.userData?['email'] ?? '';
    final studentId = widget.userData?['studentId'] ?? 'STU-1002';
    final studentName = widget.userData?['fullName'] ?? 'Student';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          children: [
            Icon(Icons.how_to_reg_rounded, color: Colors.tealAccent),
            SizedBox(width: 8),
            Text('Module Self-Registration', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('subjects').snapshots(),
        builder: (context, subjectSnap) {
          return StreamBuilder<List<EnrollmentModel>>(
            stream: _enrollmentService.getStudentActiveEnrollmentsStream(email),
            builder: (context, enrollSnap) {
              if (subjectSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
              }

              final subjectDocs = subjectSnap.hasData ? subjectSnap.data!.docs : [];
              final allSubjects = subjectDocs
                  .map((d) => SubjectModel.fromFirestore(d))
                  .where((s) => s.status.toLowerCase() == 'active')
                  .toList();

              final enrollments = enrollSnap.data ?? [];
              final enrolledCodes = enrollments.map((e) => e.subjectCode.toUpperCase()).toSet();

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Registration Info Banner
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
                        const Text('SEMESTER REGISTRATION OPEN', style: TextStyle(color: Colors.tealAccent, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        const SizedBox(height: 6),
                        const Text(
                          'Select your academic modules for the upcoming semester. Maximum allowable credit limit is 21 credits.',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text('Selected Term: ', style: TextStyle(color: Colors.white70, fontSize: 13)),
                            DropdownButton<String>(
                              value: _selectedSemester,
                              dropdownColor: const Color(0xFF0F172A),
                              style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 13),
                              underline: const SizedBox(),
                              items: const [
                                DropdownMenuItem(value: 'Semester 1', child: Text('Semester 1')),
                                DropdownMenuItem(value: 'Semester 2', child: Text('Semester 2')),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedSemester = val);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text('Available Subject Catalog', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  if (allSubjects.isEmpty)
                    const Center(child: Text('No active subjects available for registration.', style: TextStyle(color: Colors.grey)))
                  else
                    ...allSubjects.map((s) {
                      final isEnrolled = enrolledCodes.contains(s.subjectCode.toUpperCase());

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isEnrolled ? Colors.green.withAlpha(80) : Colors.white10),
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
                                    s.subjectCode,
                                    style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isEnrolled ? Colors.green.withAlpha(30) : Colors.indigo.withAlpha(30),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isEnrolled ? 'ENROLLED' : '3 CREDITS',
                                    style: TextStyle(
                                      color: isEnrolled ? Colors.greenAccent : Colors.indigoAccent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(s.subjectName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(
                              s.description.isNotEmpty ? s.description : 'Theoretical and practical laboratory coursework.',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                            const Divider(color: Colors.white10, height: 1),
                            const SizedBox(height: 8),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Lecturer: ${s.lecturerName.isNotEmpty ? s.lecturerName : "Faculty"}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                if (isEnrolled)
                                  const Row(
                                    children: [
                                      Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 16),
                                      SizedBox(width: 4),
                                      Text('Registered', style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  )
                                else
                                  ElevatedButton.icon(
                                    onPressed: _isRegistering
                                        ? null
                                        : () async {
                                            setState(() => _isRegistering = true);
                                            final messenger = ScaffoldMessenger.of(context);
                                            try {
                                              await _portalService.registerModule(
                                                studentEmail: email,
                                                studentId: studentId,
                                                studentName: studentName,
                                                subjectDocId: s.docId ?? '',
                                                subjectCode: s.subjectCode,
                                                subjectName: s.subjectName,
                                                lecturerName: s.lecturerName,
                                                semester: _selectedSemester,
                                                academicYear: '2025/2026',
                                              );

                                              messenger.showSnackBar(
                                                SnackBar(
                                                  content: Text('Successfully registered for ${s.subjectName}!'),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                            } catch (e) {
                                              messenger.showSnackBar(
                                                SnackBar(content: Text('Registration failed: $e'), backgroundColor: Colors.redAccent),
                                              );
                                            } finally {
                                              if (mounted) setState(() => _isRegistering = false);
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    icon: const Icon(Icons.add_task_rounded, size: 14, color: Colors.white),
                                    label: const Text('Enroll Now', style: TextStyle(color: Colors.white, fontSize: 12)),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
