import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/assignment_model.dart';
import '../models/submission_model.dart';

class AssignmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _assignmentsRef =>
      _firestore.collection('assignments');

  CollectionReference<Map<String, dynamic>> get _submissionsRef =>
      _firestore.collection('submissions');

  // ─── ASSIGNMENT CRUD ───────────────────────────────────────────────────────

  /// Live stream of all assignments ordered by createdDate desc
  Stream<List<AssignmentModel>> getAssignmentsStream() {
    return _assignmentsRef
        .orderBy('createdDate', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => AssignmentModel.fromFirestore(d)).toList());
  }

  /// Live stream of published assignments for a given list of subject codes (student portal)
  Stream<List<AssignmentModel>> getPublishedAssignmentsForSubjects(List<String> subjectCodes) {
    if (subjectCodes.isEmpty) {
      return const Stream.empty();
    }
    return _assignmentsRef
        .where('status', isEqualTo: 'published')
        .where('subjectCode', whereIn: subjectCodes)
        .snapshots()
        .map((snap) => snap.docs.map((d) => AssignmentModel.fromFirestore(d)).toList());
  }

  /// Add new assignment to Firestore
  Future<void> addAssignment(AssignmentModel assignment) async {
    try {
      final docRef = await _assignmentsRef.add(assignment.toMap());
      debugPrint('Assignment added: ${docRef.id}');
    } catch (e) {
      debugPrint('Error adding assignment: $e');
      throw Exception('Failed to create assignment: $e');
    }
  }

  /// Update existing assignment
  Future<void> updateAssignment(AssignmentModel assignment) async {
    if (assignment.docId == null) return;
    try {
      await _assignmentsRef.doc(assignment.docId).update(assignment.toMap());
      debugPrint('Assignment updated: ${assignment.docId}');
    } catch (e) {
      debugPrint('Error updating assignment: $e');
      throw Exception('Failed to update assignment: $e');
    }
  }

  /// Update only the status field (Draft → Published → Closed → Deactivated)
  Future<void> updateAssignmentStatus(String docId, String newStatus) async {
    try {
      await _assignmentsRef.doc(docId).update({'status': newStatus});
      debugPrint('Assignment $docId status → $newStatus');
    } catch (e) {
      debugPrint('Error updating assignment status: $e');
      throw Exception('Failed to update assignment status: $e');
    }
  }

  // ─── SUBMISSIONS ──────────────────────────────────────────────────────────

  /// Live stream of submissions for a specific assignment
  Stream<List<SubmissionModel>> getSubmissionsForAssignment(String assignmentId) {
    return _submissionsRef
        .where('assignmentId', isEqualTo: assignmentId)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => SubmissionModel.fromFirestore(d)).toList());
  }

  /// Live stream of all submissions for a specific student (by email)
  Stream<List<SubmissionModel>> getStudentSubmissionsStream(String studentEmail) {
    return _submissionsRef
        .where('studentEmail', isEqualTo: studentEmail.trim().toLowerCase())
        .snapshots()
        .map((snap) => snap.docs.map((d) => SubmissionModel.fromFirestore(d)).toList());
  }

  /// Submit an assignment (prevents duplicates)
  Future<void> submitAssignment(SubmissionModel submission) async {
    try {
      // Duplicate check: same student + same assignment
      final existing = await _submissionsRef
          .where('assignmentId', isEqualTo: submission.assignmentId)
          .where('studentEmail', isEqualTo: submission.studentEmail)
          .get();

      if (existing.docs.isNotEmpty) {
        throw Exception('You have already submitted this assignment.');
      }

      await _submissionsRef.add(submission.toMap());
      debugPrint('Submission saved for ${submission.studentEmail} on ${submission.assignmentId}');
    } catch (e) {
      debugPrint('Error submitting assignment: $e');
      rethrow;
    }
  }

  /// Get count of active enrollments for a subject (for statistics)
  Future<int> getEnrolledCount(String subjectCode) async {
    try {
      final snap = await _firestore
          .collection('enrollments')
          .where('subjectCode', isEqualTo: subjectCode)
          .where('status', isEqualTo: 'active')
          .get();
      return snap.docs.length;
    } catch (e) {
      debugPrint('Error counting enrollments: $e');
      return 0;
    }
  }

  /// Check if a student already submitted a specific assignment
  Future<SubmissionModel?> getStudentSubmission(String assignmentId, String studentEmail) async {
    try {
      final snap = await _submissionsRef
          .where('assignmentId', isEqualTo: assignmentId)
          .where('studentEmail', isEqualTo: studentEmail.trim().toLowerCase())
          .get();
      if (snap.docs.isEmpty) return null;
      return SubmissionModel.fromFirestore(snap.docs.first);
    } catch (e) {
      debugPrint('Error checking submission: $e');
      return null;
    }
  }
}
