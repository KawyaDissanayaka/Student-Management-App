import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/subject_model.dart';

class SubjectService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _subjectsRef =>
      _firestore.collection('subjects');

  /// Live Stream of Subjects
  Stream<List<SubjectModel>> getSubjectsStream() {
    return _subjectsRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => SubjectModel.fromFirestore(doc)).toList();
    });
  }

  /// Check if Subject Code is unique
  Future<bool> isSubjectCodeUnique(String subjectCode, {String? excludeDocId}) async {
    final cleanCode = subjectCode.trim().toUpperCase();
    final query = await _subjectsRef.where('subjectCode', isEqualTo: cleanCode).get();
    for (var doc in query.docs) {
      if (excludeDocId == null || doc.id != excludeDocId) {
        return false;
      }
    }
    return true;
  }

  /// Add new Subject with duplicate Subject Code check
  Future<void> addSubject(SubjectModel subject) async {
    try {
      final isUnique = await isSubjectCodeUnique(subject.subjectCode);
      if (!isUnique) {
        throw Exception('A subject with Subject Code "${subject.subjectCode}" already exists.');
      }

      final docRef = await _subjectsRef.add(subject.toMap());
      debugPrint('Subject added successfully with ID: ${docRef.id}');
    } catch (e) {
      debugPrint('Error adding subject: $e');
      rethrow;
    }
  }

  /// Update existing Subject record
  Future<void> updateSubject(SubjectModel subject) async {
    if (subject.docId == null) return;
    try {
      final isUnique = await isSubjectCodeUnique(subject.subjectCode, excludeDocId: subject.docId);
      if (!isUnique) {
        throw Exception('A subject with Subject Code "${subject.subjectCode}" already exists.');
      }

      await _subjectsRef.doc(subject.docId).update(subject.toMap());
      debugPrint('Subject updated successfully: ${subject.docId}');
    } catch (e) {
      debugPrint('Error updating subject: $e');
      rethrow;
    }
  }

  /// Toggle Subject status (active <-> inactive) without deleting record
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
