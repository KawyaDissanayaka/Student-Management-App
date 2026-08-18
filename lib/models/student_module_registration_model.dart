import 'package:cloud_firestore/cloud_firestore.dart';

class StudentModuleRegistrationModel {
  final String? docId;
  final String registrationId;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String moduleId; // moduleCode e.g. 'CS101'
  final String moduleName;
  final String registrationPeriodId;
  final String academicYear;
  final String semester;
  final int credits;
  final String moduleType; // 'Core', 'Elective', 'Optional'
  final String status; // 'Pending', 'Approved', 'Rejected', 'Dropped'
  final String registeredAt;
  final String? approvedAt;
  final String? approvedBy;
  final String? rejectionReason;

  StudentModuleRegistrationModel({
    this.docId,
    required this.registrationId,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.moduleId,
    required this.moduleName,
    required this.registrationPeriodId,
    required this.academicYear,
    required this.semester,
    required this.credits,
    this.moduleType = 'Core',
    this.status = 'Approved',
    required this.registeredAt,
    this.approvedAt,
    this.approvedBy,
    this.rejectionReason,
  });

  static const List<String> supportedStatuses = ['Pending', 'Approved', 'Rejected', 'Dropped'];

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isRejected => status.toLowerCase() == 'rejected';
  bool get isDropped => status.toLowerCase() == 'dropped';

  /// Validates credit limits and prerequisite conditions
  static String? validateRegistrationSelection({
    required List<StudentModuleRegistrationModel> existingRegistrations,
    required List<String> candidateModuleCodes,
    required Map<String, int> moduleCreditsMap,
    required Map<String, List<String>> modulePrerequisitesMap,
    required List<String> studentPassedModuleCodes,
    required int minCredits,
    required int maxCredits,
    required int maxModules,
  }) {
    if (candidateModuleCodes.isEmpty) {
      return 'Please select at least one module for registration.';
    }

    if (candidateModuleCodes.length > maxModules) {
      return 'You cannot select more than $maxModules modules.';
    }

    // 1. Total credits tally
    int totalCredits = 0;
    for (final code in candidateModuleCodes) {
      totalCredits += moduleCreditsMap[code] ?? 3;
    }

    if (totalCredits > maxCredits) {
      return 'Selected credits ($totalCredits) exceed the maximum credit limit of $maxCredits credits.';
    }

    if (totalCredits < minCredits) {
      return 'Selected credits ($totalCredits) are below the minimum required credit limit of $minCredits credits.';
    }

    // 2. Duplicate registration check
    for (final code in candidateModuleCodes) {
      final isAlreadyRegistered = existingRegistrations.any(
        (r) => r.moduleId.toUpperCase() == code.toUpperCase() && !r.isDropped && !r.isRejected,
      );
      if (isAlreadyRegistered) {
        return 'Module $code is already registered in this semester.';
      }
    }

    // 3. Prerequisites check
    for (final code in candidateModuleCodes) {
      final prerequisites = modulePrerequisitesMap[code] ?? [];
      for (final prereq in prerequisites) {
        if (!studentPassedModuleCodes.map((c) => c.toUpperCase()).contains(prereq.toUpperCase())) {
          return 'Cannot register for $code. Missing prerequisite: $prereq';
        }
      }
    }

    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'registrationId': registrationId,
      'studentId': studentId,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'moduleId': moduleId,
      'moduleName': moduleName,
      'registrationPeriodId': registrationPeriodId,
      'academicYear': academicYear,
      'semester': semester,
      'credits': credits,
      'moduleType': moduleType,
      'status': status,
      'registeredAt': registeredAt,
      'approvedAt': approvedAt,
      'approvedBy': approvedBy,
      'rejectionReason': rejectionReason,
    };
  }

  factory StudentModuleRegistrationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return StudentModuleRegistrationModel(
      docId: doc.id,
      registrationId: data['registrationId'] ?? doc.id,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      studentEmail: data['studentEmail'] ?? '',
      moduleId: data['moduleId'] ?? '',
      moduleName: data['moduleName'] ?? '',
      registrationPeriodId: data['registrationPeriodId'] ?? '',
      academicYear: data['academicYear'] ?? '',
      semester: data['semester'] ?? '',
      credits: (data['credits'] as num?)?.toInt() ?? 3,
      moduleType: data['moduleType'] ?? 'Core',
      status: data['status'] ?? 'Approved',
      registeredAt: data['registeredAt'] ?? DateTime.now().toIso8601String(),
      approvedAt: data['approvedAt'],
      approvedBy: data['approvedBy'],
      rejectionReason: data['rejectionReason'],
    );
  }
}
