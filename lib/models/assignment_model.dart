import 'package:cloud_firestore/cloud_firestore.dart';

class AssignmentModel {
  final String? docId;
  final String assignmentId;
  final String title;
  final String description;
  final String instructions;
  final String subjectDocId;
  final String moduleId; // subjectCode
  final String subjectName;
  final String lecturerName;
  final String? lecturerId;
  final String createdBy;
  final String createdDate;
  final String startDate;
  final String dueDate;
  final num totalMarks; // maximumMarks
  final String? attachmentUrl;
  final String? fileType;
  final String? fileSize;
  final String status; // 'Draft' | 'Published' | 'Closed' | 'draft' | 'published' | 'closed'
  final String semester;
  final String academicYear;

  AssignmentModel({
    this.docId,
    required this.assignmentId,
    required this.title,
    this.description = '',
    this.instructions = '',
    this.subjectDocId = '',
    String? moduleId,
    String? subjectCode,
    this.subjectName = '',
    this.lecturerName = 'Unassigned',
    this.lecturerId,
    this.createdBy = '',
    this.createdDate = '',
    required this.startDate,
    required this.dueDate,
    num? totalMarks,
    num? maximumMarks,
    this.attachmentUrl,
    this.fileType,
    this.fileSize,
    this.status = 'Published',
    this.semester = 'Semester 1',
    this.academicYear = '2025/2026',
  })  : moduleId = moduleId ?? subjectCode ?? '',
        totalMarks = totalMarks ?? maximumMarks ?? 100;

  // Backwards compatibility & convenience getters
  String get assignmentTitle => title;
  String get subjectCode => moduleId;
  double get maximumMarks => totalMarks.toDouble();
  String? get attachment => attachmentUrl;

  bool get isDraft => status.toLowerCase() == 'draft';
  bool get isPublished => status.toLowerCase() == 'published';
  bool get isClosed => status.toLowerCase() == 'closed';

  /// Validates assignment fields
  static String? validateAssignment({
    required String title,
    required String startDate,
    required String dueDate,
    required double maxMarks,
  }) {
    if (title.trim().isEmpty) {
      return 'Assignment title is required';
    }
    if (maxMarks <= 0) {
      return 'Maximum marks must be greater than 0';
    }
    if (startDate.isEmpty || dueDate.isEmpty) {
      return 'Start date and due date are required';
    }
    try {
      final start = DateTime.parse(startDate);
      final due = DateTime.parse(dueDate);
      if (due.isBefore(start)) {
        return 'Due date must be after start date';
      }
    } catch (_) {
      return 'Invalid date format. Use YYYY-MM-DD';
    }
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'assignmentId': assignmentId,
      'title': title,
      'assignmentTitle': title,
      'description': description,
      'instructions': instructions,
      'subjectDocId': subjectDocId,
      'moduleId': moduleId,
      'subjectCode': moduleId,
      'subjectName': subjectName,
      'lecturerName': lecturerName,
      'lecturerId': lecturerId,
      'createdBy': createdBy,
      'createdDate': createdDate,
      'startDate': startDate,
      'dueDate': dueDate,
      'totalMarks': totalMarks,
      'maximumMarks': totalMarks,
      'attachmentUrl': attachmentUrl,
      'attachment': attachmentUrl,
      'fileType': fileType,
      'fileSize': fileSize,
      'status': status,
      'semester': semester,
      'academicYear': academicYear,
    };
  }

  factory AssignmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final mod = data['moduleId'] ?? data['subjectCode'] ?? '';
    final tit = data['assignmentTitle'] ?? data['title'] ?? '';
    final marks = (data['maximumMarks'] ?? data['totalMarks'] ?? 100) as num;

    return AssignmentModel(
      docId: doc.id,
      assignmentId: data['assignmentId'] ?? doc.id,
      title: tit,
      description: data['description'] ?? '',
      instructions: data['instructions'] ?? '',
      subjectDocId: data['subjectDocId'] ?? '',
      moduleId: mod,
      subjectName: data['subjectName'] ?? '',
      lecturerName: data['lecturerName'] ?? 'Unassigned',
      lecturerId: data['lecturerId'],
      createdBy: data['createdBy'] ?? '',
      createdDate: data['createdDate'] ?? '',
      startDate: data['startDate'] ?? '',
      dueDate: data['dueDate'] ?? '',
      totalMarks: marks,
      attachmentUrl: data['attachment'] ?? data['attachmentUrl'],
      fileType: data['fileType'],
      fileSize: data['fileSize'],
      status: data['status'] ?? 'Published',
      semester: data['semester'] ?? '',
      academicYear: data['academicYear'] ?? '',
    );
  }

  factory AssignmentModel.fromMap(Map<String, dynamic> map, {String? id}) {
    final mod = map['moduleId'] ?? map['subjectCode'] ?? '';
    final tit = map['assignmentTitle'] ?? map['title'] ?? '';
    final marks = (map['maximumMarks'] ?? map['totalMarks'] ?? 100) as num;

    return AssignmentModel(
      docId: id,
      assignmentId: map['assignmentId'] ?? '',
      title: tit,
      description: map['description'] ?? '',
      instructions: map['instructions'] ?? '',
      subjectDocId: map['subjectDocId'] ?? '',
      moduleId: mod,
      subjectName: map['subjectName'] ?? '',
      lecturerName: map['lecturerName'] ?? 'Unassigned',
      lecturerId: map['lecturerId'],
      createdBy: map['createdBy'] ?? '',
      createdDate: map['createdDate'] ?? '',
      startDate: map['startDate'] ?? '',
      dueDate: map['dueDate'] ?? '',
      totalMarks: marks,
      attachmentUrl: map['attachment'] ?? map['attachmentUrl'],
      fileType: map['fileType'],
      fileSize: map['fileSize'],
      status: map['status'] ?? 'Published',
      semester: map['semester'] ?? '',
      academicYear: map['academicYear'] ?? '',
    );
  }
}
