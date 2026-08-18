import 'package:cloud_firestore/cloud_firestore.dart';

class ModuleRegistrationPeriodModel {
  final String? docId;
  final String periodId;
  final String academicYear; // e.g. '2025/2026'
  final String semester; // e.g. 'Semester 1'
  final String programme; // e.g. 'BSc (Hons) in Computing' or 'All'
  final String batchId; // e.g. '2026' or 'All'
  final String registrationStartDate; // 'YYYY-MM-DD'
  final String registrationEndDate; // 'YYYY-MM-DD'
  final int maximumModules; // e.g. 6
  final int minimumCredits; // e.g. 12
  final int maximumCredits; // e.g. 24
  final String status; // 'Draft', 'Open', 'Closed'
  final List<String> offeredModuleCodes;
  final Map<String, String> offeredModuleTypes; // moduleCode -> 'Core' | 'Elective' | 'Optional'
  final String createdAt;
  final String updatedAt;

  ModuleRegistrationPeriodModel({
    this.docId,
    required this.periodId,
    required this.academicYear,
    required this.semester,
    required this.programme,
    required this.batchId,
    required this.registrationStartDate,
    required this.registrationEndDate,
    this.maximumModules = 6,
    this.minimumCredits = 12,
    this.maximumCredits = 24,
    this.status = 'Draft',
    this.offeredModuleCodes = const [],
    this.offeredModuleTypes = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  static const List<String> supportedStatuses = ['Draft', 'Open', 'Closed'];
  static const List<String> supportedModuleTypes = ['Core', 'Elective', 'Optional'];

  bool get isDraft => status.toLowerCase() == 'draft';
  bool get isOpen => status.toLowerCase() == 'open';
  bool get isClosed => status.toLowerCase() == 'closed';

  /// Evaluates whether students are currently eligible to register based on status and dates
  bool get isOpenForRegistration {
    if (!isOpen) return false;
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final start = DateTime.parse(registrationStartDate);
      final end = DateTime.parse(registrationEndDate);

      return !today.isBefore(start) && !today.isAfter(end);
    } catch (_) {
      return false;
    }
  }

  /// Validates registration period parameters
  static String? validatePeriod({
    required String academicYear,
    required String semester,
    required String programme,
    required String batchId,
    required String startDate,
    required String endDate,
    required int minCredits,
    required int maxCredits,
    required int maxModules,
  }) {
    if (academicYear.trim().isEmpty || semester.trim().isEmpty || programme.trim().isEmpty || batchId.trim().isEmpty) {
      return 'Academic Year, Semester, Programme, and Batch are required.';
    }

    if (startDate.trim().isEmpty || endDate.trim().isEmpty) {
      return 'Start and End dates are required.';
    }

    try {
      final start = DateTime.parse(startDate);
      final end = DateTime.parse(endDate);
      if (start.isAfter(end)) {
        return 'Registration Start Date cannot be after End Date.';
      }
    } catch (_) {
      return 'Invalid date format. Use YYYY-MM-DD.';
    }

    if (minCredits <= 0) {
      return 'Minimum credits must be greater than zero.';
    }

    if (maxCredits < minCredits) {
      return 'Maximum credits ($maxCredits) cannot be less than minimum credits ($minCredits).';
    }

    if (maxModules <= 0) {
      return 'Maximum modules must be at least 1.';
    }

    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'periodId': periodId,
      'academicYear': academicYear,
      'semester': semester,
      'programme': programme,
      'batchId': batchId,
      'registrationStartDate': registrationStartDate,
      'registrationEndDate': registrationEndDate,
      'maximumModules': maximumModules,
      'minimumCredits': minimumCredits,
      'maximumCredits': maximumCredits,
      'status': status,
      'offeredModuleCodes': offeredModuleCodes,
      'offeredModuleTypes': offeredModuleTypes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory ModuleRegistrationPeriodModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ModuleRegistrationPeriodModel(
      docId: doc.id,
      periodId: data['periodId'] ?? doc.id,
      academicYear: data['academicYear'] ?? '2025/2026',
      semester: data['semester'] ?? 'Semester 1',
      programme: data['programme'] ?? 'BSc (Hons) in Computing',
      batchId: data['batchId'] ?? 'All',
      registrationStartDate: data['registrationStartDate'] ?? DateTime.now().toIso8601String().substring(0, 10),
      registrationEndDate: data['registrationEndDate'] ?? DateTime.now().add(const Duration(days: 14)).toIso8601String().substring(0, 10),
      maximumModules: (data['maximumModules'] as num?)?.toInt() ?? 6,
      minimumCredits: (data['minimumCredits'] as num?)?.toInt() ?? 12,
      maximumCredits: (data['maximumCredits'] as num?)?.toInt() ?? 24,
      status: data['status'] ?? 'Draft',
      offeredModuleCodes: List<String>.from(data['offeredModuleCodes'] ?? []),
      offeredModuleTypes: Map<String, String>.from(data['offeredModuleTypes'] ?? {}),
      createdAt: data['createdAt'] ?? DateTime.now().toIso8601String(),
      updatedAt: data['updatedAt'] ?? DateTime.now().toIso8601String(),
    );
  }
}
