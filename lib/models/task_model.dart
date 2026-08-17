import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String? docId;
  final String taskId;
  final String title;
  final String description;
  final String assignedToType; // 'student' | 'lecturer'
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

  TaskModel({
    this.docId,
    required this.taskId,
    required this.title,
    required this.description,
    required this.assignedToType,
    required this.assignedToDocId,
    required this.assignedToName,
    required this.assignedToEmail,
    required this.assignedToId,
    required this.assignedBy,
    required this.priority,
    required this.startDate,
    required this.dueDate,
    required this.createdDate,
    this.status = 'pending',
  });

  /// Computed dynamic status:
  /// If status is 'completed' or 'deactivated', keep it.
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
    );
  }

  TaskModel copyWith({
    String? docId,
    String? taskId,
    String? title,
    String? description,
    String? assignedToType,
    String? assignedToDocId,
    String? assignedToName,
    String? assignedToEmail,
    String? assignedToId,
    String? assignedBy,
    String? priority,
    String? startDate,
    String? dueDate,
    String? createdDate,
    String? status,
  }) {
    return TaskModel(
      docId: docId ?? this.docId,
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      description: description ?? this.description,
      assignedToType: assignedToType ?? this.assignedToType,
      assignedToDocId: assignedToDocId ?? this.assignedToDocId,
      assignedToName: assignedToName ?? this.assignedToName,
      assignedToEmail: assignedToEmail ?? this.assignedToEmail,
      assignedToId: assignedToId ?? this.assignedToId,
      assignedBy: assignedBy ?? this.assignedBy,
      priority: priority ?? this.priority,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
      createdDate: createdDate ?? this.createdDate,
      status: status ?? this.status,
    );
  }
}
