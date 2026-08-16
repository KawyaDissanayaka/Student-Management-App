import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  final String? docId;
  final String studentDocId;
  final String studentId;
  final String studentName;
  final String subjectCode;
  final String subjectName;
  final String date; // formatted yyyy-MM-dd
  final String status; // Present, Absent, Late
  final String markedBy;
  final String batch;
  final String semester;

  AttendanceModel({
    this.docId,
    required this.studentDocId,
    required this.studentId,
    required this.studentName,
    required this.subjectCode,
    required this.subjectName,
    required this.date,
    required this.status,
    required this.markedBy,
    required this.batch,
    required this.semester,
  });

  Map<String, dynamic> toMap() {
    return {
      'studentDocId': studentDocId,
      'studentId': studentId,
      'studentName': studentName,
      'subjectCode': subjectCode,
      'subjectName': subjectName,
      'date': date,
      'status': status,
      'markedBy': markedBy,
      'batch': batch,
      'semester': semester,
    };
  }

  factory AttendanceModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AttendanceModel(
      docId: doc.id,
      studentDocId: data['studentDocId'] ?? '',
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      subjectCode: data['subjectCode'] ?? '',
      subjectName: data['subjectName'] ?? '',
      date: data['date'] ?? '',
      status: data['status'] ?? 'Present',
      markedBy: data['markedBy'] ?? '',
      batch: data['batch'] ?? '',
      semester: data['semester'] ?? '',
    );
  }

  factory AttendanceModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return AttendanceModel(
      docId: id,
      studentDocId: map['studentDocId'] ?? '',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      subjectCode: map['subjectCode'] ?? '',
      subjectName: map['subjectName'] ?? '',
      date: map['date'] ?? '',
      status: map['status'] ?? 'Present',
      markedBy: map['markedBy'] ?? '',
      batch: map['batch'] ?? '',
      semester: map['semester'] ?? '',
    );
  }
}
