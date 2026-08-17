import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/subject_model.dart';
import 'lecturer_subject_detail_screen.dart';

class LecturerSubjectsScreen extends StatefulWidget {
  final String lecturerEmail;
  final String lecturerName;
  final String lecturerId;

  const LecturerSubjectsScreen({
    super.key,
    required this.lecturerEmail,
    required this.lecturerName,
    required this.lecturerId,
  });

  @override
  State<LecturerSubjectsScreen> createState() => _LecturerSubjectsScreenState();
}

class _LecturerSubjectsScreenState extends State<LecturerSubjectsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _searchQuery = '';
  String _selectedSemester = 'All';
  String _selectedAcademicYear = 'All';
  String _selectedStatus = 'All';

  final List<String> _semesters = ['All', 'Semester 1', 'Semester 2', 'Semester 3', 'Semester 4'];
  final List<String> _academicYears = ['All', '2025/2026', '2024/2025', '2026/2027'];
  final List<String> _statuses = ['All', 'Active', 'Inactive'];

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
        title: const Row(
          children: [
            Icon(Icons.menu_book_rounded, color: Colors.amberAccent),
            SizedBox(width: 8),
            Text('My Assigned Subjects', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search & Filter Panel
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1E293B),
            child: Column(
              children: [
                TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search by subject code or name...',
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
                      // Semester Filter
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)),
                        child: DropdownButton<String>(
                          value: _selectedSemester,
                          dropdownColor: const Color(0xFF0F172A),
                          style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold),
                          underline: const SizedBox(),
                          items: _semesters.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedSemester = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Academic Year Filter
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)),
                        child: DropdownButton<String>(
                          value: _selectedAcademicYear,
                          dropdownColor: const Color(0xFF0F172A),
                          style: const TextStyle(color: Colors.tealAccent, fontSize: 12, fontWeight: FontWeight.bold),
                          underline: const SizedBox(),
                          items: _academicYears.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedAcademicYear = val);
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
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          underline: const SizedBox(),
                          items: _statuses.map((st) => DropdownMenuItem(value: st, child: Text(st))).toList(),
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

          // Subjects List with Real-time Enrollment Counts
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('subjects').snapshots(),
              builder: (context, subSnap) {
                if (subSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.amberAccent));
                }

                if (subSnap.hasError) {
                  return Center(child: Text('Error loading subjects: ${subSnap.error}', style: const TextStyle(color: Colors.redAccent)));
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('enrollments').where('status', isEqualTo: 'active').snapshots(),
                  builder: (context, enrollSnap) {
                    final allDocs = subSnap.data?.docs ?? [];
                    final enrollDocs = enrollSnap.data?.docs ?? [];

                    // Calculate active unique enrollments per subject code
                    final Map<String, Set<String>> subjectEnrollmentMap = {};
                    for (var doc in enrollDocs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final code = data['subjectCode']?.toString() ?? '';
                      final stuId = (data['studentEmail'] ?? data['studentId'] ?? '').toString().toLowerCase();
                      if (code.isNotEmpty && stuId.isNotEmpty) {
                        subjectEnrollmentMap.putIfAbsent(code, () => <String>{}).add(stuId);
                      }
                    }

                    // Filter subjects assigned to this lecturer
                    final mySubjects = allDocs
                        .map((d) => SubjectModel.fromFirestore(d as DocumentSnapshot<Map<String, dynamic>>))
                        .where((s) {
                      final lName = s.lecturerName.toLowerCase();
                      final lId = (s.lecturerId ?? '').toUpperCase();
                      final targetName = widget.lecturerName.toLowerCase();
                      final targetLastName = targetName.split(' ').last;

                      final isAssigned = lName == targetName ||
                          (widget.lecturerId.isNotEmpty && lId == widget.lecturerId.toUpperCase()) ||
                          lName.contains(targetLastName);

                      if (!isAssigned) return false;

                      // Apply search filter
                      final matchesSearch = s.subjectCode.toLowerCase().contains(_searchQuery) ||
                          s.subjectName.toLowerCase().contains(_searchQuery);

                      // Apply Semester filter
                      final matchesSem = _selectedSemester == 'All' || s.semester.toLowerCase() == _selectedSemester.toLowerCase();

                      // Apply Academic Year filter
                      final matchesYear = _selectedAcademicYear == 'All' || s.academicYear == _selectedAcademicYear;

                      // Apply Status filter
                      final matchesStatus = _selectedStatus == 'All' || s.status.toLowerCase() == _selectedStatus.toLowerCase();

                      return matchesSearch && matchesSem && matchesYear && matchesStatus;
                    }).toList();

                    if (mySubjects.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.menu_book_rounded, size: 56, color: Colors.grey.withAlpha(80)),
                            const SizedBox(height: 12),
                            const Text('No assigned subjects found matching criteria.', style: TextStyle(color: Colors.grey, fontSize: 14)),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: mySubjects.length,
                      itemBuilder: (context, index) {
                        final s = mySubjects[index];
                        final enrolledCount = subjectEnrollmentMap[s.subjectCode]?.length ?? 0;
                        final isActive = s.status.toLowerCase() == 'active';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LecturerSubjectDetailScreen(
                                    subject: s,
                                    lecturerEmail: widget.lecturerEmail,
                                    lecturerName: widget.lecturerName,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withAlpha(30),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.amberAccent.withAlpha(80)),
                                        ),
                                        child: Text(
                                          s.subjectCode,
                                          style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isActive ? Colors.green.withAlpha(30) : Colors.red.withAlpha(30),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          s.status.toUpperCase(),
                                          style: TextStyle(
                                            color: isActive ? Colors.greenAccent : Colors.redAccent,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  Text(s.subjectName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),

                                  Row(
                                    children: [
                                      const Icon(Icons.school_outlined, size: 14, color: Colors.tealAccent),
                                      const SizedBox(width: 4),
                                      Text('${s.semester} • ${s.academicYear}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                      const SizedBox(width: 12),
                                      const Icon(Icons.stars_rounded, size: 14, color: Colors.amberAccent),
                                      const SizedBox(width: 4),
                                      const Text('3 Credits', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.people_alt_rounded, size: 14, color: Colors.tealAccent),
                                          const SizedBox(width: 6),
                                          Text(
                                            '$enrolledCount Active Students Enrolled',
                                            style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                      const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                                    ],
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
            ),
          ),
        ],
      ),
    );
  }
}
