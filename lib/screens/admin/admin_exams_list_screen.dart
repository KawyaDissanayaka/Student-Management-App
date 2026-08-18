import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/exam_model.dart';
import '../../models/exam_hall_model.dart';
import '../../services/exam_hall_service.dart';

class AdminExamsListScreen extends StatefulWidget {
  const AdminExamsListScreen({super.key});

  @override
  State<AdminExamsListScreen> createState() => _AdminExamsListScreenState();
}

class _AdminExamsListScreenState extends State<AdminExamsListScreen> {
  final ExamHallService _hallService = ExamHallService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  String _typeFilter = 'All'; // 'All', 'Final', 'Midterm', 'Quiz', 'Practical'
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─── ADD / EDIT EXAM MODAL ──────────────────────────────────────────────────
  void _showAddEditExamModal({ExamModel? existingExam}) {
    final formKey = GlobalKey<FormState>();
    final codeController = TextEditingController(text: existingExam?.subjectCode ?? '');
    final nameController = TextEditingController(text: existingExam?.subjectName ?? '');
    final dateController = TextEditingController(text: existingExam?.date ?? '2026-09-15');
    final startController = TextEditingController(text: existingExam?.startTime ?? '09:00 AM');
    final endController = TextEditingController(text: existingExam?.endTime ?? '12:00 PM');
    final studentsController = TextEditingController(text: existingExam != null ? '${existingExam.registeredStudentCount}' : '45');
    final instructionsController = TextEditingController(text: existingExam?.instructions ?? 'Bring Student ID card. Electronic devices prohibited.');

    String selectedType = existingExam?.examType ?? 'Final';
    String selectedSemester = existingExam?.semester ?? 'Semester 1';
    String selectedYear = existingExam?.academicYear ?? '2025/2026';
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
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
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
                          Icon(existingExam == null ? Icons.post_add_rounded : Icons.edit_calendar_rounded, color: Colors.amberAccent),
                          const SizedBox(width: 8),
                          Text(
                            existingExam == null ? 'Schedule New Examination' : 'Edit Examination Details',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Subject Code & Name
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          controller: codeController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('Subject Code (e.g. CS101)', Icons.code_rounded),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: nameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('Subject Name', Icons.book_rounded),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Exam Type & Registered Student Count
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedType,
                          dropdownColor: const Color(0xFF1E293B),
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: _inputDecoration('Exam Type', Icons.assignment_rounded),
                          items: const [
                            DropdownMenuItem(value: 'Final', child: Text('Final Examination')),
                            DropdownMenuItem(value: 'Midterm', child: Text('Midterm Test')),
                            DropdownMenuItem(value: 'In-Class Quiz', child: Text('In-Class Quiz')),
                            DropdownMenuItem(value: 'Practical', child: Text('Practical Lab Exam')),
                          ],
                          onChanged: (val) {
                            if (val != null) setModalState(() => selectedType = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: studentsController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('Registered Students', Icons.groups_rounded),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Required';
                            final n = int.tryParse(val.trim());
                            if (n == null || n < 0) return 'Must be >= 0';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Date, Start Time, End Time
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: dateController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('Date (YYYY-MM-DD)', Icons.calendar_month_rounded),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: startController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('Start Time', Icons.schedule_rounded),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: endController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('End Time', Icons.timer_off_rounded),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Instructions
                  TextFormField(
                    controller: instructionsController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 2,
                    decoration: _inputDecoration('Special Exam Instructions', Icons.info_outline_rounded),
                  ),
                  const SizedBox(height: 20),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setModalState(() => isSaving = true);

                              final count = int.parse(studentsController.text.trim());
                              final docRef = existingExam?.docId != null
                                  ? _firestore.collection('exams').doc(existingExam!.docId)
                                  : _firestore.collection('exams').doc();

                              final examData = {
                                'examId': existingExam?.examId ?? 'EXM-${docRef.id.substring(0, 5).toUpperCase()}',
                                'subjectCode': codeController.text.trim().toUpperCase(),
                                'subjectName': nameController.text.trim(),
                                'examType': selectedType,
                                'date': dateController.text.trim(),
                                'startTime': startController.text.trim(),
                                'endTime': endController.text.trim(),
                                'registeredStudentCount': count,
                                'instructions': instructionsController.text.trim(),
                                'semester': selectedSemester,
                                'academicYear': selectedYear,
                                'status': existingExam?.status ?? 'scheduled',
                                'examHall': existingExam?.examHall ?? 'Not Assigned',
                                if (existingExam?.hallId != null) 'hallId': existingExam!.hallId,
                                if (existingExam?.hallCapacity != null) 'hallCapacity': existingExam!.hallCapacity,
                                'updatedAt': DateTime.now().toIso8601String(),
                              };

                              try {
                                await docRef.set(examData, SetOptions(merge: true));
                                if (context.mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(existingExam == null ? 'Exam scheduled successfully!' : 'Exam details updated!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
                                  );
                                }
                              } finally {
                                setModalState(() => isSaving = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: isSaving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_rounded, color: Colors.white),
                      label: Text(
                        existingExam == null ? 'Save Examination' : 'Update Examination',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── ASSIGN EXAM HALL MODAL (STEP 2 CORE FEATURE) ──────────────────────────
  void _showAssignHallModal(ExamModel exam) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.82,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & Exam Metadata Summary Card
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.meeting_room_rounded, color: Colors.amberAccent, size: 24),
                      SizedBox(width: 8),
                      Text('Assign Examination Hall', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Exam Details Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E293B)]),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.tealAccent.withAlpha(80)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${exam.subjectCode} • ${exam.subjectName}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.amber.withAlpha(30), borderRadius: BorderRadius.circular(4)),
                          child: Text(exam.examType.toUpperCase(), style: const TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded, size: 14, color: Colors.tealAccent),
                        const SizedBox(width: 4),
                        Text(exam.date, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(width: 12),
                        const Icon(Icons.schedule_rounded, size: 14, color: Colors.tealAccent),
                        const SizedBox(width: 4),
                        Text('${exam.startTime} - ${exam.endTime}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.groups_rounded, size: 14, color: Colors.indigoAccent),
                        const SizedBox(width: 4),
                        Text(
                          'Registered Students: ${exam.registeredStudentCount}',
                          style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        if (exam.hallId != null) ...[
                          const SizedBox(width: 12),
                          const Icon(Icons.check_circle_rounded, size: 14, color: Colors.greenAccent),
                          const SizedBox(width: 4),
                          Text('Current: ${exam.examHall}', style: const TextStyle(color: Colors.greenAccent, fontSize: 11)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              const Text('Available Examination Halls (Real-Time Availability):', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),

              // Live Stream of Exam Halls with Real-Time Multi-Factor Conflict & Capacity Check
              Expanded(
                child: StreamBuilder<List<ExamHallModel>>(
                  stream: _hallService.getExamHallsStream(),
                  builder: (context, hallSnapshot) {
                    if (hallSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
                    }

                    final halls = hallSnapshot.data ?? [];

                    if (halls.isEmpty) {
                      return const Center(
                        child: Text('No Examination Halls configured in database.', style: TextStyle(color: Colors.grey)),
                      );
                    }

                    return ListView.builder(
                      itemCount: halls.length,
                      itemBuilder: (context, index) {
                        final hall = halls[index];
                        final isAvailableStatus = hall.isAvailable;
                        final hasSufficientCapacity = hall.capacity >= exam.registeredStudentCount;
                        final isCurrentAssigned = exam.hallId == hall.hallId;

                        return FutureBuilder<String?>(
                          future: _hallService.checkHallConflict(
                            hallId: hall.hallId,
                            examDate: exam.date,
                            startTime: exam.startTime,
                            endTime: exam.endTime,
                            excludeExamDocId: exam.docId,
                          ),
                          builder: (context, conflictSnapshot) {
                            final conflictReason = conflictSnapshot.data;
                            final hasTimeConflict = conflictReason != null;

                            // Final validity check: Available + Sufficient Capacity + No Time Conflict
                            final bool canAssign = isAvailableStatus && hasSufficientCapacity && !hasTimeConflict;

                            Color borderColor = Colors.white10;
                            if (isCurrentAssigned) {
                              borderColor = Colors.greenAccent;
                            } else if (!isAvailableStatus) {
                              borderColor = Colors.redAccent.withAlpha(50);
                            } else if (!hasSufficientCapacity) {
                              borderColor = Colors.orangeAccent.withAlpha(80);
                            } else if (hasTimeConflict) {
                              borderColor = Colors.amberAccent.withAlpha(80);
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isCurrentAssigned ? const Color(0xFF064E3B).withAlpha(40) : const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(4)),
                                              child: Text(hall.hallId, style: const TextStyle(color: Colors.tealAccent, fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                                            ),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(hall.hallName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Status Badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isAvailableStatus ? Colors.green.withAlpha(30) : Colors.red.withAlpha(30),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          hall.status.toUpperCase(),
                                          style: TextStyle(color: isAvailableStatus ? Colors.greenAccent : Colors.redAccent, fontSize: 9, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),

                                  // Location and Capacity info
                                  Row(
                                    children: [
                                      Text('${hall.building} • ${hall.floor}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                      const Spacer(),
                                      Text(
                                        'Capacity: ${hall.capacity} Seats',
                                        style: TextStyle(
                                          color: hasSufficientCapacity ? Colors.white70 : Colors.redAccent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Validation Error Badges / Warnings
                                  if (!isAvailableStatus)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        '⚠️ Hall is currently ${hall.status}. Cannot be assigned to exams.',
                                        style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                                      ),
                                    )
                                  else if (!hasSufficientCapacity)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        '⚠️ Insufficient Capacity: Hall has ${hall.capacity} seats, but exam requires ${exam.registeredStudentCount} seats.',
                                        style: const TextStyle(color: Colors.orangeAccent, fontSize: 11),
                                      ),
                                    )
                                  else if (hasTimeConflict)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        '⚠️ $conflictReason',
                                        style: const TextStyle(color: Colors.amberAccent, fontSize: 11),
                                      ),
                                    ),

                                  const SizedBox(height: 10),

                                  // Action: Assign / Current Assigned Button
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (isCurrentAssigned)
                                        TextButton.icon(
                                          onPressed: () async {
                                            await _hallService.unassignHall(exam.docId!);
                                            if (context.mounted) {
                                              Navigator.pop(ctx);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Hall unassigned successfully.'), backgroundColor: Colors.amber),
                                              );
                                            }
                                          },
                                          icon: const Icon(Icons.remove_circle_outline, size: 14, color: Colors.redAccent),
                                          label: const Text('Unassign Hall', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
                                        ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        onPressed: canAssign && !isCurrentAssigned
                                            ? () async {
                                                try {
                                                  await _hallService.assignHallToExam(
                                                    examDocId: exam.docId!,
                                                    hall: hall,
                                                    registeredStudentCount: exam.registeredStudentCount,
                                                    examDate: exam.date,
                                                    startTime: exam.startTime,
                                                    endTime: exam.endTime,
                                                  );
                                                  if (context.mounted) {
                                                    Navigator.pop(ctx);
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text('Hall "${hall.hallName}" (${hall.hallId}) assigned successfully to ${exam.subjectCode}!'),
                                                        backgroundColor: Colors.green,
                                                      ),
                                                    );
                                                  }
                                                } catch (e) {
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
                                                    );
                                                  }
                                                }
                                              }
                                            : null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isCurrentAssigned ? Colors.green : (canAssign ? Colors.teal : Colors.grey.withAlpha(50)),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        icon: Icon(
                                          isCurrentAssigned ? Icons.check_circle_rounded : Icons.add_task_rounded,
                                          size: 14,
                                          color: isCurrentAssigned || canAssign ? Colors.white : Colors.grey,
                                        ),
                                        label: Text(
                                          isCurrentAssigned ? 'Assigned (Active)' : 'Assign This Hall',
                                          style: TextStyle(
                                            color: isCurrentAssigned || canAssign ? Colors.white : Colors.grey,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteExam(ExamModel exam) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Delete Examination', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Text('Are you sure you want to delete ${exam.subjectCode} (${exam.examType})? This will remove all hall and seat allocations.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _firestore.collection('exams').doc(exam.docId).delete();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Exam deleted successfully.'), backgroundColor: Colors.amber),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
        title: const Row(
          children: [
            Icon(Icons.assignment_turned_in_rounded, color: Colors.amberAccent),
            SizedBox(width: 8),
            Text('Examinations & Hall Assignment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.tealAccent),
            tooltip: 'Schedule Exam',
            onPressed: () => _showAddEditExamModal(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Schedule Exam', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _showAddEditExamModal(),
      ),
      body: StreamBuilder<List<ExamModel>>(
        stream: _hallService.getExamsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
          }

          final allExams = snapshot.data ?? [];

          // Compute Metrics
          final totalExams = allExams.length;
          final assignedExams = allExams.where((e) => e.hallId != null && e.hallId!.isNotEmpty).length;
          final unassignedExams = totalExams - assignedExams;

          // Filter by Type & Search
          final filteredExams = allExams.where((e) {
            final matchesType = _typeFilter == 'All' || e.examType.toLowerCase() == _typeFilter.toLowerCase();
            final matchesSearch = _searchQuery.isEmpty ||
                e.subjectCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                e.subjectName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                e.examHall.toLowerCase().contains(_searchQuery.toLowerCase());
            return matchesType && matchesSearch;
          }).toList();

          return Column(
            children: [
              // KPI Cards Strip
              Container(
                padding: const EdgeInsets.all(14),
                color: const Color(0xFF1E293B),
                child: Row(
                  children: [
                    Expanded(child: _buildMetricCard('Total Exams', '$totalExams', Colors.indigoAccent, Icons.assignment_rounded)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildMetricCard('Hall Assigned', '$assignedExams', Colors.greenAccent, Icons.check_circle_rounded)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildMetricCard('Pending Hall', '$unassignedExams', unassignedExams > 0 ? Colors.orangeAccent : Colors.grey, Icons.pending_actions_rounded)),
                  ],
                ),
              ),

              // Search & Filter
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search by subject code, name, or hall...',
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded, color: Colors.tealAccent, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, color: Colors.grey, size: 18),
                                onPressed: () => setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                }),
                              )
                            : null,
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    ),
                    const SizedBox(height: 8),

                    // Filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['All', 'Final', 'Midterm', 'Quiz', 'Practical'].map((type) {
                          final isSelected = _typeFilter == type;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(type, style: TextStyle(color: isSelected ? Colors.black : Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                              selected: isSelected,
                              selectedColor: Colors.tealAccent,
                              backgroundColor: const Color(0xFF1E293B),
                              onSelected: (selected) {
                                if (selected) setState(() => _typeFilter = type);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              // List of Exams
              Expanded(
                child: filteredExams.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.assignment_turned_in_outlined, size: 54, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(
                              allExams.isEmpty ? 'No examinations scheduled yet.' : 'No exams match filter criteria.',
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                            const SizedBox(height: 12),
                            if (allExams.isEmpty)
                              ElevatedButton.icon(
                                onPressed: () => _showAddEditExamModal(),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                                icon: const Icon(Icons.add_rounded, color: Colors.white),
                                label: const Text('Schedule First Exam', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(left: 14, right: 14, bottom: 80),
                        itemCount: filteredExams.length,
                        itemBuilder: (context, index) {
                          final exam = filteredExams[index];
                          final hasHall = exam.hallId != null && exam.hallId!.isNotEmpty;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: hasHall ? Colors.greenAccent.withAlpha(50) : Colors.orangeAccent.withAlpha(50)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top Row: Code, Type & Actions
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(6)),
                                            child: Text(
                                              exam.subjectCode,
                                              style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: Colors.indigo.withAlpha(40), borderRadius: BorderRadius.circular(4)),
                                            child: Text(
                                              exam.examType,
                                              style: const TextStyle(color: Colors.indigoAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert_rounded, color: Colors.white70, size: 20),
                                        color: const Color(0xFF0F172A),
                                        onSelected: (action) {
                                          if (action == 'assign') {
                                            _showAssignHallModal(exam);
                                          } else if (action == 'edit') {
                                            _showAddEditExamModal(existingExam: exam);
                                          } else if (action == 'delete') {
                                            _confirmDeleteExam(exam);
                                          }
                                        },
                                        itemBuilder: (ctx) => [
                                          const PopupMenuItem(value: 'assign', child: Text('Assign / Change Hall', style: TextStyle(color: Colors.tealAccent))),
                                          const PopupMenuItem(value: 'edit', child: Text('Edit Exam Details', style: TextStyle(color: Colors.white))),
                                          const PopupMenuDivider(),
                                          const PopupMenuItem(value: 'delete', child: Text('Delete Exam', style: TextStyle(color: Colors.redAccent))),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),

                                  // Subject Name
                                  Text(exam.subjectName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                  const SizedBox(height: 8),

                                  // Date & Time
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_month_rounded, size: 14, color: Colors.tealAccent),
                                      const SizedBox(width: 4),
                                      Text(exam.date, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                      const SizedBox(width: 12),
                                      const Icon(Icons.schedule_rounded, size: 14, color: Colors.tealAccent),
                                      const SizedBox(width: 4),
                                      Text('${exam.startTime} - ${exam.endTime}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                      const Spacer(),
                                      Text(
                                        '${exam.registeredStudentCount} Students',
                                        style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // Assigned Hall Card / Button Strip
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F172A),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: hasHall ? Colors.greenAccent.withAlpha(60) : Colors.orangeAccent.withAlpha(60)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          hasHall ? Icons.meeting_room_rounded : Icons.warning_amber_rounded,
                                          size: 16,
                                          color: hasHall ? Colors.greenAccent : Colors.orangeAccent,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                hasHall ? 'Assigned Hall: ${exam.examHall}' : 'No Hall Assigned Yet',
                                                style: TextStyle(
                                                  color: hasHall ? Colors.white : Colors.orangeAccent,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              if (hasHall && exam.hallCapacity != null)
                                                Text('Hall ID: ${exam.hallId} • Capacity: ${exam.hallCapacity} Seats', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                                            ],
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => _showAssignHallModal(exam),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: hasHall ? Colors.teal : Colors.amberAccent,
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                          ),
                                          child: Text(
                                            hasHall ? 'Change Hall' : 'Assign Hall',
                                            style: TextStyle(
                                              color: hasHall ? Colors.white : Colors.black,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 10), overflow: TextOverflow.ellipsis)),
              Icon(icon, size: 12, color: color),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
      prefixIcon: Icon(icon, color: Colors.tealAccent, size: 18),
      filled: true,
      fillColor: const Color(0xFF0F172A),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.tealAccent)),
    );
  }
}
