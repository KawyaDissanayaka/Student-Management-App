import 'package:cloud_firestore/cloud_firestore.dart';

class FeeStructureModel {
  final String? docId;
  final String feeStructureId;
  final String academicYear; // e.g. '2025/2026'
  final String semester; // e.g. 'Semester 1', 'Semester 2'
  final String programme; // e.g. 'BSc (Hons) in Computing'
  final String batchId; // e.g. '2026', '2025', 'All'
  final String feeType; // 'Semester Fee', 'Registration Fee', 'Examination Fee', 'Library Fee', 'Laboratory Fee', 'Other Fee'
  final double amount; // must be > 0
  final String dueDate; // 'YYYY-MM-DD'
  final String status; // 'Active' or 'Inactive'
  final String? description;
  final String createdAt;
  final String updatedAt;

  FeeStructureModel({
    this.docId,
    required this.feeStructureId,
    required this.academicYear,
    required this.semester,
    required this.programme,
    required this.batchId,
    required this.feeType,
    required this.amount,
    required this.dueDate,
    this.status = 'Active',
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  static const List<String> supportedFeeTypes = [
    'Semester Fee',
    'Registration Fee',
    'Examination Fee',
    'Library Fee',
    'Laboratory Fee',
    'Other Fee',
  ];

  bool get isActive => status.toLowerCase() == 'active';
  bool get isInactive => status.toLowerCase() == 'inactive';

  bool get isPastDueDate {
    try {
      final parsed = DateTime.parse(dueDate);
      final today = DateTime.now();
      final dateOnly = DateTime(today.year, today.month, today.day);
      return parsed.isBefore(dateOnly);
    } catch (_) {
      return false;
    }
  }

  /// Calculates student fee balance: Balance = Total Fee - Paid Amount - Approved Discounts
  static double calculateBalance({
    required double totalFee,
    required double paidAmount,
    double approvedDiscounts = 0.0,
  }) {
    final balance = totalFee - paidAmount - approvedDiscounts;
    return balance < 0 ? 0.0 : balance;
  }

  /// Automatically determines payment status: Unpaid, Partially Paid, Paid, Overdue
  static String determinePaymentStatus({
    required double balance,
    required double paidAmount,
    required String dueDate,
  }) {
    if (balance <= 0 && paidAmount > 0) {
      return 'Paid';
    }

    bool isOverdue = false;
    try {
      final parsed = DateTime.parse(dueDate);
      final today = DateTime.now();
      final dateOnly = DateTime(today.year, today.month, today.day);
      if (parsed.isBefore(dateOnly) && balance > 0) {
        isOverdue = true;
      }
    } catch (_) {}

    if (isOverdue) {
      return 'Overdue';
    }

    if (paidAmount > 0 && balance > 0) {
      return 'Partially Paid';
    }

    return 'Unpaid';
  }

  Map<String, dynamic> toMap() {
    return {
      'feeStructureId': feeStructureId,
      'academicYear': academicYear,
      'semester': semester,
      'programme': programme,
      'batchId': batchId,
      'feeType': feeType,
      'amount': amount,
      'dueDate': dueDate,
      'status': status,
      'description': description,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory FeeStructureModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return FeeStructureModel(
      docId: doc.id,
      feeStructureId: data['feeStructureId'] ?? doc.id,
      academicYear: data['academicYear'] ?? '2025/2026',
      semester: data['semester'] ?? 'Semester 1',
      programme: data['programme'] ?? 'BSc (Hons) in Computing',
      batchId: data['batchId'] ?? 'All',
      feeType: data['feeType'] ?? 'Semester Fee',
      amount: ((data['amount'] ?? 0) as num).toDouble(),
      dueDate: data['dueDate'] ?? DateTime.now().toIso8601String().substring(0, 10),
      status: data['status'] ?? 'Active',
      description: data['description'],
      createdAt: data['createdAt'] ?? DateTime.now().toIso8601String(),
      updatedAt: data['updatedAt'] ?? DateTime.now().toIso8601String(),
    );
  }
}
