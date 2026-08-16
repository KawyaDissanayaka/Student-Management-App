import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/lecturer_model.dart';

class LecturerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _lecturersRef =>
      _firestore.collection('lecturers');

  // Live Stream of Lecturers
  Stream<List<LecturerModel>> getLecturersStream() {
    return _lecturersRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => LecturerModel.fromFirestore(doc)).toList();
    });
  }

  // Add new Lecturer to Firestore 'lecturers' and 'users' collections
  Future<void> addLecturer(LecturerModel lecturer, String password) async {
    try {
      final docRef = await _lecturersRef.add(lecturer.toMap());

      await _firestore.collection('users').doc(docRef.id).set({
        'uid': docRef.id,
        'email': lecturer.email,
        'fullName': lecturer.name,
        'role': 'LECTURER',
        'lecturerId': lecturer.lecturerId,
        'department': lecturer.department,
        'status': lecturer.status,
        'createdAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      debugPrint('Lecturer added successfully with ID: ${docRef.id}');
    } catch (e) {
      debugPrint('Error adding lecturer: $e');
      throw Exception('Failed to add lecturer to database: $e');
    }
  }

  // Update existing Lecturer record
  Future<void> updateLecturer(LecturerModel lecturer) async {
    if (lecturer.docId == null) return;
    try {
      await _lecturersRef.doc(lecturer.docId).update(lecturer.toMap());

      await _firestore.collection('users').doc(lecturer.docId).set({
        'email': lecturer.email,
        'fullName': lecturer.name,
        'lecturerId': lecturer.lecturerId,
        'department': lecturer.department,
        'status': lecturer.status,
      }, SetOptions(merge: true));

      debugPrint('Lecturer updated successfully: ${lecturer.docId}');
    } catch (e) {
      debugPrint('Error updating lecturer: $e');
      throw Exception('Failed to update lecturer: $e');
    }
  }

  // Toggle Lecturer status (active <-> inactive) without deleting record
  Future<void> toggleLecturerStatus(String docId, String currentStatus) async {
    final newStatus = (currentStatus.toLowerCase() == 'active') ? 'inactive' : 'active';
    try {
      await _lecturersRef.doc(docId).update({'status': newStatus});
      await _firestore.collection('users').doc(docId).set({
        'status': newStatus,
      }, SetOptions(merge: true));

      debugPrint('Lecturer status updated to $newStatus for doc: $docId');
    } catch (e) {
      debugPrint('Error updating lecturer status: $e');
      throw Exception('Failed to change lecturer status: $e');
    }
  }
}
