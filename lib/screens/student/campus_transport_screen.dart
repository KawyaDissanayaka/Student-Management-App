import 'package:flutter/material.dart';
import '../../services/student_portal_service.dart';
import '../../models/transport_model.dart';

class CampusTransportScreen extends StatelessWidget {
  const CampusTransportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final portalService = StudentPortalService();

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
            Text('University Shuttle & Transport', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: StreamBuilder<List<TransportModel>>(
        stream: portalService.getTransportRoutesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
          }

          final routes = snapshot.data ?? [];

          if (routes.isEmpty) {
            return const Center(
              child: Text('No bus routes registered currently.', style: TextStyle(color: Colors.white70)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: routes.length,
            itemBuilder: (context, index) {
              final r = routes[index];
              final isOnTime = r.status.toLowerCase() == 'on_time';

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
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
                            r.busNumber,
                            style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isOnTime ? Colors.green.withAlpha(30) : Colors.orange.withAlpha(30),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            r.status.replaceAll('_', ' ').toUpperCase(),
                            style: TextStyle(
                              color: isOnTime ? Colors.greenAccent : Colors.orangeAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(r.routeName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        const Icon(Icons.departure_board_rounded, size: 14, color: Colors.amberAccent),
                        const SizedBox(width: 6),
                        Text('Departure: ${r.departureTime}', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 14),
                        const Icon(Icons.flag_rounded, size: 14, color: Colors.tealAccent),
                        const SizedBox(width: 6),
                        Text('Arrival: ${r.arrivalTime}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        const Icon(Icons.person_pin_rounded, size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text('Driver: ${r.driverName} (${r.driverPhone})', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white10, height: 1),
                    const SizedBox(height: 8),

                    const Text('Pickup Points & Stops:', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: r.pickupPoints.map((stop) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(6)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.pin_drop_rounded, size: 10, color: Colors.tealAccent),
                              const SizedBox(width: 4),
                              Text(stop, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
