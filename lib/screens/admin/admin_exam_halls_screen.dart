import 'package:flutter/material.dart';
import '../../models/exam_hall_model.dart';
import '../../services/exam_hall_service.dart';

class AdminExamHallsScreen extends StatefulWidget {
  const AdminExamHallsScreen({super.key});

  @override
  State<AdminExamHallsScreen> createState() => _AdminExamHallsScreenState();
}

class _AdminExamHallsScreenState extends State<AdminExamHallsScreen> {
  final ExamHallService _hallService = ExamHallService();
  final TextEditingController _searchController = TextEditingController();

  String _statusFilter = 'All'; // 'All', 'Available', 'Maintenance', 'Inactive'
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditHallModal({ExamHallModel? existingHall}) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: existingHall?.hallName ?? '');
    final buildingController = TextEditingController(text: existingHall?.building ?? '');
    final floorController = TextEditingController(text: existingHall?.floor ?? '');
    final capacityController = TextEditingController(text: existingHall != null ? '${existingHall.capacity}' : '80');
    final facilityInputController = TextEditingController();

    String autoHallId = existingHall?.hallId ?? await _hallService.generateUniqueHallId();
    String selectedStatus = existingHall?.status ?? 'Available';
    List<String> selectedFacilities = existingHall != null
        ? List<String>.from(existingHall.facilities)
        : ['Air Conditioning', 'CCTV Monitoring', 'PA Audio System'];

    const presetFacilities = [
      'Air Conditioning',
      'CCTV Monitoring',
      'PA Audio System',
      'Individual Desks',
      'Projector',
      'Wi-Fi',
      'Power Outlets',
      'Wheelchair Accessible',
    ];

    bool isSaving = false;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                          Icon(
                            existingHall == null ? Icons.add_business_rounded : Icons.edit_location_alt_rounded,
                            color: Colors.amberAccent,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            existingHall == null ? 'Add Examination Hall' : 'Edit Examination Hall',
                            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          autoHallId,
                          style: const TextStyle(color: Colors.tealAccent, fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Hall Name
                  TextFormField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Hall Name (e.g. Main Exam Hall Alpha)', Icons.meeting_room_rounded),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Please enter hall name' : null,
                  ),
                  const SizedBox(height: 12),

                  // Building & Floor
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: buildingController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('Building (e.g. Complex A)', Icons.domain_rounded),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Enter building' : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: floorController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('Floor (e.g. 2nd Floor)', Icons.layers_rounded),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Enter floor' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Capacity & Status
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: capacityController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('Seating Capacity', Icons.event_seat_rounded),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Enter capacity';
                            final numVal = int.tryParse(val.trim());
                            if (numVal == null || numVal <= 0) return 'Must be > 0';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedStatus,
                          dropdownColor: const Color(0xFF1E293B),
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: _inputDecoration('Status', Icons.flag_rounded),
                          items: const [
                            DropdownMenuItem(value: 'Available', child: Text('Available', style: TextStyle(color: Colors.greenAccent))),
                            DropdownMenuItem(value: 'Maintenance', child: Text('Maintenance', style: TextStyle(color: Colors.orangeAccent))),
                            DropdownMenuItem(value: 'Inactive', child: Text('Inactive', style: TextStyle(color: Colors.redAccent))),
                          ],
                          onChanged: (val) {
                            if (val != null) setModalState(() => selectedStatus = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Facilities Chips Selection
                  const Text('Hall Facilities & Features:', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: presetFacilities.map((facility) {
                      final isSelected = selectedFacilities.contains(facility);
                      return FilterChip(
                        selected: isSelected,
                        label: Text(facility, style: TextStyle(fontSize: 11, color: isSelected ? Colors.black : Colors.white70, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                        backgroundColor: const Color(0xFF0F172A),
                        selectedColor: Colors.tealAccent,
                        checkmarkColor: Colors.black,
                        side: BorderSide(color: isSelected ? Colors.tealAccent : Colors.white12),
                        onSelected: (selected) {
                          setModalState(() {
                            if (selected) {
                              selectedFacilities.add(facility);
                            } else {
                              selectedFacilities.remove(facility);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),

                  // Custom Facility Input
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: facilityInputController,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                          decoration: InputDecoration(
                            hintText: 'Add custom facility...',
                            hintStyle: const TextStyle(color: Colors.grey),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          final text = facilityInputController.text.trim();
                          if (text.isNotEmpty && !selectedFacilities.contains(text)) {
                            setModalState(() {
                              selectedFacilities.add(text);
                              facilityInputController.clear();
                            });
                          }
                        },
                        icon: const Icon(Icons.add_circle_rounded, color: Colors.tealAccent),
                      ),
                    ],
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

                              final newHall = ExamHallModel(
                                docId: existingHall?.docId,
                                hallId: autoHallId,
                                hallName: nameController.text.trim(),
                                building: buildingController.text.trim(),
                                floor: floorController.text.trim(),
                                capacity: int.parse(capacityController.text.trim()),
                                facilities: selectedFacilities,
                                status: selectedStatus,
                              );

                              try {
                                if (existingHall == null) {
                                  await _hallService.addExamHall(newHall);
                                } else {
                                  await _hallService.updateExamHall(existingHall.docId!, newHall);
                                }
                                if (context.mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(existingHall == null ? 'Exam Hall created successfully!' : 'Exam Hall updated successfully!'),
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
                        existingHall == null ? 'Save & Create Hall' : 'Update Hall Details',
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

  void _confirmDelete(ExamHallModel hall) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Delete Exam Hall', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${hall.hallName}" (${hall.hallId})? This action cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _hallService.deleteExamHall(hall.docId!);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Exam Hall deleted successfully.'), backgroundColor: Colors.amber),
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
            Icon(Icons.meeting_room_rounded, color: Colors.amberAccent),
            SizedBox(width: 8),
            Text('Exam Halls Management', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.tealAccent),
            tooltip: 'Add Exam Hall',
            onPressed: () => _showAddEditHallModal(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Exam Hall', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _showAddEditHallModal(),
      ),
      body: StreamBuilder<List<ExamHallModel>>(
        stream: _hallService.getExamHallsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading halls: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
          }

          final allHalls = snapshot.data ?? [];

          // Compute KPI counts
          final totalHalls = allHalls.length;
          final availableHalls = allHalls.where((h) => h.isAvailable).length;
          final maintenanceHalls = allHalls.where((h) => h.isUnderMaintenance).length;
          final inactiveHalls = allHalls.where((h) => h.isInactive).length;

          // Filter by status & search
          final filteredHalls = allHalls.where((h) {
            final matchesStatus = _statusFilter == 'All' || h.status.toLowerCase() == _statusFilter.toLowerCase();
            final matchesSearch = _searchQuery.isEmpty ||
                h.hallName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                h.hallId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                h.building.toLowerCase().contains(_searchQuery.toLowerCase());
            return matchesStatus && matchesSearch;
          }).toList();

          return Column(
            children: [
              // 1. KPI Summary Cards Strip
              Container(
                padding: const EdgeInsets.all(14),
                color: const Color(0xFF1E293B),
                child: Row(
                  children: [
                    Expanded(child: _buildKpiCard('Total Halls', '$totalHalls', Colors.indigoAccent, Icons.apartment_rounded)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildKpiCard('Available', '$availableHalls', Colors.greenAccent, Icons.check_circle_rounded)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildKpiCard('Maintenance', '$maintenanceHalls', Colors.orangeAccent, Icons.build_rounded)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildKpiCard('Inactive', '$inactiveHalls', Colors.redAccent, Icons.do_not_disturb_on_rounded)),
                  ],
                ),
              ),

              // 2. Search & Filter Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search by hall name, ID, or building...',
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

                    // Status Filter Segmented Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['All', 'Available', 'Maintenance', 'Inactive'].map((status) {
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
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Hall List View
              Expanded(
                child: filteredHalls.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.meeting_room_outlined, size: 54, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(
                              allHalls.isEmpty ? 'No Examination Halls added yet.' : 'No halls match your filter criteria.',
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                            const SizedBox(height: 12),
                            if (allHalls.isEmpty)
                              ElevatedButton.icon(
                                onPressed: () => _showAddEditHallModal(),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                                icon: const Icon(Icons.add_rounded, color: Colors.white),
                                label: const Text('Add First Hall', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(left: 14, right: 14, bottom: 80),
                        itemCount: filteredHalls.length,
                        itemBuilder: (context, index) {
                          final hall = filteredHalls[index];
                          final isAvail = hall.isAvailable;
                          final isMaint = hall.isUnderMaintenance;

                          Color statusColor = isAvail ? Colors.greenAccent : (isMaint ? Colors.orangeAccent : Colors.redAccent);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: isAvail ? Colors.white10 : statusColor.withAlpha(80)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top Row: Hall ID & Status Badge
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(6)),
                                            child: Text(
                                              hall.hallId,
                                              style: const TextStyle(color: Colors.tealAccent, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${hall.capacity} Seats',
                                            style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert_rounded, color: Colors.white70, size: 20),
                                        color: const Color(0xFF0F172A),
                                        onSelected: (action) async {
                                          if (action == 'edit') {
                                            _showAddEditHallModal(existingHall: hall);
                                          } else if (action == 'delete') {
                                            _confirmDelete(hall);
                                          } else {
                                            await _hallService.updateHallStatus(hall.docId!, action);
                                          }
                                        },
                                        itemBuilder: (ctx) => [
                                          const PopupMenuItem(value: 'edit', child: Text('Edit Hall Details', style: TextStyle(color: Colors.white))),
                                          const PopupMenuItem(value: 'Available', child: Text('Mark Available', style: TextStyle(color: Colors.greenAccent))),
                                          const PopupMenuItem(value: 'Maintenance', child: Text('Mark Maintenance', style: TextStyle(color: Colors.orangeAccent))),
                                          const PopupMenuItem(value: 'Inactive', child: Text('Mark Inactive', style: TextStyle(color: Colors.redAccent))),
                                          const PopupMenuDivider(),
                                          const PopupMenuItem(value: 'delete', child: Text('Delete Hall', style: TextStyle(color: Colors.redAccent))),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),

                                  // Hall Name
                                  Text(hall.hallName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),

                                  // Location: Building & Floor
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_rounded, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text('${hall.building} • ${hall.floor}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // Facilities Chips
                                  if (hall.facilities.isNotEmpty)
                                    Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: hall.facilities.map((fac) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(4)),
                                          child: Text(fac, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                                        );
                                      }).toList(),
                                    ),
                                  const SizedBox(height: 10),

                                  // Status Indicator Bar
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withAlpha(25),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: statusColor.withAlpha(60)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                                        const SizedBox(width: 6),
                                        Text(
                                          hall.status.toUpperCase(),
                                          style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isAvail ? '• Ready for Exam Allocation' : (isMaint ? '• Under Service' : '• Hall Disabled'),
                                          style: TextStyle(color: statusColor.withAlpha(200), fontSize: 10),
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

  Widget _buildKpiCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
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
