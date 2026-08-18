import 'package:cloud_firestore/cloud_firestore.dart';

class FacilityModel {
  final String? docId;
  final String facilityId;
  final String name;
  final String type; // 'Lecture Hall' | 'Laboratory' | 'Library' | 'Canteen' | 'Office' | 'Examination Hall' | 'Student Service' | 'Other'
  final String category; // legacy alias
  final String building;
  final String floor;
  final String roomNumber;
  final String description;
  final String location; // Map Coordinates or Area Name
  final int capacity;
  final String status; // 'Available' | 'Maintenance' | 'Closed'
  final String createdAt;
  final String openingHours;
  final String contactEmail;
  final String contactPhone;
  final String iconName;

  FacilityModel({
    this.docId,
    required this.facilityId,
    required this.name,
    this.type = 'Lecture Hall',
    String? category,
    this.building = 'Main Academic Block',
    this.floor = 'Ground Floor',
    this.roomNumber = '',
    this.description = '',
    this.location = 'Main Campus',
    this.capacity = 50,
    this.status = 'Available',
    String? createdAt,
    this.openingHours = '08:00 AM - 05:00 PM',
    this.contactEmail = 'facilities@uni.lk',
    this.contactPhone = '+94 11 234 5678',
    this.iconName = 'business',
  })  : category = category ?? type,
        createdAt = createdAt ?? DateTime.now().toIso8601String();

  static const List<String> supportedTypes = [
    'Lecture Hall',
    'Laboratory',
    'Library',
    'Canteen',
    'Office',
    'Examination Hall',
    'Student Service',
    'Other',
  ];

  static const List<String> supportedStatuses = [
    'Available',
    'Maintenance',
    'Closed',
  ];

  bool get isAvailable => status.toLowerCase() == 'available';

  Map<String, dynamic> toMap() {
    return {
      'facilityId': facilityId,
      'name': name,
      'type': type,
      'category': type,
      'building': building,
      'floor': floor,
      'roomNumber': roomNumber,
      'description': description,
      'location': location,
      'capacity': capacity,
      'status': status,
      'createdAt': createdAt,
      'openingHours': openingHours,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'iconName': iconName,
    };
  }

  factory FacilityModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final t = data['type'] ?? (data['category'] ?? 'Lecture Hall');

    return FacilityModel(
      docId: doc.id,
      facilityId: data['facilityId'] ?? doc.id,
      name: data['name'] ?? '',
      type: t,
      category: t,
      building: data['building'] ?? 'Main Campus Complex',
      floor: data['floor'] ?? 'Ground Floor',
      roomNumber: data['roomNumber'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] ?? 'Main Campus',
      capacity: (data['capacity'] as num?)?.toInt() ?? 50,
      status: data['status'] ?? 'Available',
      createdAt: data['createdAt'] ?? '',
      openingHours: data['openingHours'] ?? '08:00 AM - 05:00 PM',
      contactEmail: data['contactEmail'] ?? 'facilities@uni.lk',
      contactPhone: data['contactPhone'] ?? '+94 11 234 5678',
      iconName: data['iconName'] ?? 'business',
    );
  }

  factory FacilityModel.fromMap(Map<String, dynamic> map, {String? id}) {
    final t = map['type'] ?? (map['category'] ?? 'Lecture Hall');
    return FacilityModel(
      docId: id,
      facilityId: map['facilityId'] ?? '',
      name: map['name'] ?? '',
      type: t,
      category: t,
      building: map['building'] ?? 'Main Campus Complex',
      floor: map['floor'] ?? 'Ground Floor',
      roomNumber: map['roomNumber'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? 'Main Campus',
      capacity: (map['capacity'] as num?)?.toInt() ?? 50,
      status: map['status'] ?? 'Available',
      createdAt: map['createdAt'] ?? '',
      openingHours: map['openingHours'] ?? '08:00 AM - 05:00 PM',
      contactEmail: map['contactEmail'] ?? 'facilities@uni.lk',
      contactPhone: map['contactPhone'] ?? '+94 11 234 5678',
      iconName: map['iconName'] ?? 'business',
    );
  }
}
