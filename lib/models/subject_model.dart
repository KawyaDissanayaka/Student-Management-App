import 'package:cloud_firestore/cloud_firestore.dart';

class SubjectModel {
  final String? docId;
  final String subjectId;
  final String subjectCode;
  final String subjectName;
  final String description;
  final String semester;
  final String academicYear;
  final String lecturerName;
  final String? lecturerId;
  final int credits;
  final String status;
  final String? createdAt;

  SubjectModel({
    this.docId,
    required this.subjectId,
    required this.subjectCode,
    required this.subjectName,
    required this.description,
    required this.semester,
    required this.academicYear,
    required this.lecturerName,
    this.lecturerId,
    this.credits = 3,
    this.status = 'active',
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'subjectId': subjectId,
      'subjectCode': subjectCode,
      'subjectName': subjectName,
      'description': description,
      'semester': semester,
      'academicYear': academicYear,
      'lecturerName': lecturerName,
      'lecturerId': lecturerId,
      'credits': credits,
      'status': status,
      'createdAt': createdAt ?? DateTime.now().toIso8601String(),
    };
  }

  factory SubjectModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return SubjectModel(
      docId: doc.id,
      subjectId: data['subjectId'] ?? '',
      subjectCode: data['subjectCode'] ?? '',
      subjectName: data['subjectName'] ?? '',
      description: data['description'] ?? '',
      semester: data['semester'] ?? '',
      academicYear: data['academicYear'] ?? '',
      lecturerName: data['lecturerName'] ?? 'Unassigned',
      lecturerId: data['lecturerId'],
      credits: (data['credits'] as num?)?.toInt() ?? 3,
      status: data['status'] ?? 'active',
      createdAt: data['createdAt']?.toString(),
    );
  }

  factory SubjectModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return SubjectModel(
      docId: id,
      subjectId: map['subjectId'] ?? '',
      subjectCode: map['subjectCode'] ?? '',
      subjectName: map['subjectName'] ?? '',
      description: map['description'] ?? '',
      semester: map['semester'] ?? '',
      academicYear: map['academicYear'] ?? '',
      lecturerName: map['lecturerName'] ?? 'Unassigned',
      lecturerId: map['lecturerId'],
      credits: (map['credits'] as num?)?.toInt() ?? 3,
      status: map['status'] ?? 'active',
      createdAt: map['createdAt']?.toString(),
    );
  }
}
