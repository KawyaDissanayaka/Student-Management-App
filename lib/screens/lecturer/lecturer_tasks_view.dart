import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/subject_model.dart';
import '../../models/task_model.dart';
import '../../models/enrollment_model.dart';

class LecturerTasksView extends StatefulWidget {
  final SubjectModel subject;
  final String lecturerEmail;
  final String lecturerName;
  final String? lecturerId;

  const LecturerTasksView({
    super.key,
    required this.subject,
    required this.lecturerEmail,
    required this.lecturerName,
    this.lecturerId,
  });

  @override
  State<LecturerTasksView> createState() => _LecturerTasksViewState();
}

class _LecturerTasksViewState extends State<LecturerTasksView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _searchQuery = '';
  String _selectedPriority = 'All';
  String _selectedStatus = 'All';

  final List<String> _priorities = ['All', 'urgent', 'high', 'medium', 'low'];
  final List<String> _statuses = ['All', 'pending', 'in_progress', 'completed', 'overdue'];

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  void _showCreateEditTaskModal(List<EnrollmentModel> activeStudents, {TaskModel? existingTask}) {
    final isEditing = existingTask != null;
    final titleController = TextEditingController(text: existingTask?.title ?? '');
    final descController = TextEditingController(text: existingTask?.description ?? '');

    DateTime startDate = existingTask != null && existingTask.startDate.isNotEmpty
        ? (DateTime.tryParse(existingTask.startDate) ?? DateTime.now())
        : DateTime.now();

    DateTime dueDate = existingTask != null && existingTask.dueDate.isNotEmpty
        ? (DateTime.tryParse(existingTask.dueDate) ?? DateTime.now().add(const Duration(days: 7)))
        : DateTime.now().add(const Duration(days: 7));

    String selectedPriority = existingTask?.priority ?? 'medium';
    String selectedStatus = existingTask?.status ?? 'pending';
    bool assignToAll = existingTask == null || existingTask.assignedStudents.contains('ALL');
    final Set<String> selectedStudentEmails = existingTask != null && !assignToAll
        ? existingTask.assignedStudents.toSet()
        : {};

    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(isEditing ? Icons.edit_calendar_rounded : Icons.add_task_rounded, color: Colors.cyanAccent),
                        const SizedBox(width: 8),
                        Text(
                          isEditing ? 'Edit Subject Task' : 'Assign New Task',
                          style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Subject: ${widget.subject.subjectCode} - ${widget.subject.subjectName}', style: const TextStyle(color: Colors.amberAccent, fontSize: 12)),
                const SizedBox(height: 16),

                // Task Title
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Task Title *',
                    labelStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),

                // Priority & Status Selectors
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedPriority.toLowerCase(),
                        dropdownColor: const Color(0xFF0F172A),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Priority',
                          labelStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'urgent', child: Text('🚨 Urgent', style: TextStyle(color: Colors.redAccent))),
                          DropdownMenuItem(value: 'high', child: Text('🔥 High', style: TextStyle(color: Colors.orangeAccent))),
                          DropdownMenuItem(value: 'medium', child: Text('⚡ Medium', style: TextStyle(color: Colors.cyanAccent))),
                          DropdownMenuItem(value: 'low', child: Text('🌱 Low', style: TextStyle(color: Colors.greenAccent))),
                        ],
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedPriority = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedStatus.toLowerCase(),
                        dropdownColor: const Color(0xFF0F172A),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Status',
                          labelStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'pending', child: Text('Pending', style: TextStyle(color: Colors.orangeAccent))),
                          DropdownMenuItem(value: 'in_progress', child: Text('In Progress', style: TextStyle(color: Colors.cyanAccent))),
                          DropdownMenuItem(value: 'completed', child: Text('Completed', style: TextStyle(color: Colors.greenAccent))),
                          DropdownMenuItem(value: 'deactivated', child: Text('Deactivated', style: TextStyle(color: Colors.grey))),
                        ],
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedStatus = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Start Date & Due Date pickers
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: DateTime(2025, 1, 1),
                            lastDate: DateTime(2030, 12, 31),
                            builder: (context, child) => Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(primary: Colors.tealAccent, onPrimary: Colors.black, surface: Color(0xFF1E293B)),
                              ),
                              child: child!,
                            ),
                          );
                          if (picked != null) setModalState(() => startDate = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white10)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Start Date', style: TextStyle(color: Colors.grey, fontSize: 10)),
                              const SizedBox(height: 4),
                              Text(_formatDate(startDate), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: dueDate,
                            firstDate: DateTime(2025, 1, 1),
                            lastDate: DateTime(2030, 12, 31),
                            builder: (context, child) => Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(primary: Colors.tealAccent, onPrimary: Colors.black, surface: Color(0xFF1E293B)),
                              ),
                              child: child!,
                            ),
                          );
                          if (picked != null) setModalState(() => dueDate = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.cyanAccent.withAlpha(80))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Due Date (Deadline) *', style: TextStyle(color: Colors.cyanAccent, fontSize: 10)),
                              const SizedBox(height: 4),
                              Text(_formatDate(dueDate), style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Description
                TextField(
                  controller: descController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Task Guidelines & Instructions *',
                    labelStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 14),

                // Target Students Selector
                const Text('ASSIGN TASK TO:', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 6),

                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setModalState(() => assignToAll = true),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: assignToAll ? Colors.teal.withAlpha(40) : const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: assignToAll ? Colors.tealAccent : Colors.white10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.groups_rounded, size: 16, color: assignToAll ? Colors.tealAccent : Colors.grey),
                              const SizedBox(width: 6),
                              Text('All Enrolled (${activeStudents.length})', style: TextStyle(color: assignToAll ? Colors.tealAccent : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () => setModalState(() => assignToAll = false),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: !assignToAll ? Colors.cyan.withAlpha(40) : const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: !assignToAll ? Colors.cyanAccent : Colors.white10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_pin_rounded, size: 16, color: !assignToAll ? Colors.cyanAccent : Colors.grey),
                              const SizedBox(width: 6),
                              Text('Select Students (${selectedStudentEmails.length})', style: TextStyle(color: !assignToAll ? Colors.cyanAccent : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Specific Student Checkbox List
                if (!assignToAll) ...[
                  const SizedBox(height: 10),
                  Container(
                    height: 140,
                    decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(10)),
                    child: ListView.builder(
                      itemCount: activeStudents.length,
                      itemBuilder: (context, idx) {
                        final s = activeStudents[idx];
                        final isChecked = selectedStudentEmails.contains(s.studentEmail.toLowerCase());

                        return CheckboxListTile(
                          dense: true,
                          value: isChecked,
                          title: Text(s.studentName, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          subtitle: Text('${s.studentId} • ${s.studentEmail}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                          activeColor: Colors.cyanAccent,
                          checkColor: Colors.black,
                          onChanged: (val) {
                            setModalState(() {
                              if (val == true) {
                                selectedStudentEmails.add(s.studentEmail.toLowerCase());
                              } else {
                                selectedStudentEmails.remove(s.studentEmail.toLowerCase());
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // Save Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final title = titleController.text.trim();
                            final desc = descController.text.trim();

                            if (title.isEmpty || desc.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter task title and guidelines.'), backgroundColor: Colors.redAccent),
                              );
                              return;
                            }

                            // Validate Date: dueDate not before startDate
                            if (dueDate.isBefore(startDate)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Error: Due Date cannot be earlier than Start Date.'), backgroundColor: Colors.redAccent),
                              );
                              return;
                            }

                            if (!assignToAll && selectedStudentEmails.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please select at least one student or choose "All Enrolled".'), backgroundColor: Colors.redAccent),
                              );
                              return;
                            }

                            setModalState(() => isSaving = true);
                            final messenger = ScaffoldMessenger.of(context);
                            final nav = Navigator.of(ctx);

                            try {
                              final taskData = {
                                'taskId': existingTask?.taskId ?? 'TSK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                                'title': title,
                                'description': desc,
                                'assignedToType': 'subject_students',
                                'assignedBy': widget.lecturerName,
                                'lecturerId': widget.lecturerId ?? 'LEC-1001',
                                'lecturerName': widget.lecturerName,
                                'subjectDocId': widget.subject.docId ?? '',
                                'subjectCode': widget.subject.subjectCode,
                                'subjectName': widget.subject.subjectName,
                                'assignedStudents': assignToAll ? ['ALL'] : selectedStudentEmails.toList(),
                                'priority': selectedPriority,
                                'startDate': _formatDate(startDate),
                                'dueDate': _formatDate(dueDate),
                                'createdDate': DateTime.now().toIso8601String(),
                                'status': selectedStatus,
                                'completedAt': selectedStatus == 'completed' ? DateTime.now().toIso8601String() : null,
                              };

                              if (!isEditing) {
                                await _firestore.collection('tasks').add(taskData);
                                messenger.showSnackBar(
                                  SnackBar(content: Text('Task "$title" created and assigned!'), backgroundColor: Colors.green),
                                );
                              } else {
                                await _firestore.collection('tasks').doc(existingTask.docId).update(taskData);
                                messenger.showSnackBar(
                                  SnackBar(content: Text('Task "$title" updated successfully!'), backgroundColor: Colors.green),
                                );
                              }

                              nav.pop();
                            } catch (e) {
                              setModalState(() => isSaving = false);
                              messenger.showSnackBar(
                                SnackBar(content: Text('Failed to save task: $e'), backgroundColor: Colors.redAccent),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan[700], padding: const EdgeInsets.symmetric(vertical: 14)),
                    icon: isSaving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Icon(isEditing ? Icons.save_rounded : Icons.check_circle_rounded, color: Colors.white),
                    label: Text(
                      isEditing ? 'Save Changes' : 'Assign Task to Students',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTaskProgressModal(BuildContext context, TaskModel task, List<EnrollmentModel> allEnrolled) {
    final assignedStudents = task.assignedStudents.contains('ALL')
        ? allEnrolled
        : allEnrolled.where((e) => task.assignedStudents.contains(e.studentEmail.toLowerCase())).toList();

    final isCompleted = task.status.toLowerCase() == 'completed';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('${task.taskId} • Due: ${task.dueDate} • Priority: ${task.priority.toUpperCase()}', style: const TextStyle(color: Colors.cyanAccent, fontSize: 11)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Overall Status: ${task.effectiveStatus.toUpperCase()}',
                      style: TextStyle(
                        color: isCompleted ? Colors.greenAccent : (task.effectiveStatus == 'overdue' ? Colors.redAccent : Colors.cyanAccent),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      )),
                  Text('${assignedStudents.length} Students Assigned', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 14),

            const Text('ASSIGNED STUDENTS LIST', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 8),

            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: assignedStudents.length,
                itemBuilder: (context, idx) {
                  final s = assignedStudents[idx];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.studentName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            Text('${s.studentId} • ${s.studentEmail}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isCompleted ? Colors.green.withAlpha(30) : Colors.cyan.withAlpha(30),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isCompleted ? 'COMPLETED' : 'IN PROGRESS',
                            style: TextStyle(color: isCompleted ? Colors.greenAccent : Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // 1. Fetch Active Enrolled Students for this Subject
      stream: _firestore
          .collection('enrollments')
          .where('subjectCode', isEqualTo: widget.subject.subjectCode)
          .where('status', isEqualTo: 'active')
          .snapshots(),
      builder: (context, enrollSnap) {
        return StreamBuilder<QuerySnapshot>(
          // 2. Fetch Tasks for this Subject
          stream: _firestore
              .collection('tasks')
              .where('subjectCode', isEqualTo: widget.subject.subjectCode)
              .snapshots(),
          builder: (context, taskSnap) {
            if (enrollSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
            }

            final enrollDocs = enrollSnap.data?.docs ?? [];
            final taskDocs = taskSnap.data?.docs ?? [];

            // Deduplicate enrollments
            final Map<String, EnrollmentModel> studentMap = {};
            for (var d in enrollDocs) {
              final e = EnrollmentModel.fromFirestore(d as DocumentSnapshot<Map<String, dynamic>>);
              studentMap[e.studentEmail.toLowerCase()] = e;
            }
            final activeStudents = studentMap.values.toList();

            final allTasks = taskDocs
                .map((d) => TaskModel.fromFirestore(d as DocumentSnapshot<Map<String, dynamic>>))
                .where((t) => t.status.toLowerCase() != 'deactivated')
                .toList();

            // Calculate Task KPI Metrics
            final totalTasks = allTasks.length;
            final completedTasks = allTasks.where((t) => t.status.toLowerCase() == 'completed').length;
            final inProgressTasks = allTasks.where((t) => t.status.toLowerCase() == 'in_progress').length;
            final overdueTasks = allTasks.where((t) => t.effectiveStatus == 'overdue').length;
            final pendingTasks = allTasks.where((t) => t.effectiveStatus == 'pending').length;
            final double completionPct = totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0.0;

            // Filter tasks
            final filteredTasks = allTasks.where((t) {
              final matchesSearch = t.title.toLowerCase().contains(_searchQuery) ||
                  t.description.toLowerCase().contains(_searchQuery) ||
                  t.taskId.toLowerCase().contains(_searchQuery);

              final matchesPriority = _selectedPriority == 'All' || t.priority.toLowerCase() == _selectedPriority.toLowerCase();
              final matchesStatus = _selectedStatus == 'All' || t.effectiveStatus == _selectedStatus.toLowerCase();

              return matchesSearch && matchesPriority && matchesStatus;
            }).toList();

            return Scaffold(
              backgroundColor: Colors.transparent,
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () => _showCreateEditTaskModal(activeStudents),
                backgroundColor: Colors.cyan[700],
                icon: const Icon(Icons.add_task_rounded, color: Colors.white),
                label: const Text('Assign Task', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              body: Column(
                children: [
                  // KPI Dashboard Summary Strip
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: const Color(0xFF1E293B),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildMetricCard('Total Tasks', '$totalTasks', Colors.white, Icons.task_alt_rounded)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildMetricCard('Pending', '$pendingTasks', Colors.orangeAccent, Icons.pending_actions_rounded)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildMetricCard('In Progress', '$inProgressTasks', Colors.cyanAccent, Icons.cached_rounded)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildMetricCard('Completed', '$completedTasks (${completionPct.toStringAsFixed(0)}%)', Colors.greenAccent, Icons.check_circle_rounded)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildMetricCard('Overdue', '$overdueTasks', overdueTasks > 0 ? Colors.redAccent : Colors.grey, Icons.alarm_off_rounded)),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Search Bar
                        TextField(
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Search tasks by title, instructions or ID...',
                            hintStyle: const TextStyle(color: Colors.grey),
                            prefixIcon: const Icon(Icons.search, color: Colors.grey),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                          onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                        ),
                        const SizedBox(height: 10),

                        // Priority & Status Filters
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ..._priorities.map((p) {
                                final isSel = p == _selectedPriority;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ChoiceChip(
                                    label: Text(p == 'All' ? 'ALL PRIORITIES' : p.toUpperCase()),
                                    selected: isSel,
                                    onSelected: (val) {
                                      if (val) setState(() => _selectedPriority = p);
                                    },
                                    selectedColor: Colors.cyan[700],
                                    backgroundColor: const Color(0xFF0F172A),
                                    labelStyle: TextStyle(color: isSel ? Colors.white : Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                                    side: BorderSide(color: isSel ? Colors.cyanAccent : Colors.white10),
                                  ),
                                );
                              }),
                              const SizedBox(width: 10),
                              ..._statuses.map((s) {
                                final isSel = s == _selectedStatus;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ChoiceChip(
                                    label: Text(s == 'All' ? 'ALL STATUS' : s.toUpperCase().replaceAll('_', ' ')),
                                    selected: isSel,
                                    onSelected: (val) {
                                      if (val) setState(() => _selectedStatus = s);
                                    },
                                    selectedColor: Colors.teal,
                                    backgroundColor: const Color(0xFF0F172A),
                                    labelStyle: TextStyle(color: isSel ? Colors.white : Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                                    side: BorderSide(color: isSel ? Colors.tealAccent : Colors.white10),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tasks List
                  Expanded(
                    child: filteredTasks.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.assignment_outlined, size: 56, color: Colors.grey.withAlpha(80)),
                                const SizedBox(height: 12),
                                const Text('No subject tasks found matching filter.', style: TextStyle(color: Colors.grey, fontSize: 14)),
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: () => _showCreateEditTaskModal(activeStudents),
                                  icon: const Icon(Icons.add_rounded, color: Colors.cyanAccent),
                                  label: const Text('Assign First Task', style: TextStyle(color: Colors.cyanAccent)),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredTasks.length,
                            itemBuilder: (context, index) {
                              final t = filteredTasks[index];
                              final effectiveSt = t.effectiveStatus;
                              final isComp = effectiveSt == 'completed';
                              final isOverdue = effectiveSt == 'overdue';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isComp
                                        ? Colors.green.withAlpha(50)
                                        : (isOverdue ? Colors.red.withAlpha(80) : Colors.white10),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(color: Colors.cyan.withAlpha(30), borderRadius: BorderRadius.circular(6)),
                                              child: Text(t.taskId, style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: t.priority.toLowerCase() == 'urgent'
                                                    ? Colors.red.withAlpha(30)
                                                    : (t.priority.toLowerCase() == 'high' ? Colors.orange.withAlpha(30) : Colors.cyan.withAlpha(20)),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                t.priority.toUpperCase(),
                                                style: TextStyle(
                                                  color: t.priority.toLowerCase() == 'urgent'
                                                      ? Colors.redAccent
                                                      : (t.priority.toLowerCase() == 'high' ? Colors.orangeAccent : Colors.cyanAccent),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isComp
                                                ? Colors.green.withAlpha(30)
                                                : (isOverdue ? Colors.red.withAlpha(30) : Colors.orange.withAlpha(30)),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            effectiveSt.toUpperCase().replaceAll('_', ' '),
                                            style: TextStyle(
                                              color: isComp ? Colors.greenAccent : (isOverdue ? Colors.redAccent : Colors.orangeAccent),
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    Text(t.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                    const SizedBox(height: 4),
                                    Text(t.description, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    const SizedBox(height: 8),

                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today_rounded, size: 12, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text('Start: ${t.startDate}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                        const SizedBox(width: 12),
                                        Icon(Icons.alarm_rounded, size: 12, color: isOverdue ? Colors.redAccent : Colors.grey),
                                        const SizedBox(width: 4),
                                        Text('Due: ${t.dueDate}', style: TextStyle(color: isOverdue ? Colors.redAccent : Colors.grey, fontSize: 11, fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal)),
                                        const Spacer(),
                                        Text(
                                          t.assignedStudents.contains('ALL') ? 'All Students (${activeStudents.length})' : '${t.assignedStudents.length} Students',
                                          style: const TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 12),
                                    const Divider(color: Colors.white10, height: 1),
                                    const SizedBox(height: 6),

                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        TextButton.icon(
                                          onPressed: () => _showTaskProgressModal(context, t, activeStudents),
                                          icon: const Icon(Icons.visibility_rounded, size: 16, color: Colors.cyanAccent),
                                          label: const Text('View Student Progress', style: TextStyle(color: Colors.cyanAccent, fontSize: 12)),
                                        ),

                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit_rounded, size: 18, color: Colors.amberAccent),
                                              tooltip: 'Edit Task',
                                              onPressed: () => _showCreateEditTaskModal(activeStudents, existingTask: t),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                isComp ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
                                                size: 18,
                                                color: isComp ? Colors.greenAccent : Colors.grey,
                                              ),
                                              tooltip: isComp ? 'Mark as In Progress' : 'Mark as Completed',
                                              onPressed: () async {
                                                if (t.docId != null) {
                                                  final newSt = isComp ? 'in_progress' : 'completed';
                                                  await _firestore.collection('tasks').doc(t.docId).update({
                                                    'status': newSt,
                                                    'completedAt': newSt == 'completed' ? DateTime.now().toIso8601String() : null,
                                                  });
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMetricCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 9), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
