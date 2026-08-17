import 'package:cloud_firestore/cloud_firestore.dart';

class FacilityModel {
  final String? docId;
  final String facilityId;
  final String name;
  final String category; // 'Library', 'Laboratories', 'Cafeteria', 'Medical Centre', 'IT Support', 'Sports', 'Student Services'
  final String description;
  final String location;
  final String openingHours;
  final String contactEmail;
  final String contactPhone;
  final String iconName;

  FacilityModel({
    this.docId,
    required this.facilityId,
    required this.name,
    required this.category,
    required this.description,
    required this.location,
    required this.openingHours,
    required this.contactEmail,
    required this.contactPhone,
    this.iconName = 'business',
  });

  factory FacilityModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return FacilityModel(
      docId: doc.id,
      facilityId: data['facilityId'] ?? doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? 'Student Services',
      description: data['description'] ?? '',
      location: data['location'] ?? 'Main Campus',
      openingHours: data['openingHours'] ?? '8:00 AM - 5:00 PM',
      contactEmail: data['contactEmail'] ?? 'support@university.edu',
      contactPhone: data['contactPhone'] ?? '+94 11 234 5678',
      iconName: data['iconName'] ?? 'business',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'facilityId': facilityId,
      'name': name,
      'category': category,
      'description': description,
      'location': location,
      'openingHours': openingHours,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'iconName': iconName,
    };
  }
}
