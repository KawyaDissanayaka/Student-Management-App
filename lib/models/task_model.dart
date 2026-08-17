import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String? docId;
  final String taskId;
  final String title;
  final String description;
  final String assignedToType; // 'student' | 'lecturer' | 'subject_students'
  final String assignedToDocId;
  final String assignedToName;
  final String assignedToEmail;
  final String assignedToId; // Student ID or Lecturer ID
  final String assignedBy;
  final String priority; // 'low' | 'medium' | 'high' | 'urgent'
  final String startDate; // YYYY-MM-DD
  final String dueDate; // YYYY-MM-DD
  final String createdDate; // ISO string
  final String status; // 'pending' | 'in_progress' | 'completed' | 'overdue' | 'deactivated'
  final String? subjectCode;
  final String? subjectName;
  final String? subjectDocId;
  final String? lecturerId;
  final String? lecturerName;
  final List<String> assignedStudents; // list of student emails or ['ALL']
  final String? attachmentUrl;
  final String? completedAt;
  final String? completedBy;

  TaskModel({
    this.docId,
    required this.taskId,
    required this.title,
    required this.description,
    this.assignedToType = 'student',
    this.assignedToDocId = '',
    this.assignedToName = '',
    this.assignedToEmail = '',
    this.assignedToId = '',
    required this.assignedBy,
    required this.priority,
    required this.startDate,
    required this.dueDate,
    required this.createdDate,
    this.status = 'pending',
    this.subjectCode,
    this.subjectName,
    this.subjectDocId,
    this.lecturerId,
    this.lecturerName,
    this.assignedStudents = const ['ALL'],
    this.attachmentUrl,
    this.completedAt,
    this.completedBy,
  });

  /// Computed dynamic status:
  /// If status is 'completed' or 'deactivated', keep it. (Completed tasks NEVER become overdue!)
  /// If incomplete ('pending' or 'in_progress') and today is after dueDate, return 'overdue'.
  String get effectiveStatus {
    final s = status.toLowerCase();
    if (s == 'completed' || s == 'deactivated') {
      return s;
    }
    if (dueDate.isNotEmpty) {
      try {
        final parsedDue = DateTime.parse(dueDate);
        final endOfDueDay = DateTime(parsedDue.year, parsedDue.month, parsedDue.day, 23, 59, 59);
        if (DateTime.now().isAfter(endOfDueDay)) {
          return 'overdue';
        }
      } catch (_) {}
    }
    return s;
  }

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'title': title,
      'description': description,
      'assignedToType': assignedToType,
      'assignedToDocId': assignedToDocId,
      'assignedToName': assignedToName,
      'assignedToEmail': assignedToEmail,
      'assignedToId': assignedToId,
      'assignedBy': assignedBy,
      'priority': priority,
      'startDate': startDate,
      'dueDate': dueDate,
      'createdDate': createdDate,
      'status': status,
      'subjectCode': subjectCode,
      'subjectName': subjectName,
      'subjectDocId': subjectDocId,
      'lecturerId': lecturerId,
      'lecturerName': lecturerName,
      'assignedStudents': assignedStudents,
      'attachmentUrl': attachmentUrl,
      'completedAt': completedAt,
      'completedBy': completedBy,
    };
  }

  factory TaskModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return TaskModel(
      docId: doc.id,
      taskId: data['taskId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      assignedToType: data['assignedToType'] ?? 'student',
      assignedToDocId: data['assignedToDocId'] ?? '',
      assignedToName: data['assignedToName'] ?? '',
      assignedToEmail: data['assignedToEmail'] ?? '',
      assignedToId: data['assignedToId'] ?? '',
      assignedBy: data['assignedBy'] ?? 'Admin',
      priority: data['priority'] ?? 'medium',
      startDate: data['startDate'] ?? '',
      dueDate: data['dueDate'] ?? '',
      createdDate: data['createdDate'] ?? '',
      status: data['status'] ?? 'pending',
      subjectCode: data['subjectCode'],
      subjectName: data['subjectName'],
      subjectDocId: data['subjectDocId'],
      lecturerId: data['lecturerId'],
      lecturerName: data['lecturerName'],
      assignedStudents: List<String>.from(data['assignedStudents'] ?? ['ALL']),
      attachmentUrl: data['attachmentUrl'],
      completedAt: data['completedAt'],
      completedBy: data['completedBy'],
    );
  }

  factory TaskModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return TaskModel(
      docId: id,
      taskId: map['taskId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      assignedToType: map['assignedToType'] ?? 'student',
      assignedToDocId: map['assignedToDocId'] ?? '',
      assignedToName: map['assignedToName'] ?? '',
      assignedToEmail: map['assignedToEmail'] ?? '',
      assignedToId: map['assignedToId'] ?? '',
      assignedBy: map['assignedBy'] ?? 'Admin',
      priority: map['priority'] ?? 'medium',
      startDate: map['startDate'] ?? '',
      dueDate: map['dueDate'] ?? '',
      createdDate: map['createdDate'] ?? '',
      status: map['status'] ?? 'pending',
      subjectCode: map['subjectCode'],
      subjectName: map['subjectName'],
      subjectDocId: map['subjectDocId'],
      lecturerId: map['lecturerId'],
      lecturerName: map['lecturerName'],
      assignedStudents: List<String>.from(map['assignedStudents'] ?? ['ALL']),
      attachmentUrl: map['attachmentUrl'],
      completedAt: map['completedAt'],
      completedBy: map['completedBy'],
    );
  }
}
