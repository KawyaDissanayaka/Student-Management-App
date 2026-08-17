import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/student_model.dart';

class StudentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _studentsRef =>
      _firestore.collection('students');

  /// Live Stream of all Students
  Stream<List<StudentModel>> getStudentsStream() {
    return _studentsRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => StudentModel.fromFirestore(doc)).toList();
    });
  }

  /// Check if Student ID is unique (excluding current doc during edit)
  Future<bool> isStudentIdUnique(String studentId, {String? excludeDocId}) async {
    final query = await _studentsRef.where('studentId', isEqualTo: studentId.trim()).get();
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
    final query = await _studentsRef.where('email', isEqualTo: cleanEmail).get();
    for (var doc in query.docs) {
      if (excludeDocId == null || doc.id != excludeDocId) {
        return false;
      }
    }
    return true;
  }

  /// Add new Student with duplicate validations
  Future<void> addStudent(StudentModel student, String password) async {
    try {
      final idUnique = await isStudentIdUnique(student.studentId);
      if (!idUnique) {
        throw Exception('A student with Student ID "${student.studentId}" already exists.');
      }

      final emailUnique = await isEmailUnique(student.email);
      if (!emailUnique) {
        throw Exception('A student with Email "${student.email}" already exists.');
      }

      // 1. Create document in Firestore 'students' collection
      final docRef = await _studentsRef.add(student.toMap());

      // 2. Mirror record to 'users' collection so student can log in
      await _firestore.collection('users').doc(docRef.id).set({
        'uid': docRef.id,
        'email': student.email.trim().toLowerCase(),
        'fullName': student.name,
        'role': 'STUDENT',
        'studentId': student.studentId,
        'course': student.course,
        'batch': student.batch,
        'year': student.year,
        'semester': student.semester,
        'status': student.status,
        'createdAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      debugPrint('Student successfully added with ID: ${docRef.id}');
    } catch (e) {
      debugPrint('Error adding student: $e');
      rethrow;
    }
  }

  /// Update existing Student record
  Future<void> updateStudent(StudentModel student) async {
    if (student.docId == null) return;
    try {
      final idUnique = await isStudentIdUnique(student.studentId, excludeDocId: student.docId);
      if (!idUnique) {
        throw Exception('A student with Student ID "${student.studentId}" already exists.');
      }

      await _studentsRef.doc(student.docId).update(student.toMap());

      // Mirror update to 'users' collection
      await _firestore.collection('users').doc(student.docId).set({
        'email': student.email.trim().toLowerCase(),
        'fullName': student.name,
        'studentId': student.studentId,
        'course': student.course,
        'batch': student.batch,
        'year': student.year,
        'semester': student.semester,
        'status': student.status,
      }, SetOptions(merge: true));

      debugPrint('Student updated successfully: ${student.docId}');
    } catch (e) {
      debugPrint('Error updating student: $e');
      rethrow;
    }
  }

  /// Toggle Student status (active <-> inactive) without deleting record
  Future<void> toggleStudentStatus(String docId, String currentStatus) async {
    final newStatus = (currentStatus.toLowerCase() == 'active') ? 'inactive' : 'active';
    try {
      await _studentsRef.doc(docId).update({'status': newStatus});
      await _firestore.collection('users').doc(docId).set({
        'status': newStatus,
      }, SetOptions(merge: true));
      debugPrint('Student $docId status -> $newStatus');
    } catch (e) {
      debugPrint('Error toggling student status: $e');
      throw Exception('Failed to update student status: $e');
    }
  }

  /// Delete Student record
  Future<void> deleteStudent(String docId) async {
    try {
      await _studentsRef.doc(docId).delete();
      await _firestore.collection('users').doc(docId).delete();
      debugPrint('Student deleted successfully: $docId');
    } catch (e) {
      debugPrint('Error deleting student: $e');
      throw Exception('Failed to delete student: $e');
    }
  }
}
