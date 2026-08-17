import 'package:cloud_firestore/cloud_firestore.dart';

class AssignmentModel {
  final String? docId;
  final String assignmentId;
  final String title;
  final String description;
  final String subjectDocId;
  final String subjectCode;
  final String subjectName;
  final String lecturerName;
  final String? lecturerId;
  final String createdBy;
  final String createdDate;
  final String startDate;
  final String dueDate;
  final num totalMarks;
  final String? attachmentUrl;
  final String? fileType;
  final String? fileSize;
  final String status; // draft | published | closed | deactivated
  final String semester;
  final String academicYear;

  AssignmentModel({
    this.docId,
    required this.assignmentId,
    required this.title,
    required this.description,
    required this.subjectDocId,
    required this.subjectCode,
    required this.subjectName,
    required this.lecturerName,
    this.lecturerId,
    required this.createdBy,
    required this.createdDate,
    required this.startDate,
    required this.dueDate,
    this.totalMarks = 100,
    this.attachmentUrl,
    this.fileType,
    this.fileSize,
    this.status = 'draft',
    required this.semester,
    required this.academicYear,
  });

  Map<String, dynamic> toMap() {
    return {
      'assignmentId': assignmentId,
      'title': title,
      'description': description,
      'subjectDocId': subjectDocId,
      'subjectCode': subjectCode,
      'subjectName': subjectName,
      'lecturerName': lecturerName,
      'lecturerId': lecturerId,
      'createdBy': createdBy,
      'createdDate': createdDate,
      'startDate': startDate,
      'dueDate': dueDate,
      'totalMarks': totalMarks,
      'attachmentUrl': attachmentUrl,
      'fileType': fileType,
      'fileSize': fileSize,
      'status': status,
      'semester': semester,
      'academicYear': academicYear,
    };
  }

  factory AssignmentModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AssignmentModel(
      docId: doc.id,
      assignmentId: data['assignmentId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      subjectDocId: data['subjectDocId'] ?? '',
      subjectCode: data['subjectCode'] ?? '',
      subjectName: data['subjectName'] ?? '',
      lecturerName: data['lecturerName'] ?? 'Unassigned',
      lecturerId: data['lecturerId'],
      createdBy: data['createdBy'] ?? '',
      createdDate: data['createdDate'] ?? '',
      startDate: data['startDate'] ?? '',
      dueDate: data['dueDate'] ?? '',
      totalMarks: data['totalMarks'] ?? 100,
      attachmentUrl: data['attachmentUrl'],
      fileType: data['fileType'],
      fileSize: data['fileSize'],
      status: data['status'] ?? 'draft',
      semester: data['semester'] ?? '',
      academicYear: data['academicYear'] ?? '',
    );
  }

  factory AssignmentModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return AssignmentModel(
      docId: id,
      assignmentId: map['assignmentId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      subjectDocId: map['subjectDocId'] ?? '',
      subjectCode: map['subjectCode'] ?? '',
      subjectName: map['subjectName'] ?? '',
      lecturerName: map['lecturerName'] ?? 'Unassigned',
      lecturerId: map['lecturerId'],
      createdBy: map['createdBy'] ?? '',
      createdDate: map['createdDate'] ?? '',
      startDate: map['startDate'] ?? '',
      dueDate: map['dueDate'] ?? '',
      totalMarks: map['totalMarks'] ?? 100,
      attachmentUrl: map['attachmentUrl'],
      fileType: map['fileType'],
      fileSize: map['fileSize'],
      status: map['status'] ?? 'draft',
      semester: map['semester'] ?? '',
      academicYear: map['academicYear'] ?? '',
    );
  }

  AssignmentModel copyWith({
    String? docId,
    String? assignmentId,
    String? title,
    String? description,
    String? subjectDocId,
    String? subjectCode,
    String? subjectName,
    String? lecturerName,
    String? lecturerId,
    String? createdBy,
    String? createdDate,
    String? startDate,
    String? dueDate,
    num? totalMarks,
    String? attachmentUrl,
    String? fileType,
    String? fileSize,
    String? status,
    String? semester,
    String? academicYear,
  }) {
    return AssignmentModel(
      docId: docId ?? this.docId,
      assignmentId: assignmentId ?? this.assignmentId,
      title: title ?? this.title,
      description: description ?? this.description,
      subjectDocId: subjectDocId ?? this.subjectDocId,
      subjectCode: subjectCode ?? this.subjectCode,
      subjectName: subjectName ?? this.subjectName,
      lecturerName: lecturerName ?? this.lecturerName,
      lecturerId: lecturerId ?? this.lecturerId,
      createdBy: createdBy ?? this.createdBy,
      createdDate: createdDate ?? this.createdDate,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
      totalMarks: totalMarks ?? this.totalMarks,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      status: status ?? this.status,
      semester: semester ?? this.semester,
      academicYear: academicYear ?? this.academicYear,
    );
  }
}
