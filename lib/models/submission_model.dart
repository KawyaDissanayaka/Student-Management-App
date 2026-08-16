import 'package:cloud_firestore/cloud_firestore.dart';

class SubmissionModel {
  final String? docId;
  final String assignmentId;
  final String assignmentTitle;
  final String subjectCode;
  final String subjectName;
  final String studentDocId;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String submittedAt; // ISO-8601 datetime
  final bool isLate;
  final String? attachmentUrl;
  final String? notes;
  final num? mark;
  final String? feedback;

  SubmissionModel({
    this.docId,
    required this.assignmentId,
    required this.assignmentTitle,
    required this.subjectCode,
    required this.subjectName,
    required this.studentDocId,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.submittedAt,
    required this.isLate,
    this.attachmentUrl,
    this.notes,
    this.mark,
    this.feedback,
  });

  Map<String, dynamic> toMap() {
    return {
      'assignmentId': assignmentId,
      'assignmentTitle': assignmentTitle,
      'subjectCode': subjectCode,
      'subjectName': subjectName,
      'studentDocId': studentDocId,
      'studentId': studentId,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'submittedAt': submittedAt,
      'isLate': isLate,
      'attachmentUrl': attachmentUrl,
      'notes': notes,
      'mark': mark,
      'feedback': feedback,
    };
  }

  factory SubmissionModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return SubmissionModel(
      docId: doc.id,
      assignmentId: data['assignmentId'] ?? '',
      assignmentTitle: data['assignmentTitle'] ?? '',
      subjectCode: data['subjectCode'] ?? '',
      subjectName: data['subjectName'] ?? '',
      studentDocId: data['studentDocId'] ?? '',
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      studentEmail: data['studentEmail'] ?? '',
      submittedAt: data['submittedAt'] ?? '',
      isLate: data['isLate'] ?? false,
      attachmentUrl: data['attachmentUrl'],
      notes: data['notes'],
      mark: data['mark'],
      feedback: data['feedback'],
    );
  }

  factory SubmissionModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return SubmissionModel(
      docId: id,
      assignmentId: map['assignmentId'] ?? '',
      assignmentTitle: map['assignmentTitle'] ?? '',
      subjectCode: map['subjectCode'] ?? '',
      subjectName: map['subjectName'] ?? '',
      studentDocId: map['studentDocId'] ?? '',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      studentEmail: map['studentEmail'] ?? '',
      submittedAt: map['submittedAt'] ?? '',
      isLate: map['isLate'] ?? false,
      attachmentUrl: map['attachmentUrl'],
      notes: map['notes'],
      mark: map['mark'],
      feedback: map['feedback'],
    );
  }
}
