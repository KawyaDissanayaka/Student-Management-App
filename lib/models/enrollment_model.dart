import 'package:cloud_firestore/cloud_firestore.dart';

class EnrollmentModel {
  final String? docId;
  final String studentDocId;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String subjectDocId;
  final String subjectCode;
  final String subjectName;
  final String lecturerName;
  final String semester;
  final String academicYear;
  final String enrollmentDate;
  final String status;

  EnrollmentModel({
    this.docId,
    required this.studentDocId,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.subjectDocId,
    required this.subjectCode,
    required this.subjectName,
    required this.lecturerName,
    required this.semester,
    required this.academicYear,
    required this.enrollmentDate,
    this.status = 'active',
  });

  Map<String, dynamic> toMap() {
    return {
      'studentDocId': studentDocId,
      'studentId': studentId,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'subjectDocId': subjectDocId,
      'subjectCode': subjectCode,
      'subjectName': subjectName,
      'lecturerName': lecturerName,
      'semester': semester,
      'academicYear': academicYear,
      'enrollmentDate': enrollmentDate,
      'status': status,
    };
  }

  factory EnrollmentModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return EnrollmentModel(
      docId: doc.id,
      studentDocId: data['studentDocId'] ?? '',
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      studentEmail: data['studentEmail'] ?? '',
      subjectDocId: data['subjectDocId'] ?? '',
      subjectCode: data['subjectCode'] ?? '',
      subjectName: data['subjectName'] ?? '',
      lecturerName: data['lecturerName'] ?? 'Unassigned',
      semester: data['semester'] ?? '',
      academicYear: data['academicYear'] ?? '',
      enrollmentDate: data['enrollmentDate'] ?? '',
      status: data['status'] ?? 'active',
    );
  }

  factory EnrollmentModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return EnrollmentModel(
      docId: id,
      studentDocId: map['studentDocId'] ?? '',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      studentEmail: map['studentEmail'] ?? '',
      subjectDocId: map['subjectDocId'] ?? '',
      subjectCode: map['subjectCode'] ?? '',
      subjectName: map['subjectName'] ?? '',
      lecturerName: map['lecturerName'] ?? 'Unassigned',
      semester: map['semester'] ?? '',
      academicYear: map['academicYear'] ?? '',
      enrollmentDate: map['enrollmentDate'] ?? '',
      status: map['status'] ?? 'active',
    );
  }
}
