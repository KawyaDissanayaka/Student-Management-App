import 'package:flutter/material.dart';
import '../../models/task_model.dart';
import '../../services/task_service.dart';
import 'add_edit_task_screen.dart';
import 'task_detail_screen.dart';

class TasksListScreen extends StatefulWidget {
  const TasksListScreen({super.key});

  @override
  State<TasksListScreen> createState() => _TasksListScreenState();
}

class _TasksListScreenState extends State<TasksListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TaskService _taskService = TaskService();

  String _searchQuery = '';
  String _filterPriority = 'All';
  String _filterStatus = 'All';
  String _filterAssignedRole = 'All';
  String _filterDueDate = 'All';

  final List<String> _priorityOptions = ['All', 'low', 'medium', 'high', 'urgent'];
  final List<String> _statusOptions = ['All', 'pending', 'in_progress', 'completed', 'overdue', 'deactivated'];
  final List<String> _roleOptions = ['All', 'student', 'lecturer'];
  final List<String> _dueDateOptions = ['All', 'Overdue', 'Due Today', 'Due This Week'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

  bool _matchesDueDateFilter(TaskModel task, String filter) {
    if (filter == 'All') return true;
    if (task.dueDate.isEmpty) return false;

    try {
      final due = DateTime.parse(task.dueDate);
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

      if (filter == 'Overdue') {
        return task.effectiveStatus == 'overdue';
      }
      if (filter == 'Due Today') {
        return due.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
            due.isBefore(todayEnd.add(const Duration(seconds: 1)));
      }
      if (filter == 'Due This Week') {
        final weekEnd = todayStart.add(const Duration(days: 7));
        return due.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
            due.isBefore(weekEnd);
      }
    } catch (_) {}
    return true;
  }

  List<TaskModel> _applyFilters(List<TaskModel> all) {
    return all.where((t) {
      final q = _searchQuery.toLowerCase();
      final matchSearch = q.isEmpty ||
          t.taskId.toLowerCase().contains(q) ||
          t.title.toLowerCase().contains(q) ||
          t.assignedToName.toLowerCase().contains(q) ||
          t.assignedToEmail.toLowerCase().contains(q) ||
          t.assignedToId.toLowerCase().contains(q);

      final effectiveStatus = t.effectiveStatus;
      final matchStatus = _filterStatus == 'All' ||
          (_filterStatus == 'overdue' ? effectiveStatus == 'overdue' : t.status == _filterStatus);

      final matchPriority = _filterPriority == 'All' || t.priority.toLowerCase() == _filterPriority.toLowerCase();
      final matchRole = _filterAssignedRole == 'All' || t.assignedToType.toLowerCase() == _filterAssignedRole.toLowerCase();
      final matchDueDate = _matchesDueDateFilter(t, _filterDueDate);

      return matchSearch && matchStatus && matchPriority && matchRole && matchDueDate;
    }).toList();
  }

  void _showFilterSheet() {
    String tempPriority = _filterPriority;
    String tempStatus = _filterStatus;
    String tempRole = _filterAssignedRole;
    String tempDue = _filterDueDate;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheet) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Filter Tasks',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildFilterDropdown(
                'Priority',
                tempPriority,
                _priorityOptions,
                (v) => setSheet(() => tempPriority = v!),
              ),
              const SizedBox(height: 12),
              _buildFilterDropdown(
                'Status',
                tempStatus,
                _statusOptions,
                (v) => setSheet(() => tempStatus = v!),
              ),
              const SizedBox(height: 12),
              _buildFilterDropdown(
                'Assigned Role',
                tempRole,
                _roleOptions,
                (v) => setSheet(() => tempRole = v!),
              ),
              const SizedBox(height: 12),
              _buildFilterDropdown(
                'Due Date Window',
                tempDue,
                _dueDateOptions,
                (v) => setSheet(() => tempDue = v!),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _filterPriority = 'All';
                          _filterStatus = 'All';
                          _filterAssignedRole = 'All';
                          _filterDueDate = 'All';
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Reset', style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _filterPriority = tempPriority;
                          _filterStatus = tempStatus;
                          _filterAssignedRole = tempRole;
                          _filterDueDate = tempDue;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text(
                        'Apply Filters',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String currentVal,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentVal,
              isExpanded: true,
              dropdownColor: const Color(0xFF1E293B),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              items: options
                  .map((opt) => DropdownMenuItem(
                        value: opt,
                        child: Text(_formatStatusLabel(opt)),
                      ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _toggleDeactivate(TaskModel task) async {
    final isDeactivated = task.status.toLowerCase() == 'deactivated';
    try {
      if (isDeactivated) {
        await _taskService.reactivateTask(task.docId!);
      } else {
        await _taskService.deactivateTask(task.docId!);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task ${isDeactivated ? "reactivated" : "deactivated"}.'),
            backgroundColor: isDeactivated ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
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
        title: const Text(
          'Task Management',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Colors.white70),
            tooltip: 'Filter Tasks',
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.add_task_rounded, color: Colors.white),
        label: const Text('Add Task', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEditTaskScreen()),
          );
        },
      ),
      body: StreamBuilder<List<TaskModel>>(
        stream: _taskService.getTasksStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading tasks: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
          }

          final allTasks = snapshot.data!;
          final filteredTasks = _applyFilters(allTasks);

          // Statistics Calculations
          final totalTasks = allTasks.length;
          final activeTasks = allTasks.where((t) => t.status != 'deactivated').toList();
          final pendingCount = activeTasks.where((t) => t.effectiveStatus == 'pending').length;
          final inProgressCount = activeTasks.where((t) => t.effectiveStatus == 'in_progress').length;
          final completedCount = activeTasks.where((t) => t.status == 'completed').length;
          final overdueCount = activeTasks.where((t) => t.effectiveStatus == 'overdue').length;

          // Completion Rate Formula: Completed / Total Active Tasks * 100
          final double completionRate = activeTasks.isNotEmpty
              ? (completedCount / activeTasks.length) * 100
              : 0.0;

          return CustomScrollView(
            slivers: [
              // 1. Statistics Cards Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    children: [
                      // Top Row Stats
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard('Total Tasks', '$totalTasks', Icons.assignment_rounded, Colors.indigoAccent),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatCard('Completed', '$completedCount', Icons.check_circle_rounded, Colors.greenAccent),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatCard('Rate', '${completionRate.toStringAsFixed(0)}%', Icons.pie_chart_rounded, Colors.cyanAccent),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Bottom Row Stats
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard('Pending', '$pendingCount', Icons.hourglass_top_rounded, Colors.amberAccent),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatCard('In Progress', '$inProgressCount', Icons.trending_up_rounded, Colors.lightBlueAccent),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatCard('Overdue', '$overdueCount', Icons.warning_amber_rounded, Colors.redAccent),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Search & Active Filters
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search Bar
                      TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search by Task ID, Title, User...',
                          hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                          prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, color: Colors.white54, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: const Color(0xFF1E293B),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Filter Status indicator row
                      if (_filterPriority != 'All' || _filterStatus != 'All' || _filterAssignedRole != 'All' || _filterDueDate != 'All')
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              if (_filterPriority != 'All')
                                _buildFilterChip('Priority: ${_formatStatusLabel(_filterPriority)}', () {
                                  setState(() => _filterPriority = 'All');
                                }),
                              if (_filterStatus != 'All')
                                _buildFilterChip('Status: ${_formatStatusLabel(_filterStatus)}', () {
                                  setState(() => _filterStatus = 'All');
                                }),
                              if (_filterAssignedRole != 'All')
                                _buildFilterChip('Role: ${_formatStatusLabel(_filterAssignedRole)}', () {
                                  setState(() => _filterAssignedRole = 'All');
                                }),
                              if (_filterDueDate != 'All')
                                _buildFilterChip('Due: $_filterDueDate', () {
                                  setState(() => _filterDueDate = 'All');
                                }),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _filterPriority = 'All';
                                    _filterStatus = 'All';
                                    _filterAssignedRole = 'All';
                                    _filterDueDate = 'All';
                                  });
                                },
                                child: const Text('Clear All', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // 3. Task List
              filteredTasks.isEmpty
                  ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.task_alt_rounded, size: 64, color: Colors.white24),
                            const SizedBox(height: 12),
                            Text(
                              allTasks.isEmpty ? 'No tasks created yet.' : 'No tasks match your filter.',
                              style: const TextStyle(color: Colors.white60, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final task = filteredTasks[index];
                            return _buildTaskCard(task);
                          },
                          childCount: filteredTasks.length,
                        ),
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600),
              ),
              Icon(icon, size: 15, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      child: Chip(
        label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
        backgroundColor: const Color(0xFF334155),
        deleteIcon: const Icon(Icons.close_rounded, size: 14, color: Colors.white70),
        onDeleted: onRemove,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    final effectiveStatus = task.effectiveStatus;
    final priority = task.priority.toLowerCase();
    final isDeactivated = task.status.toLowerCase() == 'deactivated';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: effectiveStatus == 'overdue'
              ? Colors.redAccent.withAlpha(80)
              : Colors.white10,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (task.docId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TaskDetailScreen(taskDocId: task.docId!)),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Task ID + Priority Badge + Status Badge
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
              const SizedBox(height: 10),

              // Title
              Text(
                task.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Assigned To Info Row
              Row(
                children: [
                  Icon(
                    task.assignedToType.toLowerCase() == 'student'
                        ? Icons.school_rounded
                        : Icons.cast_for_education_rounded,
                    size: 16,
                    color: task.assignedToType.toLowerCase() == 'student'
                        ? Colors.tealAccent
                        : Colors.amberAccent,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${task.assignedToName} (${task.assignedToType.toUpperCase()})',
                      style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Dates Row (Created & Due Date)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.date_range_rounded, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Start: ${_displayDate(task.startDate)}',
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

              // Actions Row (View, Edit, Deactivate/Reactivate)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      if (task.docId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => TaskDetailScreen(taskDocId: task.docId!)),
                        );
                      }
                    },
                    icon: const Icon(Icons.visibility_rounded, size: 16, color: Colors.cyanAccent),
                    label: const Text('View', style: TextStyle(color: Colors.cyanAccent, fontSize: 13)),
                  ),
                  const SizedBox(width: 4),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddEditTaskScreen(existingTask: task)),
                      );
                    },
                    icon: const Icon(Icons.edit_rounded, size: 16, color: Colors.white70),
                    label: const Text('Edit', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ),
                  const SizedBox(width: 4),
                  TextButton.icon(
                    onPressed: () => _toggleDeactivate(task),
                    icon: Icon(
                      isDeactivated ? Icons.restore_rounded : Icons.block_rounded,
                      size: 16,
                      color: isDeactivated ? Colors.greenAccent : Colors.redAccent,
                    ),
                    label: Text(
                      isDeactivated ? 'Reactivate' : 'Deactivate',
                      style: TextStyle(
                        color: isDeactivated ? Colors.greenAccent : Colors.redAccent,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
