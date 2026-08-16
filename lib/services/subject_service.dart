import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/subject_model.dart';

class SubjectService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _subjectsRef =>
      _firestore.collection('subjects');

  // Live Stream of Subjects
  Stream<List<SubjectModel>> getSubjectsStream() {
    return _subjectsRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => SubjectModel.fromFirestore(doc)).toList();
    });
  }

  // Add new Subject to Firestore 'subjects' collection
  Future<void> addSubject(SubjectModel subject) async {
    try {
      final docRef = await _subjectsRef.add(subject.toMap());
      debugPrint('Subject added successfully with ID: ${docRef.id}');
    } catch (e) {
      debugPrint('Error adding subject: $e');
      throw Exception('Failed to add subject to database: $e');
    }
  }

  // Update existing Subject record
  Future<void> updateSubject(SubjectModel subject) async {
    if (subject.docId == null) return;
    try {
      await _subjectsRef.doc(subject.docId).update(subject.toMap());
      debugPrint('Subject updated successfully: ${subject.docId}');
    } catch (e) {
      debugPrint('Error updating subject: $e');
      throw Exception('Failed to update subject: $e');
    }
  }

  // Toggle Subject status (active <-> inactive) without deleting record
  Future<void> toggleSubjectStatus(String docId, String currentStatus) async {
    final newStatus = (currentStatus.toLowerCase() == 'active') ? 'inactive' : 'active';
    try {
      await _subjectsRef.doc(docId).update({'status': newStatus});
      debugPrint('Subject status updated to $newStatus for doc: $docId');
    } catch (e) {
      debugPrint('Error updating subject status: $e');
      throw Exception('Failed to change subject status: $e');
    }
  }
}
