import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/module_registration_period_model.dart';
import '../models/student_module_registration_model.dart';
import '../models/subject_model.dart';

class StudentModuleRegistrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _periodsRef =>
      _firestore.collection('module_registration_periods');

  CollectionReference<Map<String, dynamic>> get _registrationsRef =>
      _firestore.collection('moduleRegistrations');

  CollectionReference<Map<String, dynamic>> get _subjectsRef =>
      _firestore.collection('subjects');

  CollectionReference<Map<String, dynamic>> get _enrollmentsRef =>
      _firestore.collection('enrollments');

  // 1. Get Active Module Registration Period for Student
  Stream<List<ModuleRegistrationPeriodModel>> getActiveRegistrationPeriodsStream({
    required String programme,
    required String batchId,
  }) {
    return _periodsRef
        .where('status', isEqualTo: 'Open')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ModuleRegistrationPeriodModel.fromFirestore(doc))
          .where((p) {
        final matchesProg = p.programme.toLowerCase() == programme.toLowerCase() || p.programme == 'All';
        final matchesBatch = p.batchId == batchId || p.batchId == 'All';
        return matchesProg && matchesBatch && p.isOpenForRegistration;
      }).toList();

      return list;
    });
  }

  // 2. Stream of student's registered modules
  Stream<List<StudentModuleRegistrationModel>> getStudentRegistrationsStream({
    required String studentId,
    required String studentEmail,
  }) {
    final cleanId = studentId.trim().toUpperCase();
    final cleanEmail = studentEmail.trim().toLowerCase();

    return _registrationsRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => StudentModuleRegistrationModel.fromFirestore(doc))
          .where((r) => r.studentId.toUpperCase() == cleanId || r.studentEmail.toLowerCase() == cleanEmail)
          .toList()
        ..sort((a, b) => b.registeredAt.compareTo(a.registeredAt));
    });
  }

  // 3. Fetch offered Subject models for a registration period
  Future<List<SubjectModel>> getOfferedSubjects(List<String> moduleCodes) async {
    if (moduleCodes.isEmpty) return [];

    final snap = await _subjectsRef.where('status', isEqualTo: 'active').get();
    final allSubjects = snap.docs.map((doc) => SubjectModel.fromFirestore(doc)).toList();

    return allSubjects.where((s) => moduleCodes.map((c) => c.toUpperCase()).contains(s.subjectCode.toUpperCase())).toList();
  }

  // 4. Submit Student Module Registration
  Future<void> submitModuleRegistrations({
    required ModuleRegistrationPeriodModel period,
    required String studentId,
    required String studentName,
    required String studentEmail,
    required List<SubjectModel> selectedSubjects,
    required List<StudentModuleRegistrationModel> existingRegistrations,
  }) async {
    final candidateCodes = selectedSubjects.map((s) => s.subjectCode).toList();
    final creditsMap = {for (var s in selectedSubjects) s.subjectCode: s.credits};
    final prereqMap = <String, List<String>>{}; // Can be extended if prerequisites collection is added

    final validationError = StudentModuleRegistrationModel.validateRegistrationSelection(
      existingRegistrations: existingRegistrations,
      candidateModuleCodes: candidateCodes,
      moduleCreditsMap: creditsMap,
      modulePrerequisitesMap: prereqMap,
      studentPassedModuleCodes: [], // Default empty or passed credits
      minCredits: period.minimumCredits,
      maxCredits: period.maximumCredits,
      maxModules: period.maximumModules,
    );

    if (validationError != null) {
      throw Exception(validationError);
    }

    final timestamp = DateTime.now().toIso8601String();
    final batch = _firestore.batch();

    for (final subject in selectedSubjects) {
      final docRef = _registrationsRef.doc();
      final regId = 'MODREG-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}-${subject.subjectCode}';
      final modType = period.offeredModuleTypes[subject.subjectCode] ?? 'Core';

      final regModel = StudentModuleRegistrationModel(
        docId: docRef.id,
        registrationId: regId,
        studentId: studentId.trim().toUpperCase(),
        studentName: studentName.trim(),
        studentEmail: studentEmail.trim().toLowerCase(),
        moduleId: subject.subjectCode,
        moduleName: subject.subjectName,
        registrationPeriodId: period.periodId,
        academicYear: period.academicYear,
        semester: period.semester,
        credits: subject.credits,
        moduleType: modType,
        status: 'Approved', // Direct approval or pending based on configuration
        registeredAt: timestamp,
        approvedAt: timestamp,
        approvedBy: 'System (Auto)',
      );

      batch.set(docRef, regModel.toMap());

      // Sync to official student enrollments collection for immediate materials & timetable access
      final enrollDocRef = _enrollmentsRef.doc('${studentId.trim().toUpperCase()}_${subject.subjectCode}');
      batch.set(enrollDocRef, {
        'studentId': studentId.trim().toUpperCase(),
        'studentName': studentName.trim(),
        'studentEmail': studentEmail.trim().toLowerCase(),
        'subjectCode': subject.subjectCode,
        'subjectName': subject.subjectName,
        'semester': period.semester,
        'academicYear': period.academicYear,
        'status': 'enrolled',
        'enrolledAt': timestamp,
      });
    }

    await batch.commit();
    debugPrint('Registered ${selectedSubjects.length} modules for student $studentId');
  }

  // 5. Drop module registration
  Future<void> dropModuleRegistration(String docId) async {
    await _registrationsRef.doc(docId).update({
      'status': 'Dropped',
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }
}
