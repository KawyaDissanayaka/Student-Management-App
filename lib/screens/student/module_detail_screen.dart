import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/student_portal_service.dart';
import '../../services/assignment_service.dart';
import '../../services/attendance_service.dart';
import '../../models/material_model.dart';
import '../../models/assignment_model.dart';
import '../../models/attendance_model.dart';
import '../../models/announcement_model.dart';
import '../../models/timetable_model.dart';
import '../../models/exam_result_model.dart';
import '../../models/task_model.dart';
import '../../models/submission_model.dart';

class ModuleDetailScreen extends StatefulWidget {
  final String subjectCode;
  final String subjectName;
  final String lecturerName;
  final String semester;
  final int credits;
  final String description;
  final String studentEmail;
  final String studentName;
  final String studentId;

  const ModuleDetailScreen({
    super.key,
    required this.subjectCode,
    required this.subjectName,
    required this.lecturerName,
    required this.semester,
    this.credits = 3,
    this.description = 'Comprehensive academic module focusing on theoretical principles, analytical methods, and hands-on laboratory coursework.',
    required this.studentEmail,
    required this.studentName,
    this.studentId = 'STU-1002',
  });

  @override
  State<ModuleDetailScreen> createState() => _ModuleDetailScreenState();
}

class _ModuleDetailScreenState extends State<ModuleDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final StudentPortalService _portalService = StudentPortalService();
  final AssignmentService _assignmentService = AssignmentService();
  final AttendanceService _attendanceService = AttendanceService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.subjectCode, style: const TextStyle(color: Colors.tealAccent, fontSize: 13, fontWeight: FontWeight.bold)),
            Text(widget.subjectName, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.tealAccent,
          labelColor: Colors.tealAccent,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.info_outline_rounded, size: 15)),
            Tab(text: 'Lectures', icon: Icon(Icons.calendar_month_rounded, size: 15)),
            Tab(text: 'Materials', icon: Icon(Icons.description_rounded, size: 15)),
            Tab(text: 'Assignments', icon: Icon(Icons.assignment_rounded, size: 15)),
            Tab(text: 'Tasks', icon: Icon(Icons.task_alt_rounded, size: 15)),
            Tab(text: 'Attendance', icon: Icon(Icons.how_to_reg_rounded, size: 15)),
            Tab(text: 'Results', icon: Icon(Icons.grade_rounded, size: 15)),
            Tab(text: 'Notices', icon: Icon(Icons.campaign_rounded, size: 15)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildLecturesTab(),
          _buildMaterialsTab(),
          _buildAssignmentsTab(),
          _buildTasksTab(),
          _buildAttendanceTab(),
          _buildResultsTab(),
          _buildNoticesTab(),
        ],
      ),
    );
  }

  // ─── 1. OVERVIEW TAB ───────────────────────────────────────────────────────
  Widget _buildOverviewTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
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
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.teal.withAlpha(30), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.book_rounded, color: Colors.tealAccent, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.subjectName, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                        Text('${widget.subjectCode} • ${widget.credits} Academic Credits', style: const TextStyle(color: Colors.tealAccent, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(color: Colors.white10),
              const SizedBox(height: 10),
              const Text('Module Description & Syllabus Scope', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              Text(
                widget.description.isNotEmpty ? widget.description : 'Core module covering theoretical fundamentals and practical laboratory coursework.',
                style: const TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 14),
              const Divider(color: Colors.white10),
              const SizedBox(height: 10),
              _buildOverviewMetaRow('Assigned Lecturer', widget.lecturerName.isNotEmpty ? widget.lecturerName : 'Faculty Staff'),
              _buildOverviewMetaRow('Academic Department', 'Department of Computing & Information Systems'),
              _buildOverviewMetaRow('Academic Semester', widget.semester),
              _buildOverviewMetaRow('Academic Year', '2025/2026'),
              _buildOverviewMetaRow('Assessment Scheme', 'Continuous Assessment (40%) + Final Examination (60%)'),
              _buildOverviewMetaRow('Attendance Policy', 'Minimum 80% attendance required for examination eligibility'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 2. LECTURES / TIMETABLE TAB ───────────────────────────────────────────
  Widget _buildLecturesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('timetables')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
        }

        final docs = snapshot.data?.docs ?? [];
        final lectures = docs
            .map((d) => TimetableModel.fromFirestore(d as DocumentSnapshot<Map<String, dynamic>>))
            .where((t) => t.subjectCode.toUpperCase() == widget.subjectCode.toUpperCase())
            .toList();

        if (lectures.isEmpty) {
          return const Center(
            child: Text('No scheduled lecture sessions found for this module.', style: TextStyle(color: Colors.grey)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: lectures.length,
          itemBuilder: (context, index) {
            final t = lectures[index];

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(color: Colors.teal.withAlpha(30), borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      children: [
                        Text(t.dayOfWeek.toUpperCase(), style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                        Text(t.startTime, style: const TextStyle(color: Colors.white, fontSize: 11)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${t.subjectCode} - ${t.subjectName}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 3),
                        Text('Hall: ${t.hall} • Time: ${t.startTime} - ${t.endTime}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                        Text('Lecturer: ${t.lecturerName}', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.green.withAlpha(30), borderRadius: BorderRadius.circular(4)),
                    child: const Text('ACTIVE', style: TextStyle(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─── 3. MATERIALS TAB ──────────────────────────────────────────────────────
  Widget _buildMaterialsTab() {
    return StreamBuilder<List<MaterialModel>>(
      stream: _portalService.getMaterialsForSubject(widget.subjectCode),
      builder: (context, snapshot) {
        final materials = snapshot.data ?? [];

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
        }

        if (materials.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open_rounded, size: 54, color: Colors.grey.withAlpha(100)),
                const SizedBox(height: 12),
                const Text('No lecture slides uploaded yet.', style: TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 6),
                const Text('Materials will appear here once published by lecturer.', style: TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: materials.length,
          itemBuilder: (context, index) {
            final m = materials[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: m.fileType == 'PDF' ? Colors.red.withAlpha(30) : Colors.orange.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      m.fileType == 'PDF' ? Icons.picture_as_pdf_rounded : Icons.slideshow_rounded,
                      color: m.fileType == 'PDF' ? Colors.redAccent : Colors.orangeAccent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 3),
                        Text('Week ${m.weekNumber} • ${m.fileType} • ${m.fileSize}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.file_download_rounded, color: Colors.tealAccent),
                    tooltip: 'Download Material',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Downloading "${m.title}"...'), backgroundColor: Colors.teal),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─── 4. ASSIGNMENTS TAB ────────────────────────────────────────────────────
  Widget _buildAssignmentsTab() {
    return StreamBuilder<List<AssignmentModel>>(
      stream: _assignmentService.getPublishedAssignmentsForSubjects([widget.subjectCode]),
      builder: (context, snapshot) {
        final assignments = snapshot.data ?? [];

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
        }

        if (assignments.isEmpty) {
          return const Center(
            child: Text('No active assignments for this module.', style: TextStyle(color: Colors.grey)),
          );
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('submissions')
              .where('studentEmail', isEqualTo: widget.studentEmail.trim().toLowerCase())
              .snapshots(),
          builder: (context, subSnapshot) {
            final subDocs = subSnapshot.data?.docs ?? [];
            final studentSubmissions = subDocs.map((d) => SubmissionModel.fromFirestore(d)).toList();

            return ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: assignments.length,
              itemBuilder: (context, index) {
                final a = assignments[index];
                final sub = studentSubmissions.cast<SubmissionModel?>().firstWhere(
                      (s) => s?.assignmentId == a.assignmentId,
                      orElse: () => null,
                    );

                final isSubmitted = sub != null;
                final isGraded = sub?.isGraded ?? false;
                final isLate = sub?.isLate ?? false;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isGraded ? Colors.green.withAlpha(80) : Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: Colors.orange.withAlpha(30), borderRadius: BorderRadius.circular(6)),
                            child: Text(a.assignmentId, style: const TextStyle(color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isGraded
                                  ? Colors.green.withAlpha(30)
                                  : (isLate
                                      ? Colors.red.withAlpha(30)
                                      : (isSubmitted ? Colors.cyan.withAlpha(30) : Colors.grey.withAlpha(30))),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isGraded
                                  ? 'GRADED'
                                  : (isLate
                                      ? 'LATE SUBMISSION'
                                      : (isSubmitted ? 'SUBMITTED' : 'NOT SUBMITTED')),
                              style: TextStyle(
                                color: isGraded
                                    ? Colors.greenAccent
                                    : (isLate
                                        ? Colors.redAccent
                                        : (isSubmitted ? Colors.cyanAccent : Colors.grey)),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(a.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(a.description, style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Text('Due Date: ${a.dueDate} • Max Marks: ${a.totalMarks}', style: const TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.w600)),

                      // If graded, show marks and feedback
                      if (isGraded && sub != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.greenAccent.withAlpha(50))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Awarded Score: ${sub.marks ?? 0} / ${a.totalMarks}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                                  Text('Graded by: ${sub.gradedBy ?? "Lecturer"}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                                ],
                              ),
                              if (sub.feedback != null && sub.feedback!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text('Feedback: "${sub.feedback}"', style: const TextStyle(color: Colors.white70, fontSize: 11, fontStyle: FontStyle.italic)),
                              ],
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 10),
                      const Divider(color: Colors.white10, height: 1),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Semester: ${a.semester}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                          ElevatedButton.icon(
                            onPressed: () => _showSubmitModal(context, a),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSubmitted ? Colors.cyan[800] : Colors.teal,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            icon: Icon(isSubmitted ? Icons.edit_document : Icons.upload_file_rounded, size: 12, color: Colors.white),
                            label: Text(isSubmitted ? 'Resubmit Work' : 'Submit Work', style: const TextStyle(color: Colors.white, fontSize: 11)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showSubmitModal(BuildContext context, AssignmentModel assignment) {
    final noteController = TextEditingController();
    bool isUploading = false;

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
                  Text('Submit ${assignment.assignmentId}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 12),
              Text(assignment.title, style: const TextStyle(color: Colors.tealAccent, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 14),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.tealAccent.withAlpha(100)),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.cloud_upload_outlined, size: 32, color: Colors.tealAccent),
                    SizedBox(height: 6),
                    Text('Assignment_Report_Final.pdf', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    SizedBox(height: 2),
                    Text('PDF Document • 2.8 MB (Ready to upload)', style: TextStyle(color: Colors.grey, fontSize: 10)),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: noteController,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: InputDecoration(
                  labelText: 'Submission Note (Optional)',
                  labelStyle: const TextStyle(color: Colors.grey, fontSize: 11),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: isUploading
                      ? null
                      : () async {
                          setModalState(() => isUploading = true);
                          final messenger = ScaffoldMessenger.of(context);
                          final nav = Navigator.of(ctx);

                          try {
                            final now = DateTime.now();
                            final subStatus = SubmissionModel.determineSubmissionStatus(
                              submittedAt: now,
                              dueDate: assignment.dueDate,
                            );

                            final subData = {
                              'submissionId': 'SUB-${DateTime.now().millisecondsSinceEpoch}',
                              'assignmentId': assignment.assignmentId,
                              'assignmentDocId': assignment.docId,
                              'assignmentTitle': assignment.title,
                              'moduleId': widget.subjectCode,
                              'subjectCode': widget.subjectCode,
                              'subjectName': widget.subjectName,
                              'studentDocId': widget.studentId,
                              'studentId': widget.studentId,
                              'studentEmail': widget.studentEmail.trim().toLowerCase(),
                              'studentName': widget.studentName,
                              'submittedAt': now.toIso8601String(),
                              'isLate': subStatus == 'Late',
                              'fileName': 'Assignment_Report_Final.pdf',
                              'fileSize': '2.8 MB',
                              'fileUrl': 'https://firebasestorage.googleapis.com/v0/b/studentapp/o/submissions%2F${widget.subjectCode}%2F${assignment.assignmentId}%2F${widget.studentId}_Report.pdf?alt=media',
                              'attachmentUrl': 'https://firebasestorage.googleapis.com/v0/b/studentapp/o/submissions%2F${widget.subjectCode}%2F${assignment.assignmentId}%2F${widget.studentId}_Report.pdf?alt=media',
                              'notes': noteController.text.trim(),
                              'status': subStatus,
                            };

                            await FirebaseFirestore.instance.collection('submissions').add(subData);
                            await FirebaseFirestore.instance.collection('assignmentSubmissions').add(subData);

                            nav.pop();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Assignment submitted successfully ($subStatus)!'),
                                backgroundColor: subStatus == 'Late' ? Colors.orange : Colors.green,
                              ),
                            );
                          } catch (e) {
                            setModalState(() => isUploading = false);
                            messenger.showSnackBar(
                              SnackBar(content: Text('Submission failed: $e'), backgroundColor: Colors.redAccent),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  icon: isUploading
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded, color: Colors.white, size: 14),
                  label: const Text('Confirm & Submit Assignment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── 5. TASKS TAB ──────────────────────────────────────────────────────────
  Widget _buildTasksTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tasks')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
        }

        final docs = snapshot.data?.docs ?? [];
        final tasks = docs
            .map((d) => TaskModel.fromFirestore(d))
            .where((t) =>
                (t.moduleId.toUpperCase() == widget.subjectCode.toUpperCase() ||
                    t.subjectCode?.toUpperCase() == widget.subjectCode.toUpperCase()) &&
                !t.isDraft) // Students only see Published tasks
            .toList();

        if (tasks.isEmpty) {
          return const Center(
            child: Text('No active coursework tasks for this module.', style: TextStyle(color: Colors.grey)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final t = tasks[index];
            final effectiveSt = t.effectiveStatus;
            final isDone = effectiveSt == 'completed';
            final isOverdue = effectiveSt == 'overdue';
            final isInProgress = effectiveSt == 'in_progress';

            Color statusColor = Colors.amberAccent;
            if (isDone) {
              statusColor = Colors.greenAccent;
            } else if (isOverdue) {
              statusColor = Colors.redAccent;
            } else if (isInProgress) {
              statusColor = Colors.cyanAccent;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withAlpha(50)),
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
                            decoration: BoxDecoration(color: Colors.purple.withAlpha(30), borderRadius: BorderRadius.circular(4)),
                            child: Text(t.priority.toUpperCase(), style: const TextStyle(color: Colors.purpleAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: statusColor.withAlpha(30), borderRadius: BorderRadius.circular(4)),
                            child: Text(
                              effectiveSt.replaceAll('_', ' ').toUpperCase(),
                              style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      Text('Due: ${t.dueDate}', style: TextStyle(color: isOverdue ? Colors.redAccent : Colors.grey, fontSize: 11, fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal)),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Text(
                    t.title,
                    style: TextStyle(
                      color: isDone ? Colors.white54 : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (t.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(t.description, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                  const SizedBox(height: 10),
                  const Divider(color: Colors.white10, height: 1),
                  const SizedBox(height: 6),

                  // Student Status Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('My Status:', style: TextStyle(color: Colors.grey, fontSize: 11)),
                      Row(
                        children: [
                          // In Progress Toggle
                          if (!isDone)
                            TextButton.icon(
                              onPressed: () async {
                                if (t.docId != null) {
                                  await FirebaseFirestore.instance.collection('tasks').doc(t.docId).update({
                                    'status': isInProgress ? 'pending' : 'in_progress',
                                  });
                                }
                              },
                              icon: Icon(isInProgress ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded, size: 14, color: Colors.cyanAccent),
                              label: Text(isInProgress ? 'Pause' : 'Start Task', style: const TextStyle(color: Colors.cyanAccent, fontSize: 11)),
                            ),

                          // Complete Toggle
                          TextButton.icon(
                            onPressed: () async {
                              if (t.docId != null) {
                                final newSt = isDone ? 'pending' : 'completed';
                                await FirebaseFirestore.instance.collection('tasks').doc(t.docId).update({
                                  'status': newSt,
                                  'completedAt': isDone ? null : DateTime.now().toIso8601String(),
                                  'completedBy': isDone ? null : widget.studentName,
                                });
                              }
                            },
                            icon: Icon(isDone ? Icons.replay_rounded : Icons.check_circle_rounded, size: 14, color: isDone ? Colors.grey : Colors.greenAccent),
                            label: Text(isDone ? 'Reopen' : 'Mark Done', style: TextStyle(color: isDone ? Colors.grey : Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─── 6. ATTENDANCE TAB ─────────────────────────────────────────────────────
  Widget _buildAttendanceTab() {
    return StreamBuilder<List<AttendanceModel>>(
      stream: _attendanceService.getStudentAttendanceStream(widget.studentEmail),
      builder: (context, snapshot) {
        final records = (snapshot.data ?? []).where((r) => r.subjectCode.toUpperCase() == widget.subjectCode.toUpperCase() && r.status != 'cancelled').toList();

        final totalClasses = records.length;
        final presentCount = records.where((r) => r.status == 'present' || r.status == 'late').length;
        final absentCount = records.where((r) => r.status == 'absent').length;
        final pct = totalClasses > 0 ? (presentCount / totalClasses) * 100 : 100.0;

        return ListView(
          padding: const EdgeInsets.all(14),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white10)),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: pct >= 80 ? Colors.green.withAlpha(30) : Colors.red.withAlpha(30),
                    child: Text(
                      '${pct.toStringAsFixed(0)}%',
                      style: TextStyle(color: pct >= 80 ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Module Attendance Rate', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text('$presentCount Present • $absentCount Absent / $totalClasses Total Sessions', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            const Text('Class Attendance Session Log', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),

            if (records.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: Text('No attendance sessions logged for this module yet.', style: TextStyle(color: Colors.grey))),
              )
            else
              ...records.map((r) {
                final isPresent = r.status == 'present' || r.status == 'late';
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(r.date, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: isPresent ? Colors.green.withAlpha(30) : Colors.red.withAlpha(30), borderRadius: BorderRadius.circular(4)),
                        child: Text(r.status.toUpperCase(), style: TextStyle(color: isPresent ? Colors.greenAccent : Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  // ─── 7. RESULTS TAB (ONLY PUBLISHED) ───────────────────────────────────────
  Widget _buildResultsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('exam_results')
          .where('studentId', isEqualTo: widget.studentId)
          .where('isPublished', isEqualTo: true) // Strict security rule: Only published results
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
        }

        final docs = snapshot.data?.docs ?? [];
        final results = docs
            .map((d) => ExamResultModel.fromFirestore(d))
            .where((r) => r.moduleCode.toUpperCase() == widget.subjectCode.toUpperCase())
            .toList();

        if (results.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.hourglass_empty_rounded, size: 54, color: Colors.grey.withAlpha(100)),
                  const SizedBox(height: 14),
                  const Text('No Published Examination Results', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  const Text(
                    'Marks will appear here once officially approved and published by the Academic Administration.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(14),
          children: results.map((res) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.amber.withAlpha(40)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: Colors.green.withAlpha(40), borderRadius: BorderRadius.circular(4)),
                        child: const Text('OFFICIALLY PUBLISHED', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 10)),
                      ),
                      Text('Published: ${res.publishedAt?.substring(0, 10) ?? "Verified"}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Score Obtained', style: TextStyle(color: Colors.grey, fontSize: 11)),
                          Text('${res.obtainedMarks.toStringAsFixed(0)} / ${res.maxMarks.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Final Grade', style: TextStyle(color: Colors.grey, fontSize: 11)),
                          Text('${res.grade} (${res.gradePoint.toStringAsFixed(1)} GP)', style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 20)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 6),
                  Text('Exam ID: ${res.examId} • Student ID: ${res.studentId}', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ─── 8. NOTICES TAB ────────────────────────────────────────────────────────
  Widget _buildNoticesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('announcements').snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.hasData ? snapshot.data!.docs : [];
        final notices = docs.map((d) => AnnouncementModel.fromFirestore(d)).where((a) {
          if (a.effectiveStatus != 'published') return false;
          if (a.title.toLowerCase().contains(widget.subjectCode.toLowerCase()) ||
              a.description.toLowerCase().contains(widget.subjectCode.toLowerCase()) ||
              a.audience == 'all_students' ||
              a.audience == 'all_users') {
            return true;
          }
          return false;
        }).toList();

        if (notices.isEmpty) {
          return const Center(child: Text('No announcements for this module.', style: TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: notices.length,
          itemBuilder: (context, index) {
            final n = notices[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(n.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(n.publishDate, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(n.description, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
