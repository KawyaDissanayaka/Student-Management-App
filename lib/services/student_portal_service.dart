import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/timetable_model.dart';
import '../models/material_model.dart';
import '../models/exam_model.dart';
import '../models/result_model.dart';
import '../models/payment_model.dart';
import '../models/facility_model.dart';
import '../models/transport_model.dart';

class StudentPortalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _timetableRef => _firestore.collection('timetable');
  CollectionReference<Map<String, dynamic>> get _materialsRef => _firestore.collection('materials');
  CollectionReference<Map<String, dynamic>> get _examsRef => _firestore.collection('exams');
  CollectionReference<Map<String, dynamic>> get _resultsRef => _firestore.collection('results');
  CollectionReference<Map<String, dynamic>> get _paymentsRef => _firestore.collection('payments');
  CollectionReference<Map<String, dynamic>> get _facilitiesRef => _firestore.collection('facilities');
  CollectionReference<Map<String, dynamic>> get _transportRef => _firestore.collection('transport');
  CollectionReference<Map<String, dynamic>> get _enrollmentsRef => _firestore.collection('enrollments');

  // ─── TIMETABLE ─────────────────────────────────────────────────────────────
  Stream<List<TimetableModel>> getTimetableStream() {
    return _timetableRef.snapshots().map((snap) => snap.docs.map((d) => TimetableModel.fromFirestore(d)).toList());
  }

  Stream<List<TimetableModel>> getTimetableForSubjects(List<String> subjectCodes) {
    if (subjectCodes.isEmpty) {
      return getTimetableStream();
    }
    return _timetableRef.snapshots().map((snap) {
      final list = snap.docs.map((d) => TimetableModel.fromFirestore(d)).toList();
      return list.where((t) => subjectCodes.contains(t.subjectCode) || t.status == 'active').toList();
    });
  }

  // ─── MATERIALS ────────────────────────────────────────────────────────────
  Stream<List<MaterialModel>> getMaterialsForSubject(String subjectCode) {
    return _materialsRef.snapshots().map((snap) {
      final list = snap.docs
          .map((d) => MaterialModel.fromFirestore(d))
          .where((m) =>
              (m.moduleId.toUpperCase() == subjectCode.toUpperCase() || m.subjectCode.toUpperCase() == subjectCode.toUpperCase()) &&
              m.isPublished)
          .toList();
      list.sort((a, b) => a.weekNumber.compareTo(b.weekNumber));
      return list;
    });
  }

  // ─── EXAMS ────────────────────────────────────────────────────────────────
  Stream<List<ExamModel>> getExamsForSubjects(List<String> subjectCodes) {
    return _examsRef.snapshots().map((snap) {
      final list = snap.docs.map((d) => ExamModel.fromFirestore(d)).toList();
      if (subjectCodes.isEmpty) return list;
      return list.where((e) => subjectCodes.contains(e.subjectCode)).toList();
    });
  }

  Stream<List<ResultModel>> getStudentResultsStream(String studentEmail) {
    final cleanEmail = studentEmail.trim().toLowerCase();
    return _resultsRef.where('studentEmail', isEqualTo: cleanEmail).snapshots().map((snap) {
      final list = snap.docs
          .map((d) => ResultModel.fromFirestore(d))
          .where((r) => r.status.toLowerCase() != 'draft')
          .toList();
      list.sort((a, b) => a.semester.compareTo(b.semester));
      return list;
    });
  }

  /// Calculates cumulative GPA from list of student results
  static double calculateGPA(List<ResultModel> results) {
    if (results.isEmpty) return 0.0;
    double totalPoints = 0.0;
    int totalCredits = 0;

    for (var r in results) {
      totalPoints += (r.gradePoint * r.credits);
      totalCredits += r.credits;
    }

    if (totalCredits == 0) return 0.0;
    return totalPoints / totalCredits;
  }

  /// Calculates total completed credits (passed modules)
  static int calculateCompletedCredits(List<ResultModel> results) {
    int credits = 0;
    for (var r in results) {
      if (r.isPassed) {
        credits += r.credits;
      }
    }
    return credits;
  }

  // ─── PAYMENTS & FEES ──────────────────────────────────────────────────────
  Stream<List<PaymentModel>> getStudentPaymentsStream(String studentEmail) {
    final cleanEmail = studentEmail.trim().toLowerCase();
    return _paymentsRef.where('studentEmail', isEqualTo: cleanEmail).snapshots().map((snap) {
      final list = snap.docs.map((d) => PaymentModel.fromFirestore(d)).toList();
      list.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
      return list;
    });
  }

  /// Process online payment transaction
  Future<void> processPayment(PaymentModel payment) async {
    try {
      final docRef = await _paymentsRef.add(payment.toMap());
      debugPrint('Payment processed successfully with ID: ${docRef.id}');
    } catch (e) {
      debugPrint('Error processing payment: $e');
      throw Exception('Payment transaction failed: $e');
    }
  }

  // ─── MODULE REGISTRATION ──────────────────────────────────────────────────
  Future<void> registerModule({
    required String studentEmail,
    required String studentId,
    required String studentName,
    required String subjectDocId,
    required String subjectCode,
    required String subjectName,
    required String lecturerName,
    required String semester,
    required String academicYear,
  }) async {
    final cleanEmail = studentEmail.trim().toLowerCase();
    try {
      // Check for duplicate active registration
      final query = await _enrollmentsRef
          .where('studentEmail', isEqualTo: cleanEmail)
          .where('subjectCode', isEqualTo: subjectCode)
          .where('status', isEqualTo: 'active')
          .get();

      if (query.docs.isNotEmpty) {
        throw Exception('You are already registered for $subjectCode.');
      }

      await _enrollmentsRef.add({
        'studentDocId': studentId,
        'studentId': studentId,
        'studentName': studentName,
        'studentEmail': cleanEmail,
        'subjectDocId': subjectDocId,
        'subjectCode': subjectCode,
        'subjectName': subjectName,
        'lecturerName': lecturerName,
        'enrollmentDate': DateTime.now().toIso8601String().substring(0, 10),
        'status': 'active',
        'semester': semester,
        'academicYear': academicYear,
      });

      debugPrint('Student $cleanEmail successfully registered for $subjectCode');
    } catch (e) {
      debugPrint('Error registering module: $e');
      rethrow;
    }
  }

  // ─── FACILITIES ───────────────────────────────────────────────────────────
  Stream<List<FacilityModel>> getFacilitiesStream() {
    return _facilitiesRef.snapshots().map((snap) => snap.docs.map((d) => FacilityModel.fromFirestore(d)).toList());
  }

  // ─── TRANSPORT ────────────────────────────────────────────────────────────
  Stream<List<TransportModel>> getTransportRoutesStream() {
    return _transportRef.snapshots().map((snap) => snap.docs.map((d) => TransportModel.fromFirestore(d)).toList());
  }

  // ─── PROGRAMMATIC INITIAL DATA SEEDER ─────────────────────────────────────
  /// Populates campus life data if collections are newly accessed
  Future<void> ensureCampusDataInitialized() async {
    try {
      final facSnap = await _facilitiesRef.limit(1).get();
      if (facSnap.docs.isEmpty) {
        final defaultFacilities = [
          {
            'facilityId': 'FAC-101',
            'name': 'Main Central Library',
            'category': 'Library',
            'description': '3 floors of academic books, journals, study pods, and digital research terminals.',
            'location': 'Building B, Level 2',
            'openingHours': '8:00 AM - 8:00 PM',
            'contactEmail': 'library@university.edu',
            'contactPhone': '+94 11 234 5601',
            'iconName': 'local_library',
          },
          {
            'facilityId': 'FAC-102',
            'name': 'Computing & AI Labs',
            'category': 'Laboratories',
            'description': 'High-performance computing workstations with GPU clusters for software development.',
            'location': 'Tech Block, Room 304',
            'openingHours': '8:30 AM - 6:00 PM',
            'contactEmail': 'itlabs@university.edu',
            'contactPhone': '+94 11 234 5602',
            'iconName': 'computer',
          },
          {
            'facilityId': 'FAC-103',
            'name': 'Campus Cafeteria & Lounge',
            'category': 'Cafeteria',
            'description': 'Fresh healthy meals, snacks, barista coffee, and social dining spaces.',
            'location': 'Student Center, Ground Floor',
            'openingHours': '7:30 AM - 7:00 PM',
            'contactEmail': 'cafeteria@university.edu',
            'contactPhone': '+94 11 234 5603',
            'iconName': 'restaurant',
          },
          {
            'facilityId': 'FAC-104',
            'name': 'Health & Medical Centre',
            'category': 'Medical Centre',
            'description': 'Full-time nursing staff, first aid, routine consultations, and emergency care.',
            'location': 'Administration Wing, Ground Floor',
            'openingHours': '8:00 AM - 5:00 PM',
            'contactEmail': 'health@university.edu',
            'contactPhone': '+94 11 234 5604',
            'iconName': 'medical_services',
          },
          {
            'facilityId': 'FAC-105',
            'name': 'Sports Complex & Gym',
            'category': 'Sports',
            'description': 'Indoor badminton, basketball courts, fitness gym, and swimming pool.',
            'location': 'West Wing Pavilion',
            'openingHours': '6:00 AM - 9:00 PM',
            'contactEmail': 'sports@university.edu',
            'contactPhone': '+94 11 234 5605',
            'iconName': 'fitness_center',
          },
        ];

        for (var f in defaultFacilities) {
          await _facilitiesRef.add(f);
        }
      }

      final transSnap = await _transportRef.limit(1).get();
      if (transSnap.docs.isEmpty) {
        final defaultRoutes = [
          {
            'routeId': 'TR-101',
            'routeName': 'Colombo Fort Express (Route 01)',
            'busNumber': 'WP ND-4589',
            'driverName': 'Saman Kumara',
            'driverPhone': '+94 77 123 4567',
            'pickupPoints': ['Fort Station', 'Bambalapitiya', 'Nugegoda', 'Maharagama', 'University Campus'],
            'departureTime': '06:30 AM',
            'arrivalTime': '08:15 AM',
            'status': 'on_time',
          },
          {
            'routeId': 'TR-102',
            'routeName': 'Kandy Road Shuttle (Route 02)',
            'busNumber': 'WP NB-8821',
            'driverName': 'Kamal Perera',
            'driverPhone': '+94 71 987 6543',
            'pickupPoints': ['Kadawatha', 'Kiribathgoda', 'Kelaniya', 'University Campus'],
            'departureTime': '06:45 AM',
            'arrivalTime': '08:10 AM',
            'status': 'on_time',
          },
          {
            'routeId': 'TR-103',
            'routeName': 'Galle Road Coastal Line (Route 03)',
            'busNumber': 'SP NA-3319',
            'driverName': 'Nimal Bandara',
            'driverPhone': '+94 76 555 4321',
            'pickupPoints': ['Moratuwa', 'Panadura', 'Ratmalana', 'Wellawatte', 'University Campus'],
            'departureTime': '06:15 AM',
            'arrivalTime': '08:20 AM',
            'status': 'on_time',
          },
        ];

        for (var r in defaultRoutes) {
          await _transportRef.add(r);
        }
      }
    } catch (e) {
      debugPrint('Initial data setup note: $e');
    }
  }
}
