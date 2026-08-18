import 'package:cloud_firestore/cloud_firestore.dart';

class GradingScale {
  final String grade;
  final double minMarks;
  final double maxMarks;
  final double gradePoint;

  const GradingScale({
    required this.grade,
    required this.minMarks,
    required this.maxMarks,
    required this.gradePoint,
  });

  Map<String, dynamic> toMap() => {
        'grade': grade,
        'minMarks': minMarks,
        'maxMarks': maxMarks,
        'gradePoint': gradePoint,
      };

  factory GradingScale.fromMap(Map<String, dynamic> map) => GradingScale(
        grade: map['grade'] ?? 'F',
        minMarks: ((map['minMarks'] ?? 0) as num).toDouble(),
        maxMarks: ((map['maxMarks'] ?? 100) as num).toDouble(),
        gradePoint: ((map['gradePoint'] ?? 0) as num).toDouble(),
      );
}

class ExamResultModel {
  final String? docId;
  final String resultId;
  final String examId;
  final String examDocId;
  final String moduleId; // subjectCode
  final String subjectName;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final double marks;
  final double maxMarks;
  final String grade;
  final double gradePoint;
  final String status; // 'Draft', 'Submitted', 'Approved', 'Rejected', 'Published', 'Unlocked'
  final bool isAbsent;
  final String? submittedBy;
  final String? submittedAt;
  final String? approvedBy;
  final String? approvedAt;
  final String? publishedAt;
  final String? rejectionReason;
  final String updatedAt;

  ExamResultModel({
    this.docId,
    required this.resultId,
    required this.examId,
    required this.examDocId,
    required this.moduleId,
    required this.subjectName,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.marks,
    this.maxMarks = 100.0,
    required this.grade,
    required this.gradePoint,
    this.status = 'Draft',
    this.isAbsent = false,
    this.submittedBy,
    this.submittedAt,
    this.approvedBy,
    this.approvedAt,
    this.publishedAt,
    this.rejectionReason,
    required this.updatedAt,
  });

  bool get isDraft => status.toLowerCase() == 'draft';
  bool get isSubmitted => status.toLowerCase() == 'submitted';
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isRejected => status.toLowerCase() == 'rejected';
  bool get isPublished => status.toLowerCase() == 'published';
  bool get isLocked => isPublished;

  String get moduleCode => moduleId;
  double get obtainedMarks => marks;

  // Default university grading boundaries (if not configured dynamically in Firestore)
  static const List<GradingScale> defaultGradingScales = [
    GradingScale(grade: 'A+', minMarks: 90.0, maxMarks: 100.0, gradePoint: 4.0),
    GradingScale(grade: 'A', minMarks: 80.0, maxMarks: 89.99, gradePoint: 4.0),
    GradingScale(grade: 'A-', minMarks: 75.0, maxMarks: 79.99, gradePoint: 3.7),
    GradingScale(grade: 'B+', minMarks: 70.0, maxMarks: 74.99, gradePoint: 3.3),
    GradingScale(grade: 'B', minMarks: 65.0, maxMarks: 69.99, gradePoint: 3.0),
    GradingScale(grade: 'B-', minMarks: 60.0, maxMarks: 64.99, gradePoint: 2.7),
    GradingScale(grade: 'C+', minMarks: 55.0, maxMarks: 59.99, gradePoint: 2.3),
    GradingScale(grade: 'C', minMarks: 50.0, maxMarks: 54.99, gradePoint: 2.0),
    GradingScale(grade: 'C-', minMarks: 45.0, maxMarks: 49.99, gradePoint: 1.7),
    GradingScale(grade: 'D+', minMarks: 40.0, maxMarks: 44.99, gradePoint: 1.3),
    GradingScale(grade: 'D', minMarks: 35.0, maxMarks: 39.99, gradePoint: 1.0),
    GradingScale(grade: 'E', minMarks: 0.0, maxMarks: 34.99, gradePoint: 0.0),
  ];

  /// Calculate Grade & Grade Point dynamically based on grading configuration
  static Map<String, dynamic> calculateGradeAndPoint({
    required double marks,
    required bool isAbsent,
    List<GradingScale>? scales,
  }) {
    if (isAbsent) {
      return {'grade': 'AB', 'gradePoint': 0.0};
    }

    final activeScales = scales ?? defaultGradingScales;
    for (final scale in activeScales) {
      if (marks >= scale.minMarks && marks <= scale.maxMarks) {
        return {'grade': scale.grade, 'gradePoint': scale.gradePoint};
      }
    }
    return {'grade': 'E', 'gradePoint': 0.0};
  }

  Map<String, dynamic> toMap() {
    return {
      'resultId': resultId,
      'examId': examId,
      'examDocId': examDocId,
      'moduleId': moduleId,
      'subjectCode': moduleId,
      'subjectName': subjectName,
      'studentId': studentId,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'marks': marks,
      'maxMarks': maxMarks,
      'grade': grade,
      'gradePoint': gradePoint,
      'status': status,
      'isAbsent': isAbsent,
      'submittedBy': submittedBy,
      'submittedAt': submittedAt,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt,
      'publishedAt': publishedAt,
      'rejectionReason': rejectionReason,
      'updatedAt': updatedAt,
    };
  }

  factory ExamResultModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ExamResultModel(
      docId: doc.id,
      resultId: data['resultId'] ?? doc.id,
      examId: data['examId'] ?? '',
      examDocId: data['examDocId'] ?? '',
      moduleId: data['moduleId'] ?? data['subjectCode'] ?? '',
      subjectName: data['subjectName'] ?? '',
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      studentEmail: data['studentEmail'] ?? '',
      marks: ((data['marks'] ?? 0) as num).toDouble(),
      maxMarks: ((data['maxMarks'] ?? 100) as num).toDouble(),
      grade: data['grade'] ?? 'F',
      gradePoint: ((data['gradePoint'] ?? 0) as num).toDouble(),
      status: data['status'] ?? 'Draft',
      isAbsent: (data['isAbsent'] ?? false) as bool,
      submittedBy: data['submittedBy'],
      submittedAt: data['submittedAt'],
      approvedBy: data['approvedBy'],
      approvedAt: data['approvedAt'],
      publishedAt: data['publishedAt'],
      rejectionReason: data['rejectionReason'],
      updatedAt: data['updatedAt'] ?? DateTime.now().toIso8601String(),
    );
  }
}
