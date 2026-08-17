import 'package:cloud_firestore/cloud_firestore.dart';

class HallModel {
  final String? docId;
  final String hallId;
  final String name;
  final String building;
  final String floor;
  final int capacity;
  final String type; // 'Lecture Hall', 'Laboratory', 'Computer Lab', 'Auditorium'
  final List<String> facilities; // ['Projector', 'Computers', 'Wi-Fi', 'Air Conditioning', 'Audio System']
  final String status; // 'active', 'maintenance', 'inactive'

  HallModel({
    this.docId,
    required this.hallId,
    required this.name,
    required this.building,
    required this.floor,
    required this.capacity,
    required this.type,
    required this.facilities,
    this.status = 'active',
  });

  factory HallModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return HallModel(
      docId: doc.id,
      hallId: data['hallId'] ?? doc.id,
      name: data['name'] ?? '',
      building: data['building'] ?? '',
      floor: data['floor'] ?? '',
      capacity: (data['capacity'] as num?)?.toInt() ?? 50,
      type: data['type'] ?? 'Lecture Hall',
      facilities: List<String>.from(data['facilities'] ?? []),
      status: data['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hallId': hallId,
      'name': name,
      'building': building,
      'floor': floor,
      'capacity': capacity,
      'type': type,
      'facilities': facilities,
      'status': status,
    };
  }
}
