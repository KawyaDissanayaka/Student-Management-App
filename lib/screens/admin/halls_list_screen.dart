import 'package:flutter/material.dart';
import '../../models/hall_model.dart';
import '../../services/hall_service.dart';
import 'add_edit_hall_screen.dart';

class HallsListScreen extends StatefulWidget {
  const HallsListScreen({super.key});

  @override
  State<HallsListScreen> createState() => _HallsListScreenState();
}

class _HallsListScreenState extends State<HallsListScreen> {
  final HallService _hallService = HallService();
  String _searchQuery = '';
  String _selectedType = 'All';

  @override
  void initState() {
    super.initState();
    _hallService.ensureDefaultHallsInitialized();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.greenAccent;
      case 'maintenance':
        return Colors.orangeAccent;
      default:
        return Colors.redAccent;
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
        title: const Row(
          children: [
            Icon(Icons.meeting_room_rounded, color: Colors.tealAccent),
            SizedBox(width: 8),
            Text('Lecture Halls & Labs', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEditHallScreen()),
          );
        },
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Hall', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1E293B),
            child: Column(
              children: [
                TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search by hall name, ID or building...',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Lecture Hall', 'Laboratory', 'Computer Lab', 'Auditorium'].map((type) {
                      final isSel = type == _selectedType;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(type),
                          selected: isSel,
                          onSelected: (val) {
                            if (val) setState(() => _selectedType = type);
                          },
                          selectedColor: Colors.teal,
                          backgroundColor: const Color(0xFF0F172A),
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : Colors.grey,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                          side: BorderSide(color: isSel ? Colors.tealAccent : Colors.white10),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Halls List
          Expanded(
            child: StreamBuilder<List<HallModel>>(
              stream: _hallService.getHallsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
                }

                final allHalls = snapshot.data ?? [];
                final filtered = allHalls.where((h) {
                  final matchesSearch = h.name.toLowerCase().contains(_searchQuery) ||
                      h.hallId.toLowerCase().contains(_searchQuery) ||
                      h.building.toLowerCase().contains(_searchQuery);
                  final matchesType = _selectedType == 'All' || h.type == _selectedType;
                  return matchesSearch && matchesType;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('No lecture halls found matching filters.', style: TextStyle(color: Colors.grey)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final h = filtered[index];
                    final statusColor = _getStatusColor(h.status);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.teal.withAlpha(30),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.tealAccent.withAlpha(80)),
                                ),
                                child: Text(
                                  h.hallId,
                                  style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: statusColor.withAlpha(30), borderRadius: BorderRadius.circular(6)),
                                child: Text(
                                  h.status.toUpperCase(),
                                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(h.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('${h.type} • ${h.building} (${h.floor})', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          const SizedBox(height: 10),

                          Row(
                            children: [
                              const Icon(Icons.people_alt_rounded, size: 14, color: Colors.amberAccent),
                              const SizedBox(width: 6),
                              Text('Capacity: ${h.capacity} Seats', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Equipment Chips
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: h.facilities.map((fac) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(6)),
                                child: Text(fac, style: const TextStyle(color: Colors.white60, fontSize: 11)),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                          const Divider(color: Colors.white10, height: 1),
                          const SizedBox(height: 8),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  final newStatus = h.status == 'active' ? 'maintenance' : (h.status == 'maintenance' ? 'inactive' : 'active');
                                  _hallService.toggleHallStatus(h.docId!, newStatus);
                                },
                                icon: const Icon(Icons.sync_rounded, size: 14, color: Colors.orangeAccent),
                                label: const Text('Change Status', style: TextStyle(color: Colors.orangeAccent, fontSize: 12)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_rounded, color: Colors.tealAccent, size: 18),
                                tooltip: 'Edit Hall',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => AddEditHallScreen(hall: h)),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
