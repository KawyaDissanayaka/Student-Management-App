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
  final String createdBy;
  final String createdDate;
  final String startDate;
  final String dueDate;
  final String? attachmentUrl;
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
    required this.createdBy,
    required this.createdDate,
    required this.startDate,
    required this.dueDate,
    this.attachmentUrl,
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
      'createdBy': createdBy,
      'createdDate': createdDate,
      'startDate': startDate,
      'dueDate': dueDate,
      'attachmentUrl': attachmentUrl,
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
      createdBy: data['createdBy'] ?? '',
      createdDate: data['createdDate'] ?? '',
      startDate: data['startDate'] ?? '',
      dueDate: data['dueDate'] ?? '',
      attachmentUrl: data['attachmentUrl'],
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
      createdBy: map['createdBy'] ?? '',
      createdDate: map['createdDate'] ?? '',
      startDate: map['startDate'] ?? '',
      dueDate: map['dueDate'] ?? '',
      attachmentUrl: map['attachmentUrl'],
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
    String? createdBy,
    String? createdDate,
    String? startDate,
    String? dueDate,
    String? attachmentUrl,
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
      createdBy: createdBy ?? this.createdBy,
      createdDate: createdDate ?? this.createdDate,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      status: status ?? this.status,
      semester: semester ?? this.semester,
      academicYear: academicYear ?? this.academicYear,
    );
  }
}
