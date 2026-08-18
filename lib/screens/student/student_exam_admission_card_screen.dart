import 'package:flutter/material.dart';
import '../../models/exam_registration_model.dart';
import '../../models/exam_seating_model.dart';
import '../../models/exam_hall_model.dart';

class StudentExamAdmissionCardScreen extends StatelessWidget {
  final String studentName;
  final String studentId;
  final String studentEmail;
  final String batch;
  final List<ExamRegistrationModel> registrations;
  final List<ExamSeatingModel> seatings;
  final List<ExamHallModel>? halls;

  const StudentExamAdmissionCardScreen({
    super.key,
    required this.studentName,
    required this.studentId,
    required this.studentEmail,
    required this.batch,
    required this.registrations,
    required this.seatings,
    this.halls,
  });

  @override
  Widget build(BuildContext context) {
    final approvedRegistrations = registrations.where((r) => r.isApprovedOrRegistered).toList();
    final seatingMap = {for (var s in seatings) s.examId: s};
    final hallMap = {if (halls != null) for (var h in halls!) h.hallId: h};

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Official Exam Admission Card', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded, color: Colors.tealAccent),
            tooltip: 'Print Admission Card',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Admission Card ready for print / screenshot! Present this at the exam hall.'),
                  backgroundColor: Colors.teal,
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ─── OFFICIAL ADMISSION CARD CREDENTIAL CONTAINER ─────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(80),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. University Header & Seal Strip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E1B4B), // Deep Navy
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amberAccent.withAlpha(40),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.amberAccent, width: 1.5),
                          ),
                          child: const Icon(Icons.account_balance_rounded, color: Colors.amberAccent, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'UNIVERSITY OF HIGHER EDUCATION',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8),
                              ),
                              Text(
                                'OFFICIAL EXAMINATION ADMISSION CARD',
                                style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
                              ),
                              Text(
                                'Academic Year 2025/2026 • Semester 1',
                                style: TextStyle(color: Colors.white70, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. Candidate Information Block & QR Code
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: const Color(0xFFF8FAFC),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Candidate details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('CANDIDATE NAME', style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
                              Text(studentName.toUpperCase(), style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 8),

                              Row(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('STUDENT ID', style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
                                      Text(studentId, style: const TextStyle(color: Color(0xFF1E1B4B), fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'monospace')),
                                    ],
                                  ),
                                  const SizedBox(width: 24),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('BATCH', style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
                                      Text(batch, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text('STATUS', style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: Colors.green[100], borderRadius: BorderRadius.circular(4)),
                                child: Text('ELIGIBLE & REGISTERED', style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold, fontSize: 10)),
                              ),
                            ],
                          ),
                        ),

                        // Unique Master Admission QR Code
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.qr_code_2_rounded, size: 72, color: Colors.black87),
                              Text(
                                studentId,
                                style: const TextStyle(color: Colors.black87, fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(color: Colors.black12, height: 1),

                  // 3. Registered Examination Schedule Table
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.event_note_rounded, color: Color(0xFF1E1B4B), size: 18),
                            SizedBox(width: 6),
                            Text('EXAMINATION SCHEDULE & VENUE ALLOCATIONS', style: TextStyle(color: Color(0xFF1E1B4B), fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (approvedRegistrations.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            alignment: Alignment.center,
                            child: const Text('No approved examination registrations found.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          )
                        else
                          ...approvedRegistrations.map((reg) {
                            final seating = seatingMap[reg.examId];
                            final seatNumber = seating?.seatNumber ?? 'Pending';
                            final venue = seating?.hallName ?? 'Assigned Hall';
                            final hallObj = seating != null ? hallMap[seating.hallId] : null;
                            final building = hallObj != null ? '${hallObj.building} (Floor ${hallObj.floor})' : 'Main Academic Complex';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: const Color(0xFF1E1B4B), borderRadius: BorderRadius.circular(4)),
                                        child: Text(reg.subjectCode, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(color: Colors.teal[50], borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.teal)),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.event_seat_rounded, size: 12, color: Colors.teal),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Seat: $seatNumber',
                                              style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'monospace'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(reg.subjectName, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.meeting_room_outlined, size: 14, color: Colors.black54),
                                      const SizedBox(width: 4),
                                      Text('$venue • $building', style: const TextStyle(color: Colors.black87, fontSize: 11)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.qr_code_rounded, size: 13, color: Colors.indigo),
                                      const SizedBox(width: 4),
                                      Text('Pass Reg ID: ${reg.registrationId}', style: const TextStyle(color: Colors.indigo, fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),

                  // 4. Examination Rules & Security Instructions
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline_rounded, color: Colors.amber[900], size: 16),
                            const SizedBox(width: 6),
                            Text('IMPORTANT INSTRUCTIONS TO CANDIDATES', style: TextStyle(color: Colors.amber[900], fontWeight: FontWeight.bold, fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          '1. Candidates must present this Admission Card along with official University Student ID at the hall entrance.\n'
                          '2. Occupy ONLY your allocated desk / seat number indicated above.\n'
                          '3. Mobile phones, programmable calculators, and unauthorized smart devices are strictly prohibited.\n'
                          '4. Candidates must arrive at the examination hall at least 15 minutes before the scheduled start time.',
                          style: TextStyle(color: Colors.black87, fontSize: 10, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Download / Screenshot Advice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.camera_alt_outlined, color: Colors.tealAccent, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tip: Take a screenshot or save this card on your phone to present offline on examination day.',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
