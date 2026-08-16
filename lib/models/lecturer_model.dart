import 'package:cloud_firestore/cloud_firestore.dart';

class LecturerModel {
  final String? docId;
  final String lecturerId;
  final String name;
  final String email;
  final String department;
  final String status;
  final String? uid;
  final String? createdAt;

  LecturerModel({
    this.docId,
    required this.lecturerId,
    required this.name,
    required this.email,
    required this.department,
    this.status = 'active',
    this.uid,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'lecturerId': lecturerId,
      'name': name,
      'email': email,
      'department': department,
      'status': status,
      'uid': uid,
      'createdAt': createdAt ?? DateTime.now().toIso8601String(),
    };
  }

  factory LecturerModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return LecturerModel(
      docId: doc.id,
      lecturerId: data['lecturerId'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      department: data['department'] ?? '',
      status: data['status'] ?? 'active',
      uid: data['uid'],
      createdAt: data['createdAt']?.toString(),
    );
  }

  factory LecturerModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return LecturerModel(
      docId: id,
      lecturerId: map['lecturerId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      department: map['department'] ?? '',
      status: map['status'] ?? 'active',
      uid: map['uid'],
      createdAt: map['createdAt']?.toString(),
    );
  }
}
