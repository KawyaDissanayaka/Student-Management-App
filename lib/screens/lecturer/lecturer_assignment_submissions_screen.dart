import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/assignment_model.dart';
import '../../models/submission_model.dart';
import '../../models/enrollment_model.dart';
import '../../models/subject_model.dart';

class LecturerAssignmentSubmissionsScreen extends StatefulWidget {
  final AssignmentModel assignment;
  final SubjectModel subject;
  final String lecturerEmail;
  final String lecturerName;

  const LecturerAssignmentSubmissionsScreen({
    super.key,
    required this.assignment,
    required this.subject,
    required this.lecturerEmail,
    required this.lecturerName,
  });

  @override
  State<LecturerAssignmentSubmissionsScreen> createState() => _LecturerAssignmentSubmissionsScreenState();
}

class _LecturerAssignmentSubmissionsScreenState extends State<LecturerAssignmentSubmissionsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _searchQuery = '';
  String _selectedStatusFilter = 'All';

  final List<String> _filterOptions = ['All', 'Submitted', 'Reviewed', 'Late', 'Pending'];

  void _showFilePreviewDialog(BuildContext context, SubmissionModel sub) {
    final fileExt = (sub.fileType ?? 'pdf').toLowerCase();
    final fileName = sub.fileName ?? '${sub.studentId}_${widget.assignment.assignmentId}.$fileExt';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              sub.fileType == 'PDF' ? Icons.picture_as_pdf_rounded : (sub.fileType == 'ZIP' ? Icons.folder_zip_rounded : Icons.description_rounded),
              color: Colors.tealAccent,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                fileName,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Submitted by: ${sub.studentName} (${sub.studentId})', style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 4),
            Text('Timestamp: ${sub.submittedAt}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 4),
            Text('File Type: ${sub.fileType} • Size: ${sub.fileSize}', style: const TextStyle(color: Colors.tealAccent, fontSize: 12, fontWeight: FontWeight.bold)),
            if (sub.notes != null && sub.notes!.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Divider(color: Colors.white10),
              const SizedBox(height: 4),
              Text('Student Notes:\n${sub.notes}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: Colors.grey))),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Downloading "$fileName" (${sub.fileSize})...'), backgroundColor: Colors.teal),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            icon: const Icon(Icons.download_rounded, size: 16, color: Colors.white),
            label: const Text('Download Submission', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showGradeModal(BuildContext context, SubmissionModel sub, num totalMarks) {
    final markController = TextEditingController(text: sub.mark != null ? '${sub.mark}' : '');
    final feedbackController = TextEditingController(text: sub.feedback ?? '');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Evaluate & Grade Submission', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              Text('${sub.studentName} (${sub.studentId})', style: const TextStyle(color: Colors.tealAccent, fontSize: 13, fontWeight: FontWeight.w600)),
              Text('Assignment: ${widget.assignment.title}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 14),

              TextField(
                controller: markController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Marks Awarded (0 - $totalMarks) *',
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: feedbackController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Lecturer Feedback & Guidance Remarks',
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final markVal = num.tryParse(markController.text.trim());
                          if (markVal == null || markVal < 0 || markVal > totalMarks) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: Please enter valid marks between 0 and $totalMarks.'), backgroundColor: Colors.redAccent),
                            );
                            return;
                          }

                          setModalState(() => isSaving = true);
                          final messenger = ScaffoldMessenger.of(context);
                          final nav = Navigator.of(ctx);

                          try {
                            if (sub.docId != null) {
                              await _firestore.collection('submissions').doc(sub.docId).update({
                                'mark': markVal,
                                'feedback': feedbackController.text.trim(),
                                'status': 'reviewed',
                                'gradedAt': DateTime.now().toIso8601String(),
                                'gradedBy': widget.lecturerName,
                              });
                            }
                            nav.pop();
                            messenger.showSnackBar(
                              SnackBar(content: Text('Grade $markVal/$totalMarks saved & marked as Reviewed for ${sub.studentName}!'), backgroundColor: Colors.green),
                            );
                          } catch (e) {
                            setModalState(() => isSaving = false);
                            messenger.showSnackBar(
                              SnackBar(content: Text('Failed to save grade: $e'), backgroundColor: Colors.redAccent),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, padding: const EdgeInsets.symmetric(vertical: 14)),
                  icon: isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle_rounded, color: Colors.white),
                  label: const Text('Save & Post Reviewed Grade', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.assignment;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Submissions: ${a.title}', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
            Text('${a.subjectCode} • Max: ${a.totalMarks} Marks • Due: ${a.dueDate}', style: const TextStyle(color: Colors.amberAccent, fontSize: 11)),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 1. Fetch Active Enrolled Students
        stream: _firestore
            .collection('enrollments')
            .where('subjectCode', isEqualTo: widget.subject.subjectCode)
            .where('status', isEqualTo: 'active')
            .snapshots(),
        builder: (context, enrollSnap) {
          return StreamBuilder<QuerySnapshot>(
            // 2. Fetch Submissions for this Assignment
            stream: _firestore
                .collection('submissions')
                .where('assignmentId', isEqualTo: a.assignmentId)
                .snapshots(),
            builder: (context, submisSnap) {
              if (enrollSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
              }

              final enrollDocs = enrollSnap.data?.docs ?? [];
              final submisDocs = submisSnap.data?.docs ?? [];

              // Deduplicate enrollments
              final Map<String, EnrollmentModel> studentMap = {};
              for (var d in enrollDocs) {
                final e = EnrollmentModel.fromFirestore(d as DocumentSnapshot<Map<String, dynamic>>);
                studentMap[e.studentEmail.toLowerCase()] = e;
              }
              final enrolledStudents = studentMap.values.toList();

              // Submissions map
              final Map<String, SubmissionModel> subMap = {};
              for (var d in submisDocs) {
                final s = SubmissionModel.fromFirestore(d as DocumentSnapshot<Map<String, dynamic>>);
                subMap[s.studentEmail.toLowerCase()] = s;
              }

              final totalAssigned = enrolledStudents.length;
              final totalSubmitted = subMap.length;
              final totalReviewed = subMap.values.where((s) => s.mark != null).length;
              final totalLate = subMap.values.where((s) => s.isLate).length;
              final double turnoutPct = totalAssigned > 0 ? (totalSubmitted / totalAssigned) * 100 : 0.0;

              // Calculate Average Marks strictly using reviewed submissions
              final reviewedMarks = subMap.values.where((s) => s.mark != null).map((s) => s.mark!).toList();
              final double avgMarks = reviewedMarks.isNotEmpty
                  ? (reviewedMarks.reduce((acc, m) => acc + m) / reviewedMarks.length).toDouble()
                  : 0.0;

              // Filter students
              final filteredStudents = enrolledStudents.where((stu) {
                final sub = subMap[stu.studentEmail.toLowerCase()];
                final isSubmitted = sub != null;
                final isReviewed = sub?.mark != null;
                final isLate = sub != null && sub.isLate;

                // Search Filter
                final matchesSearch = stu.studentName.toLowerCase().contains(_searchQuery) ||
                    stu.studentId.toLowerCase().contains(_searchQuery) ||
                    stu.studentEmail.toLowerCase().contains(_searchQuery);

                // Status Filter
                bool matchesStatus = true;
                if (_selectedStatusFilter == 'Submitted') {
                  matchesStatus = isSubmitted && !isReviewed;
                } else if (_selectedStatusFilter == 'Reviewed') {
                  matchesStatus = isReviewed;
                } else if (_selectedStatusFilter == 'Late') {
                  matchesStatus = isLate;
                } else if (_selectedStatusFilter == 'Pending') {
                  matchesStatus = !isSubmitted;
                }

                return matchesSearch && matchesStatus;
              }).toList();

              return Column(
                children: [
                  // KPI Stats Summary Bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: const Color(0xFF1E293B),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildMetricCard('Assigned', '$totalAssigned', Colors.white, Icons.groups_rounded)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildMetricCard('Submitted', '$totalSubmitted (${turnoutPct.toStringAsFixed(0)}%)', Colors.tealAccent, Icons.assignment_turned_in_rounded)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildMetricCard('Reviewed', '$totalReviewed', Colors.greenAccent, Icons.grade_rounded)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildMetricCard('Late', '$totalLate', totalLate > 0 ? Colors.orangeAccent : Colors.grey, Icons.alarm_rounded)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildMetricCard('Avg Score', avgMarks.toStringAsFixed(1), Colors.amberAccent, Icons.analytics_rounded)),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Search Field
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

                        // Filter Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _filterOptions.map((f) {
                              final isSel = f == _selectedStatusFilter;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(f.toUpperCase()),
                                  selected: isSel,
                                  onSelected: (val) {
                                    if (val) setState(() => _selectedStatusFilter = f);
                                  },
                                  selectedColor: Colors.teal,
                                  backgroundColor: const Color(0xFF0F172A),
                                  labelStyle: TextStyle(
                                    color: isSel ? Colors.white : Colors.grey,
                                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 11,
                                  ),
                                  side: BorderSide(color: isSel ? Colors.tealAccent : Colors.white10),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Submissions Roster List
                  Expanded(
                    child: filteredStudents.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.assignment_turned_in_rounded, size: 56, color: Colors.grey.withAlpha(80)),
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
                              final sub = subMap[stu.studentEmail.toLowerCase()];
                              final isSubmitted = sub != null;
                              final isGraded = sub?.mark != null;
                              final isLate = sub != null && sub.isLate;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isGraded
                                        ? Colors.green.withAlpha(60)
                                        : (isLate ? Colors.orange.withAlpha(80) : (isSubmitted ? Colors.teal.withAlpha(50) : Colors.white10)),
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
                                              backgroundColor: isSubmitted ? Colors.teal.withAlpha(30) : Colors.grey.withAlpha(20),
                                              child: Icon(
                                                isSubmitted ? Icons.assignment_turned_in_rounded : Icons.pending_actions_rounded,
                                                color: isSubmitted ? Colors.tealAccent : Colors.grey,
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(stu.studentName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                                Text('${stu.studentId} • ${stu.studentEmail}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                              ],
                                            ),
                                          ],
                                        ),

                                        // Status Pill Badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isGraded
                                                ? Colors.green.withAlpha(30)
                                                : (isLate ? Colors.orange.withAlpha(30) : (isSubmitted ? Colors.teal.withAlpha(30) : Colors.grey.withAlpha(20))),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            isGraded
                                                ? 'REVIEWED (${sub?.mark ?? 0}/${a.totalMarks})'
                                                : (isLate ? 'LATE SUBMISSION' : (isSubmitted ? 'SUBMITTED' : 'PENDING')),
                                            style: TextStyle(
                                              color: isGraded
                                                  ? Colors.greenAccent
                                                  : (isLate ? Colors.orangeAccent : (isSubmitted ? Colors.tealAccent : Colors.grey)),
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    if (isSubmitted) ...[
                                      const SizedBox(height: 10),
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(10)),
                                        child: Row(
                                          children: [
                                            Icon(
                                              sub.fileType == 'PDF' ? Icons.picture_as_pdf_rounded : Icons.description_rounded,
                                              color: Colors.tealAccent,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(sub.fileName ?? '${stu.studentId}_assignment.${(sub.fileType ?? 'pdf').toLowerCase()}',
                                                      style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12),
                                                      overflow: TextOverflow.ellipsis),
                                                  Text('Submitted: ${sub.submittedAt.isNotEmpty ? sub.submittedAt.substring(0, sub.submittedAt.length >= 16 ? 16 : sub.submittedAt.length) : 'N/A'} • Attempt #${sub.attemptNumber}',
                                                      style: const TextStyle(color: Colors.grey, fontSize: 10)),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.download_rounded, color: Colors.tealAccent, size: 18),
                                              tooltip: 'Preview & Download File',
                                              onPressed: () => _showFilePreviewDialog(context, sub),
                                            ),
                                          ],
                                        ),
                                      ),

                                      if (sub.feedback != null && sub.feedback!.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text('Lecturer Feedback: ${sub.feedback}', style: const TextStyle(color: Colors.tealAccent, fontSize: 11, fontStyle: FontStyle.italic)),
                                      ],

                                      const SizedBox(height: 10),
                                      const Divider(color: Colors.white10, height: 1),
                                      const SizedBox(height: 6),

                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          ElevatedButton.icon(
                                            onPressed: () => _showGradeModal(context, sub, a.totalMarks),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.teal,
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                            icon: const Icon(Icons.edit_note_rounded, size: 16, color: Colors.white),
                                            label: Text(
                                              isGraded ? 'Update Marks / Feedback' : 'Grade Submission',
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 9)),
        ],
      ),
    );
  }
}
