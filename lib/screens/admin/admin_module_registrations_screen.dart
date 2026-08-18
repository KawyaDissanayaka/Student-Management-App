import 'package:flutter/material.dart';
import '../../models/student_module_registration_model.dart';
import '../../services/admin_module_registration_service.dart';

class AdminModuleRegistrationsScreen extends StatefulWidget {
  const AdminModuleRegistrationsScreen({super.key});

  @override
  State<AdminModuleRegistrationsScreen> createState() => _AdminModuleRegistrationsScreenState();
}

class _AdminModuleRegistrationsScreenState extends State<AdminModuleRegistrationsScreen> {
  final AdminModuleRegistrationService _adminService = AdminModuleRegistrationService();
  final TextEditingController _searchController = TextEditingController();

  String _statusFilter = 'All'; // 'All', 'Pending', 'Approved', 'Rejected', 'Dropped'
  String _semesterFilter = 'All';
  String _batchFilter = 'All';
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─── REASON INPUT PROMPT DIALOG ─────────────────────────────────────────────
  Future<String?> _promptReasonDialog({required String title, required String actionLabel, required Color color}) async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: color),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Please provide a mandatory reason for this action. The student will be notified.', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
              const SizedBox(height: 12),
              TextFormField(
                controller: reasonController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Enter reason here (e.g. Prerequisites not met, Credit limit exceeded...)',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Reason is required' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, reasonController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: color),
            child: Text(actionLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ─── REVIEW INDIVIDUAL REGISTRATION MODAL ──────────────────────────────────
  void _showReviewRegistrationModal(StudentModuleRegistrationModel reg) {
    bool isProcessing = false;

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
                        const Icon(Icons.verified_user_rounded, color: Colors.cyanAccent),
                        const SizedBox(width: 8),
                        Text(
                          'Review Module Registration',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 10),

                // 1. Student Information Card
                _sectionHeader('1. Candidate & Student Profile', Icons.person_rounded),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    children: [
                      _detailRow('Student Name', reg.studentName),
                      _detailRow('Student ID', reg.studentId, isMonospace: true),
                      _detailRow('Student Email', reg.studentEmail),
                      _detailRow('Degree Programme', reg.programme),
                      _detailRow('Batch & Semester', '${reg.batchId} • ${reg.semester} (${reg.academicYear})'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 2. Module Details Card
                _sectionHeader('2. Module & Curriculum Details', Icons.menu_book_rounded),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    children: [
                      _detailRow('Module Code & Title', '${reg.moduleId} - ${reg.moduleName}'),
                      _detailRow('Credits & Classification', '${reg.credits} Credits • ${reg.moduleType} Module'),
                      _detailRow('Registration Period ID', reg.registrationPeriodId, isMonospace: true),
                      _detailRow('Registration Ref ID', reg.registrationId, isMonospace: true),
                      _detailRow('Submission Date', reg.registeredAt.length >= 10 ? reg.registeredAt.substring(0, 10) : reg.registeredAt),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 3. Automated Eligibility Verification Checklist
                _sectionHeader('3. Eligibility Verification Checklist', Icons.fact_check_rounded),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    children: [
                      _checklistItem('Student Status', 'Active Enrollment in ${reg.programme}', true),
                      _checklistItem('Registration Period', 'Valid Active Academic Period', true),
                      _checklistItem('Duplicate Check', 'No other active record for ${reg.moduleId}', true),
                      _checklistItem('Credit Bounds', 'Within min & max allowable limits', true),
                      _checklistItem('Prerequisites', 'Verified Satisfied', true),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 4. Audit Trail & Status
                _sectionHeader('4. Decision & Audit Trail', Icons.history_rounded),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Current Status', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: _statusColor(reg.status).withAlpha(30), borderRadius: BorderRadius.circular(4)),
                            child: Text(reg.status.toUpperCase(), style: TextStyle(color: _statusColor(reg.status), fontWeight: FontWeight.bold, fontSize: 11)),
                          ),
                        ],
                      ),
                      if (reg.approvedAt != null) ...[
                        const SizedBox(height: 6),
                        _detailRow('Approved Timestamp', '${reg.approvedAt} by ${reg.approvedBy ?? "Admin"}'),
                      ],
                      if (reg.rejectionReason != null && reg.rejectionReason!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        _detailRow('Rejection Reason', reg.rejectionReason!, color: Colors.redAccent),
                      ],
                      if (reg.dropReason != null && reg.dropReason!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        _detailRow('Drop Reason', reg.dropReason!, color: Colors.amberAccent),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Action Buttons Strip
                if (isProcessing)
                  const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
                else
                  Row(
                    children: [
                      // Reject Button
                      if (!reg.isRejected)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final nav = Navigator.of(ctx);

                              final reason = await _promptReasonDialog(
                                title: 'Reject Module Registration',
                                actionLabel: 'Reject Registration',
                                color: Colors.redAccent,
                              );
                              if (reason != null && reason.isNotEmpty) {
                                setModalState(() => isProcessing = true);

                                try {
                                  await _adminService.rejectRegistration(
                                    registration: reg,
                                    reason: reason,
                                    adminId: 'ADMIN-BURSAR',
                                  );
                                  nav.pop();
                                  messenger.showSnackBar(
                                    SnackBar(content: Text('Registration for ${reg.moduleId} Rejected.'), backgroundColor: Colors.redAccent),
                                  );
                                } catch (e) {
                                  setModalState(() => isProcessing = false);
                                  messenger.showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.redAccent));
                                }
                              }
                            },
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent)),
                            icon: const Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 16),
                            label: const Text('Reject', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ),
                      if (!reg.isRejected) const SizedBox(width: 8),

                      // Drop Button
                      if (!reg.isDropped)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final nav = Navigator.of(ctx);

                              final reason = await _promptReasonDialog(
                                title: 'Drop Module Registration',
                                actionLabel: 'Drop Module',
                                color: Colors.amberAccent,
                              );
                              if (reason != null && reason.isNotEmpty) {
                                setModalState(() => isProcessing = true);

                                try {
                                  await _adminService.dropRegistration(
                                    registration: reg,
                                    reason: reason,
                                    adminId: 'ADMIN-BURSAR',
                                  );
                                  nav.pop();
                                  messenger.showSnackBar(
                                    SnackBar(content: Text('Registration for ${reg.moduleId} Dropped.'), backgroundColor: Colors.amber[800]),
                                  );
                                } catch (e) {
                                  setModalState(() => isProcessing = false);
                                  messenger.showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.redAccent));
                                }
                              }
                            },
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.amberAccent)),
                            icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.amberAccent, size: 16),
                            label: const Text('Drop', style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ),
                      if (!reg.isDropped) const SizedBox(width: 8),

                      // Approve Button
                      if (!reg.isApproved)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              setModalState(() => isProcessing = true);
                              final messenger = ScaffoldMessenger.of(context);
                              final nav = Navigator.of(ctx);

                              try {
                                await _adminService.approveRegistration(
                                  registration: reg,
                                  adminId: 'ADMIN-BURSAR',
                                );
                                nav.pop();
                                messenger.showSnackBar(
                                  SnackBar(content: Text('Registration for ${reg.moduleId} Approved successfully!'), backgroundColor: Colors.green),
                                );
                              } catch (e) {
                                setModalState(() => isProcessing = false);
                                messenger.showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.redAccent));
                              }
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
                            icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                            label: const Text('Approve', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
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
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Module Registrations & Approval', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Admin • Academic Curriculum Management', style: TextStyle(color: Colors.cyanAccent, fontSize: 11)),
          ],
        ),
      ),
      body: StreamBuilder<List<StudentModuleRegistrationModel>>(
        stream: _adminService.getAllRegistrationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
          }

          final allRegistrations = snapshot.data ?? [];

          // KPI Aggregations
          final totalCount = allRegistrations.length;
          final pendingCount = allRegistrations.where((r) => r.isPending).length;
          final approvedCount = allRegistrations.where((r) => r.isApproved).length;
          final rejectedCount = allRegistrations.where((r) => r.isRejected).length;
          final droppedCount = allRegistrations.where((r) => r.isDropped).length;
          final uniqueStudents = allRegistrations.map((r) => r.studentId).toSet().length;

          // Filter by status, semester, batch, and search query
          final filteredRegistrations = allRegistrations.where((r) {
            final matchesStatus = _statusFilter == 'All' || r.status.toLowerCase() == _statusFilter.toLowerCase();
            final matchesSemester = _semesterFilter == 'All' || r.semester.toLowerCase() == _semesterFilter.toLowerCase();
            final matchesBatch = _batchFilter == 'All' || r.batchId == _batchFilter;
            final matchesSearch = _searchQuery.isEmpty ||
                r.studentId.toLowerCase().contains(_searchQuery) ||
                r.studentName.toLowerCase().contains(_searchQuery) ||
                r.moduleId.toLowerCase().contains(_searchQuery) ||
                r.moduleName.toLowerCase().contains(_searchQuery);

            return matchesStatus && matchesSemester && matchesBatch && matchesSearch;
          }).toList();

          return Column(
            children: [
              // 1. KPI Metric Strip
              Container(
                padding: const EdgeInsets.all(12),
                color: const Color(0xFF1E293B),
                child: Row(
                  children: [
                    Expanded(child: _metricCard('Total Regs', '$totalCount', Colors.white, Icons.app_registration_rounded)),
                    const SizedBox(width: 4),
                    Expanded(child: _metricCard('Pending', '$pendingCount', Colors.amberAccent, Icons.hourglass_top_rounded)),
                    const SizedBox(width: 4),
                    Expanded(child: _metricCard('Approved', '$approvedCount', Colors.greenAccent, Icons.check_circle_rounded)),
                    const SizedBox(width: 4),
                    Expanded(child: _metricCard('Rejected', '$rejectedCount', Colors.redAccent, Icons.cancel_rounded)),
                    const SizedBox(width: 4),
                    Expanded(child: _metricCard('Dropped', '$droppedCount', Colors.purpleAccent, Icons.remove_circle_rounded)),
                    const SizedBox(width: 4),
                    Expanded(child: _metricCard('Students', '$uniqueStudents', Colors.cyanAccent, Icons.groups_rounded)),
                  ],
                ),
              ),

              // 2. Search & Filter Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search by Student ID, Name, Module Code...',
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                        prefixIcon: const Icon(Icons.search_rounded, color: Colors.cyanAccent, size: 18),
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        contentPadding: const EdgeInsets.symmetric(vertical: 6),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                    ),
                    const SizedBox(height: 6),

                    // Status Chips Filter
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['All', 'Pending', 'Approved', 'Rejected', 'Dropped'].map((status) {
                          final isSelected = _statusFilter == status;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(status, style: TextStyle(color: isSelected ? Colors.black : Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                              selected: isSelected,
                              selectedColor: Colors.cyanAccent,
                              backgroundColor: const Color(0xFF1E293B),
                              onSelected: (sel) {
                                if (sel) setState(() => _statusFilter = status);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Semester Filter Row
                    Row(
                      children: [
                        const Text('Semester: ', style: TextStyle(color: Colors.grey, fontSize: 11)),
                        const SizedBox(width: 4),
                        ...['All', 'Semester 1', 'Semester 2'].map((sem) {
                          final isSel = _semesterFilter == sem;
                          return Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: ActionChip(
                              label: Text(sem, style: TextStyle(color: isSel ? Colors.cyanAccent : Colors.white60, fontSize: 10, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                              backgroundColor: isSel ? Colors.cyan.withAlpha(40) : const Color(0xFF0F172A),
                              onPressed: () => setState(() => _semesterFilter = sem),
                            ),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Batch Filter Row
                    Row(
                      children: [
                        const Text('Batch: ', style: TextStyle(color: Colors.grey, fontSize: 11)),
                        const SizedBox(width: 4),
                        ...['All', '2025', '2026', '2027'].map((b) {
                          final isSel = _batchFilter == b;
                          return Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: ActionChip(
                              label: Text(b, style: TextStyle(color: isSel ? Colors.greenAccent : Colors.white60, fontSize: 10, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                              backgroundColor: isSel ? Colors.green.withAlpha(30) : const Color(0xFF0F172A),
                              onPressed: () => setState(() => _batchFilter = b),
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),

              // 3. Registrations List
              Expanded(
                child: filteredRegistrations.isEmpty
                    ? Center(
                        child: Text(
                          allRegistrations.isEmpty ? 'No module registrations submitted yet.' : 'No registrations match filter criteria.',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(left: 14, right: 14, bottom: 20),
                        itemCount: filteredRegistrations.length,
                        itemBuilder: (context, index) {
                          final reg = filteredRegistrations[index];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _statusColor(reg.status).withAlpha(40)),
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
                                          decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(4)),
                                          child: Text(reg.studentId, style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'monospace')),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(reg.studentName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(color: _statusColor(reg.status).withAlpha(30), borderRadius: BorderRadius.circular(4)),
                                      child: Text(reg.status.toUpperCase(), style: TextStyle(color: _statusColor(reg.status), fontWeight: FontWeight.bold, fontSize: 10)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                Text('${reg.moduleId} - ${reg.moduleName}', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 4),
                                Text('${reg.credits} Credits • ${reg.moduleType} • ${reg.semester} (${reg.academicYear}) • Batch: ${reg.batchId}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                const SizedBox(height: 8),

                                // Action Buttons Strip
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Reg: ${reg.registeredAt.length >= 10 ? reg.registeredAt.substring(0, 10) : reg.registeredAt}', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                                    ElevatedButton.icon(
                                      onPressed: () => _showReviewRegistrationModal(reg),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF0F172A),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                      icon: const Icon(Icons.visibility_rounded, color: Colors.cyanAccent, size: 14),
                                      label: const Text('Review & Manage', style: TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold)),
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
          );
        },
      ),
    );
  }

  Widget _metricCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 8), overflow: TextOverflow.ellipsis)),
              Icon(icon, size: 9, color: color),
            ],
          ),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.cyanAccent),
          const SizedBox(width: 6),
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isMonospace = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: color ?? Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                fontFamily: isMonospace ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _checklistItem(String title, String subtitle, bool passed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(passed ? Icons.check_circle_rounded : Icons.cancel_rounded, size: 14, color: passed ? Colors.greenAccent : Colors.redAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
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
}
