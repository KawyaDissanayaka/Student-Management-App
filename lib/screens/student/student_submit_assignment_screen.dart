import 'package:flutter/material.dart';
import '../../models/assignment_model.dart';
import '../../models/submission_model.dart';
import '../../services/assignment_service.dart';
import '../../services/auth_service.dart';

class StudentSubmitAssignmentScreen extends StatefulWidget {
  final AssignmentModel assignment;
  final Map<String, dynamic>? userData;

  const StudentSubmitAssignmentScreen({
    super.key,
    required this.assignment,
    this.userData,
  });

  @override
  State<StudentSubmitAssignmentScreen> createState() =>
      _StudentSubmitAssignmentScreenState();
}

class _StudentSubmitAssignmentScreenState
    extends State<StudentSubmitAssignmentScreen> {
  final _assignmentService = AssignmentService();
  final _authService = AuthService();
  final _notesCtrl = TextEditingController();
  final _attachmentCtrl = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  SubmissionModel? _existingSubmission;

  @override
  void initState() {
    super.initState();
    _checkExistingSubmission();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _attachmentCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkExistingSubmission() async {
    final email = widget.userData?['email'] ??
        _authService.currentUser?.email ?? '';
    final sub = await _assignmentService.getStudentSubmission(
      widget.assignment.docId ?? '',
      email,
    );
    if (mounted) {
      setState(() {
        _existingSubmission = sub;
        _isLoading = false;
      });
    }
  }

  Future<void> _submit() async {
    final email = widget.userData?['email'] ??
        _authService.currentUser?.email ?? '';
    final studentId = widget.userData?['studentId'] ?? '';
    final studentName = widget.userData?['fullName'] ?? '';
    final studentDocId = widget.userData?['docId'] ?? '';

    setState(() => _isSubmitting = true);

    try {
      final now = DateTime.now();
      final dueDate = DateTime.tryParse(widget.assignment.dueDate);
      final isLate = dueDate != null && now.isAfter(dueDate);

      final submission = SubmissionModel(
        assignmentId: widget.assignment.docId ?? '',
        assignmentTitle: widget.assignment.title,
        subjectCode: widget.assignment.subjectCode,
        subjectName: widget.assignment.subjectName,
        studentDocId: studentDocId,
        studentId: studentId,
        studentName: studentName,
        studentEmail: email.toLowerCase(),
        submittedAt: now.toIso8601String(),
        isLate: isLate,
        attachmentUrl: _attachmentCtrl.text.trim().isEmpty
            ? null
            : _attachmentCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );

      await _assignmentService.submitAssignment(submission);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isLate
                ? 'Submitted! (Marked as Late — past due date)'
                : 'Submitted successfully! On Time ✅'),
            backgroundColor: isLate ? Colors.orange : Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _displayDate(String isoDate) {
    if (isoDate.isEmpty) return '—';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return isoDate;
    }
  }

  String _displayDateTime(String isoDate) {
    if (isoDate.isEmpty) return '—';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoDate;
    }
  }

  bool get _isPastDue {
    if (widget.assignment.dueDate.isEmpty) return false;
    try {
      return DateTime.now().isAfter(DateTime.parse(widget.assignment.dueDate));
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text(
          'Assignment',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.tealAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Assignment Info Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange.withAlpha(40), Colors.deepOrange.withAlpha(20)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orangeAccent.withAlpha(60)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.assignment.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _infoRow(Icons.book_rounded, widget.assignment.subjectName, Colors.indigoAccent),
                        const SizedBox(height: 4),
                        _infoRow(Icons.person_rounded, widget.assignment.lecturerName, Colors.amberAccent),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _dateChip(
                                'Start Date',
                                _displayDate(widget.assignment.startDate),
                                Colors.tealAccent,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _dateChip(
                                'Due Date',
                                _displayDate(widget.assignment.dueDate),
                                _isPastDue ? Colors.redAccent : Colors.orangeAccent,
                              ),
                            ),
                          ],
                        ),
                        if (_isPastDue)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withAlpha(30),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.redAccent.withAlpha(120)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.timer_off_rounded, color: Colors.redAccent, size: 14),
                                  SizedBox(width: 6),
                                  Text(
                                    'Due date passed — submission will be marked Late',
                                    style: TextStyle(color: Colors.redAccent, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  if (widget.assignment.description.isNotEmpty) ...[
                    const Text('Description',
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Text(
                        widget.assignment.description,
                        style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.6),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Attachment from admin
                  if (widget.assignment.attachmentUrl != null &&
                      widget.assignment.attachmentUrl!.isNotEmpty) ...[
                    const Text('Assignment Attachment',
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.lightBlueAccent.withAlpha(80)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.link_rounded, color: Colors.lightBlueAccent, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.assignment.attachmentUrl!,
                              style: const TextStyle(
                                color: Colors.lightBlueAccent,
                                fontSize: 13,
                                decoration: TextDecoration.underline,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  const Divider(color: Colors.white10),
                  const SizedBox(height: 8),

                  // === SUBMITTED STATE ===
                  if (_existingSubmission != null) ...[
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(20),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.greenAccent.withAlpha(80)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 22),
                              SizedBox(width: 8),
                              Text(
                                'Assignment Submitted',
                                style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _submittedRow('Submitted At',
                              _displayDateTime(_existingSubmission!.submittedAt)),
                          _submittedRow('Status',
                              _existingSubmission!.isLate ? 'Late ⚠️' : 'On Time ✅'),
                          if (_existingSubmission!.notes != null &&
                              _existingSubmission!.notes!.isNotEmpty)
                            _submittedRow('Your Notes', _existingSubmission!.notes!),
                          if (_existingSubmission!.attachmentUrl != null &&
                              _existingSubmission!.attachmentUrl!.isNotEmpty)
                            _submittedRow('Your Attachment', _existingSubmission!.attachmentUrl!),
                          if (_existingSubmission!.mark != null) ...[
                            const Divider(color: Colors.white10, height: 20),
                            _submittedRow('Mark', '${_existingSubmission!.mark}'),
                          ],
                          if (_existingSubmission!.feedback != null &&
                              _existingSubmission!.feedback!.isNotEmpty)
                            _submittedRow('Feedback', _existingSubmission!.feedback!),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Center(
                      child: Text(
                        'You cannot re-submit this assignment.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ),
                  ]

                  // === SUBMISSION FORM ===
                  else ...[
                    const Text('Your Submission',
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    // Notes
                    TextField(
                      controller: _notesCtrl,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDeco(
                        'Notes / Answer (optional)',
                        Icons.notes_rounded,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Attachment URL
                    TextField(
                      controller: _attachmentCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDeco(
                        'Attachment URL (optional — paste Google Drive, etc.)',
                        Icons.link_rounded,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submit,
                        icon: _isSubmitting
                            ? const SizedBox.shrink()
                            : const Icon(Icons.send_rounded, color: Colors.white),
                        label: _isSubmitting
                            ? const SizedBox(
                                height: 22, width: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5),
                              )
                            : Text(
                                _isPastDue ? 'Submit (Late)' : 'Submit Assignment',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isPastDue ? Colors.orange : Colors.tealAccent,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _infoRow(IconData icon, String text, Color color) {
    return Row(children: [
      Icon(icon, color: color, size: 14),
      const SizedBox(width: 6),
      Expanded(
        child: Text(text,
            style: TextStyle(color: color, fontSize: 12),
            overflow: TextOverflow.ellipsis),
      ),
    ]);
  }

  Widget _dateChip(String label, String date, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color.withAlpha(180), fontSize: 10)),
          const SizedBox(height: 2),
          Text(date,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _submittedRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text('$label:',
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
      prefixIcon: Icon(icon, color: Colors.tealAccent),
      filled: true,
      fillColor: const Color(0xFF1E293B),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.tealAccent, width: 1.5),
      ),
    );
  }
}
