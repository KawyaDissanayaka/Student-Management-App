import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/facility_model.dart';

class CampusMapScreen extends StatefulWidget {
  final String? initialFacilityFilter;

  const CampusMapScreen({super.key, this.initialFacilityFilter});

  @override
  State<CampusMapScreen> createState() => _CampusMapScreenState();
}

class _CampusMapScreenState extends State<CampusMapScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';
  String _selectedType = 'All';
  String _selectedBuilding = 'All';

  @override
  void initState() {
    super.initState();
    if (widget.initialFacilityFilter != null) {
      _searchQuery = widget.initialFacilityFilter!.toLowerCase();
    }
  }

  void _showFacilityMapModal(BuildContext context, FacilityModel fac) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.location_on_rounded, color: Colors.tealAccent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                fac.name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${fac.building} • ${fac.floor}', style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold)),
            Text('Room: ${fac.roomNumber.isNotEmpty ? fac.roomNumber : "N/A"} • Capacity: ${fac.capacity} seats', style: const TextStyle(color: Colors.grey, fontSize: 11)),
            const SizedBox(height: 6),
            Text('Type: ${fac.type} • Status: ${fac.status}', style: const TextStyle(color: Colors.tealAccent, fontSize: 11)),
            if (fac.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(fac.description, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
            const SizedBox(height: 14),

            // Map Coordinates Container
            Container(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.tealAccent.withAlpha(80)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.15,
                      child: GridPaper(
                        color: Colors.tealAccent,
                        divisions: 2,
                        subdivisions: 2,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.pin_drop_rounded, size: 36, color: Colors.redAccent),
                      const SizedBox(height: 4),
                      Text(fac.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      Text(fac.location, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold)),
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
            Icon(Icons.map_rounded, color: Colors.tealAccent),
            SizedBox(width: 8),
            Text('Campus Navigation Map & Facilities', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('facilities').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
          }

          final docs = snapshot.data?.docs ?? [];
          final allFacilities = docs.map((d) => FacilityModel.fromFirestore(d)).toList();

          final buildings = {'All', ...allFacilities.map((f) => f.building)}.toList();

          final filtered = allFacilities.where((f) {
            final matchesSearch = f.name.toLowerCase().contains(_searchQuery) ||
                f.building.toLowerCase().contains(_searchQuery) ||
                f.roomNumber.toLowerCase().contains(_searchQuery);
            final matchesType = _selectedType == 'All' || f.type == _selectedType;
            final matchesBuilding = _selectedBuilding == 'All' || f.building == _selectedBuilding;

            return matchesSearch && matchesType && matchesBuilding;
          }).toList();

          return Column(
            children: [
              // Search & Filter Header
              Container(
                padding: const EdgeInsets.all(12),
                color: const Color(0xFF1E293B),
                child: Column(
                  children: [
                    TextField(
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search halls, labs, library, canteen...',
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                        prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 18),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                    ),
                    const SizedBox(height: 8),

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['All', ...FacilityModel.supportedTypes].map((t) {
                          final isSel = _selectedType == t;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(t, style: TextStyle(color: isSel ? Colors.black : Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                              selected: isSel,
                              selectedColor: Colors.tealAccent,
                              backgroundColor: const Color(0xFF0F172A),
                              onSelected: (sel) {
                                if (sel) setState(() => _selectedType = t);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    if (buildings.length > 2) ...[
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: buildings.map((b) {
                            final isSel = _selectedBuilding == b;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(b, style: TextStyle(color: isSel ? Colors.black : Colors.white70, fontSize: 10)),
                                selected: isSel,
                                selectedColor: Colors.amberAccent,
                                backgroundColor: const Color(0xFF0F172A),
                                onSelected: (sel) {
                                  if (sel) setState(() => _selectedBuilding = b);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Facilities List / Map Directory
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('No campus facilities match search.', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(14),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final fac = filtered[index];
                          Color stColor = Colors.greenAccent;
                          if (fac.status == 'Maintenance') stColor = Colors.orangeAccent;
                          if (fac.status == 'Closed') stColor = Colors.redAccent;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(color: Colors.teal.withAlpha(30), borderRadius: BorderRadius.circular(6)),
                                      child: Text(fac.type.toUpperCase(), style: const TextStyle(color: Colors.tealAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(color: stColor.withAlpha(30), borderRadius: BorderRadius.circular(6)),
                                      child: Text(fac.status.toUpperCase(), style: TextStyle(color: stColor, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(fac.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                const SizedBox(height: 4),
                                Text('${fac.building} • ${fac.floor} • Room ${fac.roomNumber}', style: const TextStyle(color: Colors.amberAccent, fontSize: 12)),
                                const SizedBox(height: 4),
                                Text('Location: ${fac.location}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _showFacilityMapModal(context, fac),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.teal,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                      icon: const Icon(Icons.pin_drop_rounded, size: 14, color: Colors.white),
                                      label: const Text('View on Map', style: TextStyle(color: Colors.white, fontSize: 11)),
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
}
