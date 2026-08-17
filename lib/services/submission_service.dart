import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/submission_model.dart';

class SubmissionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _submissionsRef =>
      _firestore.collection('submissions');

  /// Real-time stream of all submissions
  Stream<List<SubmissionModel>> getAllSubmissionsStream() {
    return _submissionsRef
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => SubmissionModel.fromFirestore(d)).toList());
  }

  /// Real-time stream of submissions for a specific assignment
  Stream<List<SubmissionModel>> getSubmissionsForAssignment(String assignmentId) {
    return _submissionsRef
        .where('assignmentId', isEqualTo: assignmentId)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((d) => SubmissionModel.fromFirestore(d)).toList();
          list.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
          return list;
        });
  }

  /// Real-time stream of submissions for a specific student
  Stream<List<SubmissionModel>> getStudentSubmissionsStream(String studentEmail) {
    final cleanEmail = studentEmail.trim().toLowerCase();
    return _submissionsRef
        .where('studentEmail', isEqualTo: cleanEmail)
        .snapshots()
        .map((snap) => snap.docs.map((d) => SubmissionModel.fromFirestore(d)).toList());
  }

  /// Submit assignment with duplicate submission prevention
  Future<void> submitAssignment(SubmissionModel submission) async {
    try {
      final cleanEmail = submission.studentEmail.trim().toLowerCase();
      // Check for duplicate submission
      final existing = await _submissionsRef
          .where('assignmentId', isEqualTo: submission.assignmentId)
          .where('studentEmail', isEqualTo: cleanEmail)
          .get();

      if (existing.docs.isNotEmpty) {
        throw Exception('You have already submitted this assignment.');
      }

      final docRef = await _submissionsRef.add(submission.toMap());
      debugPrint('Submission recorded with ID: ${docRef.id}');
    } catch (e) {
      debugPrint('Error submitting assignment: $e');
      rethrow;
    }
  }

  /// Grade a submission
  Future<void> gradeSubmission({
    required String submissionDocId,
    required double grade,
    required String feedback,
    required String gradedBy,
  }) async {
    try {
      await _submissionsRef.doc(submissionDocId).update({
        'grade': grade,
        'feedback': feedback,
        'gradedBy': gradedBy,
        'gradedAt': DateTime.now().toIso8601String(),
        'status': 'graded',
      });
      debugPrint('Submission $submissionDocId graded: $grade');
    } catch (e) {
      debugPrint('Error grading submission: $e');
      throw Exception('Failed to grade submission: $e');
    }
  }
}
