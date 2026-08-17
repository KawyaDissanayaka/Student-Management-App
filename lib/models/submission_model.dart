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
  final String? fileName;
  final String? fileType;
  final String? fileSize;
  final String? notes;
  final num? mark;
  final String? feedback;
  final String status; // 'submitted' | 'reviewed' | 'late' | 'resubmitted'
  final int attemptNumber;
  final bool isFinal;
  final String? gradedAt;
  final String? gradedBy;

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
    this.fileName,
    this.fileType = 'PDF',
    this.fileSize = '2.5 MB',
    this.notes,
    this.mark,
    this.feedback,
    this.status = 'submitted',
    this.attemptNumber = 1,
    this.isFinal = true,
    this.gradedAt,
    this.gradedBy,
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
      'fileName': fileName,
      'fileType': fileType,
      'fileSize': fileSize,
      'notes': notes,
      'mark': mark,
      'feedback': feedback,
      'status': status,
      'attemptNumber': attemptNumber,
      'isFinal': isFinal,
      'gradedAt': gradedAt,
      'gradedBy': gradedBy,
    };
  }

  factory SubmissionModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final markVal = data['mark'] as num?;
    final isLateVal = (data['isLate'] as bool?) ?? false;

    String computedStatus = data['status'] ?? (markVal != null ? 'reviewed' : (isLateVal ? 'late' : 'submitted'));

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
      isLate: isLateVal,
      attachmentUrl: data['attachmentUrl'],
      fileName: data['fileName'],
      fileType: data['fileType'] ?? 'PDF',
      fileSize: data['fileSize'] ?? '2.5 MB',
      notes: data['notes'],
      mark: markVal,
      feedback: data['feedback'],
      status: computedStatus,
      attemptNumber: (data['attemptNumber'] as int?) ?? 1,
      isFinal: (data['isFinal'] as bool?) ?? true,
      gradedAt: data['gradedAt'],
      gradedBy: data['gradedBy'],
    );
  }
}
