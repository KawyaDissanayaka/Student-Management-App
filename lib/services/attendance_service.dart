import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/attendance_model.dart';
import '../models/attendance_session_model.dart';

class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _attendanceRef =>
      _firestore.collection('attendance');

  CollectionReference<Map<String, dynamic>> get _sessionsRef =>
      _firestore.collection('attendance_sessions');

  // Live Stream of all Attendance records
  Stream<List<AttendanceModel>> getAttendanceStream() {
    return _attendanceRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => AttendanceModel.fromFirestore(doc)).toList();
    });
  }

  // Stream of a specific Student's attendance
  Stream<List<AttendanceModel>> getStudentAttendanceStream(String email) {
    return _firestore
        .collection('students')
        .where('email', isEqualTo: email.trim().toLowerCase())
        .snapshots()
        .asyncMap((studentSnap) async {
      if (studentSnap.docs.isEmpty) {
        // Fallback: search by studentEmail directly in attendance
        final directSnap = await _attendanceRef
            .where('studentDocId', isEqualTo: email.trim().toLowerCase())
            .get();
        return directSnap.docs.map((doc) => AttendanceModel.fromFirestore(doc)).toList();
      }
      final studentDocId = studentSnap.docs.first.id;

      final attendanceSnap = await _attendanceRef
          .where('studentDocId', isEqualTo: studentDocId)
          .get();

      return attendanceSnap.docs
          .map((doc) => AttendanceModel.fromFirestore(doc))
          .toList();
    });
  }

  // Save/Update list of attendance records
  Future<void> saveAttendance(List<AttendanceModel> records) async {
    final batch = _firestore.batch();

    try {
      for (var record in records) {
        // Query to check if attendance is already marked for this Student, Subject and Date
        final query = await _attendanceRef
            .where('studentDocId', isEqualTo: record.studentDocId)
            .where('subjectCode', isEqualTo: record.subjectCode)
            .where('date', isEqualTo: record.date)
            .get();

        if (query.docs.isNotEmpty) {
          // If already exists, update/edit it
          final existingDocId = query.docs.first.id;
          batch.update(_attendanceRef.doc(existingDocId), record.toMap());
        } else {
          // If doesn't exist, create a new record
          final newDocRef = _attendanceRef.doc();
          batch.set(newDocRef, record.toMap());
        }
      }

      await batch.commit();
      debugPrint('Attendance batch saved/updated successfully.');
    } catch (e) {
      debugPrint('Error saving attendance batch: $e');
      throw Exception('Failed to save attendance: $e');
    }
  }

  // ─── DYNAMIC QR ATTENDANCE SESSIONS ─────────────────────────────────────────

  /// Create or activate a dynamic QR attendance session
  Future<AttendanceSessionModel> createAttendanceSession(AttendanceSessionModel session) async {
    try {
      final docRef = _sessionsRef.doc(session.sessionId);
      await docRef.set(session.toMap(), SetOptions(merge: true));
      debugPrint('Dynamic QR Attendance session created: ${session.sessionId}');
      return session;
    } catch (e) {
      debugPrint('Error creating attendance session: $e');
      throw Exception('Failed to create attendance session: $e');
    }
  }

  /// End an active attendance session
  Future<void> endAttendanceSession(String sessionId) async {
    try {
      await _sessionsRef.doc(sessionId).update({
        'status': 'ended',
        'endedAt': DateTime.now().toIso8601String(),
      });
      debugPrint('Attendance session ended: $sessionId');
    } catch (e) {
      debugPrint('Error ending attendance session: $e');
      throw Exception('Failed to end session: $e');
    }
  }

  /// Live stream of a specific attendance session for real-time live counters
  Stream<AttendanceSessionModel?> getLiveAttendanceSessionStream(String sessionId) {
    return _sessionsRef.doc(sessionId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return AttendanceSessionModel.fromFirestore(doc);
      }
      return null;
    });
  }

  /// Live stream of attendees who scanned for this session
  Stream<List<AttendanceModel>> getLiveSessionAttendeesStream(String sessionId) {
    return _attendanceRef
        .where('sessionId', isEqualTo: sessionId)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => AttendanceModel.fromFirestore(doc)).toList());
  }

  /// Multi-Factor Security Verification & Real-Time QR Attendance Marking
  Future<Map<String, dynamic>> verifyAndMarkQrAttendance({
    required String qrToken,
    required String studentEmail,
    required String studentId,
    required String studentName,
    double? studentLat,
    double? studentLng,
  }) async {
    final cleanEmail = studentEmail.trim().toLowerCase();

    // 1. Locate session by qrToken or sessionId
    final sessionQuery = await _sessionsRef
        .where('qrToken', isEqualTo: qrToken.trim())
        .limit(1)
        .get();

    if (sessionQuery.docs.isEmpty) {
      // Fallback: check if qrToken matches sessionId directly
      final directDoc = await _sessionsRef.doc(qrToken.trim()).get();
      if (!directDoc.exists) {
        throw Exception('Invalid or unrecognized QR Code. Please scan the current lecture screen.');
      }
    }

    final DocumentSnapshot<Map<String, dynamic>> sessionDoc = sessionQuery.docs.isNotEmpty
        ? sessionQuery.docs.first
        : (await _sessionsRef.doc(qrToken.trim()).get());
    final session = AttendanceSessionModel.fromFirestore(sessionDoc);

    // 2. Validate Session Status & Expiry
    if (session.status.toLowerCase() != 'active') {
      throw Exception('This attendance session has already ended or closed.');
    }

    final expiryTime = DateTime.tryParse(session.expiresAt);
    if (expiryTime != null && DateTime.now().isAfter(expiryTime)) {
      await _sessionsRef.doc(session.sessionId).update({'status': 'expired'});
      throw Exception('This QR Code session has expired. Please ask the lecturer to refresh the session.');
    }

    // 3. Verify Student Enrollment in this Subject
    final enrollQuery = await _firestore
        .collection('enrollments')
        .where('subjectCode', isEqualTo: session.subjectCode)
        .where('status', isEqualTo: 'active')
        .get();

    final isEnrolled = enrollQuery.docs.any((doc) {
      final data = doc.data();
      final eEmail = (data['studentEmail'] ?? '').toString().toLowerCase();
      final eId = (data['studentId'] ?? '').toString().toUpperCase();
      return eEmail == cleanEmail || (studentId.isNotEmpty && eId == studentId.toUpperCase());
    });

    if (!isEnrolled) {
      throw Exception('Access Denied: You are not actively enrolled in subject "${session.subjectCode} - ${session.subjectName}".');
    }

    // 4. Verify Class is not Cancelled
    final timetableQuery = await _firestore
        .collection('timetable')
        .where('subjectCode', isEqualTo: session.subjectCode)
        .get();

    final isCancelled = timetableQuery.docs.any((d) => (d.data()['status'] ?? '').toString().toLowerCase() == 'cancelled');
    if (isCancelled) {
      throw Exception('This class session is marked as CANCELLED by the administration.');
    }

    // 5. Check if Attendance already marked for this session / date
    final existingAttendQuery = await _attendanceRef
        .where('sessionId', isEqualTo: session.sessionId)
        .where('studentId', isEqualTo: studentId)
        .get();

    if (existingAttendQuery.docs.isNotEmpty) {
      throw Exception('Attendance already marked! You have already registered your presence for this session.');
    }

    // Secondary check: by studentDocId and date/subject
    final studentQuery = await _firestore
        .collection('students')
        .where('email', isEqualTo: cleanEmail)
        .limit(1)
        .get();

    final studentDocId = studentQuery.docs.isNotEmpty ? studentQuery.docs.first.id : cleanEmail;
    final resolvedStudentName = studentQuery.docs.isNotEmpty ? (studentQuery.docs.first.data()['name'] ?? studentName) : studentName;
    final resolvedStudentId = studentQuery.docs.isNotEmpty ? (studentQuery.docs.first.data()['studentId'] ?? studentId) : studentId;

    final dateDuplicateCheck = await _attendanceRef
        .where('studentDocId', isEqualTo: studentDocId)
        .where('subjectCode', isEqualTo: session.subjectCode)
        .where('date', isEqualTo: session.date)
        .where('sessionId', isEqualTo: session.sessionId)
        .get();

    if (dateDuplicateCheck.docs.isNotEmpty) {
      throw Exception('Attendance already recorded for this session today.');
    }

    // 6. Check Admin Dynamic Attendance Configuration for Late Status and Location
    final configDoc = await _firestore.collection('settings').doc('attendance_config').get();
    final config = configDoc.exists && configDoc.data() != null ? configDoc.data()! : <String, dynamic>{};

    final bool enableLate = config['enableLateAttendance'] as bool? ?? true;
    final int lateThresholdMinutes = (config['lateThresholdMinutes'] as num?)?.toInt() ?? 10;

    String attendanceStatus = 'Present';

    if (enableLate) {
      try {
        final now = DateTime.now();
        final timeParts = session.startTime.split(':');
        if (timeParts.length >= 2) {
          final startHour = int.tryParse(timeParts[0]) ?? 0;
          final startMinute = int.tryParse(timeParts[1]) ?? 0;
          final sessionStartDateTime = DateTime(now.year, now.month, now.day, startHour, startMinute);
          final minutesLate = now.difference(sessionStartDateTime).inMinutes;

          if (minutesLate > lateThresholdMinutes) {
            attendanceStatus = 'Late';
          }
        }
      } catch (e) {
        debugPrint('Error calculating late status: $e');
      }
    }

    // 7. Record Attendance
    final scanTimestamp = DateTime.now().toIso8601String();
    final newAttendanceDoc = _attendanceRef.doc();

    final attendanceRecord = AttendanceModel(
      docId: newAttendanceDoc.id,
      studentDocId: studentDocId,
      studentId: resolvedStudentId,
      studentName: resolvedStudentName,
      subjectCode: session.subjectCode,
      subjectName: session.subjectName,
      date: session.date,
      status: attendanceStatus,
      markedBy: 'QR Scan Verified (${session.lecturerName})',
      batch: session.batch,
      semester: 'Current',
      sessionTime: '${session.startTime} - ${session.endTime}',
      hallName: session.hallName,
      sessionId: session.sessionId,
      scanTime: scanTimestamp,
      createdBy: cleanEmail,
      updatedBy: session.lecturerEmail,
    );

    await newAttendanceDoc.set(attendanceRecord.toMap());

    // 8. Increment presentCount in attendance_sessions in Firestore
    await _sessionsRef.doc(session.sessionId).update({
      'presentCount': FieldValue.increment(1),
      'lastScannedStudent': resolvedStudentName,
      'lastScannedAt': scanTimestamp,
    });

    debugPrint('Attendance successfully verified ($attendanceStatus) for $resolvedStudentName in ${session.subjectCode}');

    return {
      'subjectCode': session.subjectCode,
      'subjectName': session.subjectName,
      'lecturerName': session.lecturerName,
      'hallName': session.hallName,
      'date': session.date,
      'time': session.startTime,
      'studentName': resolvedStudentName,
      'sessionId': session.sessionId,
      'scanTime': scanTimestamp,
      'status': attendanceStatus,
    };
  }

  /// Get complete Attendance Configuration
  Future<Map<String, dynamic>> getAttendanceConfig() async {
    try {
      final doc = await _firestore.collection('settings').doc('attendance_config').get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!;
      }
    } catch (e) {
      debugPrint('Error loading attendance config: $e');
    }
    return {
      'threshold': 80.0,
      'requiredPercentage': 80.0,
      'qrValidityMinutes': 15,
      'enableLateAttendance': true,
      'lateThresholdMinutes': 10,
      'enableLocationVerification': false,
      'allowedRadiusMeters': 200.0,
      'enableManualAttendance': true,
    };
  }

  // Get low attendance threshold
  Future<double> getAttendanceThreshold() async {
    try {
      final doc = await _firestore.collection('settings').doc('attendance_config').get();
      if (doc.exists && doc.data() != null) {
        return (doc.data()!['threshold'] as num).toDouble();
      }
    } catch (e) {
      debugPrint('Error loading threshold setting: $e');
    }
    return 80.0; // Default threshold
  }

  // Update threshold setting
  Future<void> updateAttendanceThreshold(double threshold) async {
    try {
      await _firestore.collection('settings').doc('attendance_config').set({
        'threshold': threshold,
        'requiredPercentage': threshold,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
      debugPrint('Attendance threshold updated to $threshold%');
    } catch (e) {
      debugPrint('Error updating threshold: $e');
      throw Exception('Failed to update threshold: $e');
    }
  }
}

