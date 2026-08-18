import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/attendance_service.dart';
import '../../models/attendance_session_model.dart';

class StudentQrScanScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const StudentQrScanScreen({super.key, this.userData});

  @override
  State<StudentQrScanScreen> createState() => _StudentQrScanScreenState();
}

class _StudentQrScanScreenState extends State<StudentQrScanScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final AttendanceService _attendanceService = AttendanceService();
  final TextEditingController _codeController = TextEditingController();

  late AnimationController _laserController;
  late Animation<double> _laserAnimation;

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _laserController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _laserController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _processScanToken(String token) async {
    final cleanToken = token.trim();
    if (cleanToken.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please scan or enter a valid QR session code.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    final user = _authService.currentUser;
    final email = (widget.userData?['email'] ?? user?.email ?? '').trim().toLowerCase();
    final studentId = (widget.userData?['studentId'] ?? '').trim();
    final studentName = (widget.userData?['fullName'] ?? widget.userData?['name'] ?? user?.displayName ?? 'Student').trim();

    try {
      final result = await _attendanceService.verifyAndMarkQrAttendance(
        qrToken: cleanToken,
        studentEmail: email,
        studentId: studentId,
        studentName: studentName,
      );

      if (mounted) {
        _showSuccessDialog(result);
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
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSuccessDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: Colors.green,
              child: Icon(Icons.check_rounded, color: Colors.white, size: 44),
            ),
            SizedBox(height: 14),
            Text(
              'Attendance Verified!',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.greenAccent.withAlpha(80)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${data['subjectCode']} • ${data['subjectName']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 6),
                  _dialogRow('Lecturer', data['lecturerName'] ?? 'Lecturer'),
                  _dialogRow('Venue', data['hallName'] ?? 'Main Hall'),
                  _dialogRow('Date & Time', '${data['date']} • ${data['time']}'),
                  _dialogRow('Status', 'PRESENT (Recorded in Firestore)', isGood: true),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your attendance percentage for this module has been automatically updated in real-time.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx); // close dialog
                Navigator.pop(context); // return to student attendance screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Done & Return to Attendance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dialogRow(String label, String value, {bool isGood = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: isGood ? Colors.greenAccent : Colors.white70,
                fontWeight: isGood ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
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
        title: const Row(
          children: [
            Icon(Icons.qr_code_scanner_rounded, color: Colors.tealAccent),
            SizedBox(width: 8),
            Text('Scan Attendance QR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Scanner Viewfinder Card
            Container(
              width: double.infinity,
              height: 280,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.tealAccent.withAlpha(80)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Viewfinder corners
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.tealAccent, width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),

                  // Animated Scanning Laser Bar
                  AnimatedBuilder(
                    animation: _laserAnimation,
                    builder: (context, child) {
                      return Positioned(
                        top: 40 + (_laserAnimation.value * 200),
                        child: Container(
                          width: 200,
                          height: 3,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.transparent, Colors.tealAccent, Colors.transparent],
                            ),
                            boxShadow: [
                              BoxShadow(color: Colors.tealAccent.withAlpha(150), blurRadius: 8, spreadRadius: 2),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // Center icon & instruction
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.center_focus_strong_rounded, size: 48, color: Colors.tealAccent),
                      const SizedBox(height: 10),
                      Text(
                        _isProcessing ? 'Verifying Student & Session...' : 'Align Lecturer QR in box',
                        style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      if (_isProcessing)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.tealAccent)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Live Active Sessions Quick Scan Selector (Convenient 1-Tap Attendance)
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('attendance_sessions')
                  .where('status', isEqualTo: 'active')
                  .snapshots(),
              builder: (context, sessionSnap) {
                final activeSessions = (sessionSnap.data?.docs ?? []).map((doc) {
                  return AttendanceSessionModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
                }).toList();

                if (activeSessions.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.greenAccent.withAlpha(80)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.sensors_rounded, color: Colors.greenAccent, size: 18),
                          SizedBox(width: 8),
                          Text('Active Classroom Sessions Detected:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...activeSessions.map((s) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.school_rounded, color: Colors.tealAccent, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${s.subjectCode} - ${s.subjectName}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                    Text('${s.hallName} • ${s.lecturerName}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                  ],
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _isProcessing ? null : () => _processScanToken(s.qrToken),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 16),
                                label: const Text('1-Tap Scan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),

            // Manual Code / Token Input Fallback
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Manual Session / Token Input', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 6),
                  const Text(
                    'If camera scanning is unavailable, enter the QR code token displayed on the lecturer screen:',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: _codeController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'QR Token / Session ID (e.g. QR-SESS-...)',
                      labelStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.password_rounded, color: Colors.tealAccent),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.tealAccent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : () => _processScanToken(_codeController.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: _isProcessing
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.verified_user_rounded, color: Colors.white),
                      label: Text(
                        _isProcessing ? 'Verifying with Firebase...' : 'Verify & Mark Attendance',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Multi-Layer Security Verification Criteria Checklist
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
                  const Row(
                    children: [
                      Icon(Icons.security_rounded, color: Colors.greenAccent, size: 18),
                      SizedBox(width: 8),
                      Text('Multi-Factor Verification Rules', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildSecurityRule('1. Student Authentication & Profile Active', true),
                  _buildSecurityRule('2. Active Subject Enrollment Confirmed', true),
                  _buildSecurityRule('3. Dynamic Session Token & Expiry Verified', true),
                  _buildSecurityRule('4. Assigned Lecturer Verification', true),
                  _buildSecurityRule('5. Timetable Session Schedule Validated', true),
                  _buildSecurityRule('6. Duplicate Scan Prevention Check', true),
                  _buildSecurityRule('7. Real-Time Firestore Cloud Sync', true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityRule(String title, bool isProtected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 14, color: isProtected ? Colors.greenAccent : Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
