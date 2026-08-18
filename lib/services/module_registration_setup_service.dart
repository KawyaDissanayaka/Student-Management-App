import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/module_registration_period_model.dart';
import '../models/subject_model.dart';

class ModuleRegistrationSetupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _periodsRef =>
      _firestore.collection('module_registration_periods');

  CollectionReference<Map<String, dynamic>> get _subjectsRef =>
      _firestore.collection('subjects');

  // Stream of all registration periods
  Stream<List<ModuleRegistrationPeriodModel>> getRegistrationPeriodsStream() {
    return _periodsRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ModuleRegistrationPeriodModel.fromFirestore(doc))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  // Stream of all active subjects/modules that can be offered
  Stream<List<SubjectModel>> getActiveSubjectsStream() {
    return _subjectsRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => SubjectModel.fromFirestore(doc))
          .where((s) => s.status.toLowerCase() == 'active')
          .toList()
        ..sort((a, b) => a.subjectCode.compareTo(b.subjectCode));
    });
  }

  // Create new Module Registration Period
  Future<void> createRegistrationPeriod({
    required String academicYear,
    required String semester,
    required String programme,
    required String batchId,
    required String startDate,
    required String endDate,
    int maxModules = 6,
    int minCredits = 12,
    int maxCredits = 24,
    String status = 'Draft',
    List<String> offeredModuleCodes = const [],
    Map<String, String> offeredModuleTypes = const {},
  }) async {
    final validationError = ModuleRegistrationPeriodModel.validatePeriod(
      academicYear: academicYear,
      semester: semester,
      programme: programme,
      batchId: batchId,
      startDate: startDate,
      endDate: endDate,
      minCredits: minCredits,
      maxCredits: maxCredits,
      maxModules: maxModules,
    );

    if (validationError != null) {
      throw Exception(validationError);
    }

    final docRef = _periodsRef.doc();
    final timestamp = DateTime.now().toIso8601String();
    final periodId = 'MRP-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    final period = ModuleRegistrationPeriodModel(
      docId: docRef.id,
      periodId: periodId,
      academicYear: academicYear.trim(),
      semester: semester.trim(),
      programme: programme.trim(),
      batchId: batchId.trim(),
      registrationStartDate: startDate.trim(),
      registrationEndDate: endDate.trim(),
      maximumModules: maxModules,
      minimumCredits: minCredits,
      maximumCredits: maxCredits,
      status: status,
      offeredModuleCodes: offeredModuleCodes,
      offeredModuleTypes: offeredModuleTypes,
      createdAt: timestamp,
      updatedAt: timestamp,
    );

    await docRef.set(period.toMap());
    debugPrint('Created Module Registration Period $periodId for $programme ($batchId)');
  }

  // Update existing Period
  Future<void> updateRegistrationPeriod(ModuleRegistrationPeriodModel period) async {
    if (period.docId == null || period.docId!.isEmpty) {
      throw Exception('Document ID is required for update.');
    }

    final validationError = ModuleRegistrationPeriodModel.validatePeriod(
      academicYear: period.academicYear,
      semester: period.semester,
      programme: period.programme,
      batchId: period.batchId,
      startDate: period.registrationStartDate,
      endDate: period.registrationEndDate,
      minCredits: period.minimumCredits,
      maxCredits: period.maximumCredits,
      maxModules: period.maximumModules,
    );

    if (validationError != null) {
      throw Exception(validationError);
    }

    final timestamp = DateTime.now().toIso8601String();
    await _periodsRef.doc(period.docId).update({
      'academicYear': period.academicYear.trim(),
      'semester': period.semester.trim(),
      'programme': period.programme.trim(),
      'batchId': period.batchId.trim(),
      'registrationStartDate': period.registrationStartDate.trim(),
      'registrationEndDate': period.registrationEndDate.trim(),
      'maximumModules': period.maximumModules,
      'minimumCredits': period.minimumCredits,
      'maximumCredits': period.maximumCredits,
      'status': period.status,
      'offeredModuleCodes': period.offeredModuleCodes,
      'offeredModuleTypes': period.offeredModuleTypes,
      'updatedAt': timestamp,
    });

    debugPrint('Updated Module Registration Period ${period.periodId}');
  }

  // Update Period Status ('Draft', 'Open', 'Closed')
  Future<void> updatePeriodStatus(String docId, String newStatus) async {
    final timestamp = DateTime.now().toIso8601String();
    await _periodsRef.doc(docId).update({
      'status': newStatus,
      'updatedAt': timestamp,
    });
  }

  // Assign Offered Modules to Period
  Future<void> assignOfferedModules({
    required String docId,
    required List<String> offeredModuleCodes,
    required Map<String, String> offeredModuleTypes,
  }) async {
    final timestamp = DateTime.now().toIso8601String();
    await _periodsRef.doc(docId).update({
      'offeredModuleCodes': offeredModuleCodes,
      'offeredModuleTypes': offeredModuleTypes,
      'updatedAt': timestamp,
    });
  }

  // Delete Period
  Future<void> deleteRegistrationPeriod(String docId) async {
    await _periodsRef.doc(docId).delete();
  }
}
