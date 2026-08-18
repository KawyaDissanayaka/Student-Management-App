import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/subject_model.dart';
import '../../models/timetable_model.dart';
import '../../models/submission_model.dart';
import 'subject_students_view.dart';
import 'lecturer_attendance_view.dart';
import 'lecturer_materials_view.dart';
import 'lecturer_assignments_view.dart';
import 'lecturer_tasks_view.dart';
import 'lecturer_announcements_view.dart';
import 'lecturer_results_view.dart';
import 'lecturer_qr_session_screen.dart';

class LecturerSubjectDetailScreen extends StatefulWidget {
  final SubjectModel subject;
  final String lecturerEmail;
  final String lecturerName;

  const LecturerSubjectDetailScreen({
    super.key,
    required this.subject,
    required this.lecturerEmail,
    required this.lecturerName,
  });

  @override
  State<LecturerSubjectDetailScreen> createState() => _LecturerSubjectDetailScreenState();
}

class _LecturerSubjectDetailScreenState extends State<LecturerSubjectDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 10, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showGradeSubmissionModal(BuildContext context, SubmissionModel submission) {
    final markController = TextEditingController(text: submission.mark != null ? '${submission.mark}' : '');
    final feedbackController = TextEditingController(text: submission.feedback ?? '');
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
                  const Text('Grade Submission', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 10),
              Text('${submission.studentName} (${submission.studentEmail})', style: const TextStyle(color: Colors.tealAccent, fontSize: 13, fontWeight: FontWeight.w600)),
              Text('Assignment: ${submission.assignmentTitle}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 16),

              TextField(
                controller: markController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Marks Awarded (0 - 100) *',
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: feedbackController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Lecturer Feedback / Comments',
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
                          if (markVal == null || markVal < 0 || markVal > 100) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter valid marks (0 - 100).'), backgroundColor: Colors.redAccent),
                            );
                            return;
                          }

                          setModalState(() => isSaving = true);
                          final messenger = ScaffoldMessenger.of(context);
                          final nav = Navigator.of(ctx);

                          try {
                            if (submission.docId != null) {
                              await _firestore.collection('submissions').doc(submission.docId).update({
                                'mark': markVal,
                                'feedback': feedbackController.text.trim(),
                                'gradedAt': DateTime.now().toIso8601String(),
                                'gradedBy': widget.lecturerName,
                              });
                            }
                            nav.pop();
                            messenger.showSnackBar(
                              SnackBar(content: Text('Marks saved for ${submission.studentName}!'), backgroundColor: Colors.green),
                            );
                          } catch (e) {
                            setModalState(() => isSaving = false);
                            messenger.showSnackBar(
                              SnackBar(content: Text('Failed to save grade: $e'), backgroundColor: Colors.redAccent),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle_rounded, color: Colors.white),
                  label: const Text('Save & Post Grade', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    final s = widget.subject;

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
            Text(s.subjectCode, style: const TextStyle(color: Colors.amberAccent, fontSize: 13, fontWeight: FontWeight.bold)),
            Text(s.subjectName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_2_rounded, color: Colors.tealAccent),
            tooltip: 'Start Dynamic QR Attendance',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LecturerQrSessionScreen(
                    subject: widget.subject,
                    lecturerEmail: widget.lecturerEmail,
                    lecturerName: widget.lecturerName,
                    lecturerId: 'LEC-1001',
                  ),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.amberAccent,
          labelColor: Colors.amberAccent,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.info_outline, size: 16)),
            Tab(text: 'Students', icon: Icon(Icons.people_alt_outlined, size: 16)),
            Tab(text: 'Timetable', icon: Icon(Icons.calendar_month_outlined, size: 16)),
            Tab(text: 'Attendance', icon: Icon(Icons.how_to_reg_outlined, size: 16)),
            Tab(text: 'Materials', icon: Icon(Icons.description_outlined, size: 16)),
            Tab(text: 'Assignments', icon: Icon(Icons.assignment_outlined, size: 16)),
            Tab(text: 'Tasks', icon: Icon(Icons.task_alt_outlined, size: 16)),
            Tab(text: 'Announce', icon: Icon(Icons.campaign_outlined, size: 16)),
            Tab(text: 'Submissions', icon: Icon(Icons.assignment_turned_in_outlined, size: 16)),
            Tab(text: 'Results', icon: Icon(Icons.grade_outlined, size: 16)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildStudentsTab(),
          _buildTimetableTab(),
          _buildAttendanceTab(),
          _buildMaterialsTab(),
          _buildAssignmentsTab(),
          _buildTasksTab(),
          _buildAnnouncementsTab(),
          _buildSubmissionsTab(),
          _buildResultsTab(),
        ],
      ),
    );
  }

  // ─── 1. OVERVIEW TAB ───────────────────────────────────────────────────────
  Widget _buildOverviewTab() {
    final s = widget.subject;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.amber.withAlpha(30), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.book_rounded, color: Colors.amberAccent, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.subjectName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('${s.subjectCode} • 3 Academic Credits', style: const TextStyle(color: Colors.amberAccent, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white10),
              const SizedBox(height: 12),
              const Text('Module Description', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 6),
              Text(
                s.description.isNotEmpty ? s.description : 'Standard theoretical and practical curriculum for undergraduate students.',
                style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white10),
              const SizedBox(height: 12),
              _buildMetaRow('Assigned Lecturer', s.lecturerName),
              _buildMetaRow('Academic Term', '${s.semester} • ${s.academicYear}'),
              _buildMetaRow('Course Level', 'Undergraduate Degree'),
              _buildMetaRow('Status', s.status.toUpperCase(), isGood: s.status == 'active'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetaRow(String label, String value, {bool isGood = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(value, style: TextStyle(color: isGood ? Colors.greenAccent : Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }

  // ─── 2. STUDENTS TAB ───────────────────────────────────────────────────────
  Widget _buildStudentsTab() {
    return SubjectStudentsView(
      subject: widget.subject,
      lecturerEmail: widget.lecturerEmail,
      lecturerName: widget.lecturerName,
    );
  }

  // ─── 3. TIMETABLE TAB ──────────────────────────────────────────────────────
  Widget _buildTimetableTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('timetable')
          .where('subjectCode', isEqualTo: widget.subject.subjectCode)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
        }

        final schedules = (snapshot.data?.docs ?? [])
            .map((d) => TimetableModel.fromFirestore(d))
            .where((s) => s.status != 'cancelled')
            .toList();

        if (schedules.isEmpty) {
          return const Center(child: Text('No timetable schedules assigned for this subject yet.', style: TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: schedules.length,
          itemBuilder: (context, index) {
            final s = schedules[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.amber.withAlpha(30), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.calendar_month_rounded, color: Colors.amberAccent, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${s.dayOfWeek} (${s.startTime} - ${s.endTime})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text('Venue: ${s.hallName} • Batch ${s.batch}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.teal.withAlpha(30), borderRadius: BorderRadius.circular(6)),
                    child: Text(s.mode.toUpperCase(), style: const TextStyle(color: Colors.tealAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─── 4. ATTENDANCE TAB ─────────────────────────────────────────────────────
  Widget _buildAttendanceTab() {
    return LecturerAttendanceView(
      subject: widget.subject,
      lecturerEmail: widget.lecturerEmail,
      lecturerName: widget.lecturerName,
    );
  }

  // ─── 5. MATERIALS TAB ──────────────────────────────────────────────────────
  Widget _buildMaterialsTab() {
    return LecturerMaterialsView(
      subject: widget.subject,
      lecturerEmail: widget.lecturerEmail,
      lecturerName: widget.lecturerName,
    );
  }

  // ─── 6. ASSIGNMENTS TAB ────────────────────────────────────────────────────
  Widget _buildAssignmentsTab() {
    return LecturerAssignmentsView(
      subject: widget.subject,
      lecturerEmail: widget.lecturerEmail,
      lecturerName: widget.lecturerName,
    );
  }

  // ─── 7. TASKS TAB ──────────────────────────────────────────────────────────
  Widget _buildTasksTab() {
    return LecturerTasksView(
      subject: widget.subject,
      lecturerEmail: widget.lecturerEmail,
      lecturerName: widget.lecturerName,
    );
  }

  // ─── 8. ANNOUNCEMENTS TAB ──────────────────────────────────────────────────
  Widget _buildAnnouncementsTab() {
    return LecturerAnnouncementsView(
      subject: widget.subject,
      lecturerEmail: widget.lecturerEmail,
      lecturerName: widget.lecturerName,
    );
  }

  // ─── 7. SUBMISSIONS TAB ────────────────────────────────────────────────────
  Widget _buildSubmissionsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('submissions')
          .where('subjectCode', isEqualTo: widget.subject.subjectCode)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
        }

        final submissions = (snapshot.data?.docs ?? [])
            .map((d) => SubmissionModel.fromFirestore(d as DocumentSnapshot<Map<String, dynamic>>))
            .toList();

        if (submissions.isEmpty) {
          return const Center(child: Text('No student submissions logged for this subject.', style: TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: submissions.length,
          itemBuilder: (context, index) {
            final sub = submissions[index];
            final isGraded = sub.mark != null;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isGraded ? Colors.green.withAlpha(60) : Colors.orange.withAlpha(80)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(sub.studentName.isNotEmpty ? sub.studentName : sub.studentEmail, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isGraded ? Colors.green.withAlpha(30) : Colors.orange.withAlpha(30),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isGraded ? 'GRADE: ${sub.mark}/100' : 'AWAITING GRADE',
                          style: TextStyle(color: isGraded ? Colors.greenAccent : Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Assignment: ${sub.assignmentTitle}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  if (sub.feedback != null && sub.feedback!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Feedback: ${sub.feedback}', style: const TextStyle(color: Colors.tealAccent, fontSize: 11, fontStyle: FontStyle.italic)),
                  ],
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () => _showGradeSubmissionModal(context, sub),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.edit_note_rounded, size: 16, color: Colors.white),
                      label: Text(isGraded ? 'Update Grade' : 'Grade Submission', style: const TextStyle(color: Colors.white, fontSize: 12)),
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

  // ─── 9. RESULTS TAB ────────────────────────────────────────────────────────
  Widget _buildResultsTab() {
    return LecturerResultsView(
      subject: widget.subject,
      lecturerEmail: widget.lecturerEmail,
      lecturerName: widget.lecturerName,
    );
  }
}
