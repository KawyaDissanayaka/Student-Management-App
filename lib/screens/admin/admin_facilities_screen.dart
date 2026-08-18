import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/facility_model.dart';

class AdminFacilitiesScreen extends StatefulWidget {
  const AdminFacilitiesScreen({super.key});

  @override
  State<AdminFacilitiesScreen> createState() => _AdminFacilitiesScreenState();
}

class _AdminFacilitiesScreenState extends State<AdminFacilitiesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _searchQuery = '';
  String _selectedType = 'All';

  void _showFacilityModal({FacilityModel? existing}) {
    final isEditing = existing != null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final bldCtrl = TextEditingController(text: existing?.building ?? 'Faculty of Computing Block');
    final floorCtrl = TextEditingController(text: existing?.floor ?? '1st Floor');
    final roomCtrl = TextEditingController(text: existing?.roomNumber ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final locCtrl = TextEditingController(text: existing?.location ?? 'North Wing, Zone B (Lat: 6.9271, Lng: 79.8612)');
    final capCtrl = TextEditingController(text: existing != null ? '${existing.capacity}' : '60');
    String type = existing?.type ?? 'Lecture Hall';
    String status = existing?.status ?? 'Available';
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isEditing ? 'Edit Facility' : 'Add New Campus Facility', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Facility / Hall Name (e.g. Computing Lab 01) *',
                    labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: type,
                        dropdownColor: const Color(0xFF0F172A),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Facility Type *',
                          labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: FacilityModel.supportedTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (v) => setModalState(() => type = v ?? 'Lecture Hall'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: status,
                        dropdownColor: const Color(0xFF0F172A),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Availability Status *',
                          labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: FacilityModel.supportedStatuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (v) => setModalState(() => status = v ?? 'Available'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: bldCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Building Complex *',
                          labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: floorCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Floor *',
                          labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: roomCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Room Number',
                          labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: capCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Capacity (People) *',
                          labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: locCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Map Location / Coordinates *',
                    labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Description & Features (Optional)',
                    labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final name = nameCtrl.text.trim();
                            final cap = int.tryParse(capCtrl.text.trim()) ?? 0;

                            if (name.isEmpty || cap <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please provide valid name and capacity greater than zero.')),
                              );
                              return;
                            }

                            setModalState(() => isSaving = true);
                            final messenger = ScaffoldMessenger.of(context);
                            final nav = Navigator.of(ctx);

                            try {
                              final facId = existing?.facilityId ?? 'FAC-${DateTime.now().millisecondsSinceEpoch}';
                              final model = FacilityModel(
                                docId: existing?.docId,
                                facilityId: facId,
                                name: name,
                                type: type,
                                building: bldCtrl.text.trim(),
                                floor: floorCtrl.text.trim(),
                                roomNumber: roomCtrl.text.trim(),
                                description: descCtrl.text.trim(),
                                location: locCtrl.text.trim(),
                                capacity: cap,
                                status: status,
                              );

                              if (isEditing && existing.docId != null) {
                                await _firestore.collection('facilities').doc(existing.docId).update(model.toMap());
                              } else {
                                await _firestore.collection('facilities').add(model.toMap());
                              }

                              nav.pop();
                              messenger.showSnackBar(SnackBar(content: Text('Facility "$name" saved successfully!'), backgroundColor: Colors.green));
                            } catch (e) {
                              setModalState(() => isSaving = false);
                              messenger.showSnackBar(SnackBar(content: Text('Failed to save facility: $e'), backgroundColor: Colors.redAccent));
                            }
                          },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                    icon: isSaving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_rounded, color: Colors.white, size: 16),
                    label: Text(isEditing ? 'Save Changes' : 'Create Facility', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        title: const Row(
          children: [
            Icon(Icons.business_rounded, color: Colors.tealAccent),
            SizedBox(width: 8),
            Text('Campus Facilities Directory', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFacilityModal(),
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Facility', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
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
                    hintText: 'Search facilities by name or room...',
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
              ],
            ),
          ),

          // Facilities List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('facilities').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
                }

                final docs = snapshot.data?.docs ?? [];
                final allFacilities = docs.map((d) => FacilityModel.fromFirestore(d)).toList();

                final filtered = allFacilities.where((f) {
                  final matchesSearch = f.name.toLowerCase().contains(_searchQuery) ||
                      f.building.toLowerCase().contains(_searchQuery) ||
                      f.roomNumber.toLowerCase().contains(_searchQuery);
                  final matchesType = _selectedType == 'All' || f.type == _selectedType;

                  return matchesSearch && matchesType;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No campus facilities found matching criteria.', style: TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final fac = filtered[index];
                    final isAvail = fac.isAvailable;

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
                          const SizedBox(height: 6),
                          Text('Location: ${fac.location} • Capacity: ${fac.capacity} seats', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () => _showFacilityModal(existing: fac),
                                icon: const Icon(Icons.edit, size: 14, color: Colors.tealAccent),
                                label: const Text('Edit', style: TextStyle(color: Colors.tealAccent, fontSize: 12)),
                              ),
                              TextButton.icon(
                                onPressed: () async {
                                  if (fac.docId != null) {
                                    final newSt = isAvail ? 'Closed' : 'Available';
                                    await _firestore.collection('facilities').doc(fac.docId).update({'status': newSt});
                                  }
                                },
                                icon: Icon(isAvail ? Icons.cancel_outlined : Icons.check_circle_outline, size: 14, color: isAvail ? Colors.orangeAccent : Colors.greenAccent),
                                label: Text(isAvail ? 'Close' : 'Open', style: TextStyle(color: isAvail ? Colors.orangeAccent : Colors.greenAccent, fontSize: 12)),
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
