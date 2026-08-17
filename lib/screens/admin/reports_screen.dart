import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/report_export_service.dart';
import '../../services/notification_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
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
        title: const Row(
          children: [
            Icon(Icons.bar_chart_rounded, color: Colors.lightBlueAccent),
            SizedBox(width: 8),
            Text(
              'Reports & Analytics',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.lightBlueAccent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard_customize_rounded, size: 18)),
            Tab(text: 'Attendance', icon: Icon(Icons.calendar_month_rounded, size: 18)),
            Tab(text: 'Low Attendance', icon: Icon(Icons.warning_amber_rounded, size: 18)),
            Tab(text: 'Assignments', icon: Icon(Icons.assignment_rounded, size: 18)),
            Tab(text: 'Tasks', icon: Icon(Icons.task_alt_rounded, size: 18)),
            Tab(text: 'Enrollments', icon: Icon(Icons.school_rounded, size: 18)),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('students').snapshots(),
        builder: (context, studentsSnap) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('lecturers').snapshots(),
            builder: (context, lecturersSnap) {
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('subjects').snapshots(),
                builder: (context, subjectsSnap) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('enrollments').snapshots(),
                    builder: (context, enrollmentsSnap) {
                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('attendance').snapshots(),
                        builder: (context, attendanceSnap) {
                          return StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance.collection('settings').doc('attendance_config').snapshots(),
                            builder: (context, settingsSnap) {
                              return StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance.collection('assignments').snapshots(),
                                builder: (context, assignmentsSnap) {
                                  return StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance.collection('tasks').snapshots(),
                                    builder: (context, tasksSnap) {
                                      return StreamBuilder<QuerySnapshot>(
                                        stream: FirebaseFirestore.instance.collection('announcements').snapshots(),
                                        builder: (context, announcementsSnap) {
                                          return StreamBuilder<QuerySnapshot>(
                                            stream: FirebaseFirestore.instance.collection('notifications').snapshots(),
                                            builder: (context, notificationsSnap) {
                                              return _buildReportsBody(
                                                studentsSnap: studentsSnap,
                                                lecturersSnap: lecturersSnap,
                                                subjectsSnap: subjectsSnap,
                                                enrollmentsSnap: enrollmentsSnap,
                                                attendanceSnap: attendanceSnap,
                                                settingsSnap: settingsSnap,
                                                assignmentsSnap: assignmentsSnap,
                                                tasksSnap: tasksSnap,
                                                announcementsSnap: announcementsSnap,
                                                notificationsSnap: notificationsSnap,
                                              );
                                            },
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildReportsBody({
    required AsyncSnapshot<QuerySnapshot> studentsSnap,
    required AsyncSnapshot<QuerySnapshot> lecturersSnap,
    required AsyncSnapshot<QuerySnapshot> subjectsSnap,
    required AsyncSnapshot<QuerySnapshot> enrollmentsSnap,
    required AsyncSnapshot<QuerySnapshot> attendanceSnap,
    required AsyncSnapshot<DocumentSnapshot> settingsSnap,
    required AsyncSnapshot<QuerySnapshot> assignmentsSnap,
    required AsyncSnapshot<QuerySnapshot> tasksSnap,
    required AsyncSnapshot<QuerySnapshot> announcementsSnap,
    required AsyncSnapshot<QuerySnapshot> notificationsSnap,
  }) {
    // 1. Raw Docs
    final List<QueryDocumentSnapshot> studentDocs = studentsSnap.hasData ? studentsSnap.data!.docs : [];
    final List<QueryDocumentSnapshot> lecturerDocs = lecturersSnap.hasData ? lecturersSnap.data!.docs : [];
    final List<QueryDocumentSnapshot> subjectDocs = subjectsSnap.hasData ? subjectsSnap.data!.docs : [];
    final List<QueryDocumentSnapshot> enrollmentDocs = enrollmentsSnap.hasData ? enrollmentsSnap.data!.docs : [];
    final List<QueryDocumentSnapshot> attendanceDocs = attendanceSnap.hasData ? attendanceSnap.data!.docs : [];
    final List<QueryDocumentSnapshot> assignmentDocs = assignmentsSnap.hasData ? assignmentsSnap.data!.docs : [];
    final List<QueryDocumentSnapshot> taskDocs = tasksSnap.hasData ? tasksSnap.data!.docs : [];
    final List<QueryDocumentSnapshot> announcementDocs = announcementsSnap.hasData ? announcementsSnap.data!.docs : [];
    final List<QueryDocumentSnapshot> notificationDocs = notificationsSnap.hasData ? notificationsSnap.data!.docs : [];

    // Threshold config (default 80.0%)
    double threshold = 80.0;
    if (settingsSnap.hasData && settingsSnap.data!.exists) {
      final data = settingsSnap.data!.data() as Map<String, dynamic>?;
      if (data != null && data['threshold'] != null) {
        threshold = (data['threshold'] as num).toDouble();
      }
    }

    // 2. Active Students & Lecturers
    final activeStudentDocs = studentDocs.where((d) {
      final data = d.data() as Map<String, dynamic>;
      return (data['status'] ?? 'active').toString().toLowerCase() == 'active';
    }).toList();

    final activeLecturerDocs = lecturerDocs.where((d) {
      final data = d.data() as Map<String, dynamic>;
      return (data['status'] ?? 'active').toString().toLowerCase() == 'active';
    }).toList();

    final activeSubjectDocs = subjectDocs.where((d) {
      final data = d.data() as Map<String, dynamic>;
      return (data['status'] ?? 'active').toString().toLowerCase() == 'active';
    }).toList();

    // 3. Active Enrollments
    final activeEnrollments = enrollmentDocs.where((d) {
      final data = d.data() as Map<String, dynamic>;
      return (data['status'] ?? 'active').toString().toLowerCase() == 'active';
    }).toList();

    // 4. Attendance Computations (excluding cancelled)
    final validAttendanceDocs = attendanceDocs.where((d) {
      final data = d.data() as Map<String, dynamic>;
      return (data['status'] ?? '').toString().toLowerCase() != 'cancelled';
    }).toList();

    final totalAttendanceClasses = validAttendanceDocs.length;
    final totalAttended = validAttendanceDocs.where((d) {
      final data = d.data() as Map<String, dynamic>;
      final status = (data['status'] ?? '').toString().toLowerCase();
      return status == 'present' || status == 'late';
    }).length;

    final double overallAvgAttendance = totalAttendanceClasses > 0
        ? (totalAttended / totalAttendanceClasses) * 100
        : 0.0;

    // Group attendance per Student & Subject
    // Key: studentEmail_subjectCode or studentDocId_subjectDocId
    final Map<String, _StudentAttendanceRecord> studentAttendanceMap = {};
    for (var doc in validAttendanceDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final studentId = data['studentDocId'] ?? data['studentEmail'] ?? '';
      final studentName = (data['studentName'] ?? 'Unknown').toString();
      final studentOfficialId = (data['studentId'] ?? '').toString();
      final studentEmail = (data['studentEmail'] ?? '').toString();
      final subjectCode = (data['subjectCode'] ?? data['subjectName'] ?? 'Unknown').toString();
      final subjectName = (data['subjectName'] ?? subjectCode).toString();
      final status = (data['status'] ?? '').toString().toLowerCase();

      final key = '${studentEmail.isNotEmpty ? studentEmail : studentId}_$subjectCode';

      if (!studentAttendanceMap.containsKey(key)) {
        studentAttendanceMap[key] = _StudentAttendanceRecord(
          studentDocId: studentId,
          studentName: studentName,
          studentOfficialId: studentOfficialId,
          studentEmail: studentEmail,
          subjectCode: subjectCode,
          subjectName: subjectName,
          totalClasses: 0,
          presentCount: 0,
          absentCount: 0,
        );
      }

      final rec = studentAttendanceMap[key]!;
      rec.totalClasses++;
      if (status == 'present' || status == 'late') {
        rec.presentCount++;
      } else if (status == 'absent') {
        rec.absentCount++;
      }
    }

    // Low Attendance Students list
    final List<_StudentAttendanceRecord> lowAttendanceList = studentAttendanceMap.values
        .where((rec) => rec.totalClasses > 0 && rec.attendancePercentage < threshold)
        .toList();
    lowAttendanceList.sort((a, b) => a.attendancePercentage.compareTo(b.attendancePercentage));

    // 5. Assignments Statistics
    final activeAssignmentDocs = assignmentDocs.where((d) {
      final data = d.data() as Map<String, dynamic>;
      return (data['status'] ?? '').toString().toLowerCase() != 'deactivated';
    }).toList();

    int totalAssignedCount = 0;
    int totalSubmittedCount = 0;
    int totalLateSubmissions = 0;

    for (var doc in activeAssignmentDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final submissions = data['submissions'] as List? ?? [];
      final assignedCount = (data['assignedCount'] ?? activeStudentDocs.length) as int;
      totalAssignedCount += assignedCount > 0 ? assignedCount : 1;
      totalSubmittedCount += submissions.length;

      final dueDateStr = (data['dueDate'] ?? '').toString();
      if (dueDateStr.isNotEmpty) {
        try {
          final dueDt = DateTime.parse(dueDateStr);
          for (var sub in submissions) {
            if (sub is Map && sub['submittedDate'] != null) {
              final subDt = DateTime.tryParse(sub['submittedDate'].toString());
              if (subDt != null && subDt.isAfter(dueDt)) {
                totalLateSubmissions++;
              }
            }
          }
        } catch (_) {}
      }
    }

    final double assignmentSubmissionRate = totalAssignedCount > 0
        ? (totalSubmittedCount / totalAssignedCount).clamp(0.0, 1.0) * 100
        : 0.0;

    // 6. Tasks Statistics
    final activeTaskDocs = taskDocs.where((d) {
      final data = d.data() as Map<String, dynamic>;
      return (data['status'] ?? '').toString().toLowerCase() != 'deactivated';
    }).toList();

    int tasksPending = 0;
    int tasksInProgress = 0;
    int tasksCompleted = 0;
    int tasksOverdue = 0;

    for (var doc in activeTaskDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final status = (data['status'] ?? 'pending').toString().toLowerCase();
      final dueDate = (data['dueDate'] ?? '').toString();

      if (status == 'completed') {
        tasksCompleted++;
      } else if (status == 'in_progress') {
        if (dueDate.isNotEmpty && DateTime.tryParse(dueDate)?.isBefore(DateTime.now()) == true) {
          tasksOverdue++;
        } else {
          tasksInProgress++;
        }
      } else {
        if (dueDate.isNotEmpty && DateTime.tryParse(dueDate)?.isBefore(DateTime.now()) == true) {
          tasksOverdue++;
        } else {
          tasksPending++;
        }
      }
    }

    final int totalTasks = activeTaskDocs.length;
    final double taskCompletionRate = totalTasks > 0 ? (tasksCompleted / totalTasks) * 100 : 0.0;

    // 7. Enrollment breakdown per subject
    final Map<String, int> subjectEnrollmentCount = {};
    for (var doc in activeEnrollments) {
      final data = doc.data() as Map<String, dynamic>;
      final subj = (data['subjectName'] ?? data['subjectCode'] ?? 'Unknown').toString();
      subjectEnrollmentCount[subj] = (subjectEnrollmentCount[subj] ?? 0) + 1;
    }

    // 8. Communication Metrics
    int activePublishedNotices = 0;
    for (var doc in announcementDocs) {
      final data = doc.data() as Map<String, dynamic>;
      if ((data['status'] ?? '').toString().toLowerCase() == 'published') {
        final exp = (data['expiryDate'] ?? '').toString();
        bool isExp = false;
        if (exp.isNotEmpty) {
          try {
            final dt = DateTime.parse(exp);
            if (DateTime.now().isAfter(DateTime(dt.year, dt.month, dt.day, 23, 59, 59))) isExp = true;
          } catch (_) {}
        }
        if (!isExp) activePublishedNotices++;
      }
    }

    final totalSentNotifs = notificationDocs.where((d) {
      final data = d.data() as Map<String, dynamic>;
      final status = (data['status'] ?? '').toString().toLowerCase();
      if (status == 'sent') return true;
      if (status == 'scheduled') {
        final sched = (data['scheduledDate'] ?? '').toString();
        if (sched.isNotEmpty && DateTime.tryParse(sched)?.isBefore(DateTime.now()) == true) return true;
      }
      return false;
    }).length;

    return TabBarView(
      controller: _tabController,
      children: [
        // Tab 1: Overview
        _buildOverviewTab(
          activeStudents: activeStudentDocs.length,
          activeLecturers: activeLecturerDocs.length,
          activeSubjects: activeSubjectDocs.length,
          activeEnrollments: activeEnrollments.length,
          avgAttendance: overallAvgAttendance,
          lowAttendanceCount: lowAttendanceList.length,
          submissionRate: assignmentSubmissionRate,
          taskCompletionRate: taskCompletionRate,
          activeAnnouncements: activePublishedNotices,
          sentNotifications: totalSentNotifs,
        ),

        // Tab 2: Attendance Report
        _buildAttendanceReportTab(
          records: studentAttendanceMap.values.toList(),
          overallAvg: overallAvgAttendance,
          totalClasses: totalAttendanceClasses,
        ),

        // Tab 3: Low Attendance Warning Report
        _buildLowAttendanceReportTab(
          lowAttendanceRecords: lowAttendanceList,
          threshold: threshold,
        ),

        // Tab 4: Assignments Report
        _buildAssignmentsReportTab(
          assignmentDocs: activeAssignmentDocs,
          totalAssigned: totalAssignedCount,
          totalSubmitted: totalSubmittedCount,
          totalLate: totalLateSubmissions,
          submissionRate: assignmentSubmissionRate,
        ),

        // Tab 5: Tasks Report
        _buildTasksReportTab(
          taskDocs: activeTaskDocs,
          totalTasks: totalTasks,
          pending: tasksPending,
          inProgress: tasksInProgress,
          completed: tasksCompleted,
          overdue: tasksOverdue,
          completionRate: taskCompletionRate,
        ),

        // Tab 6: Enrollments Breakdown
        _buildEnrollmentsReportTab(
          totalEnrollments: activeEnrollments.length,
          subjectBreakdown: subjectEnrollmentCount,
          enrollmentDocs: activeEnrollments,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: OVERVIEW
  // ---------------------------------------------------------------------------
  Widget _buildOverviewTab({
    required int activeStudents,
    required int activeLecturers,
    required int activeSubjects,
    required int activeEnrollments,
    required double avgAttendance,
    required int lowAttendanceCount,
    required double submissionRate,
    required double taskCompletionRate,
    required int activeAnnouncements,
    required int sentNotifications,
  }) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'INSTITUTE PERFORMANCE SUMMARY',
              style: TextStyle(color: Colors.lightBlueAccent, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
            IconButton(
              icon: const Icon(Icons.file_download_rounded, color: Colors.tealAccent),
              tooltip: 'Export Overview',
              onPressed: () {
                ReportExportService.showExportDialog(
                  context: context,
                  reportTitle: 'Institute Executive Overview Report',
                  headers: ['Metric', 'Current Value', 'Status / Benchmark'],
                  rows: [
                    ['Total Active Students', '$activeStudents', 'Active Enrolled'],
                    ['Total Active Lecturers', '$activeLecturers', 'Faculty Staff'],
                    ['Total Active Subjects', '$activeSubjects', 'Academic Courses'],
                    ['Total Enrollments', '$activeEnrollments', 'Course Allocations'],
                    ['Average Attendance', '${avgAttendance.toStringAsFixed(1)}%', avgAttendance >= 80 ? 'Good' : 'Needs Attention'],
                    ['Low Attendance Students', '$lowAttendanceCount', lowAttendanceCount == 0 ? 'Optimal' : 'Action Required'],
                    ['Assignment Submission Rate', '${submissionRate.toStringAsFixed(1)}%', 'Student Submissions'],
                    ['Task Completion Rate', '${taskCompletionRate.toStringAsFixed(1)}%', 'Task Execution'],
                    ['Active Announcements', '$activeAnnouncements', 'Live Notices'],
                    ['Sent Notifications', '$sentNotifications', 'Delivered Alerts'],
                  ],
                  summaryMetrics: {
                    'Total Students': '$activeStudents',
                    'Average Attendance': '${avgAttendance.toStringAsFixed(1)}%',
                    'Low Attendance Alert Count': '$lowAttendanceCount Students',
                    'Assignment Submission Rate': '${submissionRate.toStringAsFixed(1)}%',
                    'Task Completion Rate': '${taskCompletionRate.toStringAsFixed(1)}%',
                  },
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 12),

        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.25,
          children: [
            _buildMetricCard('Active Students', '$activeStudents', Icons.people_rounded, Colors.tealAccent),
            _buildMetricCard('Active Lecturers', '$activeLecturers', Icons.school_rounded, Colors.amberAccent),
            _buildMetricCard('Active Subjects', '$activeSubjects', Icons.book_rounded, Colors.indigoAccent),
            _buildMetricCard('Enrollments', '$activeEnrollments', Icons.assignment_ind_rounded, Colors.teal),
            _buildMetricCard('Avg Attendance', '${avgAttendance.toStringAsFixed(1)}%', Icons.calendar_month_rounded, Colors.greenAccent),
            _buildMetricCard('Low Attendance', '$lowAttendanceCount Students', Icons.warning_amber_rounded, Colors.redAccent),
            _buildMetricCard('Submission Rate', '${submissionRate.toStringAsFixed(1)}%', Icons.assignment_turned_in_rounded, Colors.orangeAccent),
            _buildMetricCard('Task Completion', '${taskCompletionRate.toStringAsFixed(1)}%', Icons.task_alt_rounded, Colors.cyanAccent),
            _buildMetricCard('Live Notices', '$activeAnnouncements', Icons.campaign_rounded, Colors.pinkAccent),
            _buildMetricCard('Sent Alerts', '$sentNotifications', Icons.notifications_rounded, Colors.purpleAccent),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: ATTENDANCE REPORT
  // ---------------------------------------------------------------------------
  Widget _buildAttendanceReportTab({
    required List<_StudentAttendanceRecord> records,
    required double overallAvg,
    required int totalClasses,
  }) {
    return Column(
      children: [
        // Header Summary Strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: const Color(0xFF1E293B),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Overall Avg: ${overallAvg.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('${records.length} Student-Subject records ($totalClasses total classes)', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  ReportExportService.showExportDialog(
                    context: context,
                    reportTitle: 'Attendance Comprehensive Report',
                    headers: ['Student Name', 'Student ID', 'Subject', 'Total Classes', 'Present', 'Absent', 'Attendance %'],
                    rows: records.map((r) => [
                      r.studentName,
                      r.studentOfficialId,
                      r.subjectName,
                      '${r.totalClasses}',
                      '${r.presentCount}',
                      '${r.absentCount}',
                      '${r.attendancePercentage.toStringAsFixed(1)}%',
                    ]).toList(),
                    summaryMetrics: {
                      'Overall Average Attendance': '${overallAvg.toStringAsFixed(1)}%',
                      'Total Classes Conducted': '$totalClasses',
                      'Total Student Records': '${records.length}',
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.file_download_rounded, size: 16, color: Colors.white),
                label: const Text('Export', style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ],
          ),
        ),

        // Records List
        Expanded(
          child: records.isEmpty
              ? const Center(child: Text('No attendance records found.', style: TextStyle(color: Colors.white60)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final r = records[index];
                    final pct = r.attendancePercentage;
                    final isGood = pct >= 80;

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
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: isGood ? Colors.green.withAlpha(30) : Colors.red.withAlpha(30),
                            child: Text(
                              '${pct.toStringAsFixed(0)}%',
                              style: TextStyle(
                                color: isGood ? Colors.greenAccent : Colors.redAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.studentName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 2),
                                Text('${r.subjectName} ${r.studentOfficialId.isNotEmpty ? "• ${r.studentOfficialId}" : ""}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('P: ${r.presentCount} / ${r.totalClasses}', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                              Text('A: ${r.absentCount}', style: const TextStyle(color: Colors.redAccent, fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 3: LOW ATTENDANCE REPORT
  // ---------------------------------------------------------------------------
  Widget _buildLowAttendanceReportTab({
    required List<_StudentAttendanceRecord> lowAttendanceRecords,
    required double threshold,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: const Color(0xFF1E293B),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${lowAttendanceRecords.length} Students Below Threshold', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('Required Attendance: ${threshold.toStringAsFixed(0)}%', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  ReportExportService.showExportDialog(
                    context: context,
                    reportTitle: 'Low Attendance Deficit Report',
                    headers: ['Student Name', 'Student ID', 'Subject', 'Current %', 'Threshold %', 'Deficit %', 'Present', 'Absent', 'Total Classes'],
                    rows: lowAttendanceRecords.map((r) => [
                      r.studentName,
                      r.studentOfficialId,
                      r.subjectName,
                      '${r.attendancePercentage.toStringAsFixed(1)}%',
                      '${threshold.toStringAsFixed(0)}%',
                      '${(threshold - r.attendancePercentage).toStringAsFixed(1)}%',
                      '${r.presentCount}',
                      '${r.absentCount}',
                      '${r.totalClasses}',
                    ]).toList(),
                    summaryMetrics: {
                      'Required Threshold': '${threshold.toStringAsFixed(0)}%',
                      'Total Students in Deficit': '${lowAttendanceRecords.length}',
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.file_download_rounded, size: 16, color: Colors.white),
                label: const Text('Export', style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ],
          ),
        ),

        Expanded(
          child: lowAttendanceRecords.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline_rounded, size: 56, color: Colors.greenAccent),
                      SizedBox(height: 12),
                      Text('Great news! No students below attendance threshold.', style: TextStyle(color: Colors.white70, fontSize: 15)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: lowAttendanceRecords.length,
                  itemBuilder: (context, index) {
                    final r = lowAttendanceRecords[index];
                    final deficit = threshold - r.attendancePercentage;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.redAccent.withAlpha(80)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.red.withAlpha(40),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${r.attendancePercentage.toStringAsFixed(1)}% (${deficit.toStringAsFixed(1)}% deficit)',
                                  style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                              ),
                              const Spacer(),
                              Text('Classes: ${r.presentCount} / ${r.totalClasses}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(r.studentName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 2),
                          Text('${r.subjectName} ${r.studentOfficialId.isNotEmpty ? "• ${r.studentOfficialId}" : ""}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          const SizedBox(height: 10),
                          const Divider(color: Colors.white10, height: 1),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () async {
                                  if (r.studentEmail.isNotEmpty) {
                                    await _notificationService.triggerLowAttendanceAlert(
                                      studentEmail: r.studentEmail,
                                      studentName: r.studentName,
                                      currentAttendance: r.attendancePercentage,
                                      threshold: threshold,
                                    );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Attendance warning notification sent to ${r.studentName}!'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('No email found for this student.'), backgroundColor: Colors.redAccent),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.send_rounded, size: 14, color: Colors.amberAccent),
                                label: const Text('Send Alert Notification', style: TextStyle(color: Colors.amberAccent, fontSize: 12)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 4: ASSIGNMENTS REPORT
  // ---------------------------------------------------------------------------
  Widget _buildAssignmentsReportTab({
    required List<QueryDocumentSnapshot> assignmentDocs,
    required int totalAssigned,
    required int totalSubmitted,
    required int totalLate,
    required double submissionRate,
  }) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('ASSIGNMENT SUBMISSION METRICS', style: TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ElevatedButton.icon(
              onPressed: () {
                ReportExportService.showExportDialog(
                  context: context,
                  reportTitle: 'Assignment Performance Report',
                  headers: ['Assignment ID', 'Title', 'Subject', 'Due Date', 'Submissions', 'Status'],
                  rows: assignmentDocs.map((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final subs = data['submissions'] as List? ?? [];
                    return [
                      (data['assignmentId'] ?? '').toString(),
                      (data['title'] ?? '').toString(),
                      (data['subjectName'] ?? '').toString(),
                      (data['dueDate'] ?? '').toString(),
                      '${subs.length}',
                      (data['status'] ?? 'active').toString(),
                    ];
                  }).toList(),
                  summaryMetrics: {
                    'Total Assigned': '$totalAssigned',
                    'Total Submitted': '$totalSubmitted',
                    'Late Submissions': '$totalLate',
                    'Submission Rate': '${submissionRate.toStringAsFixed(1)}%',
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.file_download_rounded, size: 16, color: Colors.black87),
              label: const Text('Export', style: TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(child: _buildMetricCard('Submission Rate', '${submissionRate.toStringAsFixed(1)}%', Icons.pie_chart_rounded, Colors.orangeAccent)),
            const SizedBox(width: 10),
            Expanded(child: _buildMetricCard('Total Submitted', '$totalSubmitted', Icons.assignment_turned_in_rounded, Colors.greenAccent)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildMetricCard('Late Submissions', '$totalLate', Icons.history_rounded, Colors.redAccent)),
            const SizedBox(width: 10),
            Expanded(child: _buildMetricCard('Total Assigned', '$totalAssigned', Icons.assignment_rounded, Colors.cyanAccent)),
          ],
        ),
        const SizedBox(height: 20),

        const Text('Assignments List Breakdown', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),

        ...assignmentDocs.map((d) {
          final data = d.data() as Map<String, dynamic>;
          final subs = data['submissions'] as List? ?? [];
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['title'] ?? 'Untitled', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text('${data['subjectName'] ?? ""} • Due: ${data['dueDate'] ?? "—"}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(30),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${subs.length} Submitted',
                    style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 5: TASKS REPORT
  // ---------------------------------------------------------------------------
  Widget _buildTasksReportTab({
    required List<QueryDocumentSnapshot> taskDocs,
    required int totalTasks,
    required int pending,
    required int inProgress,
    required int completed,
    required int overdue,
    required double completionRate,
  }) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('TASK EXECUTION METRICS', style: TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ElevatedButton.icon(
              onPressed: () {
                ReportExportService.showExportDialog(
                  context: context,
                  reportTitle: 'Task Execution Performance Report',
                  headers: ['Task ID', 'Title', 'Assigned To', 'Priority', 'Due Date', 'Status'],
                  rows: taskDocs.map((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return [
                      (data['taskId'] ?? '').toString(),
                      (data['title'] ?? '').toString(),
                      (data['assignedToName'] ?? '').toString(),
                      (data['priority'] ?? '').toString(),
                      (data['dueDate'] ?? '').toString(),
                      (data['status'] ?? 'pending').toString(),
                    ];
                  }).toList(),
                  summaryMetrics: {
                    'Total Tasks': '$totalTasks',
                    'Completed': '$completed',
                    'Pending': '$pending',
                    'In Progress': '$inProgress',
                    'Overdue': '$overdue',
                    'Completion Rate': '${completionRate.toStringAsFixed(1)}%',
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.file_download_rounded, size: 16, color: Colors.black87),
              label: const Text('Export', style: TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(child: _buildMetricCard('Completion Rate', '${completionRate.toStringAsFixed(1)}%', Icons.task_alt_rounded, Colors.cyanAccent)),
            const SizedBox(width: 10),
            Expanded(child: _buildMetricCard('Completed', '$completed / $totalTasks', Icons.check_circle_rounded, Colors.greenAccent)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildMetricCard('In Progress', '$inProgress', Icons.run_circle_rounded, Colors.amberAccent)),
            const SizedBox(width: 10),
            Expanded(child: _buildMetricCard('Overdue', '$overdue', Icons.alarm_rounded, Colors.redAccent)),
          ],
        ),
        const SizedBox(height: 20),

        const Text('Tasks Breakdown', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),

        ...taskDocs.map((d) {
          final data = d.data() as Map<String, dynamic>;
          final status = (data['status'] ?? 'pending').toString();
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['title'] ?? 'Untitled', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text('Assigned to: ${data['assignedToName'] ?? "—"} • Due: ${data['dueDate'] ?? "—"}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: status == 'completed' ? Colors.green.withAlpha(30) : Colors.cyan.withAlpha(30),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: status == 'completed' ? Colors.greenAccent : Colors.cyanAccent,
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
  }

  // ---------------------------------------------------------------------------
  // TAB 6: ENROLLMENTS REPORT
  // ---------------------------------------------------------------------------
  Widget _buildEnrollmentsReportTab({
    required int totalEnrollments,
    required Map<String, int> subjectBreakdown,
    required List<QueryDocumentSnapshot> enrollmentDocs,
  }) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('ENROLLMENT ALLOCATION', style: TextStyle(color: Colors.tealAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ElevatedButton.icon(
              onPressed: () {
                ReportExportService.showExportDialog(
                  context: context,
                  reportTitle: 'Subject Enrollment Capacity Report',
                  headers: ['Subject Name / Code', 'Enrolled Students Count'],
                  rows: subjectBreakdown.entries.map((e) => [e.key, '${e.value} Students']).toList(),
                  summaryMetrics: {
                    'Total Active Enrollments': '$totalEnrollments',
                    'Total Subjects with Students': '${subjectBreakdown.length}',
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.file_download_rounded, size: 16, color: Colors.white),
              label: const Text('Export', style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 12),

        _buildMetricCard('Total Active Course Enrollments', '$totalEnrollments', Icons.assignment_ind_rounded, Colors.tealAccent),
        const SizedBox(height: 20),

        const Text('Students per Subject', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),

        ...subjectBreakdown.entries.map((entry) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.book_rounded, color: Colors.tealAccent, size: 20),
                    const SizedBox(width: 12),
                    Text(entry.key, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.teal.withAlpha(30),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${entry.value} Students',
                    style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _StudentAttendanceRecord {
  final String studentDocId;
  final String studentName;
  final String studentOfficialId;
  final String studentEmail;
  final String subjectCode;
  final String subjectName;
  int totalClasses;
  int presentCount;
  int absentCount;

  _StudentAttendanceRecord({
    required this.studentDocId,
    required this.studentName,
    required this.studentOfficialId,
    required this.studentEmail,
    required this.subjectCode,
    required this.subjectName,
    required this.totalClasses,
    required this.presentCount,
    required this.absentCount,
  });

  double get attendancePercentage {
    if (totalClasses == 0) return 0.0;
    return (presentCount / totalClasses) * 100;
  }
}
