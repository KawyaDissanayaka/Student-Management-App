import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/hall_model.dart';

class HallService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _hallsRef => _firestore.collection('halls');

  /// Stream of all halls
  Stream<List<HallModel>> getHallsStream() {
    return _hallsRef.snapshots().map((snap) => snap.docs.map((d) => HallModel.fromFirestore(d)).toList());
  }

  /// Stream of only active halls available for booking
  Stream<List<HallModel>> getActiveHallsStream() {
    return _hallsRef.where('status', isEqualTo: 'active').snapshots().map((snap) => snap.docs.map((d) => HallModel.fromFirestore(d)).toList());
  }

  /// Add new lecture hall with duplicate check
  Future<String> addHall(HallModel hall) async {
    try {
      final cleanId = hall.hallId.trim().toUpperCase();
      final duplicateQuery = await _hallsRef.where('hallId', isEqualTo: cleanId).limit(1).get();

      if (duplicateQuery.docs.isNotEmpty) {
        throw Exception('A Lecture Hall with ID "$cleanId" already exists.');
      }

      final docRef = await _hallsRef.add(hall.toMap());
      debugPrint('Hall added successfully: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding hall: $e');
      rethrow;
    }
  }

  /// Update existing hall
  Future<void> updateHall(String docId, HallModel hall) async {
    try {
      final cleanId = hall.hallId.trim().toUpperCase();
      final duplicateQuery = await _hallsRef.where('hallId', isEqualTo: cleanId).get();

      final otherWithSameId = duplicateQuery.docs.where((d) => d.id != docId).toList();
      if (otherWithSameId.isNotEmpty) {
        throw Exception('Another Hall already uses ID "$cleanId".');
      }

      await _hallsRef.doc(docId).update(hall.toMap());
    } catch (e) {
      debugPrint('Error updating hall: $e');
      rethrow;
    }
  }

  /// Toggle hall status between 'active', 'maintenance', 'inactive'
  Future<void> toggleHallStatus(String docId, String newStatus) async {
    try {
      await _hallsRef.doc(docId).update({'status': newStatus});
    } catch (e) {
      debugPrint('Error toggling hall status: $e');
      rethrow;
    }
  }

  /// Seeds default campus halls if empty
  Future<void> ensureDefaultHallsInitialized() async {
    try {
      final snap = await _hallsRef.limit(1).get();
      if (snap.docs.isEmpty) {
        final defaults = [
          {
            'hallId': 'HALL-01',
            'name': 'Main Auditorium 01',
            'building': 'Building A (Main Block)',
            'floor': 'Ground Floor',
            'capacity': 120,
            'type': 'Auditorium',
            'facilities': ['Projector', 'Wi-Fi', 'Air Conditioning', 'Audio System'],
            'status': 'active',
          },
          {
            'hallId': 'HALL-02',
            'name': 'Lecture Hall B-101',
            'building': 'Building B (Tech Block)',
            'floor': '1st Floor',
            'capacity': 60,
            'type': 'Lecture Hall',
            'facilities': ['Projector', 'Wi-Fi', 'Air Conditioning'],
            'status': 'active',
          },
          {
            'hallId': 'LAB-01',
            'name': 'Computing Lab 01',
            'building': 'Building B (Tech Block)',
            'floor': '2nd Floor',
            'capacity': 45,
            'type': 'Computer Lab',
            'facilities': ['Computers', 'Projector', 'Wi-Fi', 'Air Conditioning'],
            'status': 'active',
          },
          {
            'hallId': 'LAB-02',
            'name': 'AI & Robotics Lab 02',
            'building': 'Building D (Engineering)',
            'floor': '1st Floor',
            'capacity': 40,
            'type': 'Laboratory',
            'facilities': ['Computers', 'Projector', 'Wi-Fi', 'Air Conditioning'],
            'status': 'active',
          },
        ];

        for (var h in defaults) {
          await _hallsRef.add(h);
        }
      }
    } catch (e) {
      debugPrint('Default halls setup note: $e');
    }
  }
}
