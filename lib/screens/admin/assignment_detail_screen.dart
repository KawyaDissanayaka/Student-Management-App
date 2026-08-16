import 'package:flutter/material.dart';
import '../../models/assignment_model.dart';
import '../../models/submission_model.dart';
import '../../services/assignment_service.dart';
import 'add_edit_assignment_screen.dart';

class AssignmentDetailScreen extends StatelessWidget {
  final AssignmentModel assignment;

  const AssignmentDetailScreen({super.key, required this.assignment});

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'published': return Colors.greenAccent;
      case 'closed': return Colors.amberAccent;
      case 'deactivated': return Colors.redAccent;
      default: return Colors.grey;
    }
  }

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

  bool _isPastDue() {
    if (assignment.dueDate.isEmpty) return false;
    try {
      final due = DateTime.parse(assignment.dueDate);
      return DateTime.now().isAfter(due);
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignmentService = AssignmentService();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text(
          'Assignment Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.orangeAccent),
            tooltip: 'Edit Assignment',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditAssignmentScreen(existingAssignment: assignment),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<int>(
        future: assignmentService.getEnrolledCount(assignment.subjectCode),
        builder: (context, enrolledSnap) {
          final totalAssigned = enrolledSnap.data ?? 0;

          return StreamBuilder<List<SubmissionModel>>(
            stream: assignmentService.getSubmissionsForAssignment(assignment.docId ?? ''),
            builder: (context, submissionsSnap) {
              final submissions = submissionsSnap.data ?? [];
              final submitted = submissions.length;
              final pending = (totalAssigned - submitted).clamp(0, totalAssigned);
              final late = submissions.where((s) => s.isLate).length;
              final rate = totalAssigned > 0
                  ? (submitted / totalAssigned * 100).toStringAsFixed(1)
                  : '0.0';

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + Status
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.withAlpha(40),
                            Colors.deepOrange.withAlpha(20),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.orangeAccent.withAlpha(60)),
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
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _statusColor(assignment.status).withAlpha(30),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: _statusColor(assignment.status).withAlpha(150)),
                                ),
                                child: Text(
                                  assignment.status.toUpperCase(),
                                  style: TextStyle(
                                    color: _statusColor(assignment.status),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _tagRow(Icons.book_rounded, assignment.subjectName, Colors.indigoAccent),
                          const SizedBox(height: 4),
                          _tagRow(Icons.person_rounded, assignment.lecturerName, Colors.amberAccent),
                          const SizedBox(height: 4),
                          _tagRow(Icons.tag_rounded, assignment.assignmentId, Colors.grey),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Info Grid
                    _sectionTitle('Details'),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        children: [
                          _detailRow(Icons.play_arrow_rounded, 'Start Date', _displayDate(assignment.startDate), Colors.tealAccent),
                          _divider(),
                          _detailRow(
                            Icons.alarm_rounded,
                            'Due Date',
                            _displayDate(assignment.dueDate),
                            _isPastDue() ? Colors.redAccent : Colors.orangeAccent,
                          ),
                          _divider(),
                          _detailRow(Icons.calendar_today_rounded, 'Created', _displayDate(assignment.createdDate), Colors.grey),
                          _divider(),
                          _detailRow(Icons.admin_panel_settings_rounded, 'Created By', assignment.createdBy, Colors.grey),
                          _divider(),
                          _detailRow(Icons.bookmark_rounded, 'Semester', '${assignment.semester} • ${assignment.academicYear}', Colors.purpleAccent),
                          if (assignment.attachmentUrl != null && assignment.attachmentUrl!.isNotEmpty) ...[
                            _divider(),
                            _detailRow(Icons.link_rounded, 'Attachment', assignment.attachmentUrl!, Colors.lightBlueAccent),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Description
                    _sectionTitle('Description'),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Text(
                        assignment.description.isNotEmpty
                            ? assignment.description
                            : 'No description provided.',
                        style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.6),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Statistics
                    _sectionTitle('Submission Statistics'),
                    const SizedBox(height: 10),
                    if (enrolledSnap.connectionState == ConnectionState.waiting)
                      const Center(child: CircularProgressIndicator(color: Colors.orangeAccent))
                    else
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.5,
                        children: [
                          _statCard('Total Assigned', '$totalAssigned', Icons.people_rounded, Colors.tealAccent),
                          _statCard('Submitted', '$submitted', Icons.check_circle_rounded, Colors.greenAccent),
                          _statCard('Pending', '$pending', Icons.hourglass_top_rounded, Colors.amberAccent),
                          _statCard('Late', '$late', Icons.timer_off_rounded, Colors.redAccent),
                        ],
                      ),
                    const SizedBox(height: 12),
                    // Submission Rate Bar
                    Container(
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
                              const Text(
                                'Submission Rate',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                '$rate%',
                                style: const TextStyle(
                                  color: Colors.orangeAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: totalAssigned > 0 ? submitted / totalAssigned : 0,
                              backgroundColor: Colors.white10,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$submitted submitted out of $totalAssigned assigned students',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submissions List
                    _sectionTitle('Submissions (${submissions.length})'),
                    const SizedBox(height: 10),
                    if (submissionsSnap.connectionState == ConnectionState.waiting)
                      const Center(child: CircularProgressIndicator(color: Colors.orangeAccent))
                    else if (submissions.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.inbox_rounded, color: Colors.grey, size: 40),
                            SizedBox(height: 8),
                            Text(
                              'No submissions yet.',
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    else
                      ...submissions.map((sub) => _submissionCard(sub)),

                    const SizedBox(height: 30),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _submissionCard(SubmissionModel sub) {
    final isLate = sub.isLate;
    String displayDate = sub.submittedAt;
    try {
      final dt = DateTime.parse(sub.submittedAt).toLocal();
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      displayDate = '${dt.day} ${months[dt.month - 1]} ${dt.year}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLate ? Colors.redAccent.withAlpha(80) : Colors.greenAccent.withAlpha(60),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.orange.withAlpha(30),
            child: Text(
              sub.studentName.isNotEmpty ? sub.studentName[0].toUpperCase() : 'S',
              style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sub.studentName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  'ID: ${sub.studentId} • $displayDate',
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
                if (sub.notes != null && sub.notes!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      sub.notes!,
                      style: const TextStyle(color: Colors.white60, fontSize: 11),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isLate ? Colors.redAccent.withAlpha(30) : Colors.greenAccent.withAlpha(30),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isLate ? Colors.redAccent : Colors.greenAccent,
              ),
            ),
            child: Text(
              isLate ? 'LATE' : 'ON TIME',
              style: TextStyle(
                color: isLate ? Colors.redAccent : Colors.greenAccent,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _tagRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: color, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _detailRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(color: Colors.white10, height: 1);

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
