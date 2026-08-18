import 'package:flutter/material.dart';
import '../../models/fee_structure_model.dart';
import '../../services/fee_service.dart';

class AdminFeeStructuresScreen extends StatefulWidget {
  const AdminFeeStructuresScreen({super.key});

  @override
  State<AdminFeeStructuresScreen> createState() => _AdminFeeStructuresScreenState();
}

class _AdminFeeStructuresScreenState extends State<AdminFeeStructuresScreen> {
  final FeeService _feeService = FeeService();
  final TextEditingController _searchController = TextEditingController();

  String _statusFilter = 'All'; // 'All', 'Active', 'Inactive'
  final String _feeTypeFilter = 'All';
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─── ADD / EDIT FEE STRUCTURE MODAL ─────────────────────────────────────────
  void _showAddEditFeeModal({FeeStructureModel? existing}) {
    final formKey = GlobalKey<FormState>();
    final yearController = TextEditingController(text: existing?.academicYear ?? '2025/2026');
    final semController = TextEditingController(text: existing?.semester ?? 'Semester 1');
    final progController = TextEditingController(text: existing?.programme ?? 'BSc (Hons) in Computing');
    final batchController = TextEditingController(text: existing?.batchId ?? '2026');
    final amountController = TextEditingController(text: existing != null ? existing.amount.toString() : '');
    final dateController = TextEditingController(text: existing?.dueDate ?? '2026-09-30');
    final descController = TextEditingController(text: existing?.description ?? '');

    String selectedFeeType = existing?.feeType ?? 'Semester Fee';
    String selectedStatus = existing?.status ?? 'Active';
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
                          Icon(existing != null ? Icons.edit_rounded : Icons.add_card_rounded, color: Colors.amberAccent),
                          const SizedBox(width: 8),
                          Text(
                            existing != null ? 'Edit Fee Structure' : 'Create Fee Structure',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                          ),
                        ],
                      ),
                      IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Fee Type Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: selectedFeeType,
                    dropdownColor: const Color(0xFF0F172A),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: _inputDecoration('Fee Category / Type', Icons.category_rounded),
                    items: FeeStructureModel.supportedFeeTypes.map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (val) => setModalState(() => selectedFeeType = val ?? selectedFeeType),
                  ),
                  const SizedBox(height: 10),

                  // Amount (must be > 0)
                  TextFormField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    decoration: _inputDecoration('Fee Amount (LKR / USD)', Icons.payments_rounded),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Amount is required';
                      final num = double.tryParse(val.trim());
                      if (num == null || num <= 0) return 'Amount must be greater than 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),

                  // Programme
                  TextFormField(
                    controller: progController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: _inputDecoration('Degree Programme (or "All")', Icons.school_rounded),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Programme is required' : null,
                  ),
                  const SizedBox(height: 10),

                  // Batch & Semester in Row
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: batchController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: _inputDecoration('Batch ID', Icons.groups_rounded),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Batch is required' : null,
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

                  // Academic Year & Due Date in Row
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
                          controller: dateController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: _inputDecoration('Due Date (YYYY-MM-DD)', Icons.event_rounded),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Due Date is required';
                            if (DateTime.tryParse(val.trim()) == null) return 'Invalid YYYY-MM-DD';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Status Radio Row (Active / Inactive)
                  Row(
                    children: [
                      const Text('Status: ', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(width: 10),
                      ChoiceChip(
                        label: const Text('Active', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        selected: selectedStatus == 'Active',
                        selectedColor: Colors.greenAccent,
                        onSelected: (sel) => setModalState(() => selectedStatus = 'Active'),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('Inactive', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        selected: selectedStatus == 'Inactive',
                        selectedColor: Colors.grey,
                        onSelected: (sel) => setModalState(() => selectedStatus = 'Inactive'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Save Button
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
                                final amount = double.parse(amountController.text.trim());

                                if (existing == null) {
                                  await _feeService.addFeeStructure(
                                    academicYear: yearController.text.trim(),
                                    semester: semController.text.trim(),
                                    programme: progController.text.trim(),
                                    batchId: batchController.text.trim(),
                                    feeType: selectedFeeType,
                                    amount: amount,
                                    dueDate: dateController.text.trim(),
                                    status: selectedStatus,
                                    description: descController.text.trim().isNotEmpty ? descController.text.trim() : null,
                                  );
                                  messenger.showSnackBar(
                                    const SnackBar(content: Text('Fee structure created successfully!'), backgroundColor: Colors.green),
                                  );
                                } else {
                                  final updated = FeeStructureModel(
                                    docId: existing.docId,
                                    feeStructureId: existing.feeStructureId,
                                    academicYear: yearController.text.trim(),
                                    semester: semController.text.trim(),
                                    programme: progController.text.trim(),
                                    batchId: batchController.text.trim(),
                                    feeType: selectedFeeType,
                                    amount: amount,
                                    dueDate: dateController.text.trim(),
                                    status: selectedStatus,
                                    description: descController.text.trim().isNotEmpty ? descController.text.trim() : null,
                                    createdAt: existing.createdAt,
                                    updatedAt: DateTime.now().toIso8601String(),
                                  );
                                  await _feeService.updateFeeStructure(updated);
                                  messenger.showSnackBar(
                                    const SnackBar(content: Text('Fee structure updated successfully!'), backgroundColor: Colors.green),
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
                        backgroundColor: Colors.amber[700],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: isSaving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_circle_rounded, color: Colors.white),
                      label: Text(
                        existing != null ? 'Update Fee Structure' : 'Create & Apply Fee',
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

  // ─── CONFIRM DELETE MODAL ───────────────────────────────────────────────────
  void _confirmDelete(FeeStructureModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Delete Fee Structure?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete ${item.feeType} (${item.feeStructureId}) for ${item.programme}? This will remove it from future fee applications.',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              if (item.docId != null) {
                await _feeService.deleteFeeStructure(item.docId!);
                messenger.showSnackBar(const SnackBar(content: Text('Fee structure deleted.'), backgroundColor: Colors.redAccent));
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
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fee Structure Management', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Admin • Finance & Tuition Management', style: TextStyle(color: Colors.amberAccent, fontSize: 11)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_card_rounded, color: Colors.amberAccent),
            tooltip: 'Add Fee Structure',
            onPressed: () => _showAddEditFeeModal(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.amber[700],
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Create Fee', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _showAddEditFeeModal(),
      ),
      body: StreamBuilder<List<FeeStructureModel>>(
        stream: _feeService.getFeeStructuresStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.amberAccent));
          }

          final allItems = snapshot.data ?? [];

          // KPI Metrics
          final totalCount = allItems.length;
          final activeCount = allItems.where((f) => f.isActive).length;
          final inactiveCount = totalCount - activeCount;
          final totalActiveValue = allItems.where((f) => f.isActive).fold(0.0, (sum, f) => sum + f.amount);

          // Filtering
          final filteredItems = allItems.where((item) {
            final matchesStatus = _statusFilter == 'All' || item.status.toLowerCase() == _statusFilter.toLowerCase();
            final matchesType = _feeTypeFilter == 'All' || item.feeType.toLowerCase() == _feeTypeFilter.toLowerCase();
            final matchesSearch = _searchQuery.isEmpty ||
                item.programme.toLowerCase().contains(_searchQuery) ||
                item.feeType.toLowerCase().contains(_searchQuery) ||
                item.batchId.toLowerCase().contains(_searchQuery) ||
                item.academicYear.toLowerCase().contains(_searchQuery);

            return matchesStatus && matchesType && matchesSearch;
          }).toList();

          return Column(
            children: [
              // 1. KPI Metrics Strip
              Container(
                padding: const EdgeInsets.all(12),
                color: const Color(0xFF1E293B),
                child: Row(
                  children: [
                    Expanded(child: _metricCard('Total Fees', '$totalCount', Colors.white, Icons.receipt_long_rounded)),
                    const SizedBox(width: 6),
                    Expanded(child: _metricCard('Active', '$activeCount', Colors.greenAccent, Icons.check_circle_rounded)),
                    const SizedBox(width: 6),
                    Expanded(child: _metricCard('Inactive', '$inactiveCount', Colors.grey, Icons.pause_circle_rounded)),
                    const SizedBox(width: 6),
                    Expanded(child: _metricCard('Active Sum', 'LKR ${totalActiveValue.toStringAsFixed(0)}', Colors.amberAccent, Icons.account_balance_wallet_rounded)),
                  ],
                ),
              ),

              // 2. Search Bar & Filter Chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search by Programme, Fee Type, Batch...',
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                        prefixIcon: const Icon(Icons.search_rounded, color: Colors.amberAccent, size: 18),
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
                        children: ['All', 'Active', 'Inactive'].map((status) {
                          final isSelected = _statusFilter == status;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(status, style: TextStyle(color: isSelected ? Colors.black : Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                              selected: isSelected,
                              selectedColor: Colors.amberAccent,
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

              // 3. Fee Structures List
              Expanded(
                child: filteredItems.isEmpty
                    ? Center(
                        child: Text(
                          allItems.isEmpty ? 'No fee structures created yet.\nTap "+ Create Fee" to add.' : 'No items match filter criteria.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(left: 14, right: 14, bottom: 80),
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          final isOverdue = item.isPastDueDate;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: item.isActive ? Colors.greenAccent.withAlpha(40) : Colors.white10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.indigo.withAlpha(50),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.indigoAccent.withAlpha(80)),
                                      ),
                                      child: Text(item.feeType, style: const TextStyle(color: Colors.indigoAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          'LKR ${item.amount.toStringAsFixed(2)}',
                                          style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                        const SizedBox(width: 6),
                                        PopupMenuButton<String>(
                                          icon: const Icon(Icons.more_vert_rounded, color: Colors.grey, size: 18),
                                          color: const Color(0xFF0F172A),
                                          onSelected: (action) {
                                            if (action == 'edit') {
                                              _showAddEditFeeModal(existing: item);
                                            } else if (action == 'toggle') {
                                              _feeService.toggleFeeStructureStatus(item.docId!, item.isActive ? 'Inactive' : 'Active');
                                            } else if (action == 'delete') {
                                              _confirmDelete(item);
                                            }
                                          },
                                          itemBuilder: (ctx) => [
                                            const PopupMenuItem(value: 'edit', child: Text('Edit Fee Structure', style: TextStyle(color: Colors.white))),
                                            PopupMenuItem(
                                              value: 'toggle',
                                              child: Text(item.isActive ? 'Deactivate' : 'Activate', style: TextStyle(color: item.isActive ? Colors.orangeAccent : Colors.greenAccent)),
                                            ),
                                            const PopupMenuDivider(),
                                            const PopupMenuItem(value: 'delete', child: Text('Delete Fee', style: TextStyle(color: Colors.redAccent))),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                Text(item.programme, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 4),

                                Row(
                                  children: [
                                    Text('Batch: ${item.batchId} • ${item.semester} (${item.academicYear})', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.event_rounded, size: 13, color: isOverdue ? Colors.redAccent : Colors.tealAccent),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Due: ${item.dueDate}',
                                          style: TextStyle(color: isOverdue ? Colors.redAccent : Colors.white70, fontSize: 11, fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal),
                                        ),
                                        if (isOverdue) ...[
                                          const SizedBox(width: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                            decoration: BoxDecoration(color: Colors.red.withAlpha(40), borderRadius: BorderRadius.circular(3)),
                                            child: const Text('OVERDUE', style: TextStyle(color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ],
                                    ),

                                    // Status Switch
                                    Row(
                                      children: [
                                        Text(item.status, style: TextStyle(color: item.isActive ? Colors.greenAccent : Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                                        Transform.scale(
                                          scale: 0.75,
                                          child: Switch(
                                            value: item.isActive,
                                            activeThumbColor: Colors.greenAccent,
                                            onChanged: (val) {
                                              if (item.docId != null) {
                                                _feeService.toggleFeeStructureStatus(item.docId!, val ? 'Active' : 'Inactive');
                                              }
                                            },
                                          ),
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
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
      prefixIcon: Icon(icon, color: Colors.amberAccent, size: 18),
      filled: true,
      fillColor: const Color(0xFF0F172A),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.amberAccent)),
    );
  }
}
