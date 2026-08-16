import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/student_model.dart';

class StudentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection Reference
  CollectionReference<Map<String, dynamic>> get _studentsRef =>
      _firestore.collection('students');

  // Live Stream of Students
  Stream<List<StudentModel>> getStudentsStream() {
    return _studentsRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => StudentModel.fromFirestore(doc)).toList();
    });
  }

  // Add new Student to Firestore 'students' and 'users' collections
  Future<void> addStudent(StudentModel student, String password) async {
    try {
      // 1. Create document in Firestore 'students' collection
      final docRef = await _studentsRef.add(student.toMap());

      // 2. Mirror record to 'users' collection so student can log in
      await _firestore.collection('users').doc(docRef.id).set({
        'uid': docRef.id,
        'email': student.email,
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
      throw Exception('Failed to add student to database: $e');
    }
  }

  // Update existing Student record
  Future<void> updateStudent(StudentModel student) async {
    if (student.docId == null) return;
    try {
      await _studentsRef.doc(student.docId).update(student.toMap());

      // Mirror update to 'users' collection
      await _firestore.collection('users').doc(student.docId).set({
        'email': student.email,
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
      throw Exception('Failed to update student: $e');
    }
  }

  // Delete Student record
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
