import 'package:flutter/material.dart';
import '../../services/student_portal_service.dart';
import '../../models/facility_model.dart';

class CampusFacilitiesScreen extends StatelessWidget {
  const CampusFacilitiesScreen({super.key});

  IconData _getCategoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'library':
        return Icons.local_library_rounded;
      case 'laboratories':
      case 'it support':
        return Icons.computer_rounded;
      case 'cafeteria':
        return Icons.restaurant_rounded;
      case 'medical centre':
        return Icons.medical_services_rounded;
      case 'sports':
        return Icons.fitness_center_rounded;
      default:
        return Icons.business_rounded;
    }
  }

  Color _getCategoryColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'library':
        return Colors.indigoAccent;
      case 'laboratories':
      case 'it support':
        return Colors.cyanAccent;
      case 'cafeteria':
        return Colors.orangeAccent;
      case 'medical centre':
        return Colors.redAccent;
      case 'sports':
        return Colors.greenAccent;
      default:
        return Colors.tealAccent;
    }
  }

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
            Icon(Icons.apartment_rounded, color: Colors.amberAccent),
            SizedBox(width: 8),
            Text('Campus Facilities', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: StreamBuilder<List<FacilityModel>>(
        stream: portalService.getFacilitiesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
          }

          final facilities = snapshot.data ?? [];

          if (facilities.isEmpty) {
            return const Center(
              child: Text('No campus facilities registered yet.', style: TextStyle(color: Colors.white70)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: facilities.length,
            itemBuilder: (context, index) {
              final f = facilities[index];
              final iconColor = _getCategoryColor(f.category);

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
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: iconColor.withAlpha(30),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(_getCategoryIcon(f.category), color: iconColor, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(f.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 2),
                              Text(f.category, style: TextStyle(color: iconColor, fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(f.description, style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.3)),
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white10, height: 1),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: Colors.tealAccent),
                        const SizedBox(width: 6),
                        Text(f.location, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        const Spacer(),
                        const Icon(Icons.access_time_rounded, size: 14, color: Colors.amberAccent),
                        const SizedBox(width: 6),
                        Text(f.openingHours, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(f.contactPhone, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                        const Spacer(),
                        const Icon(Icons.email_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(f.contactEmail, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
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
