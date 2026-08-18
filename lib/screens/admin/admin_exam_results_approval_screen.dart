import 'package:flutter/material.dart';
import '../../models/exam_model.dart';
import '../../models/exam_result_model.dart';
import '../../services/exam_results_service.dart';

class AdminExamResultsApprovalScreen extends StatefulWidget {
  final ExamModel exam;

  const AdminExamResultsApprovalScreen({super.key, required this.exam});

  @override
  State<AdminExamResultsApprovalScreen> createState() => _AdminExamResultsApprovalScreenState();
}

class _AdminExamResultsApprovalScreenState extends State<AdminExamResultsApprovalScreen> {
  final ExamResultsService _resultsService = ExamResultsService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  bool _isProcessing = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─── REJECTION MODAL WITH MANDATORY REASON ─────────────────────────────────
  void _showRejectReasonDialog(List<ExamResultModel> results) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Row(
          children: [
            Icon(Icons.assignment_return_rounded, color: Colors.redAccent, size: 22),
            SizedBox(width: 8),
            Text('Reject & Return Results', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please provide a specific reason for rejection. The lecturer will be notified and results will be unlocked for corrections.',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: reasonController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'e.g. Discrepancy in Question 3 grading / Missing marks for Student STU-1002',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white24)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.redAccent)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Rejection reason cannot be empty.'), backgroundColor: Colors.redAccent),
                );
                return;
              }

              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              setState(() => _isProcessing = true);

              try {
                final lecturerEmail = results.isNotEmpty ? results.first.submittedBy : null;
                await _resultsService.rejectResults(
                  examId: widget.exam.examId,
                  examDocId: widget.exam.docId ?? widget.exam.examId,
                  rejectionReason: reason,
                  rejectedBy: 'Exam Administration',
                  lecturerEmail: lecturerEmail,
                  subjectName: widget.exam.subjectName,
                );

                messenger.showSnackBar(
                  const SnackBar(content: Text('Results returned to Lecturer for revision with feedback.'), backgroundColor: Colors.orangeAccent),
                );
              } catch (e) {
                final msg = e.toString().replaceAll('Exception: ', '');
                messenger.showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
              } finally {
                if (mounted) setState(() => _isProcessing = false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Reject & Notify', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ─── UNLOCK FOR CORRECTION DIALOG ──────────────────────────────────────────
  void _showUnlockDialog() {
    final reasonController = TextEditingController(text: 'Administrative correction requested');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Unlock Results for Correction?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Unlocking allows the lecturer to modify marks. Please provide an audit reason:', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              setState(() => _isProcessing = true);

              try {
                await _resultsService.unlockResultsForCorrection(
                  examId: widget.exam.examId,
                  examDocId: widget.exam.docId ?? widget.exam.examId,
                  unlockedBy: 'Admin',
                  unlockReason: reasonController.text.trim(),
                );

                messenger.showSnackBar(
                  const SnackBar(content: Text('Results unlocked for lecturer corrections.'), backgroundColor: Colors.amberAccent),
                );
              } catch (e) {
                final msg = e.toString().replaceAll('Exception: ', '');
                messenger.showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
              } finally {
                if (mounted) setState(() => _isProcessing = false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[700]),
            child: const Text('Unlock Results', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
            const Text('Exam Results Review & Publishing', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            Text('${widget.exam.subjectCode} • ${widget.exam.subjectName}', style: const TextStyle(color: Colors.tealAccent, fontSize: 11)),
          ],
        ),
      ),
      body: StreamBuilder<List<ExamResultModel>>(
        stream: _resultsService.getExamResultsStream(widget.exam.examId, examDocId: widget.exam.docId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
          }

          final results = snapshot.data ?? [];
          if (results.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.pending_actions_rounded, size: 50, color: Colors.grey),
                    const SizedBox(height: 14),
                    const Text('No Marks Submitted Yet', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('The lecturer has not submitted marks for ${widget.exam.subjectCode}.', style: const TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }

          // Compute KPI Statistics
          final batchStatus = results.first.status;
          final totalStudents = results.length;
          final presentCount = results.where((r) => !r.isAbsent).length;
          final absentCount = results.where((r) => r.isAbsent).length;

          final presentMarks = results.where((r) => !r.isAbsent).map((r) => r.marks).toList();
          final avgScore = presentMarks.isNotEmpty ? (presentMarks.reduce((a, b) => a + b) / presentMarks.length).toStringAsFixed(1) : '0.0';
          final highestMark = presentMarks.isNotEmpty ? presentMarks.reduce((a, b) => a > b ? a : b).toStringAsFixed(0) : '0';
          final lowestMark = presentMarks.isNotEmpty ? presentMarks.reduce((a, b) => a < b ? a : b).toStringAsFixed(0) : '0';
          final passCount = results.where((r) => !r.isAbsent && r.grade != 'E' && r.grade != 'F').length;
          final passRate = presentCount > 0 ? ((passCount / presentCount) * 100).toStringAsFixed(1) : '0.0';

          final isSubmitted = batchStatus == 'Submitted';
          final isApproved = batchStatus == 'Approved';
          final isPublished = batchStatus == 'Published';
          final isRejected = batchStatus == 'Rejected';

          // Filter by search query
          final filteredResults = results.where((r) {
            if (_searchQuery.isEmpty) return true;
            return r.studentName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                r.studentId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                r.grade.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();

          return Column(
            children: [
              // 1. Status Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: _statusBgColor(batchStatus),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(_statusIcon(batchStatus), color: _statusColor(batchStatus), size: 18),
                        const SizedBox(width: 8),
                        Text('Result Status: ${batchStatus.toUpperCase()}', style: TextStyle(color: _statusColor(batchStatus), fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    if (results.first.submittedBy != null)
                      Text('By: ${results.first.submittedBy}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),

              // 2. KPI Metrics Card Strip
              Container(
                padding: const EdgeInsets.all(12),
                color: const Color(0xFF1E293B),
                child: Row(
                  children: [
                    Expanded(child: _metricCard('Students', '$totalStudents', Colors.white, Icons.people_rounded)),
                    const SizedBox(width: 6),
                    Expanded(child: _metricCard('Average', avgScore, Colors.amberAccent, Icons.analytics_rounded)),
                    const SizedBox(width: 6),
                    Expanded(child: _metricCard('Pass Rate', '$passRate%', Colors.tealAccent, Icons.percent_rounded)),
                    const SizedBox(width: 6),
                    Expanded(child: _metricCard('Hi / Lo', '$highestMark / $lowestMark', Colors.cyanAccent, Icons.swap_vert_rounded)),
                    const SizedBox(width: 6),
                    Expanded(child: _metricCard('Absent', '$absentCount', absentCount > 0 ? Colors.redAccent : Colors.grey, Icons.person_off_rounded)),
                  ],
                ),
              ),

              // 3. Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Search by Student Name, ID, Grade...',
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.tealAccent, size: 18),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    contentPadding: const EdgeInsets.symmetric(vertical: 6),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                ),
              ),

              // 4. Marksheet List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(left: 14, right: 14, bottom: 80),
                  itemCount: filteredResults.length,
                  itemBuilder: (context, index) {
                    final item = filteredResults[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: item.isAbsent ? Colors.redAccent.withAlpha(40) : Colors.white10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.studentName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('${item.studentId} • ${item.studentEmail}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                item.isAbsent ? 'ABSENT' : '${item.marks.toStringAsFixed(1)} / ${item.maxMarks.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: item.isAbsent ? Colors.redAccent : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              Text('GP: ${item.gradePoint.toStringAsFixed(1)}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 42,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: item.isAbsent ? Colors.red.withAlpha(40) : Colors.teal.withAlpha(40),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: item.isAbsent ? Colors.redAccent : Colors.tealAccent),
                            ),
                            child: Text(
                              item.grade,
                              style: TextStyle(
                                color: item.isAbsent ? Colors.redAccent : Colors.tealAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // 5. Admin Actions Floating Bottom Bar
              Container(
                padding: const EdgeInsets.all(14),
                color: const Color(0xFF1E293B),
                child: Row(
                  children: [
                    if (isSubmitted) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isProcessing ? null : () => _showRejectReasonDialog(results),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.redAccent),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 16),
                          label: const Text('Reject & Return', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isProcessing
                              ? null
                              : () async {
                                  final messenger = ScaffoldMessenger.of(context);
                                  setState(() => _isProcessing = true);
                                  try {
                                    await _resultsService.approveResults(
                                      examId: widget.exam.examId,
                                      examDocId: widget.exam.docId ?? widget.exam.examId,
                                      approvedBy: 'Examination Admin',
                                    );
                                    messenger.showSnackBar(
                                      const SnackBar(content: Text('Results Approved! You can now publish to students.'), backgroundColor: Colors.green),
                                    );
                                  } catch (e) {
                                    final msg = e.toString().replaceAll('Exception: ', '');
                                    messenger.showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
                                  } finally {
                                    if (mounted) setState(() => _isProcessing = false);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                          label: const Text('Approve Results', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                    ] else if (isApproved) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isProcessing
                              ? null
                              : () async {
                                  final messenger = ScaffoldMessenger.of(context);
                                  setState(() => _isProcessing = true);
                                  try {
                                    await _resultsService.publishResults(
                                      examId: widget.exam.examId,
                                      examDocId: widget.exam.docId ?? widget.exam.examId,
                                      publishedBy: 'Examination Admin',
                                      semester: widget.exam.semester,
                                      academicYear: widget.exam.academicYear,
                                    );
                                    messenger.showSnackBar(
                                      const SnackBar(content: Text('Results Published to Student Portal & Locked!'), backgroundColor: Colors.green),
                                    );
                                  } catch (e) {
                                    final msg = e.toString().replaceAll('Exception: ', '');
                                    messenger.showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
                                  } finally {
                                    if (mounted) setState(() => _isProcessing = false);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.public_rounded, color: Colors.white, size: 18),
                          label: const Text('Publish & Lock to Student Portal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                    ] else if (isPublished) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isProcessing ? null : () => _showUnlockDialog(),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.amberAccent),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.lock_open_rounded, color: Colors.amberAccent, size: 16),
                          label: const Text('Unlock for Corrections (Admin)', style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                    ] else if (isRejected) ...[
                      const Expanded(
                        child: Text(
                          'Results returned to Lecturer for corrections.',
                          style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _metricCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 9), overflow: TextOverflow.ellipsis)),
              Icon(icon, size: 10, color: color),
            ],
          ),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'published':
        return Colors.greenAccent;
      case 'approved':
        return Colors.tealAccent;
      case 'submitted':
        return Colors.amberAccent;
      case 'rejected':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  Color _statusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'published':
        return Colors.green[900]!.withAlpha(80);
      case 'approved':
        return Colors.teal[900]!.withAlpha(80);
      case 'submitted':
        return Colors.amber[900]!.withAlpha(80);
      case 'rejected':
        return Colors.red[900]!.withAlpha(80);
      default:
        return Colors.white10;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'published':
        return Icons.verified_rounded;
      case 'approved':
        return Icons.check_circle_rounded;
      case 'submitted':
        return Icons.hourglass_top_rounded;
      case 'rejected':
        return Icons.assignment_return_rounded;
      default:
        return Icons.edit_note_rounded;
    }
  }
}
