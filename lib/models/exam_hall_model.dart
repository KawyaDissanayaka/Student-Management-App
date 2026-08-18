import 'package:cloud_firestore/cloud_firestore.dart';

class ExamHallModel {
  final String? docId;
  final String hallId;
  final String hallName;
  final String building;
  final String floor;
  final int capacity;
  final List<String> facilities;
  final String status; // 'Available', 'Maintenance', 'Inactive'
  final String? createdAt;
  final String? updatedAt;

  ExamHallModel({
    this.docId,
    required this.hallId,
    required this.hallName,
    required this.building,
    required this.floor,
    required this.capacity,
    required this.facilities,
    this.status = 'Available',
    this.createdAt,
    this.updatedAt,
  });

  bool get isAvailable => status.toLowerCase() == 'available';
  bool get isUnderMaintenance => status.toLowerCase() == 'maintenance';
  bool get isInactive => status.toLowerCase() == 'inactive';

  Map<String, dynamic> toMap() {
    return {
      'hallId': hallId,
      'hallName': hallName,
      'building': building,
      'floor': floor,
      'capacity': capacity,
      'facilities': facilities,
      'status': status,
      'createdAt': createdAt ?? DateTime.now().toIso8601String(),
      'updatedAt': updatedAt ?? DateTime.now().toIso8601String(),
    };
  }

  factory ExamHallModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ExamHallModel(
      docId: doc.id,
      hallId: data['hallId'] ?? doc.id,
      hallName: data['hallName'] ?? data['name'] ?? '',
      building: data['building'] ?? '',
      floor: data['floor'] ?? '',
      capacity: (data['capacity'] as num?)?.toInt() ?? 50,
      facilities: List<String>.from(data['facilities'] ?? []),
      status: data['status'] ?? 'Available',
      createdAt: data['createdAt']?.toString(),
      updatedAt: data['updatedAt']?.toString(),
    );
  }
}
