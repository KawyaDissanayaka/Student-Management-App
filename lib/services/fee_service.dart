import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/fee_structure_model.dart';
import '../models/payment_model.dart';

class StudentFeeSummary {
  final double totalApplicableFee;
  final double totalPaid;
  final double approvedDiscounts;
  final double balance;
  final String paymentStatus; // 'Unpaid', 'Partially Paid', 'Paid', 'Overdue'
  final List<FeeStructureModel> applicableFeeItems;
  final List<PaymentModel> paymentHistory;

  StudentFeeSummary({
    required this.totalApplicableFee,
    required this.totalPaid,
    required this.approvedDiscounts,
    required this.balance,
    required this.paymentStatus,
    required this.applicableFeeItems,
    required this.paymentHistory,
  });
}

class FeeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _feeStructuresRef =>
      _firestore.collection('fee_structures');

  CollectionReference<Map<String, dynamic>> get _paymentsRef =>
      _firestore.collection('payments');

  // Stream of all fee structures
  Stream<List<FeeStructureModel>> getFeeStructuresStream() {
    return _feeStructuresRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => FeeStructureModel.fromFirestore(doc))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  // Stream of active fee structures filtered for a program/batch
  Stream<List<FeeStructureModel>> getActiveFeeStructuresStream({
    String? programme,
    String? batchId,
    String? semester,
  }) {
    return _feeStructuresRef
        .where('status', isEqualTo: 'Active')
        .snapshots()
        .map((snapshot) {
      var list = snapshot.docs.map((doc) => FeeStructureModel.fromFirestore(doc)).toList();

      if (programme != null && programme.isNotEmpty && programme != 'All') {
        list = list.where((f) => f.programme.toLowerCase() == programme.toLowerCase() || f.programme == 'All').toList();
      }
      if (batchId != null && batchId.isNotEmpty && batchId != 'All') {
        list = list.where((f) => f.batchId == batchId || f.batchId == 'All').toList();
      }
      if (semester != null && semester.isNotEmpty && semester != 'All') {
        list = list.where((f) => f.semester.toLowerCase() == semester.toLowerCase() || f.semester == 'All').toList();
      }

      return list;
    });
  }

  // Create new Fee Structure
  Future<void> addFeeStructure({
    required String academicYear,
    required String semester,
    required String programme,
    required String batchId,
    required String feeType,
    required double amount,
    required String dueDate,
    String status = 'Active',
    String? description,
  }) async {
    if (amount <= 0) {
      throw Exception('Fee amount must be greater than zero.');
    }
    if (academicYear.trim().isEmpty || semester.trim().isEmpty || programme.trim().isEmpty) {
      throw Exception('Academic Year, Semester, and Programme cannot be empty.');
    }
    if (dueDate.trim().isEmpty) {
      throw Exception('A valid Due Date is required.');
    }

    final docRef = _feeStructuresRef.doc();
    final timestamp = DateTime.now().toIso8601String();
    final feeStructureId = 'FEE-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    final feeModel = FeeStructureModel(
      docId: docRef.id,
      feeStructureId: feeStructureId,
      academicYear: academicYear.trim(),
      semester: semester.trim(),
      programme: programme.trim(),
      batchId: batchId.trim(),
      feeType: feeType.trim(),
      amount: amount,
      dueDate: dueDate.trim(),
      status: status,
      description: description?.trim(),
      createdAt: timestamp,
      updatedAt: timestamp,
    );

    await docRef.set(feeModel.toMap());
    debugPrint('Created Fee Structure $feeStructureId for $programme ($feeType: $amount)');
  }

  // Update existing Fee Structure
  Future<void> updateFeeStructure(FeeStructureModel model) async {
    if (model.amount <= 0) {
      throw Exception('Fee amount must be greater than zero.');
    }
    if (model.docId == null || model.docId!.isEmpty) {
      throw Exception('Document ID is required for update.');
    }

    final timestamp = DateTime.now().toIso8601String();
    await _feeStructuresRef.doc(model.docId).update({
      'academicYear': model.academicYear,
      'semester': model.semester,
      'programme': model.programme,
      'batchId': model.batchId,
      'feeType': model.feeType,
      'amount': model.amount,
      'dueDate': model.dueDate,
      'status': model.status,
      'description': model.description,
      'updatedAt': timestamp,
    });

    debugPrint('Updated Fee Structure ${model.feeStructureId}');
  }

  // Toggle Fee Structure Status (Active / Inactive)
  Future<void> toggleFeeStructureStatus(String docId, String newStatus) async {
    final timestamp = DateTime.now().toIso8601String();
    await _feeStructuresRef.doc(docId).update({
      'status': newStatus,
      'updatedAt': timestamp,
    });
  }

  // Delete Fee Structure
  Future<void> deleteFeeStructure(String docId) async {
    await _feeStructuresRef.doc(docId).delete();
  }

  // Dynamic Student Fee Calculation & Summary
  Future<StudentFeeSummary> calculateStudentFeeSummary({
    required String programme,
    required String batchId,
    required String studentId,
    required String studentEmail,
    double approvedDiscounts = 0.0,
  }) async {
    // 1. Fetch active applicable fee structures
    final feeSnap = await _feeStructuresRef.where('status', isEqualTo: 'Active').get();
    final allActiveFees = feeSnap.docs.map((d) => FeeStructureModel.fromFirestore(d)).toList();

    final applicableFees = allActiveFees.where((f) {
      final matchesProg = f.programme.toLowerCase() == programme.toLowerCase() || f.programme == 'All';
      final matchesBatch = f.batchId == batchId || f.batchId == 'All';
      return matchesProg && matchesBatch;
    }).toList();

    final double totalFee = applicableFees.fold(0.0, (acc, f) => acc + f.amount);

    // 2. Fetch successful student payments
    final cleanId = studentId.trim().toUpperCase();
    final cleanEmail = studentEmail.trim().toLowerCase();

    final paySnap = await _paymentsRef.get();
    final allPayments = paySnap.docs.map((d) => PaymentModel.fromFirestore(d)).toList();

    final studentPayments = allPayments.where((p) {
      final matchesId = p.studentId.toUpperCase() == cleanId;
      final matchesEmail = p.studentEmail.toLowerCase() == cleanEmail;
      final isSuccess = p.status.toLowerCase() == 'success';
      return (matchesId || matchesEmail) && isSuccess;
    }).toList();

    final double totalPaid = studentPayments.fold(0.0, (acc, p) => acc + p.amount);

    // 3. Compute Balance = Total Fee - Paid Amount - Approved Discounts
    final balance = FeeStructureModel.calculateBalance(
      totalFee: totalFee,
      paidAmount: totalPaid,
      approvedDiscounts: approvedDiscounts,
    );

    // 4. Determine overall payment status
    String latestDueDate = DateTime.now().toIso8601String().substring(0, 10);
    if (applicableFees.isNotEmpty) {
      latestDueDate = applicableFees.first.dueDate;
    }

    final paymentStatus = FeeStructureModel.determinePaymentStatus(
      balance: balance,
      paidAmount: totalPaid,
      dueDate: latestDueDate,
    );

    return StudentFeeSummary(
      totalApplicableFee: totalFee,
      totalPaid: totalPaid,
      approvedDiscounts: approvedDiscounts,
      balance: balance,
      paymentStatus: paymentStatus,
      applicableFeeItems: applicableFees,
      paymentHistory: studentPayments,
    );
  }
}
