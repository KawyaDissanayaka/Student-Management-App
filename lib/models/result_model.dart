import 'package:cloud_firestore/cloud_firestore.dart';

class ResultModel {
  final String? docId;
  final String resultId;
  final String studentDocId;
  final String studentOfficialId;
  final String studentEmail;
  final String studentName;
  final String subjectCode;
  final String subjectName;
  final int credits;
  final double marks; // 0.0 - 100.0 (Weighted Total)
  final String grade; // 'A+', 'A', 'B+', etc.
  final double gradePoint; // 4.0, 3.7, etc.
  final String semester;
  final String academicYear;
  final String publishedDate;
  final String status; // 'draft' | 'published' | 'locked'
  final double? assignmentMarks;
  final double? midtermMarks;
  final double? finalExamMarks;
  final String? lecturerName;
  final String? lecturerEmail;
  final String? lockedAt;
  final String? lockedBy;

  ResultModel({
    this.docId,
    required this.resultId,
    required this.studentDocId,
    required this.studentOfficialId,
    required this.studentEmail,
    required this.studentName,
    required this.subjectCode,
    required this.subjectName,
    required this.credits,
    required this.marks,
    required this.grade,
    required this.gradePoint,
    required this.semester,
    required this.academicYear,
    required this.publishedDate,
    this.status = 'published',
    this.assignmentMarks,
    this.midtermMarks,
    this.finalExamMarks,
    this.lecturerName,
    this.lecturerEmail,
    this.lockedAt,
    this.lockedBy,
  });

  /// Calculates letter grade from marks
  static String calculateGrade(double marks) {
    if (marks >= 85) return 'A+';
    if (marks >= 80) return 'A';
    if (marks >= 75) return 'A-';
    if (marks >= 70) return 'B+';
    if (marks >= 65) return 'B';
    if (marks >= 60) return 'B-';
    if (marks >= 55) return 'C+';
    if (marks >= 50) return 'C';
    if (marks >= 45) return 'C-';
    if (marks >= 40) return 'D';
    return 'F';
  }

  /// Calculates official Grade Point (4.0 scale)
  static double calculateGradePoint(double marks) {
    if (marks >= 80) return 4.0;
    if (marks >= 75) return 3.7;
    if (marks >= 70) return 3.3;
    if (marks >= 65) return 3.0;
    if (marks >= 60) return 2.7;
    if (marks >= 55) return 2.3;
    if (marks >= 50) return 2.0;
    if (marks >= 45) return 1.7;
    if (marks >= 40) return 1.0;
    return 0.0;
  }

  bool get isPassed => grade != 'F' && gradePoint >= 2.0;
  bool get isLocked => status.toLowerCase() == 'locked';

  factory ResultModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ResultModel(
      docId: doc.id,
      resultId: data['resultId'] ?? doc.id,
      studentDocId: data['studentDocId'] ?? '',
      studentOfficialId: data['studentOfficialId'] ?? data['studentId'] ?? '',
      studentEmail: data['studentEmail'] ?? '',
      studentName: data['studentName'] ?? '',
      subjectCode: data['subjectCode'] ?? '',
      subjectName: data['subjectName'] ?? '',
      credits: (data['credits'] ?? 3) as int,
      marks: ((data['marks'] ?? 0) as num).toDouble(),
      grade: data['grade'] ?? calculateGrade(((data['marks'] ?? 0) as num).toDouble()),
      gradePoint: ((data['gradePoint'] ?? 0) as num).toDouble(),
      semester: data['semester'] ?? '',
      academicYear: data['academicYear'] ?? '',
      publishedDate: data['publishedDate'] ?? '',
      status: data['status'] ?? 'published',
      assignmentMarks: (data['assignmentMarks'] as num?)?.toDouble(),
      midtermMarks: (data['midtermMarks'] as num?)?.toDouble(),
      finalExamMarks: (data['finalExamMarks'] as num?)?.toDouble(),
      lecturerName: data['lecturerName'],
      lecturerEmail: data['lecturerEmail'],
      lockedAt: data['lockedAt'],
      lockedBy: data['lockedBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'resultId': resultId,
      'studentDocId': studentDocId,
      'studentOfficialId': studentOfficialId,
      'studentEmail': studentEmail,
      'studentName': studentName,
      'subjectCode': subjectCode,
      'subjectName': subjectName,
      'credits': credits,
      'marks': marks,
      'grade': grade,
      'gradePoint': gradePoint,
      'semester': semester,
      'academicYear': academicYear,
      'publishedDate': publishedDate,
      'status': status,
      'assignmentMarks': assignmentMarks,
      'midtermMarks': midtermMarks,
      'finalExamMarks': finalExamMarks,
      'lecturerName': lecturerName,
      'lecturerEmail': lecturerEmail,
      'lockedAt': lockedAt,
      'lockedBy': lockedBy,
    };
  }
}
