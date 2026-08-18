import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/subject_model.dart';
import '../../models/timetable_model.dart';
import '../../models/attendance_session_model.dart';
import '../../models/attendance_model.dart';
import '../../services/attendance_service.dart';
import '../../widgets/dynamic_qr_view.dart';

class LecturerQrSessionScreen extends StatefulWidget {
  final SubjectModel subject;
  final String lecturerEmail;
  final String lecturerName;
  final String lecturerId;
  final TimetableModel? preselectedSession;

  const LecturerQrSessionScreen({
    super.key,
    required this.subject,
    required this.lecturerEmail,
    required this.lecturerName,
    required this.lecturerId,
    this.preselectedSession,
  });

  @override
  State<LecturerQrSessionScreen> createState() => _LecturerQrSessionScreenState();
}

class _LecturerQrSessionScreenState extends State<LecturerQrSessionScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AttendanceService _attendanceService = AttendanceService();

  late String _sessionId;
  late String _qrToken;
  late DateTime _expiryTime;
  late String _currentDate;
  late String _startTime;
  late String _endTime;
  late String _hallName;
  late String _batch;

  bool _isInitializing = true;
  bool _isSessionActive = true;
  Timer? _countdownTimer;
  Duration _remainingTime = const Duration(minutes: 15);
  int _totalEnrolled = 0;

  @override
  void initState() {
    super.initState();
    _setupSession();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  int _configuredValidityMinutes = 15;
  double _configuredRadiusMeters = 200.0;

  Future<void> _setupSession() async {
    final now = DateTime.now();
    _currentDate = _formatDate(now);

    try {
      // 0. Dynamically fetch Admin Attendance Configuration from Firestore
      final config = await _attendanceService.getAttendanceConfig();
      _configuredValidityMinutes = (config['qrValidityMinutes'] as num?)?.toInt() ?? 15;
      _configuredRadiusMeters = (config['allowedRadiusMeters'] as num?)?.toDouble() ?? 200.0;
    } catch (e) {
      debugPrint('Error loading attendance config for session: $e');
    }

    _expiryTime = now.add(Duration(minutes: _configuredValidityMinutes));
    _remainingTime = Duration(minutes: _configuredValidityMinutes);

    // Auto-resolve session time and hall from Timetable
    if (widget.preselectedSession != null) {
      _startTime = widget.preselectedSession!.startTime;
      _endTime = widget.preselectedSession!.endTime;
      _hallName = widget.preselectedSession!.hallName;
      _batch = widget.preselectedSession!.batch;
    } else {
      _startTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      _endTime = '${(now.hour + 2).toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      _hallName = 'Main Lecture Hall (LH-01)';
      _batch = '2026';
    }

    _sessionId = 'SESS-${widget.subject.subjectCode}-${now.millisecondsSinceEpoch.toString().substring(7)}';
    _qrToken = 'QR-$_sessionId-${now.millisecondsSinceEpoch}';

    try {
      // 1. Fetch total enrolled students for this subject
      final enrollSnap = await _firestore
          .collection('enrollments')
          .where('subjectCode', isEqualTo: widget.subject.subjectCode)
          .where('status', isEqualTo: 'active')
          .get();
      _totalEnrolled = enrollSnap.docs.length;

      // 2. Create the active attendance session document in Firestore
      final session = AttendanceSessionModel(
        sessionId: _sessionId,
        subjectCode: widget.subject.subjectCode,
        subjectName: widget.subject.subjectName,
        lecturerId: widget.lecturerId,
        lecturerName: widget.lecturerName,
        lecturerEmail: widget.lecturerEmail,
        hallName: _hallName,
        batch: _batch,
        date: _currentDate,
        startTime: _startTime,
        endTime: _endTime,
        qrToken: _qrToken,
        expiresAt: _expiryTime.toIso8601String(),
        status: 'active',
        enrolledCount: _totalEnrolled,
        presentCount: 0,
        allowedRadiusMeters: _configuredRadiusMeters,
      );

      await _attendanceService.createAttendanceSession(session);

      // 3. Start countdown timer
      _startTimer();
    } catch (e) {
      debugPrint('Error starting QR session: $e');
    } finally {
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      if (now.isAfter(_expiryTime)) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _remainingTime = Duration.zero;
            _isSessionActive = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _remainingTime = _expiryTime.difference(now);
          });
        }
      }
    });
  }

  Future<void> _refreshQrCode() async {
    final now = DateTime.now();
    setState(() {
      _expiryTime = now.add(Duration(minutes: _configuredValidityMinutes));
      _qrToken = 'QR-$_sessionId-${now.millisecondsSinceEpoch}';
      _isSessionActive = true;
    });

    await _firestore.collection('attendance_sessions').doc(_sessionId).update({
      'qrToken': _qrToken,
      'expiresAt': _expiryTime.toIso8601String(),
      'status': 'active',
    });

    _startTimer();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dynamic QR Code refreshed & session extended by $_configuredValidityMinutes minutes!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _endSession() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.stop_circle_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('End Attendance Session', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: const Text(
          'Are you sure you want to end this attendance session? Students will no longer be able to scan.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('End Session', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _countdownTimer?.cancel();
      await _attendanceService.endAttendanceSession(_sessionId);
      if (mounted) {
        setState(() => _isSessionActive = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance session ended successfully.'), backgroundColor: Colors.amber),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _remainingTime.inMinutes.toString().padLeft(2, '0');
    final seconds = (_remainingTime.inSeconds % 60).toString().padLeft(2, '0');

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
            const Text(
              'Dynamic QR Attendance',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${widget.subject.subjectCode} • ${widget.subject.subjectName}',
              style: const TextStyle(color: Colors.tealAccent, fontSize: 11),
            ),
          ],
        ),
        actions: [
          if (_isSessionActive)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.cyanAccent),
              tooltip: 'Refresh QR / Extend Time',
              onPressed: _refreshQrCode,
            ),
          IconButton(
            icon: const Icon(Icons.stop_circle_rounded, color: Colors.redAccent),
            tooltip: 'End Session',
            onPressed: _endSession,
          ),
        ],
      ),
      body: _isInitializing
          ? const Center(child: CircularProgressIndicator(color: Colors.tealAccent))
          : StreamBuilder<AttendanceSessionModel?>(
              // Live stream of the active session
              stream: _attendanceService.getLiveAttendanceSessionStream(_sessionId),
              builder: (context, sessionSnap) {
                final session = sessionSnap.data;
                final presentCount = session?.presentCount ?? 0;
                final enrolledCount = session?.enrolledCount ?? _totalEnrolled;
                final pendingCount = (enrolledCount - presentCount) > 0 ? (enrolledCount - presentCount) : 0;
                final double attendancePct = enrolledCount > 0 ? (presentCount / enrolledCount) * 100 : 0.0;

                return StreamBuilder<List<AttendanceModel>>(
                  // Live stream of students scanning in real time
                  stream: _attendanceService.getLiveSessionAttendeesStream(_sessionId),
                  builder: (context, attendeesSnap) {
                    final attendees = attendeesSnap.data ?? [];

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 1. Session Metadata Info Strip
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on_rounded, size: 14, color: Colors.tealAccent),
                                        const SizedBox(width: 4),
                                        Text(_hallName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text('$_currentDate • $_startTime - $_endTime • Batch $_batch', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _isSessionActive ? Colors.green.withAlpha(40) : Colors.red.withAlpha(40),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: _isSessionActive ? Colors.greenAccent : Colors.redAccent),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: _isSessionActive ? Colors.greenAccent : Colors.redAccent,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _isSessionActive ? 'LIVE ACTIVE' : 'CLOSED',
                                        style: TextStyle(
                                          color: _isSessionActive ? Colors.greenAccent : Colors.redAccent,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 2. Dynamic QR Code Display Box
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.tealAccent.withAlpha(80)),
                            ),
                            child: Column(
                              children: [
                                // Countdown Timer Pill
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _isSessionActive ? Colors.amber.withAlpha(30) : Colors.grey.withAlpha(30),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: _isSessionActive ? Colors.amberAccent : Colors.grey),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.timer_rounded, size: 16, color: _isSessionActive ? Colors.amberAccent : Colors.grey),
                                      const SizedBox(width: 6),
                                      Text(
                                        _isSessionActive ? 'QR Valid for: $minutes:$seconds' : 'QR Session Expired',
                                        style: TextStyle(
                                          color: _isSessionActive ? Colors.amberAccent : Colors.grey,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 18),

                                // Dynamic QR Code Canvas
                                DynamicQrView(
                                  data: _qrToken,
                                  size: 220,
                                  foregroundColor: const Color(0xFF0F172A),
                                  backgroundColor: Colors.white,
                                ),
                                const SizedBox(height: 14),

                                Text(
                                  'Ask students to open Student App → Attendance → Scan QR',
                                  style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(6)),
                                  child: SelectableText(
                                    'Code / Session: $_qrToken',
                                    style: const TextStyle(color: Colors.tealAccent, fontSize: 11, fontFamily: 'monospace'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // 3. Real-Time Live KPI Counters (3 Cards)
                          Row(
                            children: [
                              Expanded(
                                child: _buildKpiCard(
                                  'Enrolled',
                                  '$enrolledCount',
                                  'Total Students',
                                  Colors.indigoAccent,
                                  Icons.groups_rounded,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildKpiCard(
                                  'Present',
                                  '$presentCount',
                                  '${attendancePct.toStringAsFixed(0)}% Rate',
                                  Colors.greenAccent,
                                  Icons.check_circle_rounded,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildKpiCard(
                                  'Pending',
                                  '$pendingCount',
                                  'Awaiting Scan',
                                  pendingCount > 0 ? Colors.orangeAccent : Colors.grey,
                                  Icons.hourglass_top_rounded,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // 4. Real-Time Live Feed of Scanned Students
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.sensors_rounded, color: Colors.greenAccent, size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Live Scanned Attendance (${attendees.length})',
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.green.withAlpha(30), borderRadius: BorderRadius.circular(6)),
                                      child: const Text('AUTO-SYNC', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                if (attendees.isEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: 24),
                                    alignment: Alignment.center,
                                    child: const Column(
                                      children: [
                                        CircularProgressIndicator(strokeWidth: 2, color: Colors.tealAccent),
                                        SizedBox(height: 12),
                                        Text('Waiting for students to scan the QR code...', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                      ],
                                    ),
                                  )
                                else
                                  ...attendees.reversed.map((att) {
                                    final scanTimeStr = att.scanTime != null && att.scanTime!.length >= 19
                                        ? att.scanTime!.substring(11, 19)
                                        : 'Just now';

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0F172A),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.greenAccent.withAlpha(60)),
                                      ),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 16,
                                            backgroundColor: Colors.green.withAlpha(40),
                                            child: Text(
                                              att.studentName.isNotEmpty ? att.studentName[0].toUpperCase() : 'S',
                                              style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(att.studentName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                                Text(att.studentId, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(color: Colors.green.withAlpha(40), borderRadius: BorderRadius.circular(4)),
                                                child: const Text('PRESENT', style: TextStyle(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(scanTimeStr, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildKpiCard(String title, String mainValue, String subValue, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600)),
              Icon(icon, size: 14, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(mainValue, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(subValue, style: const TextStyle(color: Colors.white60, fontSize: 10)),
        ],
      ),
    );
  }
}
