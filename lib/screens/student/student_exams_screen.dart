import 'package:flutter/material.dart';
import '../../services/student_portal_service.dart';
import '../../services/enrollment_service.dart';
import '../../services/exam_registration_service.dart';
import '../../services/exam_seating_service.dart';
import '../../services/exam_attendance_service.dart';
import '../../models/exam_model.dart';
import '../../models/exam_registration_model.dart';
import '../../models/exam_seating_model.dart';
import '../../models/exam_attendance_record_model.dart';
import 'student_exam_admission_card_screen.dart';

class StudentExamsScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const StudentExamsScreen({super.key, this.userData});

  @override
  State<StudentExamsScreen> createState() => _StudentExamsScreenState();
}

class _StudentExamsScreenState extends State<StudentExamsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ExamRegistrationService _regService = ExamRegistrationService();
  final ExamSeatingService _seatingService = ExamSeatingService();
  final ExamAttendanceService _attendanceService = ExamAttendanceService();
  final StudentPortalService _portalService = StudentPortalService();
  final EnrollmentService _enrollmentService = EnrollmentService();

  bool _isRegistering = false;

  void _showQrPassModal(ExamRegistrationModel reg, ExamSeatingModel? seating) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Digital Exam Hall Pass QR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
            const SizedBox(height: 4),
            Text('${reg.subjectCode} • ${reg.subjectName}', style: const TextStyle(color: Colors.tealAccent, fontSize: 12), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            // Large QR Code Frame
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.qr_code_2_rounded, size: 140, color: Colors.black),
                  Text(
                    reg.registrationId,
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'monospace', fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (seating != null) ...[
              Text('Allocated Seat: ${seating.seatNumber} • Venue: ${seating.hallName}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 4),
            ],
            const Text('Present this QR code to the invigilator at the examination hall entrance for verification.', style: TextStyle(color: Colors.grey, fontSize: 11), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister(ExamModel exam, String email, String studentId, String studentName, String batch) async {
    setState(() => _isRegistering = true);

    try {
      final reg = await _regService.registerForExam(
        exam: exam,
        studentDocId: email,
        studentId: studentId,
        studentName: studentName,
        studentEmail: email,
        studentBatch: batch,
      );

      if (mounted) {
        _showSuccessDialog(reg, exam);
      }
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRegistering = false);
    }
  }

  void _showSuccessDialog(ExamRegistrationModel reg, ExamModel exam) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Column(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: reg.status.toLowerCase() == 'registered' ? Colors.green : Colors.amber,
              child: Icon(
                reg.status.toLowerCase() == 'registered' ? Icons.check_rounded : Icons.hourglass_top_rounded,
                color: Colors.white,
                size: 38,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              reg.status.toLowerCase() == 'registered' ? 'Registration Confirmed!' : 'Registration Submitted!',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.tealAccent.withAlpha(80)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Registration ID:', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      Text(reg.registrationId, style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontFamily: 'monospace', fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Module:', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      Text('${exam.subjectCode} • ${exam.examType}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Date & Time:', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      Text('${exam.date} • ${exam.startTime}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Status:', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      Text(reg.status.toUpperCase(), style: TextStyle(color: reg.status.toLowerCase() == 'registered' ? Colors.greenAccent : Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              reg.status.toLowerCase() == 'registered'
                  ? 'Your digital exam admission pass has been activated. Please ensure to bring your student ID card on exam day.'
                  : 'Your registration is pending administrator review. You will receive an alert once approved.',
              style: const TextStyle(color: Colors.grey, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _tabController.animateTo(0); // Switch to registered tab
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('View Registered Passes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = (widget.userData?['email'] ?? '').trim().toLowerCase();
    final studentId = (widget.userData?['studentId'] ?? 'STU-1002').trim();
    final studentName = (widget.userData?['fullName'] ?? widget.userData?['name'] ?? 'Student').trim();
    final batch = (widget.userData?['batch'] ?? '2026').trim();

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
            Icon(Icons.assignment_outlined, color: Colors.amberAccent),
            SizedBox(width: 8),
            Text('Examinations & Registration', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amberAccent,
          labelColor: Colors.amberAccent,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: const [
            Tab(text: 'My Registered Exams & Passes', icon: Icon(Icons.verified_rounded, size: 16)),
            Tab(text: 'Register for Upcoming Exams', icon: Icon(Icons.app_registration_rounded, size: 16)),
          ],
        ),
      ),
      body: StreamBuilder(
        stream: _enrollmentService.getStudentActiveEnrollmentsStream(email),
        builder: (context, enrollSnap) {
          final enrollments = enrollSnap.data ?? [];
          final enrolledCodes = enrollments.map((e) => e.subjectCode.toUpperCase()).toList();

          return StreamBuilder<List<ExamRegistrationModel>>(
            stream: _regService.getStudentRegistrationsStream(studentId, studentEmail: email),
            builder: (context, regSnap) {
              final registrations = regSnap.data ?? [];
              final registeredExamIds = registrations.map((r) => r.examId).toSet();

              return StreamBuilder<List<ExamSeatingModel>>(
                stream: _seatingService.getSeatingForStudentStream(studentId, studentEmail: email),
                builder: (context, seatingSnap) {
                  final seatings = seatingSnap.data ?? [];

                  return StreamBuilder<List<ExamAttendanceRecordModel>>(
                    stream: _attendanceService.getStudentExamAttendanceStream(studentId, studentEmail: email),
                    builder: (context, attSnap) {
                      final attendances = attSnap.data ?? [];

                      return TabBarView(
                        controller: _tabController,
                        children: [
                          // ─── TAB 1: MY REGISTERED EXAMS & HALL PASSES ────────────────
                          _buildRegisteredPassesTab(studentName, studentId, batch, registrations, seatings, attendances),

                          // ─── TAB 2: REGISTER FOR UPCOMING EXAMS ─────────────────────
                          _buildRegisterUpcomingTab(email, studentId, studentName, batch, enrolledCodes, registeredExamIds, registrations),
                        ],
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

  // ─── TAB 1: REGISTERED EXAMS & HALL PASSES ─────────────────────────────────
  Widget _buildRegisteredPassesTab(
    String studentName,
    String studentId,
    String batch,
    List<ExamRegistrationModel> registrations,
    List<ExamSeatingModel> seatings,
    List<ExamAttendanceRecordModel> attendances,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Digital Admission Pass Banner
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF312E81), Color(0xFF1E1B4B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.indigoAccent.withAlpha(90)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.verified_rounded, color: Colors.amberAccent, size: 20),
                      SizedBox(width: 6),
                      Text('DIGITAL EXAM HALL PASS', style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.green.withAlpha(40), borderRadius: BorderRadius.circular(6)),
                    child: const Text('OFFICIAL', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(studentName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Text('Student ID: $studentId • Batch $batch', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 10),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${registrations.length} Active Registrations', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  const Text('Semester 1 • Academic Year 2026', style: TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
              if (registrations.isNotEmpty) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StudentExamAdmissionCardScreen(
                            studentName: studentName,
                            studentId: studentId,
                            studentEmail: studentId,
                            batch: batch,
                            registrations: registrations,
                            seatings: seatings,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amberAccent,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.badge_rounded, color: Colors.black87, size: 16),
                    label: const Text('View Official Admission Card', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        const Text('Registered Exam Passes & Allocated Seats', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),

        if (registrations.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            alignment: Alignment.center,
            child: Column(
              children: [
                const Icon(Icons.assignment_turned_in_outlined, size: 48, color: Colors.grey),
                const SizedBox(height: 10),
                const Text('You have not registered for any exams yet.', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 4),
                const Text('Switch to "Register for Upcoming Exams" tab to register.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: () => _tabController.animateTo(1),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  icon: const Icon(Icons.app_registration_rounded, color: Colors.white, size: 16),
                  label: const Text('Register for Exams Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          )
        else
          ...registrations.map((reg) {
            final isApproved = reg.isApprovedOrRegistered;

            // Match allocated seating for this registration
            final seatingMatch = seatings.where((s) => s.examId == reg.examId || s.examDocId == reg.examDocId).toList();
            final hasSeat = seatingMatch.isNotEmpty;
            final assignedSeat = hasSeat ? seatingMatch.first : null;

            // Match attendance record for this registration
            final attMatch = attendances.where((a) => a.examId == reg.examId || a.examDocId == reg.examDocId).toList();
            final attRecord = attMatch.isNotEmpty ? attMatch.first : null;
            final isPresent = attRecord != null && attRecord.isPresent;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isPresent ? const Color(0xFF064E3B).withAlpha(30) : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isPresent ? Colors.greenAccent : (hasSeat ? Colors.tealAccent.withAlpha(80) : Colors.amberAccent.withAlpha(80))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.teal.withAlpha(40),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.tealAccent),
                        ),
                        child: Text(reg.subjectCode, style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      Row(
                        children: [
                          if (isPresent)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: Colors.green.withAlpha(40), borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.greenAccent)),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle_rounded, size: 12, color: Colors.greenAccent),
                                  SizedBox(width: 4),
                                  Text('PRESENT (VERIFIED)', style: TextStyle(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isApproved ? Colors.teal.withAlpha(30) : Colors.amber.withAlpha(30),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                reg.status.toUpperCase(),
                                style: TextStyle(color: isApproved ? Colors.tealAccent : Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(reg.subjectName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 10),

                  // Allocated Seat & Venue Banner
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: hasSeat ? const Color(0xFF064E3B).withAlpha(40) : const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: hasSeat ? Colors.greenAccent.withAlpha(60) : Colors.white10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          hasSeat ? Icons.event_seat_rounded : Icons.pending_actions_rounded,
                          size: 18,
                          color: hasSeat ? Colors.greenAccent : Colors.amberAccent,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    hasSeat ? 'Assigned Seat: ' : 'Seat Number: ',
                                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                                  ),
                                  Text(
                                    hasSeat ? assignedSeat!.seatNumber : 'Desk Allocation Pending',
                                    style: TextStyle(
                                      color: hasSeat ? Colors.greenAccent : Colors.amberAccent,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: hasSeat ? 'monospace' : null,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              if (hasSeat)
                                Text('Venue: ${assignedSeat!.hallName}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _showQrPassModal(reg, assignedSeat),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          icon: const Icon(Icons.qr_code_rounded, size: 14, color: Colors.white),
                          label: const Text('Show QR', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      const Icon(Icons.qr_code_rounded, size: 14, color: Colors.amberAccent),
                      const SizedBox(width: 4),
                      Text('Reg ID: ${reg.registrationId}', style: const TextStyle(color: Colors.amberAccent, fontSize: 11, fontFamily: 'monospace')),
                      const Spacer(),
                      Text('Registered: ${reg.registeredAt.length >= 10 ? reg.registeredAt.substring(0, 10) : reg.registeredAt}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // ─── TAB 2: REGISTER FOR UPCOMING EXAMS ───────────────────────────────────
  Widget _buildRegisterUpcomingTab(
    String email,
    String studentId,
    String studentName,
    String batch,
    List<String> enrolledCodes,
    Set<String> registeredExamIds,
    List<ExamRegistrationModel> existingRegistrations,
  ) {
    return StreamBuilder<List<ExamModel>>(
      stream: _portalService.getExamsForSubjects(enrolledCodes),
      builder: (context, examSnap) {
        if (examSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
        }

        final allExams = examSnap.data ?? [];
        final eligibleExams = allExams.where((e) => e.status.toLowerCase() != 'cancelled').toList();

        if (eligibleExams.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.event_busy_rounded, size: 52, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('No upcoming examinations found for your enrolled modules.', style: TextStyle(color: Colors.white70, fontSize: 14), textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Text('Enrolled modules: ${enrolledCodes.join(', ')}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Eligibility Notice Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.tealAccent.withAlpha(60)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_rounded, color: Colors.tealAccent, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Automatic Eligibility Verification', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text('Module Enrollment: Active (${enrolledCodes.length} Modules) • Student: Verified', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            ...eligibleExams.map((exam) {
              final isAlreadyRegistered = registeredExamIds.contains(exam.examId);
              final isPastDl = exam.isPastDeadline;
              final canRegister = !isAlreadyRegistered && !isPastDl;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isAlreadyRegistered ? Colors.greenAccent.withAlpha(60) : Colors.white10),
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
                              decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(6)),
                              child: Text(exam.subjectCode, style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 8),
                            Text(exam.examType, style: const TextStyle(color: Colors.indigoAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        // Registration Status Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isAlreadyRegistered
                                ? Colors.green.withAlpha(30)
                                : (isPastDl ? Colors.red.withAlpha(30) : Colors.teal.withAlpha(30)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isAlreadyRegistered ? 'REGISTERED' : (isPastDl ? 'DEADLINE PASSED' : 'OPEN FOR REGISTRATION'),
                            style: TextStyle(
                              color: isAlreadyRegistered ? Colors.greenAccent : (isPastDl ? Colors.redAccent : Colors.tealAccent),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(exam.subjectName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        const Icon(Icons.event_available_rounded, size: 14, color: Colors.tealAccent),
                        const SizedBox(width: 4),
                        Text(exam.date, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(width: 12),
                        const Icon(Icons.schedule_rounded, size: 14, color: Colors.tealAccent),
                        const SizedBox(width: 4),
                        Text('${exam.startTime} - ${exam.endTime}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Deadline info & Register Action
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Deadline: ${exam.registrationDeadline.isNotEmpty ? exam.registrationDeadline : exam.date}',
                          style: TextStyle(color: isPastDl ? Colors.redAccent : Colors.grey, fontSize: 11),
                        ),
                        ElevatedButton.icon(
                          onPressed: canRegister && !_isRegistering
                              ? () => _handleRegister(exam, email, studentId, studentName, batch)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isAlreadyRegistered ? Colors.green : (canRegister ? Colors.teal : Colors.grey.withAlpha(50)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: _isRegistering
                              ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Icon(isAlreadyRegistered ? Icons.check_circle_rounded : Icons.how_to_reg_rounded, size: 14, color: Colors.white),
                          label: Text(
                            isAlreadyRegistered ? 'Registered' : (isPastDl ? 'Closed' : 'Register for Exam'),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ],
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
}
