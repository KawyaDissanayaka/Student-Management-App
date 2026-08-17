import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/subject_model.dart';
import '../../models/result_model.dart';
import '../../models/enrollment_model.dart';

class LecturerResultsView extends StatefulWidget {
  final SubjectModel subject;
  final String lecturerEmail;
  final String lecturerName;

  const LecturerResultsView({
    super.key,
    required this.subject,
    required this.lecturerEmail,
    required this.lecturerName,
  });

  @override
  State<LecturerResultsView> createState() => _LecturerResultsViewState();
}

class _LecturerResultsViewState extends State<LecturerResultsView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _searchQuery = '';
  String _selectedGradeFilter = 'All';
  String _selectedStatusFilter = 'All';

  final List<String> _grades = ['All', 'A+', 'A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'C-', 'D', 'F'];
  final List<String> _statuses = ['All', 'published', 'draft', 'locked'];

  void _showPostEditResultModal(EnrollmentModel enrollment, {ResultModel? existingResult}) {
    if (existingResult != null && existingResult.isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔒 Results for this student are LOCKED and finalized. An Admin unlock request is required to modify.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final isEditing = existingResult != null;
    final assignController = TextEditingController(text: existingResult?.assignmentMarks != null ? '${existingResult!.assignmentMarks}' : '25');
    final midController = TextEditingController(text: existingResult?.midtermMarks != null ? '${existingResult!.midtermMarks}' : '25');
    final finalController = TextEditingController(text: existingResult?.finalExamMarks != null ? '${existingResult!.finalExamMarks}' : '35');

    String selectedStatus = existingResult?.status ?? 'published';
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          // Calculate dynamic weighted marks
          final assignMark = double.tryParse(assignController.text.trim()) ?? 0.0;
          final midMark = double.tryParse(midController.text.trim()) ?? 0.0;
          final finalMark = double.tryParse(finalController.text.trim()) ?? 0.0;
          final totalMarks = (assignMark + midMark + finalMark).clamp(0.0, 100.0);
          final computedGrade = ResultModel.calculateGrade(totalMarks);
          final computedGp = ResultModel.calculateGradePoint(totalMarks);

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(isEditing ? Icons.edit_note_rounded : Icons.grade_rounded, color: Colors.amberAccent),
                          const SizedBox(width: 8),
                          Text(
                            isEditing ? 'Update Academic Result' : 'Enter Student Marks',
                            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${enrollment.studentName} (${enrollment.studentId})', style: const TextStyle(color: Colors.tealAccent, fontSize: 13, fontWeight: FontWeight.w600)),
                  Text('${widget.subject.subjectCode} - ${widget.subject.subjectName} • ${widget.subject.credits} Credits', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 16),

                  // Assessment Component Breakdown Inputs
                  const Text('ASSESSMENT WEIGHTING BREAKDOWN', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      // Assignment Marks (30%)
                      Expanded(
                        child: TextField(
                          controller: assignController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Assignments (30%)',
                            labelStyle: const TextStyle(color: Colors.grey, fontSize: 11),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onChanged: (_) => setModalState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Midterm Exam (30%)
                      Expanded(
                        child: TextField(
                          controller: midController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Midterm (30%)',
                            labelStyle: const TextStyle(color: Colors.grey, fontSize: 11),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onChanged: (_) => setModalState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Final Exam (40%)
                      Expanded(
                        child: TextField(
                          controller: finalController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Final Exam (40%)',
                            labelStyle: const TextStyle(color: Colors.grey, fontSize: 11),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onChanged: (_) => setModalState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Dynamic Result Preview Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: totalMarks >= 50 ? Colors.green.withAlpha(80) : Colors.red.withAlpha(80)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Weighted Total: ${totalMarks.toStringAsFixed(1)} / 100', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('Grade Point: ${computedGp.toStringAsFixed(2)} GPA', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: totalMarks >= 50 ? Colors.green.withAlpha(30) : Colors.red.withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'GRADE $computedGrade',
                            style: TextStyle(
                              color: totalMarks >= 50 ? Colors.greenAccent : Colors.redAccent,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Result State Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: selectedStatus.toLowerCase(),
                    dropdownColor: const Color(0xFF0F172A),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Result Publication Status',
                      labelStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'published', child: Text('Published (Visible to Student)', style: TextStyle(color: Colors.greenAccent))),
                      DropdownMenuItem(value: 'draft', child: Text('Draft (Visible only to Lecturer)', style: TextStyle(color: Colors.orangeAccent))),
                      DropdownMenuItem(value: 'locked', child: Text('Locked (Finalized & Sealed)', style: TextStyle(color: Colors.amberAccent))),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedStatus = val);
                    },
                  ),
                  const SizedBox(height: 20),

                  // Submit Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (assignMark < 0 || assignMark > 30 || midMark < 0 || midMark > 30 || finalMark < 0 || finalMark > 40) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Invalid component marks: Assign (0-30), Midterm (0-30), Final (0-40).'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                                return;
                              }

                              setModalState(() => isSaving = true);
                              final messenger = ScaffoldMessenger.of(context);
                              final nav = Navigator.of(ctx);

                              try {
                                final resultData = {
                                  'resultId': existingResult?.resultId ?? 'RES-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                                  'studentDocId': enrollment.studentDocId,
                                  'studentOfficialId': enrollment.studentId,
                                  'studentEmail': enrollment.studentEmail,
                                  'studentName': enrollment.studentName,
                                  'subjectCode': widget.subject.subjectCode,
                                  'subjectName': widget.subject.subjectName,
                                  'credits': widget.subject.credits,
                                  'marks': totalMarks,
                                  'grade': computedGrade,
                                  'gradePoint': computedGp,
                                  'assignmentMarks': assignMark,
                                  'midtermMarks': midMark,
                                  'finalExamMarks': finalMark,
                                  'semester': widget.subject.semester,
                                  'academicYear': widget.subject.academicYear,
                                  'publishedDate': DateTime.now().toIso8601String().substring(0, 10),
                                  'status': selectedStatus,
                                  'lecturerName': widget.lecturerName,
                                  'lecturerEmail': widget.lecturerEmail,
                                  'lockedAt': selectedStatus == 'locked' ? DateTime.now().toIso8601String() : null,
                                  'lockedBy': selectedStatus == 'locked' ? widget.lecturerEmail : null,
                                };

                                if (!isEditing) {
                                  await _firestore.collection('results').add(resultData);
                                  messenger.showSnackBar(
                                    SnackBar(content: Text('Result posted: Grade $computedGrade (${totalMarks.toStringAsFixed(1)}%) for ${enrollment.studentName}!'), backgroundColor: Colors.green),
                                  );
                                } else {
                                  await _firestore.collection('results').doc(existingResult.docId).update(resultData);
                                  messenger.showSnackBar(
                                    SnackBar(content: Text('Result updated: Grade $computedGrade for ${enrollment.studentName}!'), backgroundColor: Colors.green),
                                  );
                                }

                                nav.pop();
                              } catch (e) {
                                setModalState(() => isSaving = false);
                                messenger.showSnackBar(
                                  SnackBar(content: Text('Failed to save result: $e'), backgroundColor: Colors.redAccent),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[700], padding: const EdgeInsets.symmetric(vertical: 14)),
                      icon: isSaving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_circle_rounded, color: Colors.white),
                      label: Text(
                        isEditing ? 'Save Result Changes' : 'Confirm & Post Result',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _lockAllResults(List<ResultModel> results) {
    if (results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No results entered to lock.'), backgroundColor: Colors.orange),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock_outline_rounded, color: Colors.amberAccent),
            SizedBox(width: 8),
            Text('Lock & Finalize All Results', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Are you sure you want to lock all ${results.length} result records for ${widget.subject.subjectCode}? Once locked, grades cannot be changed without Admin unlock authorization.',
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              try {
                final batch = _firestore.batch();
                for (var r in results) {
                  if (r.docId != null) {
                    batch.update(_firestore.collection('results').doc(r.docId), {
                      'status': 'locked',
                      'lockedAt': DateTime.now().toIso8601String(),
                      'lockedBy': widget.lecturerEmail,
                    });
                  }
                }
                await batch.commit();
                messenger.showSnackBar(
                  SnackBar(content: Text('All ${results.length} subject results locked successfully!'), backgroundColor: Colors.green),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Failed to lock results: $e'), backgroundColor: Colors.redAccent),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[700]),
            child: const Text('Confirm Lock', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // 1. Fetch Active Enrolled Students for this Subject
      stream: _firestore
          .collection('enrollments')
          .where('subjectCode', isEqualTo: widget.subject.subjectCode)
          .where('status', isEqualTo: 'active')
          .snapshots(),
      builder: (context, enrollSnap) {
        return StreamBuilder<QuerySnapshot>(
          // 2. Fetch Results for this Subject
          stream: _firestore
              .collection('results')
              .where('subjectCode', isEqualTo: widget.subject.subjectCode)
              .snapshots(),
          builder: (context, resultSnap) {
            if (enrollSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.amberAccent));
            }

            final enrollDocs = enrollSnap.data?.docs ?? [];
            final resultDocs = resultSnap.data?.docs ?? [];

            // Deduplicate enrollments
            final Map<String, EnrollmentModel> studentMap = {};
            for (var d in enrollDocs) {
              final e = EnrollmentModel.fromFirestore(d as DocumentSnapshot<Map<String, dynamic>>);
              studentMap[e.studentEmail.toLowerCase()] = e;
            }
            final activeStudents = studentMap.values.toList();

            // Map results by studentEmail
            final Map<String, ResultModel> resultMap = {};
            for (var d in resultDocs) {
              final r = ResultModel.fromFirestore(d);
              resultMap[r.studentEmail.toLowerCase()] = r;
            }

            final resultsList = resultMap.values.toList();

            // Academic KPIs
            final totalEnrolled = activeStudents.length;
            final gradedCount = resultsList.length;
            final passedCount = resultsList.where((r) => r.isPassed).length;
            final failedCount = resultsList.where((r) => !r.isPassed).length;
            final double passRate = gradedCount > 0 ? (passedCount / gradedCount) * 100 : 0.0;

            final marksList = resultsList.map((r) => r.marks).toList();
            final double avgMarks = marksList.isNotEmpty
                ? marksList.reduce((a, b) => a + b) / marksList.length
                : 0.0;
            final double highestMark = marksList.isNotEmpty ? marksList.reduce((a, b) => a > b ? a : b) : 0.0;
            final double lowestMark = marksList.isNotEmpty ? marksList.reduce((a, b) => a < b ? a : b) : 0.0;

            // Filter students
            final filteredStudents = activeStudents.where((stu) {
              final res = resultMap[stu.studentEmail.toLowerCase()];
              final hasResult = res != null;

              // Search Filter
              final matchesSearch = stu.studentName.toLowerCase().contains(_searchQuery) ||
                  stu.studentId.toLowerCase().contains(_searchQuery) ||
                  stu.studentEmail.toLowerCase().contains(_searchQuery);

              // Grade Filter
              bool matchesGrade = true;
              if (_selectedGradeFilter != 'All') {
                matchesGrade = hasResult && res.grade.toUpperCase() == _selectedGradeFilter.toUpperCase();
              }

              // Status Filter
              bool matchesStatus = true;
              if (_selectedStatusFilter != 'All') {
                matchesStatus = hasResult && res.status.toLowerCase() == _selectedStatusFilter.toLowerCase();
              }

              return matchesSearch && matchesGrade && matchesStatus;
            }).toList();

            return Scaffold(
              backgroundColor: Colors.transparent,
              body: Column(
                children: [
                  // KPI Dashboard Summary Strip
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: const Color(0xFF1E293B),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildMetricCard('Enrolled', '$totalEnrolled', Colors.white, Icons.groups_rounded)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildMetricCard('Passed', '$passedCount (${passRate.toStringAsFixed(0)}%)', Colors.greenAccent, Icons.check_circle_outline_rounded)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildMetricCard('Failed', '$failedCount', failedCount > 0 ? Colors.redAccent : Colors.grey, Icons.cancel_outlined)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildMetricCard('Avg Mark', '${avgMarks.toStringAsFixed(1)}%', Colors.amberAccent, Icons.analytics_rounded)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildMetricCard('Range', '${highestMark.toInt()} / ${lowestMark.toInt()}', Colors.tealAccent, Icons.swap_vert_rounded)),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Search Bar & Lock Button
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
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
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              onPressed: () => _lockAllResults(resultsList),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber[800],
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.lock_rounded, size: 16, color: Colors.white),
                              label: const Text('Lock All', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Filters: Grade and Status
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ..._grades.map((g) {
                                final isSel = g == _selectedGradeFilter;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ChoiceChip(
                                    label: Text(g == 'All' ? 'ALL GRADES' : g),
                                    selected: isSel,
                                    onSelected: (val) {
                                      if (val) setState(() => _selectedGradeFilter = g);
                                    },
                                    selectedColor: Colors.amber[700],
                                    backgroundColor: const Color(0xFF0F172A),
                                    labelStyle: TextStyle(color: isSel ? Colors.white : Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                                    side: BorderSide(color: isSel ? Colors.amberAccent : Colors.white10),
                                  ),
                                );
                              }),
                              const SizedBox(width: 10),
                              ..._statuses.map((s) {
                                final isSel = s == _selectedStatusFilter;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ChoiceChip(
                                    label: Text(s == 'All' ? 'ALL STATUS' : s.toUpperCase()),
                                    selected: isSel,
                                    onSelected: (val) {
                                      if (val) setState(() => _selectedStatusFilter = s);
                                    },
                                    selectedColor: Colors.teal,
                                    backgroundColor: const Color(0xFF0F172A),
                                    labelStyle: TextStyle(color: isSel ? Colors.white : Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                                    side: BorderSide(color: isSel ? Colors.tealAccent : Colors.white10),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Student Results Roster List
                  Expanded(
                    child: filteredStudents.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.grade_outlined, size: 56, color: Colors.grey.withAlpha(80)),
                                const SizedBox(height: 12),
                                const Text('No students found matching filter criteria.', style: TextStyle(color: Colors.grey, fontSize: 14)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredStudents.length,
                            itemBuilder: (context, index) {
                              final stu = filteredStudents[index];
                              final res = resultMap[stu.studentEmail.toLowerCase()];
                              final hasResult = res != null;
                              final isLocked = res?.isLocked ?? false;
                              final isPassed = res?.isPassed ?? false;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isLocked
                                        ? Colors.amber.withAlpha(80)
                                        : (hasResult ? (isPassed ? Colors.green.withAlpha(50) : Colors.red.withAlpha(50)) : Colors.white10),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 20,
                                              backgroundColor: hasResult
                                                  ? (isPassed ? Colors.green.withAlpha(30) : Colors.red.withAlpha(30))
                                                  : Colors.grey.withAlpha(20),
                                              child: Text(
                                                hasResult ? res.grade : '?',
                                                style: TextStyle(
                                                  color: hasResult ? (isPassed ? Colors.greenAccent : Colors.redAccent) : Colors.grey,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(stu.studentName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                                Text('${stu.studentId} • Batch ${stu.academicYear}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                              ],
                                            ),
                                          ],
                                        ),

                                        // Status & Grade Pill
                                        if (hasResult) ...[
                                          Row(
                                            children: [
                                              if (isLocked)
                                                const Padding(
                                                  padding: EdgeInsets.only(right: 6),
                                                  child: Icon(Icons.lock_rounded, size: 14, color: Colors.amberAccent),
                                                ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: isPassed ? Colors.green.withAlpha(30) : Colors.red.withAlpha(30),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  '${res.marks.toStringAsFixed(1)}% (${res.grade})',
                                                  style: TextStyle(
                                                    color: isPassed ? Colors.greenAccent : Colors.redAccent,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ] else ...[
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(color: Colors.grey.withAlpha(20), borderRadius: BorderRadius.circular(6)),
                                            child: const Text('NOT GRADED', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ],
                                    ),

                                    if (hasResult) ...[
                                      const SizedBox(height: 10),
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(10)),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                                          children: [
                                            _buildComponentScoreBadge('Assignments', '${res.assignmentMarks?.toStringAsFixed(1) ?? 'N/A'}/30'),
                                            _buildComponentScoreBadge('Midterm', '${res.midtermMarks?.toStringAsFixed(1) ?? 'N/A'}/30'),
                                            _buildComponentScoreBadge('Final Exam', '${res.finalExamMarks?.toStringAsFixed(1) ?? 'N/A'}/40'),
                                            _buildComponentScoreBadge('GPA Value', res.gradePoint.toStringAsFixed(2)),
                                          ],
                                        ),
                                      ),
                                    ],

                                    const SizedBox(height: 10),
                                    const Divider(color: Colors.white10, height: 1),
                                    const SizedBox(height: 6),

                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          hasResult ? 'Status: ${res.status.toUpperCase()}' : 'Pending Evaluation',
                                          style: TextStyle(color: hasResult ? Colors.amberAccent : Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                        ElevatedButton.icon(
                                          onPressed: isLocked
                                              ? () {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('🔒 Results are locked. Contact Admin for changes.'), backgroundColor: Colors.orange),
                                                  );
                                                }
                                              : () => _showPostEditResultModal(stu, existingResult: res),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isLocked ? Colors.grey[800] : (hasResult ? Colors.amber[700] : Colors.teal),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          icon: Icon(isLocked ? Icons.lock_rounded : (hasResult ? Icons.edit_note_rounded : Icons.add_rounded), size: 16, color: Colors.white),
                                          label: Text(
                                            isLocked ? 'Locked' : (hasResult ? 'Update Marks' : 'Post Result'),
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildComponentScoreBadge(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 9)),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 9), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
