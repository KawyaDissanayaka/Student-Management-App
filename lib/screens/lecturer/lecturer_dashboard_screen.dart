import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../auth/login_screen.dart';
import '../../models/timetable_model.dart';
import '../../models/submission_model.dart';
import '../user_tasks_screen.dart';
import '../user_notifications_screen.dart';
import 'lecturer_subjects_screen.dart';
import 'lecturer_timetable_screen.dart';

class LecturerDashboardScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const LecturerDashboardScreen({super.key, this.userData});

  @override
  State<LecturerDashboardScreen> createState() => _LecturerDashboardScreenState();
}

class _LecturerDashboardScreenState extends State<LecturerDashboardScreen> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _getTodayDayOfWeek() {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[DateTime.now().weekday - 1];
  }

  void _showUploadMaterialDialog(BuildContext context, List<String> mySubjectCodes) {
    final titleController = TextEditingController();
    final weekController = TextEditingController(text: '1');
    final descController = TextEditingController();
    String selectedSubject = mySubjectCodes.isNotEmpty ? mySubjectCodes.first : 'CS101';
    String selectedFileType = 'PDF';
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
                  const Row(
                    children: [
                      Icon(Icons.upload_file_rounded, color: Colors.tealAccent),
                      SizedBox(width: 8),
                      Text('Upload Learning Material', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 14),

              if (mySubjectCodes.isNotEmpty)
                DropdownButtonFormField<String>(
                  initialValue: selectedSubject,
                  dropdownColor: const Color(0xFF0F172A),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Target Subject',
                    labelStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: mySubjectCodes.map((code) => DropdownMenuItem(value: code, child: Text(code))).toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedSubject = val);
                  },
                ),
              const SizedBox(height: 12),

              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Lecture / Slide Title *',
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: weekController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Week Number',
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
                      initialValue: selectedFileType,
                      dropdownColor: const Color(0xFF0F172A),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'File Type',
                        labelStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: ['PDF', 'PPTX', 'DOCX', 'ZIP'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedFileType = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextField(
                controller: descController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Description / Notes',
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
                          final title = titleController.text.trim();
                          if (title.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a title.'), backgroundColor: Colors.redAccent),
                            );
                            return;
                          }

                          setModalState(() => isUploading = true);
                          final messenger = ScaffoldMessenger.of(context);
                          final nav = Navigator.of(ctx);

                          final lecturerName = widget.userData?['fullName'] ?? _authService.currentUser?.displayName ?? 'Lecturer';

                          try {
                            await _firestore.collection('materials').add({
                              'materialId': 'MAT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                              'title': title,
                              'description': descController.text.trim(),
                              'subjectCode': selectedSubject,
                              'subjectName': selectedSubject,
                              'lecturerName': lecturerName,
                              'fileType': selectedFileType,
                              'fileSize': '3.2 MB',
                              'downloadUrl': 'https://university.edu/materials/$selectedSubject.pdf',
                              'uploadedDate': DateTime.now().toIso8601String().substring(0, 10),
                              'weekNumber': int.tryParse(weekController.text.trim()) ?? 1,
                            });

                            nav.pop();
                            messenger.showSnackBar(
                              SnackBar(content: Text('Material "$title" published for students!'), backgroundColor: Colors.green),
                            );
                          } catch (e) {
                            setModalState(() => isUploading = false);
                            messenger.showSnackBar(
                              SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.redAccent),
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
                      : const Icon(Icons.cloud_upload_rounded, color: Colors.white),
                  label: const Text('Publish Material to Students', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Sign Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: const Text('Are you sure you want to sign out from Lecturer Portal?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              final nav = Navigator.of(context);
              Navigator.pop(ctx);
              await _authService.signOut();
              if (mounted) {
                nav.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Sign Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = (widget.userData?['email'] ?? _authService.currentUser?.email ?? '').trim().toLowerCase();
    final defaultName = widget.userData?['fullName'] ?? _authService.currentUser?.displayName ?? 'Dr. Lecturer';
    final todayDay = _getTodayDayOfWeek();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.amber,
              child: Icon(Icons.cast_for_education_rounded, color: Colors.black87, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Lecturer Portal', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                Text(email, style: const TextStyle(color: Colors.amberAccent, fontSize: 11)),
              ],
            ),
          ],
        ),
        actions: [
          StreamBuilder<int>(
            stream: NotificationService().getUnreadCountStream(email, 'Lecturer'),
            builder: (context, notifSnap) {
              final unreadCount = notifSnap.data ?? 0;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_rounded, color: Colors.purpleAccent),
                    tooltip: 'Notifications',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserNotificationsScreen(
                            userEmail: email,
                            userName: defaultName,
                            userRole: 'Lecturer',
                          ),
                        ),
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: 'Sign Out',
            onPressed: _confirmSignOut,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 1. Fetch Lecturer Profile
        stream: _firestore.collection('lecturers').where('email', isEqualTo: email).limit(1).snapshots(),
        builder: (context, lecSnap) {
          final lecData = (lecSnap.data?.docs.isNotEmpty ?? false) ? lecSnap.data!.docs.first.data() as Map<String, dynamic> : widget.userData ?? {};

          final lecturerName = lecData['name'] ?? lecData['fullName'] ?? defaultName;
          final lecturerId = lecData['lecturerId'] ?? 'LEC-1001';
          final department = lecData['department'] ?? 'Department of Computing';

          return StreamBuilder<QuerySnapshot>(
            // 2. Fetch Subjects Assigned to this Lecturer
            stream: _firestore.collection('subjects').snapshots(),
            builder: (context, subSnap) {
              final allSubjects = subSnap.data?.docs ?? [];
              final mySubjects = allSubjects.where((d) {
                final data = d.data() as Map<String, dynamic>;
                final isActive = (data['status'] ?? 'active').toString().toLowerCase() == 'active';
                if (!isActive) return false;
                final lName = (data['lecturerName'] ?? '').toString().toLowerCase();
                final lId = (data['lecturerId'] ?? '').toString().toUpperCase();
                return lName == lecturerName.toLowerCase() || (lecturerId.isNotEmpty && lId == lecturerId) || (lName.contains(lecturerName.toLowerCase().split(' ').last));
              }).toList();

              final mySubjectCodes = mySubjects.map((d) => (d.data() as Map<String, dynamic>)['subjectCode'].toString()).toList();

              return StreamBuilder<QuerySnapshot>(
                // 3. Fetch Unique Enrolled Students for My Subjects
                stream: _firestore.collection('enrollments').where('status', isEqualTo: 'active').snapshots(),
                builder: (context, enrollSnap) {
                  final allEnrollments = enrollSnap.data?.docs ?? [];
                  final myEnrollments = allEnrollments.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final code = data['subjectCode']?.toString() ?? '';
                    final lEmail = (data['lecturerEmail'] ?? '').toString().toLowerCase();
                    return mySubjectCodes.contains(code) || (email.isNotEmpty && lEmail == email);
                  }).toList();

                  // Distinct active students count
                  final uniqueStudentIds = myEnrollments.map((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return (data['studentEmail'] ?? data['studentId'] ?? '').toString().toLowerCase();
                  }).where((id) => id.isNotEmpty).toSet();

                  return StreamBuilder<QuerySnapshot>(
                    // 4. Fetch Timetable Schedules for this Lecturer
                    stream: _firestore.collection('timetable').snapshots(),
                    builder: (context, timeSnap) {
                      final allSchedules = (timeSnap.data?.docs ?? []).map((d) => TimetableModel.fromFirestore(d)).where((s) {
                        if (s.status == 'cancelled') return false;
                        final matchesEmail = email.isNotEmpty && s.lecturerEmail.trim().toLowerCase() == email;
                        final matchesName = s.lecturerName.toLowerCase().contains(lecturerName.toLowerCase().split(' ').last);
                        final matchesSubject = mySubjectCodes.contains(s.subjectCode);
                        return matchesEmail || matchesName || matchesSubject;
                      }).toList();

                      final todayLectures = allSchedules.where((s) => s.dayOfWeek.toLowerCase() == todayDay.toLowerCase()).toList();

                      // Nearest upcoming lecture
                      TimetableModel? nextLecture;
                      if (todayLectures.isNotEmpty) {
                        nextLecture = todayLectures.first;
                      } else if (allSchedules.isNotEmpty) {
                        nextLecture = allSchedules.first;
                      }

                      return StreamBuilder<QuerySnapshot>(
                        // 5. Fetch Submissions for My Subjects
                        stream: _firestore.collection('submissions').snapshots(),
                        builder: (context, submisSnap) {
                          final allSubmissions = (submisSnap.data?.docs ?? [])
                              .map((d) => SubmissionModel.fromFirestore(d as DocumentSnapshot<Map<String, dynamic>>))
                              .where((sub) {
                            return mySubjectCodes.contains(sub.subjectCode) || sub.subjectCode.isEmpty;
                          }).toList();

                          final pendingSubmissions = allSubmissions.where((s) => s.mark == null).toList();

                          return StreamBuilder<QuerySnapshot>(
                            // 6. Fetch Tasks Assigned to this Lecturer
                            stream: _firestore.collection('tasks').snapshots(),
                            builder: (context, taskSnap) {
                              final allTasks = taskSnap.data?.docs ?? [];
                              final myPendingTasks = allTasks.where((d) {
                                final data = d.data() as Map<String, dynamic>;
                                final tEmail = (data['assignedToEmail'] ?? '').toString().toLowerCase();
                                final tStatus = (data['status'] ?? 'pending').toString().toLowerCase();
                                final isMine = tEmail == email || tEmail.isEmpty;
                                return isMine && (tStatus == 'pending' || tStatus == 'in_progress');
                              }).toList();

                              return StreamBuilder<int>(
                                // 7. Unread Notifications Count
                                stream: NotificationService().getUnreadCountStream(email, 'Lecturer'),
                                builder: (context, notifCountSnap) {
                                  final unreadNotifs = notifCountSnap.data ?? 0;

                                  return ListView(
                                    padding: const EdgeInsets.all(16),
                                    children: [
                                      // Lecturer Profile Header Banner
                                      Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFF1E293B), Color(0xFF334155)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(18),
                                          border: Border.all(color: Colors.amberAccent.withAlpha(80)),
                                        ),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 30,
                                              backgroundColor: Colors.amber.withAlpha(30),
                                              child: const Icon(Icons.person_rounded, size: 36, color: Colors.amberAccent),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(lecturerName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                                  const SizedBox(height: 2),
                                                  Text('$lecturerId • $department', style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.w600)),
                                                  const SizedBox(height: 4),
                                                  Text(email, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 18),

                                      // Summary KPI Cards Grid (6 Cards)
                                      const Text('LECTURER METRICS OVERVIEW', style: TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                      const SizedBox(height: 10),

                                      GridView.count(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        crossAxisCount: 2,
                                        crossAxisSpacing: 10,
                                        mainAxisSpacing: 10,
                                        childAspectRatio: 1.3,
                                        children: [
                                          _buildMetricCard('My Subjects', '${mySubjects.length} Modules', Icons.book_rounded, Colors.indigoAccent, onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => LecturerSubjectsScreen(
                                                  lecturerEmail: email,
                                                  lecturerName: lecturerName,
                                                  lecturerId: lecturerId,
                                                ),
                                              ),
                                            );
                                          }),
                                          _buildMetricCard('Total Students', '${uniqueStudentIds.length} Enrolled', Icons.people_alt_rounded, Colors.tealAccent, onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => LecturerSubjectsScreen(
                                                  lecturerEmail: email,
                                                  lecturerName: lecturerName,
                                                  lecturerId: lecturerId,
                                                ),
                                              ),
                                            );
                                          }),
                                          _buildMetricCard("Today's Lectures", '${todayLectures.length} Classes', Icons.today_rounded, Colors.cyanAccent),
                                          _buildMetricCard('Pending Submissions', '${pendingSubmissions.length} To Review', Icons.assignment_late_rounded, Colors.orangeAccent),
                                          _buildMetricCard('Pending Tasks', '${myPendingTasks.length} Active', Icons.task_alt_rounded, Colors.greenAccent, onTap: () {
                                            Navigator.push(context, MaterialPageRoute(builder: (context) => UserTasksScreen(userEmail: email, userName: lecturerName, userRole: 'Lecturer')));
                                          }),
                                          _buildMetricCard('Unread Alerts', '$unreadNotifs Notifications', Icons.notifications_active_rounded, Colors.purpleAccent, onTap: () {
                                            Navigator.push(context, MaterialPageRoute(builder: (context) => UserNotificationsScreen(userEmail: email, userName: lecturerName, userRole: 'Lecturer')));
                                          }),
                                        ],
                                      ),
                                      const SizedBox(height: 22),

                                      // Next Upcoming Lecture Banner
                                      const Text('NEXT UPCOMING LECTURE', style: TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                      const SizedBox(height: 10),

                                      if (nextLecture == null)
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(14)),
                                          child: const Center(child: Text('No upcoming lectures scheduled in timetable.', style: TextStyle(color: Colors.grey))),
                                        )
                                      else
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFF064E3B), Color(0xFF0F172A)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: Colors.tealAccent.withAlpha(80)),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(color: Colors.teal.withAlpha(40), borderRadius: BorderRadius.circular(6)),
                                                    child: Text(nextLecture.subjectCode, style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                                                  ),
                                                  Text('${nextLecture.dayOfWeek} • ${nextLecture.startTime}', style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(nextLecture.subjectName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  const Icon(Icons.location_on_rounded, size: 14, color: Colors.tealAccent),
                                                  const SizedBox(width: 4),
                                                  Text('Venue: ${nextLecture.hallName}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                                  const SizedBox(width: 14),
                                                  const Icon(Icons.groups_rounded, size: 14, color: Colors.grey),
                                                  const SizedBox(width: 4),
                                                  Text('Batch ${nextLecture.batch}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      const SizedBox(height: 22),

                                      // Today's Scheduled Lectures
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text("TODAY'S SCHEDULE ($todayDay)", style: const TextStyle(color: Colors.tealAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => LecturerTimetableScreen(
                                                    lecturerEmail: email,
                                                    lecturerName: lecturerName,
                                                    lecturerId: lecturerId,
                                                  ),
                                                ),
                                              );
                                            },
                                            child: const Text('All Timetable', style: TextStyle(color: Colors.tealAccent, fontSize: 12)),
                                          ),
                                        ],
                                      ),

                                      if (todayLectures.isEmpty)
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(14)),
                                          child: const Center(child: Text('No classes scheduled for today. Have a productive day!', style: TextStyle(color: Colors.grey))),
                                        )
                                      else
                                        ...todayLectures.map((lec) {
                                          return Container(
                                            margin: const EdgeInsets.only(bottom: 10),
                                            padding: const EdgeInsets.all(14),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1E293B),
                                              borderRadius: BorderRadius.circular(14),
                                              border: Border.all(color: Colors.white10),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(10),
                                                  decoration: BoxDecoration(color: Colors.teal.withAlpha(30), borderRadius: BorderRadius.circular(10)),
                                                  child: const Icon(Icons.class_rounded, color: Colors.tealAccent, size: 20),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(lec.subjectName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                                      const SizedBox(height: 2),
                                                      Text('${lec.startTime} - ${lec.endTime} • ${lec.hallName} • Batch ${lec.batch}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                                    ],
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(color: Colors.amber.withAlpha(30), borderRadius: BorderRadius.circular(6)),
                                                  child: Text(lec.classType.toUpperCase(), style: const TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                      const SizedBox(height: 22),

                                      // Pending Assignment Submissions Section
                                      const Text('SUBMISSIONS AWAITING GRADING', style: TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                      const SizedBox(height: 10),

                                      if (pendingSubmissions.isEmpty)
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(14)),
                                          child: const Center(child: Text('All student submissions are reviewed and graded!', style: TextStyle(color: Colors.greenAccent))),
                                        )
                                      else
                                        ...pendingSubmissions.take(3).map((sub) {
                                          return Container(
                                            margin: const EdgeInsets.only(bottom: 8),
                                            padding: const EdgeInsets.all(14),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1E293B),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Colors.white10),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.assignment_turned_in_rounded, color: Colors.orangeAccent, size: 20),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(sub.studentName.isNotEmpty ? sub.studentName : sub.studentEmail, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                                      Text('${sub.subjectCode} • ${sub.assignmentTitle}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                                    ],
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(color: Colors.orange.withAlpha(30), borderRadius: BorderRadius.circular(6)),
                                                  child: const Text('SUBMITTED', style: TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                      const SizedBox(height: 22),

                                      // Lecturer Quick Actions
                                      const Text('LECTURER ACTION HUB', style: TextStyle(color: Colors.tealAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                      const SizedBox(height: 12),

                                      GridView.count(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        crossAxisCount: 3,
                                        crossAxisSpacing: 10,
                                        mainAxisSpacing: 10,
                                        childAspectRatio: 1.0,
                                        children: [
                                          _buildActionTile('Mark Attendance', Icons.how_to_reg_rounded, Colors.greenAccent, () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => LecturerSubjectsScreen(
                                                  lecturerEmail: email,
                                                  lecturerName: lecturerName,
                                                  lecturerId: lecturerId,
                                                ),
                                              ),
                                            );
                                          }),
                                          _buildActionTile('Upload Materials', Icons.upload_file_rounded, Colors.tealAccent, () {
                                            _showUploadMaterialDialog(context, mySubjectCodes);
                                          }),
                                          _buildActionTile('New Assignment', Icons.assignment_add, Colors.orangeAccent, () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => LecturerSubjectsScreen(
                                                  lecturerEmail: email,
                                                  lecturerName: lecturerName,
                                                  lecturerId: lecturerId,
                                                ),
                                              ),
                                            );
                                          }),
                                          _buildActionTile('Assign Task', Icons.add_task_rounded, Colors.cyanAccent, () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => LecturerSubjectsScreen(
                                                  lecturerEmail: email,
                                                  lecturerName: lecturerName,
                                                  lecturerId: lecturerId,
                                                ),
                                              ),
                                            );
                                          }),
                                          _buildActionTile('Announce', Icons.campaign_rounded, Colors.pinkAccent, () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => LecturerSubjectsScreen(
                                                  lecturerEmail: email,
                                                  lecturerName: lecturerName,
                                                  lecturerId: lecturerId,
                                                ),
                                              ),
                                            );
                                          }),
                                          _buildActionTile('My Timetable', Icons.calendar_month_rounded, Colors.amberAccent, () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => LecturerTimetableScreen(
                                                  lecturerEmail: email,
                                                  lecturerName: lecturerName,
                                                  lecturerId: lecturerId,
                                                ),
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                                      const SizedBox(height: 24),
                                    ],
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

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
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
                Expanded(child: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11), overflow: TextOverflow.ellipsis)),
                Icon(icon, size: 16, color: color),
              ],
            ),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withAlpha(20), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
