import 'package:cloud_firestore/cloud_firestore.dart';

class SubmissionModel {
  final String? docId;
  final String submissionId;
  final String assignmentId;
  final String assignmentTitle;
  final String moduleId; // subjectCode
  final String subjectName;
  final String studentDocId;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String submittedAt; // ISO-8601 datetime
  final bool isLate;
  final String? fileUrl; // attachmentUrl
  final String? fileName;
  final String? fileType;
  final String? fileSize;
  final String? notes;
  final num? marks; // mark
  final String? feedback;
  final String status; // 'Not Submitted', 'Submitted', 'Late', 'Returned', 'Graded'
  final int attemptNumber;
  final bool isFinal;
  final String? gradedAt;
  final String? gradedBy;

  SubmissionModel({
    this.docId,
    String? submissionId,
    required this.assignmentId,
    this.assignmentTitle = '',
    String? moduleId,
    String? subjectCode,
    this.subjectName = '',
    this.studentDocId = '',
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.submittedAt,
    bool? isLate,
    String? fileUrl,
    String? attachmentUrl,
    this.fileName,
    this.fileType = 'PDF',
    this.fileSize = '2.5 MB',
    this.notes,
    num? marks,
    num? mark,
    this.feedback,
    this.status = 'Submitted',
    this.attemptNumber = 1,
    this.isFinal = true,
    this.gradedAt,
    this.gradedBy,
  })  : submissionId = submissionId ?? 'SUB-${DateTime.now().millisecondsSinceEpoch}',
        moduleId = moduleId ?? subjectCode ?? '',
        fileUrl = fileUrl ?? attachmentUrl,
        marks = marks ?? mark,
        isLate = isLate ?? (status.toLowerCase() == 'late');

  // Backwards compatibility getters
  String get subjectCode => moduleId;
  String? get attachmentUrl => fileUrl;
  num? get mark => marks;

  bool get isSubmitted => status.toLowerCase() == 'submitted' || status.toLowerCase() == 'late';
  bool get isGraded => status.toLowerCase() == 'graded' || marks != null;

  /// Helper: Auto-detect submission status based on due date
  static String determineSubmissionStatus({
    required DateTime submittedAt,
    required String dueDate,
  }) {
    try {
      final due = DateTime.parse(dueDate);
      final endOfDueDay = DateTime(due.year, due.month, due.day, 23, 59, 59);
      if (submittedAt.isAfter(endOfDueDay)) {
        return 'Late';
      }
      return 'Submitted';
    } catch (_) {
      return 'Submitted';
    }
  }

  /// Validate grading score
  static String? validateGradingMarks({
    required double marks,
    required double maxMarks,
  }) {
    if (marks < 0) {
      return 'Marks cannot be negative';
    }
    if (marks > maxMarks) {
      return 'Marks cannot exceed maximum marks ($maxMarks)';
    }
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'submissionId': submissionId,
      'assignmentId': assignmentId,
      'assignmentTitle': assignmentTitle,
      'moduleId': moduleId,
      'subjectCode': moduleId,
      'subjectName': subjectName,
      'studentDocId': studentDocId,
      'studentId': studentId,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'submittedAt': submittedAt,
      'isLate': isLate,
      'fileUrl': fileUrl,
      'attachmentUrl': fileUrl,
      'fileName': fileName,
      'fileType': fileType,
      'fileSize': fileSize,
      'notes': notes,
      'marks': marks,
      'mark': marks,
      'feedback': feedback,
      'status': status,
      'attemptNumber': attemptNumber,
      'isFinal': isFinal,
      'gradedAt': gradedAt,
      'gradedBy': gradedBy,
    };
  }

  factory SubmissionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final markVal = (data['marks'] ?? data['mark']) as num?;
    final isLateVal = (data['isLate'] as bool?) ?? (data['status']?.toString().toLowerCase() == 'late');
    final mod = data['moduleId'] ?? data['subjectCode'] ?? '';
    final url = data['fileUrl'] ?? data['attachmentUrl'];

    return SubmissionModel(
      docId: doc.id,
      submissionId: data['submissionId'] ?? doc.id,
      assignmentId: data['assignmentId'] ?? '',
      assignmentTitle: data['assignmentTitle'] ?? '',
      moduleId: mod,
      subjectName: data['subjectName'] ?? '',
      studentDocId: data['studentDocId'] ?? '',
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      studentEmail: data['studentEmail'] ?? '',
      submittedAt: data['submittedAt'] ?? '',
      isLate: isLateVal,
      fileUrl: url,
      fileName: data['fileName'],
      fileType: data['fileType'] ?? 'PDF',
      fileSize: data['fileSize'] ?? '2.5 MB',
      notes: data['notes'],
      marks: markVal,
      feedback: data['feedback'],
      status: data['status'] ?? (markVal != null ? 'Graded' : (isLateVal ? 'Late' : 'Submitted')),
      attemptNumber: (data['attemptNumber'] as num?)?.toInt() ?? 1,
      isFinal: (data['isFinal'] as bool?) ?? true,
      gradedAt: data['gradedAt'],
      gradedBy: data['gradedBy'],
    );
  }
}
