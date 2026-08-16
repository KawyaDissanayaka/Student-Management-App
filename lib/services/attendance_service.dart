import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/attendance_model.dart';

class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _attendanceRef =>
      _firestore.collection('attendance');

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
      if (studentSnap.docs.isEmpty) return <AttendanceModel>[];
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
        'updatedAt': DateTime.now().toIso8601String(),
      });
      debugPrint('Attendance threshold updated to $threshold%');
    } catch (e) {
      debugPrint('Error updating threshold: $e');
      throw Exception('Failed to update threshold: $e');
    }
  }
}
