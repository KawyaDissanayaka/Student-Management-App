import 'package:flutter/material.dart';
import '../../models/exam_model.dart';
import '../../models/exam_registration_model.dart';
import '../../services/exam_registration_service.dart';

class AdminExamRegistrationsScreen extends StatefulWidget {
  final ExamModel? exam;

  const AdminExamRegistrationsScreen({super.key, this.exam});

  @override
  State<AdminExamRegistrationsScreen> createState() => _AdminExamRegistrationsScreenState();
}

class _AdminExamRegistrationsScreenState extends State<AdminExamRegistrationsScreen> {
  final ExamRegistrationService _regService = ExamRegistrationService();
  final TextEditingController _searchController = TextEditingController();

  String _statusFilter = 'All'; // 'All', 'Registered', 'Approved', 'Pending', 'Rejected', 'Cancelled'
  final String _batchFilter = 'All';
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showActionDialog({
    required ExamRegistrationModel registration,
    required String targetStatus,
  }) {
    final reasonController = TextEditingController();
    final isReject = targetStatus == 'Rejected';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isReject ? Icons.cancel_rounded : (targetStatus == 'Approved' ? Icons.check_circle_rounded : Icons.info_rounded),
              color: isReject ? Colors.redAccent : Colors.greenAccent,
            ),
            const SizedBox(width: 8),
            Text(
              '$targetStatus Registration',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Student: ${registration.studentName} (${registration.studentId})',
              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Module: ${registration.subjectCode} • ${registration.registrationId}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 12),
            if (isReject) ...[
              const Text('Reason for Rejection (Optional):', style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 6),
              TextField(
                controller: reasonController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'e.g. Ineligible due to attendance or pending dues',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ] else
              Text(
                'Are you sure you want to mark this registration as $targetStatus?',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _regService.updateRegistrationStatus(
                  regDocId: registration.docId!,
                  newStatus: targetStatus,
                  approvedBy: 'Admin',
                  rejectionReason: isReject && reasonController.text.trim().isNotEmpty ? reasonController.text.trim() : null,
                  examDocId: registration.examDocId,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Registration marked as $targetStatus successfully!'),
                      backgroundColor: isReject ? Colors.redAccent : Colors.green,
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
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isReject ? Colors.redAccent : Colors.teal,
            ),
            child: Text(
              targetStatus,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.exam != null ? 'Exam Registrations' : 'All Exam Registrations',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (widget.exam != null)
              Text(
                '${widget.exam!.subjectCode} • ${widget.exam!.examType} (${widget.exam!.date})',
                style: const TextStyle(color: Colors.amberAccent, fontSize: 11),
              ),
          ],
        ),
      ),
      body: StreamBuilder<List<ExamRegistrationModel>>(
        stream: widget.exam != null
            ? _regService.getRegistrationsForExamStream(widget.exam!.examId, examDocId: widget.exam!.docId)
            : _regService.getAllRegistrationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading registrations: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
          }

          final allRegistrations = snapshot.data ?? [];

          // Compute KPI Metrics
          final totalCount = allRegistrations.length;
          final approvedCount = allRegistrations.where((r) => r.isApprovedOrRegistered).length;
          final pendingCount = allRegistrations.where((r) => r.isPending).length;
          final rejectedCount = allRegistrations.where((r) => r.isRejected).length;

          // Filter by Search, Status, and Batch
          final filtered = allRegistrations.where((r) {
            final matchesStatus = _statusFilter == 'All' || r.status.toLowerCase() == _statusFilter.toLowerCase();
            final matchesBatch = _batchFilter == 'All' || r.batch.toLowerCase() == _batchFilter.toLowerCase();
            final matchesSearch = _searchQuery.isEmpty ||
                r.studentName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                r.studentId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                r.registrationId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                r.subjectCode.toLowerCase().contains(_searchQuery.toLowerCase());
            return matchesStatus && matchesBatch && matchesSearch;
          }).toList();

          return Column(
            children: [
              // 1. KPI Summary Cards Strip
              Container(
                padding: const EdgeInsets.all(12),
                color: const Color(0xFF1E293B),
                child: Row(
                  children: [
                    Expanded(child: _buildMetricMiniCard('Total Reg.', '$totalCount', Colors.indigoAccent, Icons.groups_rounded)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildMetricMiniCard('Confirmed', '$approvedCount', Colors.greenAccent, Icons.verified_rounded)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildMetricMiniCard('Pending', '$pendingCount', pendingCount > 0 ? Colors.amberAccent : Colors.grey, Icons.hourglass_top_rounded)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildMetricMiniCard('Rejected', '$rejectedCount', rejectedCount > 0 ? Colors.redAccent : Colors.grey, Icons.cancel_rounded)),
                  ],
                ),
              ),

              // 2. Search Bar & Filter Chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search by Student Name, ID, or Reg Code...',
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

                    // Filter row: Status & Batch
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ...['All', 'Registered', 'Approved', 'Pending', 'Rejected', 'Cancelled'].map((status) {
                            final isSelected = _statusFilter == status;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(status, style: TextStyle(color: isSelected ? Colors.black : Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                                selected: isSelected,
                                selectedColor: Colors.tealAccent,
                                backgroundColor: const Color(0xFF1E293B),
                                onSelected: (selected) {
                                  if (selected) setState(() => _statusFilter = status);
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Registrations List View
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.person_search_rounded, size: 48, color: Colors.grey),
                            const SizedBox(height: 10),
                            Text(
                              allRegistrations.isEmpty
                                  ? 'No students registered for this examination yet.'
                                  : 'No registrations match filter criteria.',
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(left: 14, right: 14, bottom: 20),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final reg = filtered[index];
                          final isApproved = reg.isApprovedOrRegistered;
                          final isPending = reg.isPending;
                          final isRejected = reg.isRejected;

                          Color statusColor = isApproved ? Colors.greenAccent : (isPending ? Colors.amberAccent : Colors.redAccent);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: isApproved ? Colors.white10 : statusColor.withAlpha(60)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top Row: Reg ID & Status Badge
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(4)),
                                          child: Text(
                                            reg.registrationId,
                                            style: const TextStyle(color: Colors.tealAccent, fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          reg.subjectCode,
                                          style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: statusColor.withAlpha(25),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: statusColor.withAlpha(80)),
                                      ),
                                      child: Text(
                                        reg.status.toUpperCase(),
                                        style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Student Name & ID
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Colors.teal.withAlpha(30),
                                      child: Text(
                                        reg.studentName.isNotEmpty ? reg.studentName[0].toUpperCase() : 'S',
                                        style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(reg.studentName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                          Text('${reg.studentId} • Batch ${reg.batch} • ${reg.studentEmail}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Module & Registered Time
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(reg.subjectName, style: const TextStyle(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis),
                                    ),
                                    Text(
                                      'Reg: ${reg.registeredAt.length >= 10 ? reg.registeredAt.substring(0, 10) : reg.registeredAt}',
                                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                                    ),
                                  ],
                                ),

                                if (reg.rejectionReason != null && reg.rejectionReason!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text('Reason: ${reg.rejectionReason}', style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontStyle: FontStyle.italic)),
                                ],

                                const SizedBox(height: 10),

                                // Admin Quick Action Buttons
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (!isApproved)
                                      ElevatedButton.icon(
                                        onPressed: () => _showActionDialog(registration: reg, targetStatus: 'Approved'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                        ),
                                        icon: const Icon(Icons.check_circle_rounded, size: 13, color: Colors.white),
                                        label: const Text('Approve', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
                                    if (!isRejected) ...[
                                      const SizedBox(width: 8),
                                      OutlinedButton.icon(
                                        onPressed: () => _showActionDialog(registration: reg, targetStatus: 'Rejected'),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: Colors.redAccent),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                        ),
                                        icon: const Icon(Icons.cancel_outlined, size: 13, color: Colors.redAccent),
                                        label: const Text('Reject', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
                                      ),
                                    ],
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

  Widget _buildMetricMiniCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
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
          const SizedBox(height: 2),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}
