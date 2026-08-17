import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/task_model.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _tasksRef =>
      _firestore.collection('tasks');

  /// Real-time stream of all tasks ordered by createdDate descending
  Stream<List<TaskModel>> getTasksStream() {
    return _tasksRef
        .orderBy('createdDate', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => TaskModel.fromFirestore(d)).toList());
  }

  /// Real-time stream of tasks assigned to a specific user email
  Stream<List<TaskModel>> getUserTasksStream(String email) {
    final cleanEmail = email.trim().toLowerCase();
    return _tasksRef
        .where('assignedToEmail', isEqualTo: cleanEmail)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((d) => TaskModel.fromFirestore(d)).toList();
          list.sort((a, b) => b.createdDate.compareTo(a.createdDate));
          return list;
        });
  }

  /// Auto-generate next task ID (e.g. TSK-1001, TSK-1002)
  Future<String> generateNextTaskId() async {
    try {
      final snap = await _tasksRef.get();
      if (snap.docs.isEmpty) {
        return 'TSK-1001';
      }

      int maxNum = 1000;
      for (var doc in snap.docs) {
        final data = doc.data();
        final rawId = data['taskId']?.toString() ?? '';
        final match = RegExp(r'TSK-(\d+)').firstMatch(rawId);
        if (match != null) {
          final numVal = int.tryParse(match.group(1) ?? '0') ?? 0;
          if (numVal > maxNum) {
            maxNum = numVal;
          }
        }
      }
      return 'TSK-${maxNum + 1}';
    } catch (e) {
      debugPrint('Error generating next taskId: $e');
      return 'TSK-1001';
    }
  }

  /// Add a new task to Firestore
  Future<void> addTask(TaskModel task) async {
    try {
      final docRef = await _tasksRef.add(task.toMap());
      debugPrint('Task added with ID: ${docRef.id}');
    } catch (e) {
      debugPrint('Error adding task: $e');
      throw Exception('Failed to create task: $e');
    }
  }

  /// Update an existing task
  Future<void> updateTask(TaskModel task) async {
    if (task.docId == null) return;
    try {
      await _tasksRef.doc(task.docId).update(task.toMap());
      debugPrint('Task updated: ${task.docId}');
    } catch (e) {
      debugPrint('Error updating task: $e');
      throw Exception('Failed to update task: $e');
    }
  }

  /// Update only the status field
  Future<void> updateTaskStatus(String docId, String newStatus) async {
    try {
      await _tasksRef.doc(docId).update({'status': newStatus.toLowerCase()});
      debugPrint('Task $docId status -> $newStatus');
    } catch (e) {
      debugPrint('Error updating task status: $e');
      throw Exception('Failed to update task status: $e');
    }
  }

  /// Soft deactivate task
  Future<void> deactivateTask(String docId) async {
    try {
      await _tasksRef.doc(docId).update({'status': 'deactivated'});
      debugPrint('Task $docId deactivated');
    } catch (e) {
      debugPrint('Error deactivating task: $e');
      throw Exception('Failed to deactivate task: $e');
    }
  }

  /// Reactivate task
  Future<void> reactivateTask(String docId) async {
    try {
      await _tasksRef.doc(docId).update({'status': 'pending'});
      debugPrint('Task $docId reactivated');
    } catch (e) {
      debugPrint('Error reactivating task: $e');
      throw Exception('Failed to reactivate task: $e');
    }
  }
}
