import 'package:flutter/material.dart';
import '../../models/module_registration_period_model.dart';
import '../../models/student_module_registration_model.dart';
import '../../models/subject_model.dart';
import '../../services/student_module_registration_service.dart';

class StudentModuleRegistrationScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const StudentModuleRegistrationScreen({super.key, this.userData});

  @override
  State<StudentModuleRegistrationScreen> createState() => _StudentModuleRegistrationScreenState();
}

class _StudentModuleRegistrationScreenState extends State<StudentModuleRegistrationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final StudentModuleRegistrationService _regService = StudentModuleRegistrationService();

  final Set<String> _selectedModuleCodes = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── REVIEW SELECTION & CONFIRM MODAL ───────────────────────────────────────
  void _showReviewModal({
    required ModuleRegistrationPeriodModel period,
    required List<SubjectModel> allOfferedSubjects,
    required List<StudentModuleRegistrationModel> existingRegistrations,
  }) {
    final selectedSubjects = allOfferedSubjects.where((s) => _selectedModuleCodes.contains(s.subjectCode)).toList();
    final totalCredits = selectedSubjects.fold(0, (acc, s) => acc + s.credits);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.checklist_rounded, color: Colors.tealAccent),
                      SizedBox(width: 8),
                      Text('Review Module Selection', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 12),

              // Summary KPI box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.teal.withAlpha(50)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('Modules Selected', style: TextStyle(color: Colors.grey, fontSize: 11)),
                        Text('${selectedSubjects.length} of ${period.maximumModules}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    Container(width: 1, height: 28, color: Colors.white12),
                    Column(
                      children: [
                        const Text('Total Credits', style: TextStyle(color: Colors.grey, fontSize: 11)),
                        Text('$totalCredits Credits', style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    Container(width: 1, height: 28, color: Colors.white12),
                    Column(
                      children: [
                        const Text('Allowed Range', style: TextStyle(color: Colors.grey, fontSize: 11)),
                        Text('${period.minimumCredits} - ${period.maximumCredits}', style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              const Text('Selected Curriculum Modules:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              // Modules List Container
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView(
                  shrinkWrap: true,
                  children: selectedSubjects.map((sub) {
                    final type = period.offeredModuleTypes[sub.subjectCode] ?? 'Core';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${sub.subjectCode} - ${sub.subjectName}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                Text('Credits: ${sub.credits} • Type: $type', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: _moduleTypeColor(type).withAlpha(30), borderRadius: BorderRadius.circular(4)),
                            child: Text(type, style: TextStyle(color: _moduleTypeColor(type), fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Confirm and Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting
                      ? null
                      : () async {
                          setModalState(() => _isSubmitting = true);
                          final messenger = ScaffoldMessenger.of(context);
                          final nav = Navigator.of(ctx);

                          final studentId = widget.userData?['studentId'] ?? 'STU-1002';
                          final studentName = widget.userData?['fullName'] ?? widget.userData?['name'] ?? 'Student';
                          final studentEmail = widget.userData?['email'] ?? '';

                          try {
                            await _regService.submitModuleRegistrations(
                              period: period,
                              studentId: studentId,
                              studentName: studentName,
                              studentEmail: studentEmail,
                              selectedSubjects: selectedSubjects,
                              existingRegistrations: existingRegistrations,
                            );

                            nav.pop();
                            setState(() => _selectedModuleCodes.clear());
                            _tabController.animateTo(1); // Switch to Registered tab

                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Successfully registered for ${selectedSubjects.length} modules ($totalCredits Credits)!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            setModalState(() => _isSubmitting = false);
                            final msg = e.toString().replaceAll('Exception: ', '');
                            messenger.showSnackBar(
                              SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  icon: _isSubmitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.verified_rounded, color: Colors.white),
                  label: const Text('Confirm & Save Registrations', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final programme = widget.userData?['course'] ?? widget.userData?['programme'] ?? 'All';
    final batch = widget.userData?['batch'] ?? '2026';
    final studentId = widget.userData?['studentId'] ?? '';
    final studentEmail = widget.userData?['email'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Academic Module Registration', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.tealAccent,
          labelColor: Colors.tealAccent,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: const [
            Tab(text: 'Active Registration', icon: Icon(Icons.add_task_rounded, size: 16)),
            Tab(text: 'My Registered Modules', icon: Icon(Icons.bookmark_added_rounded, size: 16)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ─── TAB 1: ACTIVE REGISTRATION ─────────────────────────────────────
          _buildActiveRegistrationTab(programme, batch, studentId, studentEmail),

          // ─── TAB 2: MY REGISTERED MODULES ───────────────────────────────────
          _buildMyRegisteredModulesTab(studentId, studentEmail),
        ],
      ),
    );
  }

  // ─── 1. ACTIVE REGISTRATION TAB ─────────────────────────────────────────────
  Widget _buildActiveRegistrationTab(String programme, String batch, String studentId, String studentEmail) {
    return StreamBuilder<List<ModuleRegistrationPeriodModel>>(
      stream: _regService.getActiveRegistrationPeriodsStream(
        programme: programme,
        batchId: batch,
      ),
      builder: (context, periodSnapshot) {
        if (periodSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
        }

        final periods = periodSnapshot.data ?? [];
        if (periods.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy_rounded, size: 54, color: Colors.grey.shade600),
                  const SizedBox(height: 14),
                  const Text('No Active Module Registration Period', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text(
                    'Module registration is currently closed for $programme (Batch $batch).\nPlease check back when the academic registration window opens.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }

        final activePeriod = periods.first;

        return StreamBuilder<List<StudentModuleRegistrationModel>>(
          stream: _regService.getStudentRegistrationsStream(
            studentId: studentId,
            studentEmail: studentEmail,
          ),
          builder: (context, studentRegSnapshot) {
            final existingRegistrations = studentRegSnapshot.data ?? [];

            return FutureBuilder<List<SubjectModel>>(
              future: _regService.getOfferedSubjects(activePeriod.offeredModuleCodes),
              builder: (context, subjectsSnapshot) {
                if (subjectsSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
                }

                final offeredSubjects = subjectsSnapshot.data ?? [];

                // Calculate current selected credits
                int selectedCredits = 0;
                for (var s in offeredSubjects) {
                  if (_selectedModuleCodes.contains(s.subjectCode)) {
                    selectedCredits += s.credits;
                  }
                }

                final isOverLimit = selectedCredits > activePeriod.maximumCredits;
                final isUnderMin = selectedCredits < activePeriod.minimumCredits && selectedCredits > 0;

                return Column(
                  children: [
                    // 1. Period Information & Credit Gauge Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      color: const Color(0xFF1E293B),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: Colors.green.withAlpha(40), borderRadius: BorderRadius.circular(4)),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.lock_open_rounded, size: 12, color: Colors.greenAccent),
                                    SizedBox(width: 4),
                                    Text('REGISTRATION OPEN', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 10)),
                                  ],
                                ),
                              ),
                              Text('Deadline: ${activePeriod.registrationEndDate}', style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                            ],
                          ),
                          const SizedBox(height: 8),

                          Text('${activePeriod.programme} • ${activePeriod.semester}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('Academic Year ${activePeriod.academicYear} • Batch ${activePeriod.batchId}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                          const SizedBox(height: 10),

                          // Live Credit Gauge Strip
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isOverLimit ? Colors.redAccent : Colors.teal.withAlpha(50)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Selected Credits', style: TextStyle(color: Colors.grey, fontSize: 10)),
                                    Text(
                                      '$selectedCredits Credits (${_selectedModuleCodes.length} Modules)',
                                      style: TextStyle(
                                        color: isOverLimit ? Colors.redAccent : (selectedCredits >= activePeriod.minimumCredits ? Colors.greenAccent : Colors.tealAccent),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('Required Bounds', style: TextStyle(color: Colors.grey, fontSize: 10)),
                                    Text(
                                      'Min: ${activePeriod.minimumCredits} • Max: ${activePeriod.maximumCredits}',
                                      style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          if (isOverLimit) ...[
                            const SizedBox(height: 6),
                            const Text('⚠️ Selected credits exceed maximum credit limit of this period.', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
                          ] else if (isUnderMin) ...[
                            const SizedBox(height: 6),
                            Text('ℹ️ Please select at least ${activePeriod.minimumCredits} credits to meet minimum graduation criteria.', style: const TextStyle(color: Colors.amberAccent, fontSize: 11)),
                          ],
                        ],
                      ),
                    ),

                    // 2. Offered Modules List
                    Expanded(
                      child: offeredSubjects.isEmpty
                          ? const Center(child: Text('No offered modules linked to this period.', style: TextStyle(color: Colors.grey)))
                          : ListView.builder(
                              padding: const EdgeInsets.only(left: 14, right: 14, top: 10, bottom: 80),
                              itemCount: offeredSubjects.length,
                              itemBuilder: (context, index) {
                                final sub = offeredSubjects[index];
                                final isSelected = _selectedModuleCodes.contains(sub.subjectCode);
                                final isAlreadyRegistered = existingRegistrations.any(
                                  (r) => r.moduleId.toUpperCase() == sub.subjectCode.toUpperCase() && !r.isDropped && !r.isRejected,
                                );
                                final type = activePeriod.offeredModuleTypes[sub.subjectCode] ?? 'Core';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E293B),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isAlreadyRegistered ? Colors.greenAccent.withAlpha(40) : (isSelected ? Colors.tealAccent.withAlpha(80) : Colors.white10),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      if (isAlreadyRegistered)
                                        const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 22)
                                      else
                                        Checkbox(
                                          value: isSelected,
                                          activeColor: Colors.tealAccent,
                                          checkColor: Colors.black,
                                          onChanged: (val) {
                                            setState(() {
                                              if (val == true) {
                                                _selectedModuleCodes.add(sub.subjectCode);
                                              } else {
                                                _selectedModuleCodes.remove(sub.subjectCode);
                                              }
                                            });
                                          },
                                        ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(4)),
                                                  child: Text(sub.subjectCode, style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                                                ),
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(color: _moduleTypeColor(type).withAlpha(30), borderRadius: BorderRadius.circular(4)),
                                                  child: Text(type, style: TextStyle(color: _moduleTypeColor(type), fontSize: 10, fontWeight: FontWeight.bold)),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(sub.subjectName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                            const SizedBox(height: 2),
                                            Text('${sub.credits} Credits • Semester: ${sub.semester}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                          ],
                                        ),
                                      ),
                                      if (isAlreadyRegistered)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: Colors.green.withAlpha(40), borderRadius: BorderRadius.circular(4)),
                                          child: const Text('ENROLLED', style: TextStyle(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),

                    // 3. Review & Submit Button
                    if (_selectedModuleCodes.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(14),
                        color: const Color(0xFF1E293B),
                        child: SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton.icon(
                            onPressed: isOverLimit
                                ? null
                                : () => _showReviewModal(
                                      period: activePeriod,
                                      allOfferedSubjects: offeredSubjects,
                                      existingRegistrations: existingRegistrations,
                                    ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.assignment_turned_in_rounded, color: Colors.white),
                            label: Text('Review & Register (${_selectedModuleCodes.length} Modules)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  // ─── 2. MY REGISTERED MODULES TAB ───────────────────────────────────────────
  Widget _buildMyRegisteredModulesTab(String studentId, String studentEmail) {
    return StreamBuilder<List<StudentModuleRegistrationModel>>(
      stream: _regService.getStudentRegistrationsStream(
        studentId: studentId,
        studentEmail: studentEmail,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
        }

        final registrations = snapshot.data ?? [];
        if (registrations.isEmpty) {
          return const Center(
            child: Text('You have not registered for any modules yet.', style: TextStyle(color: Colors.grey)),
          );
        }

        final totalCredits = registrations.where((r) => !r.isDropped && !r.isRejected).fold(0, (acc, r) => acc + r.credits);

        return ListView(
          padding: const EdgeInsets.all(14),
          children: [
            // Total Registered Tally Strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.teal.withAlpha(50)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Registered Modules', style: TextStyle(color: Colors.grey, fontSize: 11)),
                      Text('${registrations.length} Modules Active', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Enrolled Credits', style: TextStyle(color: Colors.grey, fontSize: 11)),
                      Text('$totalCredits Credits', style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            ...registrations.map((reg) {
              final isDropped = reg.isDropped;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDropped ? Colors.white10 : Colors.greenAccent.withAlpha(40)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(6)),
                      child: Text(reg.moduleId, style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'monospace')),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(reg.moduleName, style: TextStyle(color: isDropped ? Colors.grey : Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('${reg.credits} Credits • ${reg.semester} (${reg.academicYear})', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: _statusColor(reg.status).withAlpha(30), borderRadius: BorderRadius.circular(4)),
                      child: Text(reg.status.toUpperCase(), style: TextStyle(color: _statusColor(reg.status), fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.greenAccent;
      case 'pending':
        return Colors.amberAccent;
      case 'rejected':
      case 'dropped':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  Color _moduleTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'core':
        return Colors.cyanAccent;
      case 'elective':
        return Colors.amberAccent;
      case 'optional':
      default:
        return Colors.purpleAccent;
    }
  }
}
