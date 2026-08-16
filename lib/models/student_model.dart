import 'package:cloud_firestore/cloud_firestore.dart';

class StudentModel {
  final String? docId;
  final String studentId;
  final String name;
  final String email;
  final String course;
  final String batch;
  final String year;
  final String semester;
  final String status;
  final String? uid;
  final String? createdAt;

  StudentModel({
    this.docId,
    required this.studentId,
    required this.name,
    required this.email,
    required this.course,
    required this.batch,
    required this.year,
    required this.semester,
    this.status = 'active',
    this.uid,
    this.createdAt,
  });

  // Convert StudentModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'name': name,
      'email': email,
      'course': course,
      'batch': batch,
      'year': year,
      'semester': semester,
      'status': status,
      'uid': uid,
      'createdAt': createdAt ?? DateTime.now().toIso8601String(),
    };
  }

  // Create StudentModel from Firestore DocumentSnapshot
  factory StudentModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return StudentModel(
      docId: doc.id,
      studentId: data['studentId'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      course: data['course'] ?? '',
      batch: data['batch'] ?? '',
      year: data['year'] ?? '',
      semester: data['semester'] ?? '',
      status: data['status'] ?? 'active',
      uid: data['uid'],
      createdAt: data['createdAt']?.toString(),
    );
  }

  // Create StudentModel from Map
  factory StudentModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return StudentModel(
      docId: id,
      studentId: map['studentId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      course: map['course'] ?? '',
      batch: map['batch'] ?? '',
      year: map['year'] ?? '',
      semester: map['semester'] ?? '',
      status: map['status'] ?? 'active',
      uid: map['uid'],
      createdAt: map['createdAt']?.toString(),
    );
  }
}
