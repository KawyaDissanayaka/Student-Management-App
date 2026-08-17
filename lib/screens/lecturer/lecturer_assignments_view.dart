import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/subject_model.dart';
import '../../models/assignment_model.dart';
import '../../models/enrollment_model.dart';
import '../../models/submission_model.dart';
import 'lecturer_assignment_submissions_screen.dart';

class LecturerAssignmentsView extends StatefulWidget {
  final SubjectModel subject;
  final String lecturerEmail;
  final String lecturerName;
  final String? lecturerId;

  const LecturerAssignmentsView({
    super.key,
    required this.subject,
    required this.lecturerEmail,
    required this.lecturerName,
    this.lecturerId,
  });

  @override
  State<LecturerAssignmentsView> createState() => _LecturerAssignmentsViewState();
}

class _LecturerAssignmentsViewState extends State<LecturerAssignmentsView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _searchQuery = '';
  String _selectedStatus = 'All';

  final List<String> _statuses = ['All', 'published', 'draft', 'closed', 'deactivated'];

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  void _showCreateEditAssignmentModal({AssignmentModel? existingAssignment}) {
    final isEditing = existingAssignment != null;
    final titleController = TextEditingController(text: existingAssignment?.title ?? '');
    final descController = TextEditingController(text: existingAssignment?.description ?? '');
    final marksController = TextEditingController(text: existingAssignment != null ? '${existingAssignment.totalMarks}' : '100');

    DateTime startDate = existingAssignment != null && existingAssignment.startDate.isNotEmpty
        ? (DateTime.tryParse(existingAssignment.startDate) ?? DateTime.now())
        : DateTime.now();

    DateTime dueDate = existingAssignment != null && existingAssignment.dueDate.isNotEmpty
        ? (DateTime.tryParse(existingAssignment.dueDate) ?? DateTime.now().add(const Duration(days: 14)))
        : DateTime.now().add(const Duration(days: 14));

    String selectedStatus = existingAssignment?.status ?? 'published';
    String selectedFileType = existingAssignment?.fileType ?? 'PDF';
    String fileSizeStr = existingAssignment?.fileSize ?? '2.4 MB';
    String attachmentUrl = existingAssignment?.attachmentUrl ?? 'https://university.edu/storage/${widget.subject.subjectCode}/assignment_${DateTime.now().millisecondsSinceEpoch}.pdf';
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
                        Icon(isEditing ? Icons.edit_calendar_rounded : Icons.assignment_add, color: Colors.tealAccent),
                        const SizedBox(width: 8),
                        Text(
                          isEditing ? 'Edit Assignment' : 'Create New Assignment',
                          style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline_rounded, size: 14, color: Colors.amberAccent),
                      const SizedBox(width: 6),
                      Text('Locked Subject: ${widget.subject.subjectCode} - ${widget.subject.subjectName}', style: const TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Assignment Title
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Assignment Title *',
                    labelStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),

                // Total Marks & Status
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: marksController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Total Marks *',
                          labelStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedStatus,
                        dropdownColor: const Color(0xFF0F172A),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Status',
                          labelStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'published', child: Text('Published', style: TextStyle(color: Colors.greenAccent))),
                          DropdownMenuItem(value: 'draft', child: Text('Draft', style: TextStyle(color: Colors.orangeAccent))),
                          DropdownMenuItem(value: 'closed', child: Text('Closed', style: TextStyle(color: Colors.grey))),
                          DropdownMenuItem(value: 'deactivated', child: Text('Deactivated', style: TextStyle(color: Colors.redAccent))),
                        ],
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedStatus = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Date Selectors: Start Date & Due Date
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: DateTime(2025, 1, 1),
                            lastDate: DateTime(2030, 12, 31),
                            builder: (context, child) => Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(primary: Colors.tealAccent, onPrimary: Colors.black, surface: Color(0xFF1E293B)),
                              ),
                              child: child!,
                            ),
                          );
                          if (picked != null) {
                            setModalState(() => startDate = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white10)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Start Date', style: TextStyle(color: Colors.grey, fontSize: 10)),
                              const SizedBox(height: 4),
                              Text(_formatDate(startDate), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: dueDate,
                            firstDate: DateTime(2025, 1, 1),
                            lastDate: DateTime(2030, 12, 31),
                            builder: (context, child) => Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(primary: Colors.tealAccent, onPrimary: Colors.black, surface: Color(0xFF1E293B)),
                              ),
                              child: child!,
                            ),
                          );
                          if (picked != null) {
                            setModalState(() => dueDate = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.tealAccent.withAlpha(80))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Due Date (Deadline) *', style: TextStyle(color: Colors.tealAccent, fontSize: 10)),
                              const SizedBox(height: 4),
                              Text(_formatDate(dueDate), style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Description / Brief
                TextField(
                  controller: descController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Assignment Brief & Guidelines *',
                    labelStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),

                // File Attachment Settings
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedFileType,
                        dropdownColor: const Color(0xFF0F172A),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Brief File Type',
                          labelStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: ['PDF', 'DOCX', 'ZIP'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedFileType = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(10)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Attached Specification', style: TextStyle(color: Colors.grey, fontSize: 10)),
                            const SizedBox(height: 2),
                            Text('Size: $fileSizeStr', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final title = titleController.text.trim();
                            final desc = descController.text.trim();
                            final marks = num.tryParse(marksController.text.trim()) ?? 100;

                            if (title.isEmpty || desc.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter title and description.'), backgroundColor: Colors.redAccent),
                              );
                              return;
                            }

                            // Validate Date Range: dueDate must not be before startDate
                            if (dueDate.isBefore(startDate)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Error: Due Date cannot be earlier than Start Date.'), backgroundColor: Colors.redAccent),
                              );
                              return;
                            }

                            setModalState(() => isSaving = true);
                            final messenger = ScaffoldMessenger.of(context);
                            final nav = Navigator.of(ctx);

                            try {
                              final assignmentData = {
                                'assignmentId': existingAssignment?.assignmentId ?? 'ASN-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                                'title': title,
                                'description': desc,
                                'subjectDocId': widget.subject.docId ?? '',
                                'subjectCode': widget.subject.subjectCode,
                                'subjectName': widget.subject.subjectName,
                                'lecturerName': widget.lecturerName,
                                'lecturerId': widget.lecturerId ?? 'LEC-1001',
                                'createdBy': widget.lecturerEmail,
                                'createdDate': DateTime.now().toIso8601String(),
                                'startDate': _formatDate(startDate),
                                'dueDate': _formatDate(dueDate),
                                'totalMarks': marks,
                                'attachmentUrl': attachmentUrl,
                                'fileType': selectedFileType,
                                'fileSize': fileSizeStr,
                                'status': selectedStatus,
                                'semester': widget.subject.semester,
                                'academicYear': widget.subject.academicYear,
                              };

                              if (!isEditing) {
                                await _firestore.collection('assignments').add(assignmentData);
                                messenger.showSnackBar(
                                  SnackBar(content: Text('Assignment "$title" created and published!'), backgroundColor: Colors.green),
                                );
                              } else {
                                await _firestore.collection('assignments').doc(existingAssignment.docId).update(assignmentData);
                                messenger.showSnackBar(
                                  SnackBar(content: Text('Assignment "$title" updated successfully!'), backgroundColor: Colors.green),
                                );
                              }

                              nav.pop();
                            } catch (e) {
                              setModalState(() => isSaving = false);
                              messenger.showSnackBar(
                                SnackBar(content: Text('Failed to save assignment: $e'), backgroundColor: Colors.redAccent),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: isSaving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Icon(isEditing ? Icons.save_rounded : Icons.check_circle_rounded, color: Colors.white),
                    label: Text(
                      isEditing ? 'Save Changes' : 'Publish Assignment to Students',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateEditAssignmentModal(),
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Create Assignment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                    hintText: 'Search assignment by title or ID...',
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
                    children: _statuses.map((st) {
                      final isSel = st == _selectedStatus;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(st.toUpperCase()),
                          selected: isSel,
                          onSelected: (val) {
                            if (val) setState(() => _selectedStatus = st);
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

          // Assignments List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('assignments')
                  .where('subjectCode', isEqualTo: widget.subject.subjectCode)
                  .snapshots(),
              builder: (context, assignSnap) {
                return StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('enrollments')
                      .where('subjectCode', isEqualTo: widget.subject.subjectCode)
                      .where('status', isEqualTo: 'active')
                      .snapshots(),
                  builder: (context, enrollSnap) {
                    return StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('submissions')
                          .where('subjectCode', isEqualTo: widget.subject.subjectCode)
                          .snapshots(),
                      builder: (context, submisSnap) {
                        if (assignSnap.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
                        }

                        final assignDocs = assignSnap.data?.docs ?? [];
                        final enrollDocs = enrollSnap.data?.docs ?? [];
                        final submisDocs = submisSnap.data?.docs ?? [];

                        // Deduplicate active enrolled students
                        final Map<String, EnrollmentModel> studentMap = {};
                        for (var d in enrollDocs) {
                          final e = EnrollmentModel.fromFirestore(d as DocumentSnapshot<Map<String, dynamic>>);
                          studentMap[e.studentEmail.toLowerCase()] = e;
                        }
                        final totalActiveEnrolled = studentMap.length;

                        // Submissions grouped by assignmentId
                        final Map<String, List<SubmissionModel>> submissionsByAssign = {};
                        for (var d in submisDocs) {
                          final s = SubmissionModel.fromFirestore(d as DocumentSnapshot<Map<String, dynamic>>);
                          submissionsByAssign.putIfAbsent(s.assignmentId, () => []).add(s);
                        }

                        // Filter assignments
                        final assignments = assignDocs
                            .map((d) => AssignmentModel.fromFirestore(d as DocumentSnapshot<Map<String, dynamic>>))
                            .where((a) {
                          final matchesSearch = a.title.toLowerCase().contains(_searchQuery) || a.assignmentId.toLowerCase().contains(_searchQuery);
                          final matchesStatus = _selectedStatus == 'All' || a.status.toLowerCase() == _selectedStatus.toLowerCase();
                          return matchesSearch && matchesStatus;
                        }).toList();

                        if (assignments.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.assignment_outlined, size: 56, color: Colors.grey.withAlpha(80)),
                                const SizedBox(height: 12),
                                const Text('No assignments found matching filter.', style: TextStyle(color: Colors.grey, fontSize: 14)),
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: () => _showCreateEditAssignmentModal(),
                                  icon: const Icon(Icons.add_rounded, color: Colors.tealAccent),
                                  label: const Text('Create First Assignment', style: TextStyle(color: Colors.tealAccent)),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: assignments.length,
                          itemBuilder: (context, index) {
                            final a = assignments[index];
                            final subs = submissionsByAssign[a.assignmentId] ?? [];
                            final submittedCount = subs.length;
                            final reviewedCount = subs.where((s) => s.mark != null).length;
                            final double rate = totalActiveEnrolled > 0 ? (submittedCount / totalActiveEnrolled) * 100 : 0.0;

                            final isPublished = a.status.toLowerCase() == 'published';
                            final isClosed = a.status.toLowerCase() == 'closed';
                            final isDraft = a.status.toLowerCase() == 'draft';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isPublished
                                      ? Colors.white10
                                      : (isClosed ? Colors.orange.withAlpha(50) : (isDraft ? Colors.amber.withAlpha(50) : Colors.red.withAlpha(50))),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(color: Colors.teal.withAlpha(30), borderRadius: BorderRadius.circular(6)),
                                        child: Text(a.assignmentId, style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isPublished
                                              ? Colors.green.withAlpha(30)
                                              : (isClosed ? Colors.grey.withAlpha(30) : Colors.orange.withAlpha(30)),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          a.status.toUpperCase(),
                                          style: TextStyle(
                                            color: isPublished ? Colors.greenAccent : (isClosed ? Colors.grey : Colors.orangeAccent),
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  Text(a.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 6),

                                  Row(
                                    children: [
                                      const Icon(Icons.event_rounded, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text('Start: ${a.startDate}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                      const SizedBox(width: 14),
                                      const Icon(Icons.alarm_on_rounded, size: 14, color: Colors.redAccent),
                                      const SizedBox(width: 4),
                                      Text('Deadline: ${a.dueDate}', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                                      const Spacer(),
                                      Text('Max: ${a.totalMarks} Marks', style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // Submission Progress Bar & Statistics
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Submissions: $submittedCount / $totalActiveEnrolled ($reviewedCount Graded)', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                          Text('${rate.toStringAsFixed(0)}% Turnout', style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: totalActiveEnrolled > 0 ? (submittedCount / totalActiveEnrolled).clamp(0.0, 1.0) : 0.0,
                                          minHeight: 6,
                                          backgroundColor: const Color(0xFF0F172A),
                                          valueColor: AlwaysStoppedAnimation<Color>(rate >= 80 ? Colors.greenAccent : Colors.tealAccent),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Divider(color: Colors.white10, height: 1),
                                  const SizedBox(height: 6),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => LecturerAssignmentSubmissionsScreen(
                                                assignment: a,
                                                subject: widget.subject,
                                                lecturerEmail: widget.lecturerEmail,
                                                lecturerName: widget.lecturerName,
                                              ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.people_outline_rounded, size: 16, color: Colors.tealAccent),
                                        label: const Text('View Submissions & Grade', style: TextStyle(color: Colors.tealAccent, fontSize: 12)),
                                      ),

                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit_rounded, size: 18, color: Colors.amberAccent),
                                            tooltip: 'Edit Assignment',
                                            onPressed: () => _showCreateEditAssignmentModal(existingAssignment: a),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              isClosed ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                                              size: 18,
                                              color: isClosed ? Colors.greenAccent : Colors.orangeAccent,
                                            ),
                                            tooltip: isClosed ? 'Reopen Submissions' : 'Close Assignment Submissions',
                                            onPressed: () async {
                                              if (a.docId != null) {
                                                final newStatus = isClosed ? 'published' : 'closed';
                                                await _firestore.collection('assignments').doc(a.docId).update({'status': newStatus});
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text('Assignment marked as ${newStatus.toUpperCase()}!'), backgroundColor: Colors.orange),
                                                  );
                                                }
                                              }
                                            },
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
