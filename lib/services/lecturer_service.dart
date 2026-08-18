import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/lecturer_model.dart';

class LecturerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _lecturersRef =>
      _firestore.collection('lecturers');

  /// Live Stream of all Lecturers
  Stream<List<LecturerModel>> getLecturersStream() {
    return _lecturersRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => LecturerModel.fromFirestore(doc)).toList();
    });
  }

  /// Check if Lecturer ID is unique
  Future<bool> isLecturerIdUnique(String lecturerId, {String? excludeDocId}) async {
    final query = await _lecturersRef.where('lecturerId', isEqualTo: lecturerId.trim()).get();
    for (var doc in query.docs) {
      if (excludeDocId == null || doc.id != excludeDocId) {
        return false;
      }
    }
    return true;
  }

  /// Check if Email is unique
  Future<bool> isEmailUnique(String email, {String? excludeDocId}) async {
    final cleanEmail = email.trim().toLowerCase();
    final query = await _lecturersRef.where('email', isEqualTo: cleanEmail).get();
    for (var doc in query.docs) {
      if (excludeDocId == null || doc.id != excludeDocId) {
        return false;
      }
    }
    return true;
  }

  /// Add new Lecturer with duplicate validations
  Future<void> addLecturer(LecturerModel lecturer, String password) async {
    try {
      final idUnique = await isLecturerIdUnique(lecturer.lecturerId);
      if (!idUnique) {
        throw Exception('A lecturer with Lecturer ID "${lecturer.lecturerId}" already exists.');
      }

      final emailUnique = await isEmailUnique(lecturer.email);
      if (!emailUnique) {
        throw Exception('A lecturer with Email "${lecturer.email}" already exists.');
      }

      final docRef = await _lecturersRef.add(lecturer.toMap());

      await _firestore.collection('users').doc(docRef.id).set({
        'uid': docRef.id,
        'email': lecturer.email.trim().toLowerCase(),
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
      rethrow;
    }
  }

  /// Update existing Lecturer record
  Future<void> updateLecturer(LecturerModel lecturer) async {
    if (lecturer.docId == null) return;
    try {
      final idUnique = await isLecturerIdUnique(lecturer.lecturerId, excludeDocId: lecturer.docId);
      if (!idUnique) {
        throw Exception('A lecturer with Lecturer ID "${lecturer.lecturerId}" already exists.');
      }

      await _lecturersRef.doc(lecturer.docId).update(lecturer.toMap());

      await _firestore.collection('users').doc(lecturer.docId).set({
        'email': lecturer.email.trim().toLowerCase(),
        'fullName': lecturer.name,
        'lecturerId': lecturer.lecturerId,
        'department': lecturer.department,
        'status': lecturer.status,
      }, SetOptions(merge: true));

      debugPrint('Lecturer updated successfully: ${lecturer.docId}');
    } catch (e) {
      debugPrint('Error updating lecturer: $e');
      rethrow;
    }
  }

  /// Toggle Lecturer status (active <-> inactive) without deleting record
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

  /// Fetch single Lecturer by email or uid
  Future<LecturerModel?> getLecturerByEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    try {
      final query = await _lecturersRef.where('email', isEqualTo: cleanEmail).limit(1).get();
      if (query.docs.isNotEmpty) {
        return LecturerModel.fromFirestore(query.docs.first);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching lecturer by email: $e');
      return null;
    }
  }

  /// Update permitted profile details (phone, address, photoUrl, etc.)
  Future<void> updateLecturerProfile({
    required String docId,
    required Map<String, dynamic> updateData,
    String? uid,
  }) async {
    try {
      final payload = Map<String, dynamic>.from(updateData);
      payload['updatedAt'] = DateTime.now().toIso8601String();

      // 1. Update lecturers collection
      await _lecturersRef.doc(docId).set(payload, SetOptions(merge: true));

      // 2. Update users collection for the logged in user
      if (uid != null && uid.isNotEmpty) {
        await _firestore.collection('users').doc(uid).set(payload, SetOptions(merge: true));
      }

      debugPrint('Lecturer profile updated successfully for doc: $docId');
    } catch (e) {
      debugPrint('Error updating lecturer profile: $e');
      throw Exception('Failed to update profile: $e');
    }
  }
}
