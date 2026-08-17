import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';

class UserTasksScreen extends StatefulWidget {
  final String userEmail;
  final String userName;
  final String userRole; // 'Student' | 'Lecturer'

  const UserTasksScreen({
    super.key,
    required this.userEmail,
    required this.userName,
    required this.userRole,
  });

  @override
  State<UserTasksScreen> createState() => _UserTasksScreenState();
}

class _UserTasksScreenState extends State<UserTasksScreen> {
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
            content: Text('Task updated to ${_formatStatusLabel(newStatus)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update task status: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'My Tasks (${widget.userRole})',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<List<TaskModel>>(
        stream: _taskService.getUserTasksStream(widget.userEmail),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading tasks: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
          }

          // Filter out deactivated tasks for user portal
          final tasks = snapshot.data!.where((t) => t.status.toLowerCase() != 'deactivated').toList();

          if (tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.task_alt_rounded, size: 64, color: Colors.white24),
                  const SizedBox(height: 16),
                  const Text(
                    'No tasks assigned to you yet!',
                    style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tasks assigned by administration will appear here.',
                    style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 13),
                  ),
                ],
              ),
            );
          }

          final completedCount = tasks.where((t) => t.status.toLowerCase() == 'completed').length;
          final pendingCount = tasks.where((t) => t.effectiveStatus == 'pending').length;
          final inProgressCount = tasks.where((t) => t.effectiveStatus == 'in_progress').length;
          final overdueCount = tasks.where((t) => t.effectiveStatus == 'overdue').length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF3730A3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem('Total', '${tasks.length}', Colors.white),
                    _buildSummaryItem('Pending', '$pendingCount', Colors.amberAccent),
                    _buildSummaryItem('In Progress', '$inProgressCount', Colors.cyanAccent),
                    _buildSummaryItem('Done', '$completedCount', Colors.greenAccent),
                    if (overdueCount > 0)
                      _buildSummaryItem('Overdue', '$overdueCount', Colors.redAccent),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Tasks List
              ...tasks.map((task) => _buildUserTaskCard(task)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildUserTaskCard(TaskModel task) {
    final effectiveStatus = task.effectiveStatus;
    final priority = task.priority.toLowerCase();
    final isCompleted = task.status.toLowerCase() == 'completed';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: effectiveStatus == 'overdue'
              ? Colors.redAccent.withAlpha(100)
              : Colors.white10,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Task ID + Priority Badge + Status Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    task.taskId,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _priorityColor(priority).withAlpha(30),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _priorityColor(priority).withAlpha(100)),
                  ),
                  child: Text(
                    priority.toUpperCase(),
                    style: TextStyle(
                      color: _priorityColor(priority),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor(effectiveStatus).withAlpha(30),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _statusColor(effectiveStatus).withAlpha(100)),
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
            const SizedBox(height: 12),

            // Title
            Text(
              task.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),

            // Description
            if (task.description.isNotEmpty) ...[
              Text(
                task.description,
                style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 10),
            ],

            // Schedule & Assigned By
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.admin_panel_settings_rounded, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'By: ${task.assignedBy}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      Icons.alarm_rounded,
                      size: 14,
                      color: effectiveStatus == 'overdue' ? Colors.redAccent : Colors.orangeAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Due: ${_displayDate(task.dueDate)}',
                      style: TextStyle(
                        color: effectiveStatus == 'overdue' ? Colors.redAccent : Colors.white70,
                        fontSize: 12,
                        fontWeight: effectiveStatus == 'overdue' ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 8),

            // User Progression Workflow Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isCompleted && task.status.toLowerCase() != 'in_progress')
                  TextButton.icon(
                    onPressed: () => _updateStatus(task, 'in_progress'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.lightBlueAccent,
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: const Text('Start Task', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                if (!isCompleted)
                  ElevatedButton.icon(
                    onPressed: () => _updateStatus(task, 'completed'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    icon: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                    label: const Text(
                      'Complete',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                if (isCompleted)
                  const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Completed',
                        style: TextStyle(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
