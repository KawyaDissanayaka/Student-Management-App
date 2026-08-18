import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/transport_model.dart';

class CampusTransportScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const CampusTransportScreen({super.key, this.userData});

  @override
  State<CampusTransportScreen> createState() => _CampusTransportScreenState();
}

class _CampusTransportScreenState extends State<CampusTransportScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _showMapPreviewDialog(BuildContext context, TransportStopModel stop) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.pin_drop_rounded, color: Colors.tealAccent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                stop.pointName,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Location: ${stop.address}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            Text('Pickup Time: ${stop.pickupTime}', style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold)),
            Text('Drop-off Time: ${stop.dropOffTime}', style: const TextStyle(color: Colors.tealAccent, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),

            // Simulated interactive map render container
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
                      const Icon(Icons.location_on_rounded, size: 36, color: Colors.redAccent),
                      const SizedBox(height: 4),
                      Text(stop.pointName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                      Text(stop.address, style: const TextStyle(color: Colors.grey, fontSize: 9)),
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

  void _savePreferredTransport({
    required String studentEmail,
    required String studentId,
    required String routeId,
    required String routeName,
    required String stopId,
    required String stopName,
  }) async {
    try {
      final pref = StudentTransportPreferenceModel(
        studentId: studentId,
        studentEmail: studentEmail,
        selectedRouteId: routeId,
        selectedRouteName: routeName,
        selectedStopId: stopId,
        selectedStopName: stopName,
      );

      await _firestore
          .collection('studentTransportPreferences')
          .doc(studentEmail.trim().toLowerCase())
          .set(pref.toMap(), SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved "$routeName - $stopName" as your preferred shuttle stop!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save preference: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = (widget.userData?['email'] ?? 'student@uni.lk').toString().trim().toLowerCase();
    final studentId = (widget.userData?['studentId'] ?? 'STU-1002').toString();

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
            Text('University Shuttle & Transport', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('studentTransportPreferences').doc(email).snapshots(),
        builder: (context, prefSnap) {
          final prefData = prefSnap.data?.data() as Map<String, dynamic>?;
          final savedRouteId = prefData?['selectedRouteId'];
          final savedStopId = prefData?['selectedStopId'];

          return StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('transportRoutes').where('status', isEqualTo: 'Active').snapshots(),
            builder: (context, routeSnap) {
              if (routeSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
              }

              final docs = routeSnap.data?.docs ?? [];
              final routes = docs.map((d) => TransportRouteModel.fromFirestore(d)).toList();

              return StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('transportSchedules').where('status', isEqualTo: 'Active').snapshots(),
                builder: (context, schedSnap) {
                  final schedDocs = schedSnap.data?.docs ?? [];
                  final schedules = schedDocs.map((d) => TransportScheduleModel.fromFirestore(d)).toList();

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Preferred Route Summary Card if selected
                      if (prefData != null) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.teal.withAlpha(20),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.tealAccent.withAlpha(100)),
                          ),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.teal,
                                child: Icon(Icons.star_rounded, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('MY PREFERRED SHUTTLE', style: TextStyle(color: Colors.tealAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                    const SizedBox(height: 2),
                                    Text('${prefData['selectedRouteName']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                    Text('Pickup Stop: ${prefData['selectedStopName']}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      const Text('AVAILABLE SHUTTLE ROUTES', style: TextStyle(color: Colors.tealAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      const SizedBox(height: 10),

                      if (routes.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          alignment: Alignment.center,
                          child: const Text('No active shuttle routes available at this time.', style: TextStyle(color: Colors.grey)),
                        )
                      else
                        ...routes.map((r) {
                          final isRouteSelected = r.routeId == savedRouteId;
                          final matchingSchedules = schedules.where((s) => s.routeId == r.routeId).toList();

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isRouteSelected ? Colors.tealAccent : Colors.white10),
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
                                      child: Text(r.routeId, style: const TextStyle(color: Colors.tealAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                    Text('${r.distance} KM Distance', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(r.routeName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 4),
                                Text('${r.startPoint} ➔ ${r.destination}', style: const TextStyle(color: Colors.amberAccent, fontSize: 12)),

                                if (matchingSchedules.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)),
                                    child: Column(
                                      children: matchingSchedules.map((ms) => Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Bus: ${ms.busRegistration}', style: const TextStyle(color: Colors.tealAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                                          Text('${ms.departureTime} - ${ms.arrivalTime}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                        ],
                                      )).toList(),
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 12),
                                const Text('Pickup & Drop-off Stops:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),

                                ...r.stops.map((st) {
                                  final isStopSelected = isRouteSelected && st.stopId == savedStopId;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isStopSelected ? Colors.teal.withAlpha(30) : const Color(0xFF0F172A),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: isStopSelected ? Colors.tealAccent : Colors.white10),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 12,
                                          backgroundColor: isStopSelected ? Colors.tealAccent : Colors.white10,
                                          child: Text('${st.sequence}', style: TextStyle(color: isStopSelected ? Colors.black : Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(st.pointName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                              Text('Pickup: ${st.pickupTime} • Drop-off: ${st.dropOffTime}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.map_rounded, size: 16, color: Colors.tealAccent),
                                          tooltip: 'View on Map',
                                          onPressed: () => _showMapPreviewDialog(context, st),
                                        ),
                                        ElevatedButton(
                                          onPressed: isStopSelected
                                              ? null
                                              : () => _savePreferredTransport(
                                                    studentEmail: email,
                                                    studentId: studentId,
                                                    routeId: r.routeId,
                                                    routeName: r.routeName,
                                                    stopId: st.stopId,
                                                    stopName: st.pointName,
                                                  ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isStopSelected ? Colors.grey : Colors.teal,
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                          ),
                                          child: Text(isStopSelected ? 'Selected' : 'Select', style: const TextStyle(color: Colors.white, fontSize: 11)),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          );
                        }),
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
}
