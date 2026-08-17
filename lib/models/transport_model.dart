import 'package:cloud_firestore/cloud_firestore.dart';

class TransportModel {
  final String? docId;
  final String routeId;
  final String routeName; // 'Colombo - Campus Line'
  final String busNumber; // 'WP ND-4589'
  final String driverName;
  final String driverPhone;
  final List<String> pickupPoints;
  final String departureTime;
  final String arrivalTime;
  final String status; // 'on_time', 'delayed', 'cancelled'

  TransportModel({
    this.docId,
    required this.routeId,
    required this.routeName,
    required this.busNumber,
    required this.driverName,
    required this.driverPhone,
    required this.pickupPoints,
    required this.departureTime,
    required this.arrivalTime,
    this.status = 'on_time',
  });

  factory TransportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return TransportModel(
      docId: doc.id,
      routeId: data['routeId'] ?? doc.id,
      routeName: data['routeName'] ?? '',
      busNumber: data['busNumber'] ?? '',
      driverName: data['driverName'] ?? '',
      driverPhone: data['driverPhone'] ?? '',
      pickupPoints: List<String>.from(data['pickupPoints'] ?? []),
      departureTime: data['departureTime'] ?? '06:30 AM',
      arrivalTime: data['arrivalTime'] ?? '08:15 AM',
      status: data['status'] ?? 'on_time',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'routeId': routeId,
      'routeName': routeName,
      'busNumber': busNumber,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'pickupPoints': pickupPoints,
      'departureTime': departureTime,
      'arrivalTime': arrivalTime,
      'status': status,
    };
  }
}
