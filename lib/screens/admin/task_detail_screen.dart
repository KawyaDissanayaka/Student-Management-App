import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/task_model.dart';
import '../../services/task_service.dart';
import 'add_edit_task_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskDocId;

  const TaskDetailScreen({super.key, required this.taskDocId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final TaskService _taskService = TaskService();

  Color _priorityColor(String p) {
    switch (p.toLowerCase()) {
      case 'urgent':
        return Colors.redAccent;
      case 'high':
        return Colors.orangeAccent;
      case 'medium':
        return Colors.amberAccent;
      case 'low':
      default:
        return Colors.cyanAccent;
    }
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'completed':
        return Colors.greenAccent;
      case 'in_progress':
      case 'in progress':
        return Colors.lightBlueAccent;
      case 'overdue':
        return Colors.redAccent;
      case 'deactivated':
        return Colors.grey;
      case 'pending':
      default:
        return Colors.amberAccent;
    }
  }

  String _formatStatusLabel(String s) {
    final clean = s.replaceAll('_', ' ');
    return clean[0].toUpperCase() + clean.substring(1);
  }

  String _displayDate(String isoDate) {
    if (isoDate.isEmpty) return '—';
    try {
      final dt = DateTime.parse(isoDate);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return isoDate;
    }
  }

  Future<void> _updateStatus(TaskModel task, String newStatus) async {
    try {
      await _taskService.updateTaskStatus(task.docId!, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task status updated to ${_formatStatusLabel(newStatus)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeactivate(TaskModel task) async {
    final isDeactivated = task.status.toLowerCase() == 'deactivated';
    final action = isDeactivated ? 'Reactivate' : 'Deactivate';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '$action Task',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          isDeactivated
              ? 'Are you sure you want to reactivate "${task.title}"?'
              : 'Are you sure you want to deactivate "${task.title}"? The task will remain in history but will be inactive.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDeactivated ? Colors.green : Colors.redAccent,
            ),
            child: Text(action, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        if (isDeactivated) {
          await _taskService.reactivateTask(task.docId!);
        } else {
          await _taskService.deactivateTask(task.docId!);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Task ${isDeactivated ? "reactivated" : "deactivated"} successfully.'),
              backgroundColor: isDeactivated ? Colors.green : Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Action failed: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('tasks').doc(widget.taskDocId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: const Color(0xFF0F172A),
            appBar: AppBar(backgroundColor: const Color(0xFF1E293B)),
            body: Center(
              child: Text('Error loading task: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            backgroundColor: const Color(0xFF0F172A),
            appBar: AppBar(backgroundColor: const Color(0xFF1E293B)),
            body: const Center(
              child: CircularProgressIndicator(color: Color(0xFF6366F1)),
            ),
          );
        }

        final task = TaskModel.fromFirestore(snapshot.data!);
        final effectiveStatus = task.effectiveStatus;
        final isDeactivated = task.status.toLowerCase() == 'deactivated';
        final isCompleted = task.status.toLowerCase() == 'completed';
        final priority = task.priority.toLowerCase();

        return Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E293B),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              task.taskId.isNotEmpty ? task.taskId : 'Task Details',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: Colors.white70),
                tooltip: 'Edit Task',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddEditTaskScreen(existingTask: task),
                    ),
                  );
                },
              ),
              IconButton(
                icon: Icon(
                  isDeactivated ? Icons.restore_rounded : Icons.block_rounded,
                  color: isDeactivated ? Colors.greenAccent : Colors.redAccent,
                ),
                tooltip: isDeactivated ? 'Reactivate Task' : 'Deactivate Task',
                onPressed: () => _confirmDeactivate(task),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Main Card Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Priority Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _priorityColor(priority).withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _priorityColor(priority).withAlpha(120)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.flag_rounded, size: 14, color: _priorityColor(priority)),
                              const SizedBox(width: 4),
                              Text(
                                priority.toUpperCase(),
                                style: TextStyle(
                                  color: _priorityColor(priority),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statusColor(effectiveStatus).withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _statusColor(effectiveStatus).withAlpha(120)),
                          ),
                          child: Text(
                            _formatStatusLabel(effectiveStatus),
                            style: TextStyle(
                              color: _statusColor(effectiveStatus),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      task.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.admin_panel_settings_rounded, size: 15, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          'Assigned By: ${task.assignedBy.isNotEmpty ? task.assignedBy : "Admin"}',
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Assigned User Section Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ASSIGNED TO',
                      style: TextStyle(
                        color: Color(0xFF818CF8),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: task.assignedToType.toLowerCase() == 'student'
                              ? const Color(0xFF0D9488).withAlpha(50)
                              : const Color(0xFFD97706).withAlpha(50),
                          child: Icon(
                            task.assignedToType.toLowerCase() == 'student'
                                ? Icons.school_rounded
                                : Icons.cast_for_education_rounded,
                            color: task.assignedToType.toLowerCase() == 'student'
                                ? Colors.tealAccent
                                : Colors.amberAccent,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    task.assignedToName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: task.assignedToType.toLowerCase() == 'student'
                                          ? Colors.teal.withAlpha(50)
                                          : Colors.amber.withAlpha(50),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      task.assignedToType.toUpperCase(),
                                      style: TextStyle(
                                        color: task.assignedToType.toLowerCase() == 'student'
                                            ? Colors.tealAccent
                                            : Colors.amberAccent,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${task.assignedToEmail} ${task.assignedToId.isNotEmpty ? "• ${task.assignedToId}" : ""}',
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Timeline & Schedule Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SCHEDULE & TIMELINE',
                      style: TextStyle(
                        color: Color(0xFF818CF8),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.play_circle_outline_rounded, size: 16, color: Colors.tealAccent),
                                  SizedBox(width: 6),
                                  Text('Start Date', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _displayDate(task.startDate),
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 40, color: Colors.white10),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.alarm_rounded,
                                    size: 16,
                                    color: effectiveStatus == 'overdue' ? Colors.redAccent : Colors.orangeAccent,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Due Date',
                                    style: TextStyle(
                                      color: effectiveStatus == 'overdue' ? Colors.redAccent : Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _displayDate(task.dueDate),
                                style: TextStyle(
                                  color: effectiveStatus == 'overdue' ? Colors.redAccent : Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Created On:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        Text(_displayDate(task.createdDate), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Description Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DESCRIPTION & INSTRUCTIONS',
                      style: TextStyle(
                        color: Color(0xFF818CF8),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      task.description.isNotEmpty ? task.description : 'No description provided.',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Status Workflow Progression Buttons
              if (!isDeactivated) ...[
                const Text(
                  'Quick Actions',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (!isCompleted && task.status.toLowerCase() != 'in_progress')
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _updateStatus(task, 'in_progress'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                          label: const Text(
                            'In Progress',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    if (!isCompleted && task.status.toLowerCase() != 'in_progress')
                      const SizedBox(width: 12),
                    if (!isCompleted)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _updateStatus(task, 'completed'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                          label: const Text(
                            'Complete Task',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    if (isCompleted)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _updateStatus(task, 'pending'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.amberAccent),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.replay_rounded, color: Colors.amberAccent),
                          label: const Text(
                            'Reopen Task',
                            style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }
}
