import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/student_module_registration_model.dart';

class AdminModuleRegistrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _registrationsRef =>
      _firestore.collection('moduleRegistrations');

  CollectionReference<Map<String, dynamic>> get _enrollmentsRef =>
      _firestore.collection('enrollments');

  CollectionReference<Map<String, dynamic>> get _notificationsRef =>
      _firestore.collection('notifications');

  // Stream of all module registrations
  Stream<List<StudentModuleRegistrationModel>> getAllRegistrationsStream() {
    return _registrationsRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => StudentModuleRegistrationModel.fromFirestore(doc))
          .toList()
        ..sort((a, b) => b.registeredAt.compareTo(a.registeredAt));
    });
  }

  // 1. Approve Registration with Enrollment sync and Notification
  Future<void> approveRegistration({
    required StudentModuleRegistrationModel registration,
    required String adminId,
  }) async {
    if (registration.docId == null || registration.docId!.isEmpty) {
      throw Exception('Registration document ID is missing.');
    }

    final timestamp = DateTime.now().toIso8601String();
    final batch = _firestore.batch();

    // 1. Update moduleRegistration document
    final regRef = _registrationsRef.doc(registration.docId);
    batch.update(regRef, {
      'status': 'Approved',
      'approvedAt': timestamp,
      'approvedBy': adminId,
    });

    // 2. Sync to official enrollments collection
    final enrollDocRef = _enrollmentsRef.doc('${registration.studentId}_${registration.moduleId}');
    batch.set(enrollDocRef, {
      'studentId': registration.studentId,
      'studentName': registration.studentName,
      'studentEmail': registration.studentEmail,
      'subjectCode': registration.moduleId,
      'subjectName': registration.moduleName,
      'semester': registration.semester,
      'academicYear': registration.academicYear,
      'status': 'enrolled',
      'enrolledAt': timestamp,
      'approvedBy': adminId,
    });

    // 3. Dispatch Notification to student
    final notifRef = _notificationsRef.doc();
    batch.set(notifRef, {
      'title': 'Module Registration Approved',
      'message': 'Your registration for ${registration.moduleId} (${registration.moduleName}) has been Approved by Academic Administration.',
      'targetEmail': registration.studentEmail,
      'targetStudentId': registration.studentId,
      'type': 'module_reg_approved',
      'createdAt': timestamp,
      'isRead': false,
    });

    await batch.commit();
    debugPrint('Approved registration ${registration.registrationId} by $adminId');
  }

  // 2. Reject Registration with Required Reason
  Future<void> rejectRegistration({
    required StudentModuleRegistrationModel registration,
    required String reason,
    required String adminId,
  }) async {
    if (registration.docId == null || registration.docId!.isEmpty) {
      throw Exception('Registration document ID is missing.');
    }
    if (reason.trim().isEmpty) {
      throw Exception('Rejection reason is required.');
    }

    final timestamp = DateTime.now().toIso8601String();
    final batch = _firestore.batch();

    // Update moduleRegistration document
    final regRef = _registrationsRef.doc(registration.docId);
    batch.update(regRef, {
      'status': 'Rejected',
      'rejectionReason': reason.trim(),
      'rejectedAt': timestamp,
      'rejectedBy': adminId,
    });

    // Dispatch Notification to student
    final notifRef = _notificationsRef.doc();
    batch.set(notifRef, {
      'title': 'Module Registration Rejected',
      'message': 'Your registration for ${registration.moduleId} was Rejected. Reason: ${reason.trim()}',
      'targetEmail': registration.studentEmail,
      'targetStudentId': registration.studentId,
      'type': 'module_reg_rejected',
      'createdAt': timestamp,
      'isRead': false,
    });

    await batch.commit();
    debugPrint('Rejected registration ${registration.registrationId}');
  }

  // 3. Drop Registration with Required Reason
  Future<void> dropRegistration({
    required StudentModuleRegistrationModel registration,
    required String reason,
    required String adminId,
  }) async {
    if (registration.docId == null || registration.docId!.isEmpty) {
      throw Exception('Registration document ID is missing.');
    }
    if (reason.trim().isEmpty) {
      throw Exception('Drop reason is required.');
    }

    final timestamp = DateTime.now().toIso8601String();
    final batch = _firestore.batch();

    // Update moduleRegistration document
    final regRef = _registrationsRef.doc(registration.docId);
    batch.update(regRef, {
      'status': 'Dropped',
      'dropReason': reason.trim(),
      'droppedAt': timestamp,
      'droppedBy': adminId,
    });

    // Update enrollment status to dropped
    final enrollDocRef = _enrollmentsRef.doc('${registration.studentId}_${registration.moduleId}');
    batch.set(enrollDocRef, {'status': 'dropped', 'droppedAt': timestamp}, SetOptions(merge: true));

    // Dispatch Notification to student
    final notifRef = _notificationsRef.doc();
    batch.set(notifRef, {
      'title': 'Module Registration Dropped',
      'message': 'Your registration for ${registration.moduleId} has been Dropped. Reason: ${reason.trim()}',
      'targetEmail': registration.studentEmail,
      'targetStudentId': registration.studentId,
      'type': 'module_reg_dropped',
      'createdAt': timestamp,
      'isRead': false,
    });

    await batch.commit();
    debugPrint('Dropped registration ${registration.registrationId}');
  }
}
