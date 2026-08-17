import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/student_portal_service.dart';
import '../../services/assignment_service.dart';
import '../../services/attendance_service.dart';
import '../../models/material_model.dart';
import '../../models/assignment_model.dart';
import '../../models/attendance_model.dart';
import '../../models/announcement_model.dart';

class ModuleDetailScreen extends StatefulWidget {
  final String subjectCode;
  final String subjectName;
  final String lecturerName;
  final String semester;
  final int credits;
  final String description;
  final String studentEmail;
  final String studentName;

  const ModuleDetailScreen({
    super.key,
    required this.subjectCode,
    required this.subjectName,
    required this.lecturerName,
    required this.semester,
    this.credits = 3,
    this.description = 'Comprehensive module focusing on theory and practical implementation.',
    required this.studentEmail,
    required this.studentName,
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
    _tabController = TabController(length: 5, vsync: this);
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
            Text(widget.subjectName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.tealAccent,
          labelColor: Colors.tealAccent,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.info_outline, size: 16)),
            Tab(text: 'Materials', icon: Icon(Icons.description_outlined, size: 16)),
            Tab(text: 'Assignments', icon: Icon(Icons.assignment_outlined, size: 16)),
            Tab(text: 'Attendance', icon: Icon(Icons.calendar_month_outlined, size: 16)),
            Tab(text: 'Notices', icon: Icon(Icons.campaign_outlined, size: 16)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildMaterialsTab(),
          _buildAssignmentsTab(),
          _buildAttendanceTab(),
          _buildNoticesTab(),
        ],
      ),
    );
  }

  // ─── 1. OVERVIEW TAB ───────────────────────────────────────────────────────
  Widget _buildOverviewTab() {
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.teal.withAlpha(30), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.book_rounded, color: Colors.tealAccent, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.subjectName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('${widget.subjectCode} • ${widget.credits} Academic Credits', style: const TextStyle(color: Colors.tealAccent, fontSize: 13)),
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
                widget.description.isNotEmpty ? widget.description : 'Core module covering theoretical fundamentals and practical laboratory coursework.',
                style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white10),
              const SizedBox(height: 12),
              _buildOverviewMetaRow('Assigned Lecturer', widget.lecturerName.isNotEmpty ? widget.lecturerName : 'Faculty Staff'),
              _buildOverviewMetaRow('Academic Semester', widget.semester),
              _buildOverviewMetaRow('Grading Weightage', 'Continuous Assessment (40%) + Final Exam (60%)'),
              _buildOverviewMetaRow('Minimum Attendance Required', '80% (University Standard)'),
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
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }

  // ─── 2. MATERIALS TAB ──────────────────────────────────────────────────────
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
          padding: const EdgeInsets.all(16),
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
                        Text(m.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 3),
                        Text('Week ${m.weekNumber} • ${m.fileType} • ${m.fileSize}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
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

  // ─── 3. ASSIGNMENTS TAB ────────────────────────────────────────────────────
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

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: assignments.length,
          itemBuilder: (context, index) {
            final a = assignments[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.orange.withAlpha(30),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          a.assignmentId,
                          style: const TextStyle(color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text('Due: ${a.dueDate}', style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(a.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(a.description, style: const TextStyle(color: Colors.grey, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white10, height: 1),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Max Marks: ${a.maxMarks}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ElevatedButton.icon(
                        onPressed: () {
                          _showSubmitModal(context, a);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.upload_file_rounded, size: 14, color: Colors.white),
                        label: const Text('Submit Work', style: TextStyle(color: Colors.white, fontSize: 12)),
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

  void _showSubmitModal(BuildContext context, AssignmentModel assignment) {
    final noteController = TextEditingController();
    bool isUploading = false;

    showModalBottomSheet(
      context: context,
      isScrollable: true,
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
                  Text('Submit ${assignment.assignmentId}', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 12),
              Text(assignment.title, style: const TextStyle(color: Colors.tealAccent, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),

              // File upload simulator box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.tealAccent.withAlpha(100), style: BorderStyle.solid),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.cloud_upload_outlined, size: 36, color: Colors.tealAccent),
                    const SizedBox(height: 8),
                    const Text('Assignment_Final_Report.pdf', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 2),
                    const Text('PDF Document • 2.8 MB (Ready to upload)', style: TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: noteController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Submission Note (Optional)',
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
                  onPressed: isUploading
                      ? null
                      : () async {
                          setModalState(() => isUploading = true);
                          final messenger = ScaffoldMessenger.of(context);
                          final nav = Navigator.of(ctx);

                          try {
                            await FirebaseFirestore.instance.collection('submissions').add({
                              'assignmentId': assignment.assignmentId,
                              'assignmentDocId': assignment.docId,
                              'assignmentTitle': assignment.title,
                              'subjectCode': widget.subjectCode,
                              'studentEmail': widget.studentEmail.trim().toLowerCase(),
                              'studentName': widget.studentName,
                              'submittedAt': DateTime.now().toIso8601String(),
                              'fileName': 'Assignment_Final_Report.pdf',
                              'fileSize': '2.8 MB',
                              'notes': noteController.text.trim(),
                              'status': 'submitted',
                            });

                            nav.pop();
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Assignment submitted successfully!'), backgroundColor: Colors.green),
                            );
                          } catch (e) {
                            setModalState(() => isUploading = false);
                            messenger.showSnackBar(
                              SnackBar(content: Text('Submission failed: $e'), backgroundColor: Colors.redAccent),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: isUploading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded, color: Colors.white),
                  label: const Text('Confirm & Submit Assignment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── 4. ATTENDANCE TAB ─────────────────────────────────────────────────────
  Widget _buildAttendanceTab() {
    return StreamBuilder<List<AttendanceModel>>(
      stream: _attendanceService.getStudentAttendanceStream(widget.studentEmail),
      builder: (context, snapshot) {
        final records = (snapshot.data ?? []).where((r) => r.subjectCode == widget.subjectCode && r.status != 'cancelled').toList();

        final totalClasses = records.length;
        final presentCount = records.where((r) => r.status == 'present' || r.status == 'late').length;
        final pct = totalClasses > 0 ? (presentCount / totalClasses) * 100 : 0.0;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Attendance Summary Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: pct >= 80 ? Colors.green.withAlpha(30) : Colors.red.withAlpha(30),
                    child: Text(
                      '${pct.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: pct >= 80 ? Colors.greenAccent : Colors.redAccent,
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
                        Text('Your Attendance Rate', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 2),
                        Text('$presentCount Attended / $totalClasses Total Sessions', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const Text('Class Attendance Log', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 10),

            if (records.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: Text('No attendance records logged for this module yet.', style: TextStyle(color: Colors.grey))),
              )
            else
              ...records.map((r) {
                final isPresent = r.status == 'present' || r.status == 'late';
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(r.date, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: isPresent ? Colors.green.withAlpha(30) : Colors.red.withAlpha(30),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          r.status.toUpperCase(),
                          style: TextStyle(
                            color: isPresent ? Colors.greenAccent : Colors.redAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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

  // ─── 5. NOTICES TAB ────────────────────────────────────────────────────────
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
          padding: const EdgeInsets.all(16),
          itemCount: notices.length,
          itemBuilder: (context, index) {
            final n = notices[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(n.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(n.publishDate, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(n.description, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
