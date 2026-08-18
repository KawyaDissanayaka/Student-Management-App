import 'package:flutter/material.dart';
import '../../models/exam_model.dart';
import '../../models/exam_registration_model.dart';
import '../../models/exam_seating_model.dart';
import '../../models/exam_result_model.dart';
import '../../services/exam_results_service.dart';
import '../../services/exam_registration_service.dart';
import '../../services/exam_seating_service.dart';

class LecturerExamResultsEntryScreen extends StatefulWidget {
  final ExamModel exam;
  final String lecturerEmail;
  final String lecturerName;

  const LecturerExamResultsEntryScreen({
    super.key,
    required this.exam,
    required this.lecturerEmail,
    required this.lecturerName,
  });

  @override
  State<LecturerExamResultsEntryScreen> createState() => _LecturerExamResultsEntryScreenState();
}

class _LecturerExamResultsEntryScreenState extends State<LecturerExamResultsEntryScreen> {
  final ExamResultsService _resultsService = ExamResultsService();
  final ExamRegistrationService _regService = ExamRegistrationService();
  final ExamSeatingService _seatingService = ExamSeatingService();

  List<GradingScale> _gradingScales = [];
  bool _isLoadingScales = true;
  bool _isSaving = false;

  // Local state for mark inputs
  final Map<String, TextEditingController> _markControllers = {};
  final Map<String, bool> _absentStates = {};
  final Map<String, double> _maxMarksMap = {};

  @override
  void initState() {
    super.initState();
    _loadGradingScales();
  }

  Future<void> _loadGradingScales() async {
    try {
      final scales = await _resultsService.getGradingScales();
      if (mounted) {
        setState(() {
          _gradingScales = scales;
          _isLoadingScales = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingScales = false);
    }
  }

  @override
  void dispose() {
    for (var controller in _markControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initStudentRow(String studentId, ExamResultModel? existingResult) {
    if (!_markControllers.containsKey(studentId)) {
      final initialMarks = existingResult != null && !existingResult.isAbsent
          ? existingResult.marks.toString()
          : '';
      _markControllers[studentId] = TextEditingController(text: initialMarks);
      _absentStates[studentId] = existingResult?.isAbsent ?? false;
      _maxMarksMap[studentId] = existingResult?.maxMarks ?? 100.0;
    }
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
            const Text('Exam Results Entry & Submission', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            Text('${widget.exam.subjectCode} • ${widget.exam.subjectName}', style: const TextStyle(color: Colors.amberAccent, fontSize: 11)),
          ],
        ),
      ),
      body: _isLoadingScales
          ? const Center(child: CircularProgressIndicator(color: Colors.amberAccent))
          : StreamBuilder<List<ExamRegistrationModel>>(
              stream: _regService.getRegistrationsForExamStream(widget.exam.examId, examDocId: widget.exam.docId),
              builder: (context, regSnap) {
                final registrations = (regSnap.data ?? []).where((r) => r.isApprovedOrRegistered).toList();

                return StreamBuilder<List<ExamSeatingModel>>(
                  stream: _seatingService.getSeatingForExamStream(widget.exam.examId, examDocId: widget.exam.docId),
                  builder: (context, seatSnap) {
                    final seatings = seatSnap.data ?? [];
                    final seatMap = {for (var s in seatings) s.studentId.toUpperCase(): s.seatNumber};

                    return StreamBuilder<List<ExamResultModel>>(
                      stream: _resultsService.getExamResultsStream(widget.exam.examId, examDocId: widget.exam.docId),
                      builder: (context, resSnap) {
                        if (resSnap.connectionState == ConnectionState.waiting && !resSnap.hasData) {
                          return const Center(child: CircularProgressIndicator(color: Colors.amberAccent));
                        }

                        final existingResults = resSnap.data ?? [];
                        final resultMap = {for (var r in existingResults) r.studentId.toUpperCase(): r};

                        // Determine overall batch status
                        String batchStatus = 'Draft';
                        String? rejectionReason;
                        if (existingResults.isNotEmpty) {
                          batchStatus = existingResults.first.status;
                          rejectionReason = existingResults.first.rejectionReason;
                        }

                        final isLocked = batchStatus == 'Submitted' || batchStatus == 'Approved' || batchStatus == 'Published';
                        final isRejected = batchStatus == 'Rejected';
                        final isPublished = batchStatus == 'Published';

                        // Initialize input controllers
                        for (var reg in registrations) {
                          _initStudentRow(reg.studentId, resultMap[reg.studentId.toUpperCase()]);
                        }

                        return Column(
                          children: [
                            // 1. Status & Rejection Notice Banner
                            if (isRejected)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                color: Colors.red[900]?.withAlpha(120),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 22),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Results Returned for Revision', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                          Text('Admin Note: ${rejectionReason ?? 'Please verify and correct marks before resubmitting.'}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else if (isPublished)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                color: Colors.green[900]?.withAlpha(100),
                                child: const Row(
                                  children: [
                                    Icon(Icons.lock_rounded, color: Colors.greenAccent, size: 18),
                                    SizedBox(width: 8),
                                    Text('Results Published & Locked: Visible to Students in Portal', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ],
                                ),
                              )
                            else if (isLocked)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                color: Colors.indigo[900]?.withAlpha(100),
                                child: Row(
                                  children: [
                                    const Icon(Icons.hourglass_top_rounded, color: Colors.amberAccent, size: 18),
                                    const SizedBox(width: 8),
                                    Text('Status: $batchStatus (Pending Admin Review)', style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ],
                                ),
                              ),

                            // 2. Exam Summary Strip
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              color: const Color(0xFF1E293B),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${registrations.length} Registered Students', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                      Text('Evaluator: ${widget.lecturerName}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _statusColor(batchStatus).withAlpha(30),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: _statusColor(batchStatus).withAlpha(80)),
                                    ),
                                    child: Text(
                                      batchStatus.toUpperCase(),
                                      style: TextStyle(color: _statusColor(batchStatus), fontWeight: FontWeight.bold, fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 3. Marksheet Table Header
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              color: const Color(0xFF0F172A),
                              child: const Row(
                                children: [
                                  Expanded(flex: 3, child: Text('STUDENT & SEAT', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold))),
                                  SizedBox(width: 60, child: Text('MARKS', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold))),
                                  SizedBox(width: 45, child: Text('ABS', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold))),
                                  SizedBox(width: 50, child: Text('GRADE', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold))),
                                ],
                              ),
                            ),

                            // 4. Student Marksheet Rows
                            Expanded(
                              child: registrations.isEmpty
                                  ? const Center(child: Text('No students registered for this exam.', style: TextStyle(color: Colors.grey)))
                                  : ListView.builder(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                      itemCount: registrations.length,
                                      itemBuilder: (context, index) {
                                        final reg = registrations[index];
                                        final seat = seatMap[reg.studentId.toUpperCase()] ?? '-';
                                        final controller = _markControllers[reg.studentId]!;
                                        final isAbsent = _absentStates[reg.studentId] ?? false;

                                        // Compute dynamic preview grade
                                        final parsedMarks = double.tryParse(controller.text.trim()) ?? 0.0;
                                        final gradeMap = ExamResultModel.calculateGradeAndPoint(
                                          marks: parsedMarks,
                                          isAbsent: isAbsent,
                                          scales: _gradingScales,
                                        );

                                        return Container(
                                          margin: const EdgeInsets.only(bottom: 6),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1E293B),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: isAbsent ? Colors.redAccent.withAlpha(40) : Colors.white10),
                                          ),
                                          child: Row(
                                            children: [
                                              // Student Info & Seat
                                              Expanded(
                                                flex: 3,
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(reg.studentName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis),
                                                    Text('${reg.studentId} • Seat: $seat', style: const TextStyle(color: Colors.tealAccent, fontSize: 10, fontFamily: 'monospace')),
                                                  ],
                                                ),
                                              ),

                                              // Marks Input (0 - 100)
                                              SizedBox(
                                                width: 60,
                                                height: 36,
                                                child: TextField(
                                                  controller: controller,
                                                  enabled: !isLocked && !isAbsent,
                                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                                  decoration: InputDecoration(
                                                    contentPadding: EdgeInsets.zero,
                                                    filled: true,
                                                    fillColor: isAbsent ? Colors.white10 : const Color(0xFF0F172A),
                                                    hintText: isAbsent ? 'AB' : '0-100',
                                                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 10),
                                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                                                  ),
                                                  onChanged: (_) => setState(() {}),
                                                ),
                                              ),
                                              const SizedBox(width: 6),

                                              // Absent Checkbox
                                              SizedBox(
                                                width: 40,
                                                child: Checkbox(
                                                  value: isAbsent,
                                                  activeColor: Colors.redAccent,
                                                  onChanged: isLocked
                                                      ? null
                                                      : (val) {
                                                          setState(() {
                                                            _absentStates[reg.studentId] = val ?? false;
                                                            if (val == true) {
                                                              controller.text = '0';
                                                            }
                                                          });
                                                        },
                                                ),
                                              ),
                                              const SizedBox(width: 6),

                                              // Calculated Grade Badge
                                              SizedBox(
                                                width: 50,
                                                child: Column(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: isAbsent ? Colors.red.withAlpha(40) : Colors.amber.withAlpha(40),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        gradeMap['grade'] as String,
                                                        style: TextStyle(
                                                          color: isAbsent ? Colors.redAccent : Colors.amberAccent,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      'GP: ${gradeMap['gradePoint']}',
                                                      style: const TextStyle(color: Colors.grey, fontSize: 9),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                            ),

                            // 5. Bottom Action Bar (Save Draft & Submit for Approval)
                            if (!isLocked)
                              Container(
                                padding: const EdgeInsets.all(14),
                                color: const Color(0xFF1E293B),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _isSaving ? null : () => _saveResults(registrations, resultMap, 'Draft'),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: Colors.white30),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        icon: const Icon(Icons.save_outlined, color: Colors.white70, size: 16),
                                        label: const Text('Save Draft', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _isSaving ? null : () => _confirmSubmitApproval(registrations, resultMap),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.amber[700],
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        icon: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
                                        label: const Text('Submit for Approval', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
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

  Future<void> _saveResults(
    List<ExamRegistrationModel> registrations,
    Map<String, ExamResultModel> resultMap,
    String targetStatus,
  ) async {
    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final List<ExamResultModel> resultsToSave = [];

      for (var reg in registrations) {
        final controller = _markControllers[reg.studentId];
        final isAbsent = _absentStates[reg.studentId] ?? false;
        final existing = resultMap[reg.studentId.toUpperCase()];

        final marksText = controller?.text.trim() ?? '';
        final marks = isAbsent ? 0.0 : (double.tryParse(marksText) ?? 0.0);

        if (!isAbsent && marksText.isNotEmpty && (marks < 0 || marks > 100)) {
          throw Exception('Marks for ${reg.studentName} must be between 0 and 100.');
        }

        final gradeMap = ExamResultModel.calculateGradeAndPoint(
          marks: marks,
          isAbsent: isAbsent,
          scales: _gradingScales,
        );

        resultsToSave.add(ExamResultModel(
          docId: existing?.docId,
          resultId: existing?.resultId ?? '',
          examId: widget.exam.examId,
          examDocId: widget.exam.docId ?? widget.exam.examId,
          moduleId: widget.exam.subjectCode,
          subjectName: widget.exam.subjectName,
          studentId: reg.studentId,
          studentName: reg.studentName,
          studentEmail: reg.studentEmail,
          marks: marks,
          maxMarks: 100.0,
          grade: gradeMap['grade'] as String,
          gradePoint: (gradeMap['gradePoint'] as num).toDouble(),
          status: targetStatus,
          isAbsent: isAbsent,
          submittedBy: widget.lecturerEmail,
          updatedAt: DateTime.now().toIso8601String(),
        ));
      }

      await _resultsService.saveOrSubmitResults(
        examId: widget.exam.examId,
        examDocId: widget.exam.docId ?? widget.exam.examId,
        moduleId: widget.exam.subjectCode,
        subjectName: widget.exam.subjectName,
        results: resultsToSave,
        targetStatus: targetStatus,
        submittedBy: widget.lecturerEmail,
      );

      messenger.showSnackBar(
        SnackBar(
          content: Text(targetStatus == 'Submitted' ? 'Results submitted to Admin for approval!' : 'Draft saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      messenger.showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _confirmSubmitApproval(
    List<ExamRegistrationModel> registrations,
    Map<String, ExamResultModel> resultMap,
  ) {
    // Check if any student marks are blank and not absent
    for (var reg in registrations) {
      final controller = _markControllers[reg.studentId];
      final isAbsent = _absentStates[reg.studentId] ?? false;
      if (!isAbsent && (controller == null || controller.text.trim().isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enter marks or toggle Absent for student: ${reg.studentName} (${reg.studentId})'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
        return;
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Submit Results for Admin Approval?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Once submitted, the results will be sent to the Examination Admin for moderation & approval. Editing will be locked until reviewed.',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _saveResults(registrations, resultMap, 'Submitted');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[700]),
            child: const Text('Confirm & Submit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
