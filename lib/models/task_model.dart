import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String? docId;
  final String taskId;
  final String title;
  final String description;
  final String instructions;
  final String moduleId; // subjectCode
  final String? subjectCode;
  final String? subjectName;
  final String? subjectDocId;
  final String assignedToType; // 'student' | 'lecturer' | 'subject_students'
  final String assignedToDocId;
  final String assignedToName;
  final String assignedToEmail;
  final String assignedToId; // Student ID or Lecturer ID
  final String assignedBy;
  final String priority; // 'Low' | 'Medium' | 'High' | 'low' | 'medium' | 'high'
  final String startDate; // YYYY-MM-DD
  final String dueDate; // YYYY-MM-DD
  final String createdDate; // ISO string
  final String status; // 'Draft' | 'Published' | 'Closed' | 'pending' | 'in_progress' | 'completed' | 'overdue'
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
    this.description = '',
    this.instructions = '',
    String? moduleId,
    String? subjectCode,
    this.subjectName,
    this.subjectDocId,
    this.assignedToType = 'subject_students',
    this.assignedToDocId = '',
    this.assignedToName = '',
    this.assignedToEmail = '',
    this.assignedToId = '',
    required this.assignedBy,
    this.priority = 'Medium',
    required this.startDate,
    required this.dueDate,
    required this.createdDate,
    this.status = 'Published',
    this.lecturerId,
    this.lecturerName,
    this.assignedStudents = const ['ALL'],
    this.attachmentUrl,
    this.completedAt,
    this.completedBy,
  })  : moduleId = moduleId ?? subjectCode ?? '',
        subjectCode = subjectCode ?? moduleId;

  // Convenience & lifecycle getters
  bool get isDraft => status.toLowerCase() == 'draft';
  bool get isPublished => status.toLowerCase() == 'published';
  bool get isClosed => status.toLowerCase() == 'closed';
  bool get isCompleted => effectiveStatus == 'completed';
  bool get isOverdue => effectiveStatus == 'overdue';

  /// Computed dynamic status:
  /// If status is 'completed' or 'deactivated', keep it. (Completed tasks NEVER become overdue!)
  /// If incomplete ('pending' or 'in_progress' or 'published') and today is after dueDate, return 'overdue'.
  String get effectiveStatus {
    final s = status.toLowerCase();
    if (s == 'completed' || s == 'deactivated') {
      return 'completed';
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
    if (s == 'in_progress' || s == 'inprogress') return 'in_progress';
    if (s == 'draft') return 'draft';
    if (s == 'closed') return 'closed';
    return 'pending';
  }

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'title': title,
      'description': description,
      'instructions': instructions,
      'moduleId': moduleId,
      'subjectCode': moduleId,
      'subjectName': subjectName,
      'subjectDocId': subjectDocId,
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
      'lecturerId': lecturerId,
      'lecturerName': lecturerName,
      'assignedStudents': assignedStudents,
      'attachmentUrl': attachmentUrl,
      'attachment': attachmentUrl,
      'completedAt': completedAt,
      'completedBy': completedBy,
    };
  }

  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final mod = data['moduleId'] ?? data['subjectCode'] ?? '';

    return TaskModel(
      docId: doc.id,
      taskId: data['taskId'] ?? doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      instructions: data['instructions'] ?? '',
      moduleId: mod,
      subjectCode: mod,
      subjectName: data['subjectName'],
      subjectDocId: data['subjectDocId'],
      assignedToType: data['assignedToType'] ?? 'subject_students',
      assignedToDocId: data['assignedToDocId'] ?? '',
      assignedToName: data['assignedToName'] ?? '',
      assignedToEmail: data['assignedToEmail'] ?? '',
      assignedToId: data['assignedToId'] ?? '',
      assignedBy: data['assignedBy'] ?? 'Lecturer',
      priority: data['priority'] ?? 'Medium',
      startDate: data['startDate'] ?? '',
      dueDate: data['dueDate'] ?? '',
      createdDate: data['createdDate'] ?? '',
      status: data['status'] ?? 'Published',
      lecturerId: data['lecturerId'],
      lecturerName: data['lecturerName'],
      assignedStudents: List<String>.from(data['assignedStudents'] ?? ['ALL']),
      attachmentUrl: data['attachment'] ?? data['attachmentUrl'],
      completedAt: data['completedAt'],
      completedBy: data['completedBy'],
    );
  }

  factory TaskModel.fromMap(Map<String, dynamic> map, {String? id}) {
    final mod = map['moduleId'] ?? map['subjectCode'] ?? '';
    return TaskModel(
      docId: id,
      taskId: map['taskId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      instructions: map['instructions'] ?? '',
      moduleId: mod,
      subjectCode: mod,
      subjectName: map['subjectName'],
      subjectDocId: map['subjectDocId'],
      assignedToType: map['assignedToType'] ?? 'subject_students',
      assignedToDocId: map['assignedToDocId'] ?? '',
      assignedToName: map['assignedToName'] ?? '',
      assignedToEmail: map['assignedToEmail'] ?? '',
      assignedToId: map['assignedToId'] ?? '',
      assignedBy: map['assignedBy'] ?? 'Lecturer',
      priority: map['priority'] ?? 'Medium',
      startDate: map['startDate'] ?? '',
      dueDate: map['dueDate'] ?? '',
      createdDate: map['createdDate'] ?? '',
      status: map['status'] ?? 'Published',
      lecturerId: map['lecturerId'],
      lecturerName: map['lecturerName'],
      assignedStudents: List<String>.from(map['assignedStudents'] ?? ['ALL']),
      attachmentUrl: map['attachment'] ?? map['attachmentUrl'],
      completedAt: map['completedAt'],
      completedBy: map['completedBy'],
    );
  }
}
