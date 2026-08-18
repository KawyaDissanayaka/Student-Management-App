import 'package:flutter/material.dart';
import '../../models/exam_model.dart';
import '../../models/exam_registration_model.dart';
import '../../models/exam_seating_model.dart';
import '../../models/exam_attendance_record_model.dart';
import '../../services/exam_attendance_service.dart';
import '../../services/exam_registration_service.dart';
import '../../services/exam_seating_service.dart';

class AdminExamAttendanceScreen extends StatefulWidget {
  final ExamModel exam;

  const AdminExamAttendanceScreen({super.key, required this.exam});

  @override
  State<AdminExamAttendanceScreen> createState() => _AdminExamAttendanceScreenState();
}

class _AdminExamAttendanceScreenState extends State<AdminExamAttendanceScreen> {
  final ExamAttendanceService _attendanceService = ExamAttendanceService();
  final ExamRegistrationService _regService = ExamRegistrationService();
  final ExamSeatingService _seatingService = ExamSeatingService();
  final TextEditingController _searchController = TextEditingController();

  String _statusFilter = 'All'; // 'All', 'Present', 'Absent', 'Pending'
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─── VERIFICATION RESULT DIALOG (QR or Manual) ──────────────────────────────
  void _showVerificationResultModal(ExamVerificationResult result) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: result.isSeatMatched ? Colors.green : Colors.amber[700],
              child: Icon(
                result.isSeatMatched ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              result.isSeatMatched ? 'Verified & Present' : 'Verified with Seat Warning',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
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
                border: Border.all(color: result.isSeatMatched ? Colors.greenAccent.withAlpha(80) : Colors.amberAccent.withAlpha(80)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(result.studentName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('Student ID: ${result.studentId}', style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontFamily: 'monospace')),
                  const SizedBox(height: 8),
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Allocated Seat:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(result.allocatedSeatNumber, style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'monospace')),
                    ],
                  ),
                  if (result.claimedSeatNumber != null && !result.isSeatMatched) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Claimed / Scanned Seat:', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                        Text(result.claimedSeatNumber!, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'monospace')),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Assigned Venue:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(result.hallName, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              result.message,
              style: TextStyle(color: result.isSeatMatched ? Colors.white70 : Colors.amberAccent, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: const Text('Confirm & Next Student', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── QR CODE VERIFICATION MODAL ─────────────────────────────────────────────
  void _showQrScannerModal() {
    final qrInputController = TextEditingController();

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
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
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
                      Icon(Icons.qr_code_scanner_rounded, color: Colors.tealAccent, size: 24),
                      SizedBox(width: 8),
                      Text('QR Hall Pass Scanner', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Visual Scanner Frame
              Center(
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.tealAccent, width: 2),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(Icons.qr_code_2_rounded, size: 100, color: Colors.white24),
                      Container(
                        height: 2,
                        width: 150,
                        color: Colors.tealAccent.withAlpha(180),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Text('Scan Student QR or Enter Pass ID / Student ID:', style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 8),

              TextField(
                controller: qrInputController,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  hintText: 'e.g. EXREG-0001 or STU-1001',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                  prefixIcon: const Icon(Icons.qr_code_rounded, color: Colors.tealAccent, size: 18),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final query = qrInputController.text.trim();
                    if (query.isEmpty) return;

                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(ctx);

                    try {
                      final result = await _attendanceService.verifyAndMarkAttendance(
                        examId: widget.exam.examId,
                        examDocId: widget.exam.docId ?? widget.exam.examId,
                        studentQuery: query,
                        verificationMethod: 'QR',
                        currentHallId: widget.exam.hallId,
                        currentHallName: widget.exam.examHall,
                        markedBy: 'Exam Invigilator',
                      );

                      if (mounted) {
                        _showVerificationResultModal(result);
                      }
                    } catch (e) {
                      final msg = e.toString().replaceAll('Exception: ', '');
                      messenger.showSnackBar(
                        SnackBar(content: Text(msg), backgroundColor: Colors.redAccent, duration: const Duration(seconds: 4)),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 18),
                  label: const Text('Verify & Mark Present', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── MANUAL VERIFICATION MODAL ──────────────────────────────────────────────
  void _showManualVerifyModal({String? prefillStudentId, String? prefillSeat}) {
    final idController = TextEditingController(text: prefillStudentId ?? '');
    final seatController = TextEditingController(text: prefillSeat ?? '');
    final reasonController = TextEditingController(text: 'Physical Student ID & Hall Pass verified by Invigilator');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
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
                    Icon(Icons.how_to_reg_rounded, color: Colors.amberAccent, size: 24),
                    SizedBox(width: 8),
                    Text('Manual Exam Verification', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 14),

            TextField(
              controller: idController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: _inputDecoration('Student ID or Registration Code (e.g. STU-1001)', Icons.person_rounded),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: seatController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: _inputDecoration('Claimed / Occupied Seat Number (e.g. SEAT-004)', Icons.event_seat_rounded),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: reasonController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: _inputDecoration('Verification Reason / Note', Icons.notes_rounded),
            ),
            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final query = idController.text.trim();
                  if (query.isEmpty) return;

                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(ctx);

                  try {
                    final result = await _attendanceService.verifyAndMarkAttendance(
                      examId: widget.exam.examId,
                      examDocId: widget.exam.docId ?? widget.exam.examId,
                      studentQuery: query,
                      verificationMethod: 'Manual',
                      claimedSeatNumber: seatController.text.trim().isNotEmpty ? seatController.text.trim() : null,
                      manualReason: reasonController.text.trim(),
                      currentHallId: widget.exam.hallId,
                      currentHallName: widget.exam.examHall,
                      markedBy: 'Admin / Invigilator',
                    );

                    if (mounted) {
                      _showVerificationResultModal(result);
                    }
                  } catch (e) {
                    final msg = e.toString().replaceAll('Exception: ', '');
                    messenger.showSnackBar(
                      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent, duration: const Duration(seconds: 4)),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[700],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                label: const Text('Mark Present Manually', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
        ),
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
            const Text('Exam Day Attendance & Verification', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            Text('${widget.exam.subjectCode} • ${widget.exam.examType} (${widget.exam.date})', style: const TextStyle(color: Colors.tealAccent, fontSize: 11)),
          ],
        ),
      ),
      body: StreamBuilder<List<ExamRegistrationModel>>(
        stream: _regService.getRegistrationsForExamStream(widget.exam.examId, examDocId: widget.exam.docId),
        builder: (context, regSnapshot) {
          final registrations = regSnapshot.data ?? [];
          final confirmedRegistrations = registrations.where((r) => r.isApprovedOrRegistered).toList();

          return StreamBuilder<List<ExamSeatingModel>>(
            stream: _seatingService.getSeatingForExamStream(widget.exam.examId, examDocId: widget.exam.docId),
            builder: (context, seatSnapshot) {
              final seatings = seatSnapshot.data ?? [];
              final seatMap = {for (var s in seatings) s.studentId.toUpperCase(): s.seatNumber};

              return StreamBuilder<List<ExamAttendanceRecordModel>>(
                stream: _attendanceService.getAttendanceForExamStream(widget.exam.examId, examDocId: widget.exam.docId),
                builder: (context, attSnapshot) {
                  if (attSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
                  }

                  final attendanceRecords = attSnapshot.data ?? [];
                  final attendanceMap = {for (var a in attendanceRecords) a.studentId.toUpperCase(): a};

                  final totalRegistered = confirmedRegistrations.isNotEmpty ? confirmedRegistrations.length : widget.exam.registeredStudentCount;
                  final presentCount = attendanceRecords.where((a) => a.isPresent).length;
                  final absentCount = attendanceRecords.where((a) => a.isAbsent).length;
                  final pendingCount = totalRegistered > (presentCount + absentCount) ? (totalRegistered - presentCount - absentCount) : 0;
                  final attendancePct = totalRegistered > 0 ? ((presentCount / totalRegistered) * 100).toStringAsFixed(1) : '0.0';

                  // Build Roster Item List
                  final List<Map<String, dynamic>> roster = confirmedRegistrations.map((reg) {
                    final cleanId = reg.studentId.toUpperCase();
                    final attRecord = attendanceMap[cleanId];
                    final assignedSeat = seatMap[cleanId] ?? 'Not Assigned';
                    final status = attRecord != null ? attRecord.status : 'Pending';

                    return {
                      'registration': reg,
                      'attendance': attRecord,
                      'seatNumber': assignedSeat,
                      'status': status,
                    };
                  }).toList();

                  // Filter roster by status & search
                  final filteredRoster = roster.where((item) {
                    final reg = item['registration'] as ExamRegistrationModel;
                    final status = item['status'] as String;
                    final seat = item['seatNumber'] as String;

                    final matchesStatus = _statusFilter == 'All' || status.toLowerCase() == _statusFilter.toLowerCase();
                    final matchesSearch = _searchQuery.isEmpty ||
                        reg.studentName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        reg.studentId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        reg.registrationId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        seat.toLowerCase().contains(_searchQuery.toLowerCase());

                    return matchesStatus && matchesSearch;
                  }).toList();

                  return Column(
                    children: [
                      // 1. Exam & Venue Details Bar
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: const Color(0xFF1E293B),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(widget.exam.subjectName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text('Venue: ${widget.exam.examHall} • ${widget.exam.startTime} - ${widget.exam.endTime}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.teal.withAlpha(30), borderRadius: BorderRadius.circular(6)),
                              child: Text('Rate: $attendancePct%', style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ],
                        ),
                      ),

                      // 2. KPI Summary Strip (Registered, Present, Absent, Pending)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        color: const Color(0xFF0F172A),
                        child: Row(
                          children: [
                            Expanded(child: _buildMetricCard('Registered', '$totalRegistered', Colors.indigoAccent, Icons.groups_rounded)),
                            const SizedBox(width: 6),
                            Expanded(child: _buildMetricCard('Present', '$presentCount', Colors.greenAccent, Icons.check_circle_rounded)),
                            const SizedBox(width: 6),
                            Expanded(child: _buildMetricCard('Absent', '$absentCount', absentCount > 0 ? Colors.redAccent : Colors.grey, Icons.cancel_rounded)),
                            const SizedBox(width: 6),
                            Expanded(child: _buildMetricCard('Pending', '$pendingCount', pendingCount > 0 ? Colors.amberAccent : Colors.grey, Icons.hourglass_top_rounded)),
                          ],
                        ),
                      ),

                      // 3. Quick Action Buttons (QR Scanner + Manual Verify)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _showQrScannerModal(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 16),
                                label: const Text('QR Hall Pass Scanner', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _showManualVerifyModal(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber[700],
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.how_to_reg_rounded, color: Colors.white, size: 16),
                                label: const Text('Manual Verify ID', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 4. Search & Filter
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        child: Column(
                          children: [
                            TextField(
                              controller: _searchController,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              decoration: InputDecoration(
                                hintText: 'Search by Student Name, ID, or Seat...',
                                hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                                prefixIcon: const Icon(Icons.search_rounded, color: Colors.tealAccent, size: 18),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear_rounded, color: Colors.grey, size: 16),
                                        onPressed: () => setState(() {
                                          _searchController.clear();
                                          _searchQuery = '';
                                        }),
                                      )
                                    : null,
                                filled: true,
                                fillColor: const Color(0xFF1E293B),
                                contentPadding: const EdgeInsets.symmetric(vertical: 6),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                              ),
                              onChanged: (val) => setState(() => _searchQuery = val.trim()),
                            ),
                            const SizedBox(height: 6),

                            // Filter chips
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: ['All', 'Present', 'Absent', 'Pending'].map((status) {
                                  final isSelected = _statusFilter == status;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: ChoiceChip(
                                      label: Text(status, style: TextStyle(color: isSelected ? Colors.black : Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                                      selected: isSelected,
                                      selectedColor: Colors.tealAccent,
                                      backgroundColor: const Color(0xFF1E293B),
                                      onSelected: (selected) {
                                        if (selected) setState(() => _statusFilter = status);
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 5. Exam Day Attendance Roster List
                      Expanded(
                        child: filteredRoster.isEmpty
                            ? Center(
                                child: Text(
                                  confirmedRegistrations.isEmpty
                                      ? 'No students registered for this examination.'
                                      : 'No attendance records match filter criteria.',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.only(left: 14, right: 14, bottom: 20),
                                itemCount: filteredRoster.length,
                                itemBuilder: (context, index) {
                                  final item = filteredRoster[index];
                                  final reg = item['registration'] as ExamRegistrationModel;
                                  final attRecord = item['attendance'] as ExamAttendanceRecordModel?;
                                  final seatNumber = item['seatNumber'] as String;
                                  final status = item['status'] as String;

                                  final isPresent = status.toLowerCase() == 'present';
                                  final isAbsent = status.toLowerCase() == 'absent';
                                  final isPending = status.toLowerCase() == 'pending';

                                  Color statusColor = isPresent ? Colors.greenAccent : (isAbsent ? Colors.redAccent : Colors.amberAccent);

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isPresent ? const Color(0xFF064E3B).withAlpha(30) : const Color(0xFF1E293B),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: isPresent ? Colors.greenAccent.withAlpha(60) : Colors.white10),
                                    ),
                                    child: Row(
                                      children: [
                                        // Desk Seat Tag
                                        Container(
                                          width: 72,
                                          padding: const EdgeInsets.symmetric(vertical: 6),
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0F172A),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: Colors.tealAccent.withAlpha(60)),
                                          ),
                                          child: Text(
                                            seatNumber,
                                            style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'monospace'),
                                          ),
                                        ),
                                        const SizedBox(width: 10),

                                        // Student Info
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(reg.studentName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                              Text('${reg.studentId} • ${reg.registrationId}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                              if (attRecord != null && attRecord.isPresent)
                                                Text(
                                                  'Verified via ${attRecord.verificationMethod} at ${attRecord.markedAt.length >= 16 ? attRecord.markedAt.substring(11, 16) : attRecord.markedAt}',
                                                  style: const TextStyle(color: Colors.greenAccent, fontSize: 10),
                                                ),
                                            ],
                                          ),
                                        ),

                                        // Status & Quick Action
                                        if (isPending) ...[
                                          IconButton(
                                            icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.greenAccent, size: 22),
                                            tooltip: 'Verify Present',
                                            onPressed: () => _showManualVerifyModal(prefillStudentId: reg.studentId, prefillSeat: seatNumber),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 22),
                                            tooltip: 'Mark Absent',
                                            onPressed: () async {
                                              await _attendanceService.markAbsent(
                                                examId: widget.exam.examId,
                                                examDocId: widget.exam.docId ?? widget.exam.examId,
                                                studentId: reg.studentId,
                                                studentName: reg.studentName,
                                                studentEmail: reg.studentEmail,
                                                hallId: widget.exam.hallId ?? '',
                                                hallName: widget.exam.examHall,
                                                seatNumber: seatNumber,
                                                markedBy: 'Admin / Invigilator',
                                              );
                                            },
                                          ),
                                        ] else ...[
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(color: statusColor.withAlpha(30), borderRadius: BorderRadius.circular(6)),
                                            child: Text(
                                              status.toUpperCase(),
                                              style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.refresh_rounded, color: Colors.grey, size: 16),
                                            tooltip: 'Reset Attendance',
                                            onPressed: () async {
                                              if (attRecord?.docId != null) {
                                                await _attendanceService.resetAttendanceRecord(attRecord!.docId!);
                                              }
                                            },
                                          ),
                                        ],
                                      ],
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

  Widget _buildMetricCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(40)),
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
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
      prefixIcon: Icon(icon, color: Colors.tealAccent, size: 18),
      filled: true,
      fillColor: const Color(0xFF0F172A),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.tealAccent)),
    );
  }
}
