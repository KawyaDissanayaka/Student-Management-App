import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/enrollment_model.dart';

class EnrollmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _enrollmentsRef =>
      _firestore.collection('enrollments');

  /// Live Stream of all Enrollments
  Stream<List<EnrollmentModel>> getEnrollmentsStream() {
    return _enrollmentsRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => EnrollmentModel.fromFirestore(doc)).toList();
    });
  }

  /// Stream of Active Enrollments for a specific Student
  Stream<List<EnrollmentModel>> getStudentActiveEnrollmentsStream(String email) {
    return _enrollmentsRef
        .where('studentEmail', isEqualTo: email.trim().toLowerCase())
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => EnrollmentModel.fromFirestore(doc)).toList();
    });
  }

  /// Enroll new Student to a Subject with duplicate check
  Future<void> enrollStudent(EnrollmentModel enrollment) async {
    try {
      // Check for duplicate enrollment (same student, subject, semester, academic year, and status is active)
      final duplicateQuery = await _enrollmentsRef
          .where('studentEmail', isEqualTo: enrollment.studentEmail.trim().toLowerCase())
          .where('subjectCode', isEqualTo: enrollment.subjectCode.trim().toUpperCase())
          .where('semester', isEqualTo: enrollment.semester)
          .where('academicYear', isEqualTo: enrollment.academicYear)
          .where('status', isEqualTo: 'active')
          .get();

      if (duplicateQuery.docs.isNotEmpty) {
        throw Exception(
            'Student is already actively enrolled in this subject for ${enrollment.semester} (${enrollment.academicYear}).');
      }

      final docRef = await _enrollmentsRef.add(enrollment.toMap());
      debugPrint('Student enrolled successfully with enrollment ID: ${docRef.id}');
    } catch (e) {
      debugPrint('Error enrolling student: $e');
      rethrow;
    }
  }

  /// Update enrollment status (remove/deactivate by setting status to inactive)
  Future<void> updateEnrollmentStatus(String docId, String status) async {
    try {
      await _enrollmentsRef.doc(docId).update({'status': status});
      debugPrint('Enrollment status updated to $status for doc: $docId');
    } catch (e) {
      debugPrint('Error updating enrollment status: $e');
      throw Exception('Failed to update enrollment status: $e');
    }
  }
}
