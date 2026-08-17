import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/subject_model.dart';
import '../../models/enrollment_model.dart';
import '../../models/student_model.dart';
import '../../models/attendance_model.dart';
import '../../models/submission_model.dart';
import '../../models/result_model.dart';

class SubjectStudentsView extends StatefulWidget {
  final SubjectModel subject;
  final String lecturerEmail;
  final String lecturerName;

  const SubjectStudentsView({
    super.key,
    required this.subject,
    required this.lecturerEmail,
    required this.lecturerName,
  });

  @override
  State<SubjectStudentsView> createState() => _SubjectStudentsViewState();
}

class _SubjectStudentsViewState extends State<SubjectStudentsView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _searchQuery = '';
  String _selectedBatch = 'All';
  String _selectedYear = 'All';
  String _selectedSemester = 'All';
  String _selectedStatus = 'active';

  final List<String> _batches = ['All', '2024', '2025', '2026', '2027'];
  final List<String> _years = ['All', 'Year 1', 'Year 2', 'Year 3', 'Year 4'];
  final List<String> _semesters = ['All', 'Semester 1', 'Semester 2'];
  final List<String> _statuses = ['All', 'active', 'inactive'];

  void _showStudentSubjectDetailModal(
    BuildContext context,
    EnrollmentModel enrollment,
    StudentModel? student,
    double attendancePct,
    int totalClasses,
    int attendedClasses,
    List<SubmissionModel> studentSubmissions,
    ResultModel? studentResult,
  ) {
    final batchText = student?.batch ?? enrollment.academicYear;
    final yearText = student?.year ?? 'Year 1';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            // Header with Student Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.teal.withAlpha(30),
                      child: const Icon(Icons.person_outline_rounded, color: Colors.tealAccent, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(enrollment.studentName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('${enrollment.studentId} • Batch $batchText', style: const TextStyle(color: Colors.tealAccent, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white10),
            const SizedBox(height: 12),

            // Enrollment & Academic Profile
            const Text('ENROLLMENT DETAILS', style: TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  _buildDetailRow('Email Address', enrollment.studentEmail),
                  _buildDetailRow('Module Code', widget.subject.subjectCode),
                  _buildDetailRow('Academic Term', '$yearText • ${enrollment.semester}'),
                  _buildDetailRow('Enrolled Date', enrollment.enrollmentDate.isNotEmpty ? enrollment.enrollmentDate.substring(0, 10) : 'N/A'),
                  _buildDetailRow('Status', enrollment.status.toUpperCase(), isGood: enrollment.status == 'active'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Attendance Statistics for this subject
            const Text('SUBJECT ATTENDANCE METRICS', style: TextStyle(color: Colors.tealAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: attendancePct >= 80 ? Colors.green.withAlpha(30) : Colors.orange.withAlpha(30),
                    child: Text(
                      '${attendancePct.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: attendancePct >= 80 ? Colors.greenAccent : Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          attendancePct >= 80 ? 'Good Attendance Rate' : 'Low Attendance Alert',
                          style: TextStyle(color: attendancePct >= 80 ? Colors.greenAccent : Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text('$attendedClasses Attended out of $totalClasses Conducted Lectures', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Assignment Submissions for this subject
            const Text('ASSIGNMENT SUBMISSIONS', style: TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 8),

            if (studentSubmissions.isEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(12)),
                child: const Center(child: Text('No assignment submissions found for this module.', style: TextStyle(color: Colors.grey, fontSize: 12))),
              )
            else
              ...studentSubmissions.map((sub) {
                final isGraded = sub.mark != null;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isGraded ? Colors.green.withAlpha(50) : Colors.orange.withAlpha(60)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(sub.assignmentTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('Submitted: ${sub.submittedAt.substring(0, 10)}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                          if (sub.feedback != null && sub.feedback!.isNotEmpty)
                            Text('Feedback: ${sub.feedback}', style: const TextStyle(color: Colors.tealAccent, fontSize: 11, fontStyle: FontStyle.italic)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isGraded ? Colors.green.withAlpha(30) : Colors.orange.withAlpha(30),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isGraded ? '${sub.mark}/100' : 'AWAITING GRADE',
                          style: TextStyle(color: isGraded ? Colors.greenAccent : Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 20),

            // Exam Result for this subject
            const Text('EXAM / FINAL RESULT', style: TextStyle(color: Colors.purpleAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 8),

            if (studentResult == null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(12)),
                child: const Center(child: Text('No final exam result posted yet for this student.', style: TextStyle(color: Colors.grey, fontSize: 12))),
              )
            else
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.teal.withAlpha(60)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Marks: ${studentResult.marks.toStringAsFixed(0)}% (Grade Point: ${studentResult.gradePoint})',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('Published Date: ${studentResult.publishedDate}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.teal.withAlpha(40), borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        studentResult.grade,
                        style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isGood = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(value, style: TextStyle(color: isGood ? Colors.greenAccent : Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search & Multi-Filter Header
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF1E293B),
          child: Column(
            children: [
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search student by ID, Name or Email...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
                onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
              ),
              const SizedBox(height: 10),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Batch Filter
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)),
                      child: DropdownButton<String>(
                        value: _selectedBatch,
                        dropdownColor: const Color(0xFF0F172A),
                        style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold),
                        underline: const SizedBox(),
                        items: _batches.map((b) => DropdownMenuItem(value: b, child: Text(b == 'All' ? 'All Batches' : 'Batch $b'))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedBatch = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Year Filter
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)),
                      child: DropdownButton<String>(
                        value: _selectedYear,
                        dropdownColor: const Color(0xFF0F172A),
                        style: const TextStyle(color: Colors.tealAccent, fontSize: 12, fontWeight: FontWeight.bold),
                        underline: const SizedBox(),
                        items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedYear = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Semester Filter
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)),
                      child: DropdownButton<String>(
                        value: _selectedSemester,
                        dropdownColor: const Color(0xFF0F172A),
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        underline: const SizedBox(),
                        items: _semesters.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedSemester = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Status Filter
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)),
                      child: DropdownButton<String>(
                        value: _selectedStatus,
                        dropdownColor: const Color(0xFF0F172A),
                        style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold),
                        underline: const SizedBox(),
                        items: _statuses.map((st) => DropdownMenuItem(value: st, child: Text(st.toUpperCase()))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedStatus = val);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Students List Stream
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('students').snapshots(),
            builder: (context, studentSnap) {
              return StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('enrollments')
                    .where('subjectCode', isEqualTo: widget.subject.subjectCode)
                    .snapshots(),
                builder: (context, enrollSnap) {
                  if (enrollSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
                  }

                  if (enrollSnap.hasError) {
                    return Center(child: Text('Error: ${enrollSnap.error}', style: const TextStyle(color: Colors.redAccent)));
                  }

                  return StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('attendance')
                        .where('subjectCode', isEqualTo: widget.subject.subjectCode)
                        .snapshots(),
                    builder: (context, attendSnap) {
                      return StreamBuilder<QuerySnapshot>(
                        stream: _firestore
                            .collection('submissions')
                            .where('subjectCode', isEqualTo: widget.subject.subjectCode)
                            .snapshots(),
                        builder: (context, submisSnap) {
                          return StreamBuilder<QuerySnapshot>(
                            stream: _firestore
                                .collection('results')
                                .where('subjectCode', isEqualTo: widget.subject.subjectCode)
                                .snapshots(),
                            builder: (context, resSnap) {
                              final allStudentDocs = studentSnap.data?.docs ?? [];
                              final allEnrollDocs = enrollSnap.data?.docs ?? [];
                              final allAttendDocs = attendSnap.data?.docs ?? [];
                              final allSubmisDocs = submisSnap.data?.docs ?? [];
                              final allResDocs = resSnap.data?.docs ?? [];

                              // Map student profile by email & studentId
                              final Map<String, StudentModel> studentMap = {};
                              for (var d in allStudentDocs) {
                                final stu = StudentModel.fromFirestore(d as DocumentSnapshot<Map<String, dynamic>>);
                                studentMap[stu.email.toLowerCase()] = stu;
                                studentMap[stu.studentId.toLowerCase()] = stu;
                              }

                              // Attendance map per student Email / ID (excluding cancelled)
                              final Map<String, List<AttendanceModel>> attendMap = {};
                              for (var d in allAttendDocs) {
                                final m = AttendanceModel.fromFirestore(d as DocumentSnapshot<Map<String, dynamic>>);
                                if (m.status.toLowerCase() != 'cancelled') {
                                  final key = m.studentId.toLowerCase();
                                  attendMap.putIfAbsent(key, () => []).add(m);
                                }
                              }

                              // Submissions map per student Email
                              final Map<String, List<SubmissionModel>> submisMap = {};
                              for (var d in allSubmisDocs) {
                                final s = SubmissionModel.fromFirestore(d as DocumentSnapshot<Map<String, dynamic>>);
                                final key = s.studentEmail.toLowerCase();
                                submisMap.putIfAbsent(key, () => []).add(s);
                              }

                              // Results map per student Email
                              final Map<String, ResultModel> resMap = {};
                              for (var d in allResDocs) {
                                final r = ResultModel.fromFirestore(d as DocumentSnapshot<Map<String, dynamic>>);
                                resMap[r.studentEmail.toLowerCase()] = r;
                              }

                              // Parse and deduplicate enrollments by studentEmail
                              final Map<String, EnrollmentModel> uniqueEnrollMap = {};
                              for (var doc in allEnrollDocs) {
                                final e = EnrollmentModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
                                uniqueEnrollMap[e.studentEmail.toLowerCase()] = e;
                              }

                              // Filter based on UI criteria
                              final filteredStudents = uniqueEnrollMap.values.where((e) {
                                final stu = studentMap[e.studentEmail.toLowerCase()] ?? studentMap[e.studentId.toLowerCase()];
                                final batch = stu?.batch ?? e.academicYear;
                                final year = stu?.year ?? 'Year 1';

                                // Search Filter
                                final matchesSearch = e.studentName.toLowerCase().contains(_searchQuery) ||
                                    e.studentId.toLowerCase().contains(_searchQuery) ||
                                    e.studentEmail.toLowerCase().contains(_searchQuery);

                                // Batch Filter
                                final matchesBatch = _selectedBatch == 'All' || batch == _selectedBatch || batch.contains(_selectedBatch);

                                // Year Filter
                                final matchesYear = _selectedYear == 'All' || year.toLowerCase() == _selectedYear.toLowerCase();

                                // Semester Filter
                                final matchesSemester = _selectedSemester == 'All' || e.semester.toLowerCase() == _selectedSemester.toLowerCase();

                                // Status Filter
                                final matchesStatus = _selectedStatus == 'All' || e.status.toLowerCase() == _selectedStatus.toLowerCase();

                                return matchesSearch && matchesBatch && matchesYear && matchesSemester && matchesStatus;
                              }).toList();

                              if (filteredStudents.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.people_outline_rounded, size: 56, color: Colors.grey.withAlpha(80)),
                                      const SizedBox(height: 12),
                                      const Text('No enrolled students found matching search filters.', style: TextStyle(color: Colors.grey, fontSize: 14)),
                                    ],
                                  ),
                                );
                              }

                              return ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: filteredStudents.length,
                                itemBuilder: (context, index) {
                                  final e = filteredStudents[index];
                                  final stu = studentMap[e.studentEmail.toLowerCase()] ?? studentMap[e.studentId.toLowerCase()];
                                  final keyId = e.studentId.toLowerCase();

                                  // Calculate real attendance rate
                                  final studentAttendances = attendMap[keyId] ?? [];
                                  final totalClasses = studentAttendances.length;
                                  final attended = studentAttendances.where((r) => r.status.toLowerCase() == 'present' || r.status.toLowerCase() == 'late').length;
                                  final attendancePct = totalClasses > 0 ? (attended / totalClasses) * 100 : 100.0;

                                  final submissions = submisMap[e.studentEmail.toLowerCase()] ?? [];
                                  final result = resMap[e.studentEmail.toLowerCase()];

                                  final batchDisplay = stu?.batch ?? e.academicYear;
                                  final yearDisplay = stu?.year ?? 'Year 1';

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E293B),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.white10),
                                    ),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: () => _showStudentSubjectDetailModal(
                                        context,
                                        e,
                                        stu,
                                        attendancePct,
                                        totalClasses,
                                        attended,
                                        submissions,
                                        result,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 24,
                                              backgroundColor: Colors.teal.withAlpha(30),
                                              child: Text(
                                                e.studentName.isNotEmpty ? e.studentName[0].toUpperCase() : 'S',
                                                style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 16),
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          e.studentName,
                                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: attendancePct >= 80 ? Colors.green.withAlpha(30) : Colors.orange.withAlpha(30),
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: Text(
                                                          '${attendancePct.toStringAsFixed(0)}% ATTENDANCE',
                                                          style: TextStyle(
                                                            color: attendancePct >= 80 ? Colors.greenAccent : Colors.orangeAccent,
                                                            fontSize: 9,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text('${e.studentId} • ${e.studentEmail}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Text('Batch $batchDisplay', style: const TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.w600)),
                                                      const SizedBox(width: 8),
                                                      Text('• $yearDisplay (${e.semester})', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                                                      const Spacer(),
                                                      Text(e.status.toUpperCase(), style: TextStyle(color: e.status == 'active' ? Colors.greenAccent : Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
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
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
