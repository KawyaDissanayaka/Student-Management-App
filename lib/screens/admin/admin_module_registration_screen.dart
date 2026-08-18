import 'package:flutter/material.dart';
import '../../models/module_registration_period_model.dart';
import '../../models/subject_model.dart';
import '../../services/module_registration_setup_service.dart';

class AdminModuleRegistrationScreen extends StatefulWidget {
  const AdminModuleRegistrationScreen({super.key});

  @override
  State<AdminModuleRegistrationScreen> createState() => _AdminModuleRegistrationScreenState();
}

class _AdminModuleRegistrationScreenState extends State<AdminModuleRegistrationScreen> {
  final ModuleRegistrationSetupService _setupService = ModuleRegistrationSetupService();
  final TextEditingController _searchController = TextEditingController();

  String _statusFilter = 'All'; // 'All', 'Open', 'Draft', 'Closed'
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─── ADD / EDIT REGISTRATION PERIOD MODAL ───────────────────────────────────
  void _showAddEditPeriodModal({ModuleRegistrationPeriodModel? existing}) {
    final formKey = GlobalKey<FormState>();
    final yearController = TextEditingController(text: existing?.academicYear ?? '2025/2026');
    final semController = TextEditingController(text: existing?.semester ?? 'Semester 1');
    final progController = TextEditingController(text: existing?.programme ?? 'BSc (Hons) in Computing');
    final batchController = TextEditingController(text: existing?.batchId ?? '2026');
    final startController = TextEditingController(text: existing?.registrationStartDate ?? DateTime.now().toIso8601String().substring(0, 10));
    final endController = TextEditingController(text: existing?.registrationEndDate ?? DateTime.now().add(const Duration(days: 14)).toIso8601String().substring(0, 10));
    final maxModController = TextEditingController(text: existing != null ? '${existing.maximumModules}' : '6');
    final minCredController = TextEditingController(text: existing != null ? '${existing.minimumCredits}' : '12');
    final maxCredController = TextEditingController(text: existing != null ? '${existing.maximumCredits}' : '24');

    String selectedStatus = existing?.status ?? 'Draft';
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
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(existing != null ? Icons.edit_calendar_rounded : Icons.app_registration_rounded, color: Colors.cyanAccent),
                          const SizedBox(width: 8),
                          Text(
                            existing != null ? 'Edit Registration Period' : 'Create Registration Period',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                          ),
                        ],
                      ),
                      IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Programme & Batch in Row
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: progController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: _inputDecoration('Degree Programme', Icons.school_rounded),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Programme is required' : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: batchController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: _inputDecoration('Batch', Icons.groups_rounded),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Batch is required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Academic Year & Semester in Row
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: yearController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: _inputDecoration('Academic Year', Icons.calendar_today_rounded),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Year is required' : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: semController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: _inputDecoration('Semester', Icons.menu_book_rounded),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Semester is required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Start Date & End Date in Row
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: startController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: _inputDecoration('Start Date (YYYY-MM-DD)', Icons.event_available_rounded),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Start date required';
                            if (DateTime.tryParse(val.trim()) == null) return 'Invalid date';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: endController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: _inputDecoration('End Date (YYYY-MM-DD)', Icons.event_busy_rounded),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'End date required';
                            if (DateTime.tryParse(val.trim()) == null) return 'Invalid date';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Min Credits, Max Credits & Max Modules in Row
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: minCredController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: _inputDecoration('Min Credits', Icons.star_border_rounded),
                          validator: (val) {
                            final num = int.tryParse(val ?? '');
                            if (num == null || num <= 0) return 'Min > 0';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: maxCredController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: _inputDecoration('Max Credits', Icons.star_rounded),
                          validator: (val) {
                            final max = int.tryParse(val ?? '');
                            final min = int.tryParse(minCredController.text.trim()) ?? 0;
                            if (max == null || max < min) return 'Max >= Min';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: maxModController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: _inputDecoration('Max Modules', Icons.format_list_numbered_rounded),
                          validator: (val) {
                            final num = int.tryParse(val ?? '');
                            if (num == null || num <= 0) return 'Max > 0';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Status Selector
                  Row(
                    children: [
                      const Text('Period Status: ', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(width: 8),
                      ...ModuleRegistrationPeriodModel.supportedStatuses.map((st) {
                        final isSel = selectedStatus == st;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(st, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSel ? Colors.black : Colors.white70)),
                            selected: isSel,
                            selectedColor: _statusColor(st),
                            backgroundColor: const Color(0xFF0F172A),
                            onSelected: (sel) {
                              if (sel) setModalState(() => selectedStatus = st);
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setModalState(() => isSaving = true);
                              final messenger = ScaffoldMessenger.of(context);
                              final nav = Navigator.of(ctx);

                              try {
                                final minCred = int.parse(minCredController.text.trim());
                                final maxCred = int.parse(maxCredController.text.trim());
                                final maxMod = int.parse(maxModController.text.trim());

                                if (existing == null) {
                                  await _setupService.createRegistrationPeriod(
                                    academicYear: yearController.text.trim(),
                                    semester: semController.text.trim(),
                                    programme: progController.text.trim(),
                                    batchId: batchController.text.trim(),
                                    startDate: startController.text.trim(),
                                    endDate: endController.text.trim(),
                                    minCredits: minCred,
                                    maxCredits: maxCred,
                                    maxModules: maxMod,
                                    status: selectedStatus,
                                  );
                                  messenger.showSnackBar(
                                    const SnackBar(content: Text('Module registration period created!'), backgroundColor: Colors.green),
                                  );
                                } else {
                                  final updated = ModuleRegistrationPeriodModel(
                                    docId: existing.docId,
                                    periodId: existing.periodId,
                                    academicYear: yearController.text.trim(),
                                    semester: semController.text.trim(),
                                    programme: progController.text.trim(),
                                    batchId: batchController.text.trim(),
                                    registrationStartDate: startController.text.trim(),
                                    registrationEndDate: endController.text.trim(),
                                    minimumCredits: minCred,
                                    maximumCredits: maxCred,
                                    maximumModules: maxMod,
                                    status: selectedStatus,
                                    offeredModuleCodes: existing.offeredModuleCodes,
                                    offeredModuleTypes: existing.offeredModuleTypes,
                                    createdAt: existing.createdAt,
                                    updatedAt: DateTime.now().toIso8601String(),
                                  );
                                  await _setupService.updateRegistrationPeriod(updated);
                                  messenger.showSnackBar(
                                    const SnackBar(content: Text('Registration period updated!'), backgroundColor: Colors.green),
                                  );
                                }
                                nav.pop();
                              } catch (e) {
                                setModalState(() => isSaving = false);
                                final msg = e.toString().replaceAll('Exception: ', '');
                                messenger.showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan[700],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: isSaving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_circle_rounded, color: Colors.white),
                      label: Text(
                        existing != null ? 'Update Period' : 'Create Registration Period',
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

  // ─── MANAGE OFFERED MODULES MODAL ──────────────────────────────────────────
  void _showManageModulesModal(ModuleRegistrationPeriodModel period) {
    List<String> selectedCodes = List<String>.from(period.offeredModuleCodes);
    Map<String, String> selectedTypes = Map<String, String>.from(period.offeredModuleTypes);
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Assign Offered Modules', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('${period.programme} • ${period.semester} (${period.periodId})', style: const TextStyle(color: Colors.cyanAccent, fontSize: 11)),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Select university modules to offer for student registration (${selectedCodes.length} selected):',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 10),

                // Active Subjects Stream
                Expanded(
                  child: StreamBuilder<List<SubjectModel>>(
                    stream: _setupService.getActiveSubjectsStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
                      }

                      final subjects = snapshot.data ?? [];
                      if (subjects.isEmpty) {
                        return const Center(child: Text('No active subjects found in curriculum.', style: TextStyle(color: Colors.grey)));
                      }

                      return ListView.builder(
                        itemCount: subjects.length,
                        itemBuilder: (context, index) {
                          final sub = subjects[index];
                          final isSelected = selectedCodes.contains(sub.subjectCode);
                          final currentType = selectedTypes[sub.subjectCode] ?? 'Core';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF334155).withAlpha(40),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isSelected ? Colors.cyanAccent.withAlpha(80) : Colors.white10),
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: isSelected,
                                  activeColor: Colors.cyanAccent,
                                  checkColor: Colors.black,
                                  onChanged: (val) {
                                    setModalState(() {
                                      if (val == true) {
                                        selectedCodes.add(sub.subjectCode);
                                        selectedTypes[sub.subjectCode] = 'Core';
                                      } else {
                                        selectedCodes.remove(sub.subjectCode);
                                        selectedTypes.remove(sub.subjectCode);
                                      }
                                    });
                                  },
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${sub.subjectCode} - ${sub.subjectName}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                      Text('${sub.credits} Credits • Semester: ${sub.semester}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                    ],
                                  ),
                                ),
                                if (isSelected) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E293B),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.white24),
                                    ),
                                    child: DropdownButton<String>(
                                      value: currentType,
                                      dropdownColor: const Color(0xFF0F172A),
                                      underline: const SizedBox(),
                                      style: const TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                      items: ModuleRegistrationPeriodModel.supportedModuleTypes.map((t) {
                                        return DropdownMenuItem(value: t, child: Text(t));
                                      }).toList(),
                                      onChanged: (newType) {
                                        if (newType != null) {
                                          setModalState(() => selectedTypes[sub.subjectCode] = newType);
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Save Module Assignments Button
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: isSaving
                        ? null
                        : () async {
                            setModalState(() => isSaving = true);
                            final messenger = ScaffoldMessenger.of(context);
                            final nav = Navigator.of(ctx);

                            try {
                              await _setupService.assignOfferedModules(
                                docId: period.docId!,
                                offeredModuleCodes: selectedCodes,
                                offeredModuleTypes: selectedTypes,
                              );
                              nav.pop();
                              messenger.showSnackBar(
                                SnackBar(content: Text('${selectedCodes.length} modules assigned to ${period.periodId}!'), backgroundColor: Colors.green),
                              );
                            } catch (e) {
                              setModalState(() => isSaving = false);
                              messenger.showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.redAccent));
                            }
                          },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan[700], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    icon: isSaving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_rounded, color: Colors.white),
                    label: Text('Save Offered Modules (${selectedCodes.length})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
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
            Text('Module Registration Setup', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Admin • Academic Curriculum & Enrollment', style: TextStyle(color: Colors.cyanAccent, fontSize: 11)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.cyanAccent),
            tooltip: 'Create Registration Period',
            onPressed: () => _showAddEditPeriodModal(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.cyan[700],
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Period', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _showAddEditPeriodModal(),
      ),
      body: StreamBuilder<List<ModuleRegistrationPeriodModel>>(
        stream: _setupService.getRegistrationPeriodsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
          }

          final allPeriods = snapshot.data ?? [];

          // KPI Metrics
          final totalCount = allPeriods.length;
          final openCount = allPeriods.where((p) => p.isOpen).length;
          final draftCount = allPeriods.where((p) => p.isDraft).length;
          final closedCount = allPeriods.where((p) => p.isClosed).length;

          // Filter by status & search
          final filteredPeriods = allPeriods.where((p) {
            final matchesStatus = _statusFilter == 'All' || p.status.toLowerCase() == _statusFilter.toLowerCase();
            final matchesSearch = _searchQuery.isEmpty ||
                p.programme.toLowerCase().contains(_searchQuery) ||
                p.batchId.toLowerCase().contains(_searchQuery) ||
                p.semester.toLowerCase().contains(_searchQuery) ||
                p.periodId.toLowerCase().contains(_searchQuery);

            return matchesStatus && matchesSearch;
          }).toList();

          return Column(
            children: [
              // 1. KPI Metric Strip
              Container(
                padding: const EdgeInsets.all(12),
                color: const Color(0xFF1E293B),
                child: Row(
                  children: [
                    Expanded(child: _metricCard('Total Periods', '$totalCount', Colors.white, Icons.calendar_month_rounded)),
                    const SizedBox(width: 6),
                    Expanded(child: _metricCard('Open (Active)', '$openCount', Colors.greenAccent, Icons.lock_open_rounded)),
                    const SizedBox(width: 6),
                    Expanded(child: _metricCard('Drafts', '$draftCount', Colors.amberAccent, Icons.edit_note_rounded)),
                    const SizedBox(width: 6),
                    Expanded(child: _metricCard('Closed', '$closedCount', Colors.redAccent, Icons.lock_outline_rounded)),
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
                        hintText: 'Search by Programme, Batch, Semester...',
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
                        children: ['All', 'Open', 'Draft', 'Closed'].map((status) {
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
                  ],
                ),
              ),

              // 3. Registration Periods List
              Expanded(
                child: filteredPeriods.isEmpty
                    ? Center(
                        child: Text(
                          allPeriods.isEmpty ? 'No module registration periods created yet.\nTap "+ New Period" to add.' : 'No periods match filter criteria.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(left: 14, right: 14, bottom: 80),
                        itemCount: filteredPeriods.length,
                        itemBuilder: (context, index) {
                          final period = filteredPeriods[index];
                          final isWindowOpen = period.isOpenForRegistration;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: period.isOpen ? Colors.greenAccent.withAlpha(50) : Colors.white10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(color: Colors.cyan.withAlpha(40), borderRadius: BorderRadius.circular(4)),
                                      child: Text(period.periodId, style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'monospace')),
                                    ),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(color: _statusColor(period.status).withAlpha(30), borderRadius: BorderRadius.circular(4)),
                                          child: Text(period.status.toUpperCase(), style: TextStyle(color: _statusColor(period.status), fontWeight: FontWeight.bold, fontSize: 10)),
                                        ),
                                        const SizedBox(width: 4),
                                        PopupMenuButton<String>(
                                          icon: const Icon(Icons.more_vert_rounded, color: Colors.grey, size: 18),
                                          color: const Color(0xFF0F172A),
                                          onSelected: (action) {
                                            if (action == 'edit') {
                                              _showAddEditPeriodModal(existing: period);
                                            } else if (action == 'modules') {
                                              _showManageModulesModal(period);
                                            } else if (action == 'open') {
                                              _setupService.updatePeriodStatus(period.docId!, 'Open');
                                            } else if (action == 'close') {
                                              _setupService.updatePeriodStatus(period.docId!, 'Closed');
                                            } else if (action == 'delete') {
                                              _setupService.deleteRegistrationPeriod(period.docId!);
                                            }
                                          },
                                          itemBuilder: (ctx) => [
                                            const PopupMenuItem(value: 'edit', child: Text('Edit Period Details', style: TextStyle(color: Colors.white))),
                                            const PopupMenuItem(value: 'modules', child: Text('Assign Offered Modules', style: TextStyle(color: Colors.cyanAccent))),
                                            const PopupMenuDivider(),
                                            if (!period.isOpen)
                                              const PopupMenuItem(value: 'open', child: Text('Set Status: Open', style: TextStyle(color: Colors.greenAccent))),
                                            if (!period.isClosed)
                                              const PopupMenuItem(value: 'close', child: Text('Set Status: Closed', style: TextStyle(color: Colors.redAccent))),
                                            const PopupMenuDivider(),
                                            const PopupMenuItem(value: 'delete', child: Text('Delete Period', style: TextStyle(color: Colors.redAccent))),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                Text(period.programme, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 4),
                                Text('Batch: ${period.batchId} • ${period.semester} (${period.academicYear})', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                const SizedBox(height: 8),

                                // Date Window & Credit Rules Row
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.date_range_rounded, size: 13, color: isWindowOpen ? Colors.greenAccent : Colors.grey),
                                              const SizedBox(width: 4),
                                              Text('${period.registrationStartDate} → ${period.registrationEndDate}', style: TextStyle(color: isWindowOpen ? Colors.greenAccent : Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                                            ],
                                          ),
                                          Text('Max ${period.maximumModules} Modules', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Credits Allowed: ${period.minimumCredits} - ${period.maximumCredits}', style: const TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                                          Text('${period.offeredModuleCodes.length} Modules Offered', style: const TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Action Buttons Strip
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _showManageModulesModal(period),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: Colors.cyanAccent),
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                        ),
                                        icon: const Icon(Icons.library_books_rounded, size: 14, color: Colors.cyanAccent),
                                        label: Text(
                                          'Offered Modules (${period.offeredModuleCodes.length})',
                                          style: const TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          final nextStatus = period.isOpen ? 'Closed' : 'Open';
                                          _setupService.updatePeriodStatus(period.docId!, nextStatus);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: period.isOpen ? Colors.red[800] : Colors.green[800],
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                        ),
                                        icon: Icon(period.isOpen ? Icons.lock_outline_rounded : Icons.lock_open_rounded, size: 14, color: Colors.white),
                                        label: Text(
                                          period.isOpen ? 'Close Period' : 'Open Registration',
                                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 9), overflow: TextOverflow.ellipsis)),
              Icon(icon, size: 10, color: color),
            ],
          ),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
      prefixIcon: Icon(icon, color: Colors.cyanAccent, size: 18),
      filled: true,
      fillColor: const Color(0xFF0F172A),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.cyanAccent)),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.greenAccent;
      case 'draft':
        return Colors.amberAccent;
      case 'closed':
      default:
        return Colors.redAccent;
    }
  }
}
