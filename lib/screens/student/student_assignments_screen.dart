import 'package:flutter/material.dart';
import '../../models/assignment_model.dart';
import '../../models/submission_model.dart';
import '../../models/enrollment_model.dart';
import '../../services/assignment_service.dart';
import '../../services/enrollment_service.dart';
import '../../services/auth_service.dart';
import 'student_submit_assignment_screen.dart';

class StudentAssignmentsScreen extends StatelessWidget {
  final Map<String, dynamic>? userData;

  const StudentAssignmentsScreen({super.key, this.userData});

  String _displayDate(String isoDate) {
    if (isoDate.isEmpty) return '—';
    try {
      final dt = DateTime.parse(isoDate);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return isoDate;
    }
  }

  bool _isPastDue(String dueDate) {
    if (dueDate.isEmpty) return false;
    try {
      return DateTime.now().isAfter(DateTime.parse(dueDate));
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final email = userData?['email'] ?? authService.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text(
          'My Assignments',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<EnrollmentModel>>(
        stream: EnrollmentService().getStudentActiveEnrollmentsStream(email),
        builder: (context, enrollmentSnap) {
          if (enrollmentSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
          }

          final enrollments = enrollmentSnap.data ?? [];
          final subjectCodes = enrollments.map((e) => e.subjectCode).toSet().toList();

          if (subjectCodes.isEmpty) {
            return _emptyState('You are not enrolled in any subjects yet.');
          }

          // Firebase "whereIn" supports max 30 elements — fine for typical usage
          return StreamBuilder<List<AssignmentModel>>(
            stream: AssignmentService().getPublishedAssignmentsForSubjects(subjectCodes),
            builder: (context, assignmentSnap) {
              if (assignmentSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.orangeAccent));
              }

              final assignments = assignmentSnap.data ?? [];

              if (assignments.isEmpty) {
                return _emptyState('No published assignments for your subjects yet.');
              }

              // Sort by due date ascending (most urgent first)
              assignments.sort((a, b) => a.dueDate.compareTo(b.dueDate));

              return StreamBuilder<List<SubmissionModel>>(
                stream: AssignmentService().getStudentSubmissionsStream(email),
                builder: (context, submissionSnap) {
                  final submissions = submissionSnap.data ?? [];
                  // Map assignmentId → submission
                  final submissionMap = {
                    for (final s in submissions) s.assignmentId: s,
                  };

                  // Count stats
                  final submitted = assignments.where((a) => submissionMap.containsKey(a.docId)).length;
                  final pending = assignments.length - submitted;
                  final late = submissions.where((s) => s.isLate).length;

                  return Column(
                    children: [
                      // Summary bar
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            _statPill('Total', '${assignments.length}', Colors.tealAccent),
                            const SizedBox(width: 8),
                            _statPill('Submitted', '$submitted', Colors.greenAccent),
                            const SizedBox(width: 8),
                            _statPill('Pending', '$pending', Colors.amberAccent),
                            const SizedBox(width: 8),
                            _statPill('Late', '$late', Colors.redAccent),
                          ],
                        ),
                      ),

                      // Assignment Cards
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: assignments.length,
                          itemBuilder: (context, index) {
                            final assignment = assignments[index];
                            final submission = submissionMap[assignment.docId];
                            final isSubmitted = submission != null;
                            final isPastDue = _isPastDue(assignment.dueDate);

                            // Determine card status label
                            String statusLabel;
                            Color statusColor;
                            IconData statusIcon;

                            if (isSubmitted) {
                              if (submission.isLate) {
                                statusLabel = 'LATE';
                                statusColor = Colors.amberAccent;
                                statusIcon = Icons.timer_off_rounded;
                              } else {
                                statusLabel = 'SUBMITTED';
                                statusColor = Colors.greenAccent;
                                statusIcon = Icons.check_circle_rounded;
                              }
                            } else if (isPastDue) {
                              statusLabel = 'OVERDUE';
                              statusColor = Colors.redAccent;
                              statusIcon = Icons.alarm_off_rounded;
                            } else {
                              statusLabel = 'PENDING';
                              statusColor = Colors.orangeAccent;
                              statusIcon = Icons.hourglass_top_rounded;
                            }

                            return InkWell(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => StudentSubmitAssignmentScreen(
                                    assignment: assignment,
                                    userData: userData,
                                  ),
                                ),
                              ),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSubmitted
                                        ? statusColor.withAlpha(60)
                                        : isPastDue
                                            ? Colors.redAccent.withAlpha(60)
                                            : Colors.white10,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            assignment.title,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: statusColor.withAlpha(25),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: statusColor.withAlpha(150)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(statusIcon, color: statusColor, size: 11),
                                              const SizedBox(width: 4),
                                              Text(
                                                statusLabel,
                                                style: TextStyle(
                                                  color: statusColor,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.book_rounded,
                                            color: Colors.indigoAccent, size: 13),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            '${assignment.subjectName} (${assignment.subjectCode})',
                                            style: const TextStyle(
                                                color: Colors.indigoAccent, fontSize: 12),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.alarm_rounded,
                                            color: Colors.grey, size: 13),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Due: ${_displayDate(assignment.dueDate)}',
                                          style: TextStyle(
                                            color: isPastDue && !isSubmitted
                                                ? Colors.redAccent
                                                : Colors.grey,
                                            fontSize: 12,
                                            fontWeight: isPastDue && !isSubmitted
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          assignment.semester,
                                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                    if (isSubmitted) ...[
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.schedule_rounded,
                                              size: 12, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Submitted: ${_displayDate(submission.submittedAt)}',
                                            style: const TextStyle(color: Colors.grey, fontSize: 11),
                                          ),
                                          if (submission.mark != null) ...[
                                            const Spacer(),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.tealAccent.withAlpha(25),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'Mark: ${submission.mark}',
                                                style: const TextStyle(
                                                    color: Colors.tealAccent,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 11),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
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
          );
        },
      ),
    );
  }

  Widget _statPill(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 10),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[700]),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Colors.grey, fontSize: 15),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
