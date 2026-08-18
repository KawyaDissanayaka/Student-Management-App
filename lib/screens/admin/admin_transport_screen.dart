import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/transport_model.dart';

class AdminTransportScreen extends StatefulWidget {
  const AdminTransportScreen({super.key});

  @override
  State<AdminTransportScreen> createState() => _AdminTransportScreenState();
}

class _AdminTransportScreenState extends State<AdminTransportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // 1. ROUTE CREATION / EDIT MODAL
  // ---------------------------------------------------------------------------
  void _showRouteModal({TransportRouteModel? existing}) {
    final isEditing = existing != null;
    final nameCtrl = TextEditingController(text: existing?.routeName ?? '');
    final startCtrl = TextEditingController(text: existing?.startPoint ?? '');
    final destCtrl = TextEditingController(text: existing?.destination ?? 'Main Campus');
    final distCtrl = TextEditingController(text: existing != null ? '${existing.distance}' : '25.0');
    String status = existing?.status ?? 'Active';

    // Stops list
    List<TransportStopModel> stops = existing != null
        ? List.from(existing.stops)
        : [
            TransportStopModel(stopId: 'STP-1', pointName: 'Central Bus Stand', address: 'Main St', pickupTime: '06:30 AM', dropOffTime: '05:30 PM', sequence: 1),
            TransportStopModel(stopId: 'STP-2', pointName: 'Town Hall Junction', address: 'High Level Rd', pickupTime: '06:50 AM', dropOffTime: '05:10 PM', sequence: 2),
            TransportStopModel(stopId: 'STP-3', pointName: 'Campus Main Gate', address: 'University Way', pickupTime: '07:30 AM', dropOffTime: '04:30 PM', sequence: 3),
          ];

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
                    Text(isEditing ? 'Edit Transport Route' : 'Add New Transport Route', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Route Name (e.g. Colombo - Campus Express) *',
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
                      child: TextField(
                        controller: startCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Start Point *',
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
                        controller: destCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Destination *',
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
                        controller: distCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Distance (KM) *',
                          labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: status,
                        dropdownColor: const Color(0xFF0F172A),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Route Status',
                          labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: ['Active', 'Inactive'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (v) => setModalState(() => status = v ?? 'Active'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Stops builder header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('PICKUP & DROP-OFF STOPS', style: TextStyle(color: Colors.tealAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    TextButton.icon(
                      onPressed: () {
                        setModalState(() {
                          final nextSeq = stops.length + 1;
                          stops.add(TransportStopModel(
                            stopId: 'STP-$nextSeq',
                            pointName: 'New Stop $nextSeq',
                            address: 'Location',
                            pickupTime: '07:00 AM',
                            dropOffTime: '05:00 PM',
                            sequence: nextSeq,
                          ));
                        });
                      },
                      icon: const Icon(Icons.add, size: 14, color: Colors.tealAccent),
                      label: const Text('Add Stop', style: TextStyle(color: Colors.tealAccent, fontSize: 11)),
                    ),
                  ],
                ),

                // Stops list
                ...stops.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final st = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        CircleAvatar(radius: 10, backgroundColor: Colors.teal, child: Text('${st.sequence}', style: const TextStyle(color: Colors.white, fontSize: 10))),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(st.pointName, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                              Text('Pickup: ${st.pickupTime} • Drop: ${st.dropOffTime}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                            ],
                          ),
                        ),
                        if (stops.length > 1)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                            onPressed: () => setModalState(() => stops.removeAt(idx)),
                          ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final name = nameCtrl.text.trim();
                            if (name.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter route name.')));
                              return;
                            }

                            setModalState(() => isSaving = true);
                            final messenger = ScaffoldMessenger.of(context);
                            final nav = Navigator.of(ctx);

                            try {
                              final routeId = existing?.routeId ?? 'RTE-${DateTime.now().millisecondsSinceEpoch}';
                              final rModel = TransportRouteModel(
                                docId: existing?.docId,
                                routeId: routeId,
                                routeName: name,
                                startPoint: startCtrl.text.trim(),
                                destination: destCtrl.text.trim(),
                                distance: double.tryParse(distCtrl.text.trim()) ?? 0.0,
                                status: status,
                                stops: stops,
                              );

                              if (isEditing && existing.docId != null) {
                                await _firestore.collection('transportRoutes').doc(existing.docId).update(rModel.toMap());
                              } else {
                                await _firestore.collection('transportRoutes').add(rModel.toMap());
                              }

                              nav.pop();
                              messenger.showSnackBar(SnackBar(content: Text('Route $routeId saved successfully!'), backgroundColor: Colors.green));
                            } catch (e) {
                              setModalState(() => isSaving = false);
                              messenger.showSnackBar(SnackBar(content: Text('Failed to save route: $e'), backgroundColor: Colors.redAccent));
                            }
                          },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                    icon: isSaving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_rounded, color: Colors.white, size: 16),
                    label: Text(isEditing ? 'Save Route Changes' : 'Create Route', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. BUS CREATION / EDIT MODAL
  // ---------------------------------------------------------------------------
  void _showBusModal({TransportBusModel? existing}) {
    final isEditing = existing != null;
    final regCtrl = TextEditingController(text: existing?.registrationNumber ?? '');
    final nameCtrl = TextEditingController(text: existing?.busNameOrNumber ?? '');
    final capCtrl = TextEditingController(text: existing != null ? '${existing.capacity}' : '45');
    final driverCtrl = TextEditingController(text: existing?.driver ?? '');
    final contactCtrl = TextEditingController(text: existing?.contactNumber ?? '');
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
                    Text(isEditing ? 'Edit Shuttle Bus' : 'Add New Shuttle Bus', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: regCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Registration Number (e.g. WP NA-4521) *',
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
                      child: TextField(
                        controller: nameCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Bus Name / Fleet No *',
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
                          labelText: 'Seating Capacity *',
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
                        controller: driverCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Assigned Driver *',
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
                        controller: contactCtrl,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Contact Phone *',
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

                DropdownButtonFormField<String>(
                  initialValue: status,
                  dropdownColor: const Color(0xFF0F172A),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Bus Availability Status',
                    labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: ['Available', 'Maintenance', 'Inactive'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setModalState(() => status = v ?? 'Available'),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final reg = regCtrl.text.trim();
                            if (reg.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter registration number.')));
                              return;
                            }

                            setModalState(() => isSaving = true);
                            final messenger = ScaffoldMessenger.of(context);
                            final nav = Navigator.of(ctx);

                            try {
                              final busId = existing?.busId ?? 'BUS-${DateTime.now().millisecondsSinceEpoch}';
                              final bModel = TransportBusModel(
                                docId: existing?.docId,
                                busId: busId,
                                registrationNumber: reg,
                                busNameOrNumber: nameCtrl.text.trim(),
                                capacity: int.tryParse(capCtrl.text.trim()) ?? 45,
                                driver: driverCtrl.text.trim(),
                                contactNumber: contactCtrl.text.trim(),
                                status: status,
                              );

                              if (isEditing && existing.docId != null) {
                                await _firestore.collection('transportBuses').doc(existing.docId).update(bModel.toMap());
                              } else {
                                await _firestore.collection('transportBuses').add(bModel.toMap());
                              }

                              nav.pop();
                              messenger.showSnackBar(SnackBar(content: Text('Bus $reg saved successfully!'), backgroundColor: Colors.green));
                            } catch (e) {
                              setModalState(() => isSaving = false);
                              messenger.showSnackBar(SnackBar(content: Text('Failed to save bus: $e'), backgroundColor: Colors.redAccent));
                            }
                          },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                    icon: isSaving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_rounded, color: Colors.white, size: 16),
                    label: Text(isEditing ? 'Save Bus Changes' : 'Register Bus', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. SCHEDULE CREATION MODAL WITH CONFLICT PREVENTION
  // ---------------------------------------------------------------------------
  void _showScheduleModal(List<TransportRouteModel> routes, List<TransportBusModel> buses, List<TransportScheduleModel> existingSchedules) {
    if (routes.isEmpty || buses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one route and bus before scheduling.')));
      return;
    }

    String selectedRouteId = routes.first.routeId;
    String selectedBusId = buses.first.busId;
    final depCtrl = TextEditingController(text: '06:30 AM');
    final arrCtrl = TextEditingController(text: '08:15 AM');
    List<String> days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Assign Transport Schedule', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                initialValue: selectedRouteId,
                dropdownColor: const Color(0xFF0F172A),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Select Route *',
                  labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: routes.map((r) => DropdownMenuItem(value: r.routeId, child: Text('${r.routeName} (${r.distance} km)'))).toList(),
                onChanged: (v) => setModalState(() => selectedRouteId = v!),
              ),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                initialValue: selectedBusId,
                dropdownColor: const Color(0xFF0F172A),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Assign Bus *',
                  labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: buses.map((b) => DropdownMenuItem(value: b.busId, child: Text('${b.registrationNumber} - ${b.busNameOrNumber} (${b.capacity} Seats)'))).toList(),
                onChanged: (v) => setModalState(() => selectedBusId = v!),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: depCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Departure Time *',
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
                      controller: arrCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Arrival Time *',
                        labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final selectedRoute = routes.firstWhere((r) => r.routeId == selectedRouteId);
                          final selectedBus = buses.firstWhere((b) => b.busId == selectedBusId);

                          final candidate = TransportScheduleModel(
                            scheduleId: 'SCH-${DateTime.now().millisecondsSinceEpoch}',
                            routeId: selectedRouteId,
                            routeName: selectedRoute.routeName,
                            busId: selectedBusId,
                            busRegistration: selectedBus.registrationNumber,
                            operatingDays: days,
                            departureTime: depCtrl.text.trim(),
                            arrivalTime: arrCtrl.text.trim(),
                            status: 'Active',
                          );

                          // Check overlap conflict with existing schedules for the same bus
                          final conflict = existingSchedules.any((ex) => TransportScheduleModel.isBusScheduleConflicting(existing: ex, candidate: candidate));

                          if (conflict) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: Bus ${selectedBus.registrationNumber} already has an active overlapping schedule!'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                            return;
                          }

                          setModalState(() => isSaving = true);
                          final messenger = ScaffoldMessenger.of(context);
                          final nav = Navigator.of(ctx);

                          try {
                            await _firestore.collection('transportSchedules').add(candidate.toMap());
                            nav.pop();
                            messenger.showSnackBar(const SnackBar(content: Text('Transport schedule created successfully!'), backgroundColor: Colors.green));
                          } catch (e) {
                            setModalState(() => isSaving = false);
                            messenger.showSnackBar(SnackBar(content: Text('Failed to save schedule: $e'), backgroundColor: Colors.redAccent));
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  icon: const Icon(Icons.schedule_rounded, color: Colors.white, size: 16),
                  label: const Text('Create Schedule', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            Icon(Icons.directions_bus_rounded, color: Colors.tealAccent),
            SizedBox(width: 8),
            Text('Transport & Shuttle Management', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.tealAccent,
          labelColor: Colors.tealAccent,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Routes', icon: Icon(Icons.alt_route_rounded, size: 18)),
            Tab(text: 'Fleet / Buses', icon: Icon(Icons.directions_bus_filled_rounded, size: 18)),
            Tab(text: 'Schedules', icon: Icon(Icons.calendar_month_rounded, size: 18)),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('transportRoutes').snapshots(),
        builder: (context, routeSnap) {
          final routes = (routeSnap.data?.docs ?? []).map((d) => TransportRouteModel.fromFirestore(d)).toList();

          return StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('transportBuses').snapshots(),
            builder: (context, busSnap) {
              final buses = (busSnap.data?.docs ?? []).map((d) => TransportBusModel.fromFirestore(d)).toList();

              return StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('transportSchedules').snapshots(),
                builder: (context, schedSnap) {
                  final schedules = (schedSnap.data?.docs ?? []).map((d) => TransportScheduleModel.fromFirestore(d)).toList();

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      // 1. Routes View
                      _buildRoutesTab(routes),

                      // 2. Buses View
                      _buildBusesTab(buses),

                      // 3. Schedules View
                      _buildSchedulesTab(schedules, routes, buses),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRoutesTab(List<TransportRouteModel> routes) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRouteModal(),
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Route', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: routes.isEmpty
          ? const Center(child: Text('No transport routes created yet.', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: routes.length,
              itemBuilder: (context, index) {
                final r = routes[index];
                final isActive = r.isActive;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: Colors.teal.withAlpha(30), borderRadius: BorderRadius.circular(6)),
                            child: Text(r.routeId, style: const TextStyle(color: Colors.tealAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: isActive ? Colors.green.withAlpha(30) : Colors.red.withAlpha(30), borderRadius: BorderRadius.circular(6)),
                            child: Text(r.status.toUpperCase(), style: TextStyle(color: isActive ? Colors.greenAccent : Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(r.routeName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text('${r.startPoint} ➔ ${r.destination} (${r.distance} KM)', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 8),
                      Text('Stops: ${r.pickupPointNames.join(" • ")}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => _showRouteModal(existing: r),
                            icon: const Icon(Icons.edit, size: 14, color: Colors.tealAccent),
                            label: const Text('Edit', style: TextStyle(color: Colors.tealAccent, fontSize: 12)),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              if (r.docId != null) {
                                final newSt = isActive ? 'Inactive' : 'Active';
                                await _firestore.collection('transportRoutes').doc(r.docId).update({'status': newSt});
                              }
                            },
                            icon: Icon(isActive ? Icons.cancel_outlined : Icons.check_circle_outline, size: 14, color: isActive ? Colors.orangeAccent : Colors.greenAccent),
                            label: Text(isActive ? 'Deactivate' : 'Activate', style: TextStyle(color: isActive ? Colors.orangeAccent : Colors.greenAccent, fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildBusesTab(List<TransportBusModel> buses) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBusModal(),
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Register Bus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: buses.isEmpty
          ? const Center(child: Text('No shuttle buses registered.', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: buses.length,
              itemBuilder: (context, index) {
                final b = buses[index];
                Color stColor = Colors.greenAccent;
                if (b.status == 'Maintenance') stColor = Colors.orangeAccent;
                if (b.status == 'Inactive') stColor = Colors.redAccent;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(b.registrationNumber, style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 15)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: stColor.withAlpha(30), borderRadius: BorderRadius.circular(6)),
                            child: Text(b.status.toUpperCase(), style: TextStyle(color: stColor, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('${b.busNameOrNumber} • Capacity: ${b.capacity} Seats', style: const TextStyle(color: Colors.white, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text('Driver: ${b.driver} (${b.contactNumber})', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => _showBusModal(existing: b),
                            icon: const Icon(Icons.edit, size: 14, color: Colors.tealAccent),
                            label: const Text('Edit Bus', style: TextStyle(color: Colors.tealAccent, fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildSchedulesTab(List<TransportScheduleModel> schedules, List<TransportRouteModel> routes, List<TransportBusModel> buses) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showScheduleModal(routes, buses, schedules),
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Create Schedule', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: schedules.isEmpty
          ? const Center(child: Text('No active transport schedules.', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: schedules.length,
              itemBuilder: (context, index) {
                final s = schedules[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(s.routeName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: Colors.amber.withAlpha(30), borderRadius: BorderRadius.circular(6)),
                            child: Text(s.busRegistration, style: const TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('Departure: ${s.departureTime} ➔ Arrival: ${s.arrivalTime}', style: const TextStyle(color: Colors.tealAccent, fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('Days: ${s.operatingDays.join(", ")}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
