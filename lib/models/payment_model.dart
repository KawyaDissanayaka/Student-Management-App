import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String? docId;
  final String paymentId;
  final String receiptNumber; // Unique official receipt number e.g. REC-2026-000001
  final String studentEmail;
  final String studentId;
  final String studentName;
  final String feeType; // 'Semester Fee', 'Registration Fee', 'Examination Fee', etc.
  final double amount;
  final String currency; // 'LKR'
  final String paymentMethod; // 'Online Card (Sandbox Gateway)', 'Bank Transfer', 'Mobile Wallet'
  final String transactionRef;
  final String transactionId; // Gateway returned transaction ID
  final String paymentDate; // ISO string
  final String status; // 'pending', 'success', 'failed', 'refunded', 'cancelled'
  final String? receiptUrl;
  final String createdAt;
  final String? verifiedAt;
  final String? refundedAt;

  PaymentModel({
    this.docId,
    required this.paymentId,
    this.receiptNumber = '',
    required this.studentEmail,
    required this.studentId,
    required this.studentName,
    required this.feeType,
    required this.amount,
    this.currency = 'LKR',
    required this.paymentMethod,
    required this.transactionRef,
    this.transactionId = '',
    required this.paymentDate,
    this.status = 'pending',
    this.receiptUrl,
    String? createdAt,
    this.verifiedAt,
    this.refundedAt,
  }) : createdAt = createdAt ?? paymentDate;

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isSuccessful => status.toLowerCase() == 'success' || status.toLowerCase() == 'successful';
  bool get isFailed => status.toLowerCase() == 'failed';
  bool get isRefunded => status.toLowerCase() == 'refunded';
  bool get isCancelled => status.toLowerCase() == 'cancelled';

  /// Generates a standardized unique official receipt number: REC-YYYY-XXXXXX
  static String generateReceiptNumber() {
    final now = DateTime.now();
    final year = now.year;
    final suffix = now.millisecondsSinceEpoch.toString().substring(7);
    return 'REC-$year-$suffix';
  }

  /// Validates payment amount according to university finance rules:
  /// 1. Must be strictly > 0
  /// 2. Must not exceed current outstanding balance
  static String? validatePaymentAmount({
    required double? amount,
    required double currentBalance,
  }) {
    if (amount == null || amount <= 0) {
      return 'Payment amount must be greater than zero.';
    }
    if (amount > currentBalance && currentBalance > 0) {
      return 'Payment amount (LKR ${amount.toStringAsFixed(2)}) cannot exceed outstanding balance (LKR ${currentBalance.toStringAsFixed(2)}).';
    }
    return null;
  }

  factory PaymentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PaymentModel(
      docId: doc.id,
      paymentId: data['paymentId'] ?? doc.id,
      receiptNumber: data['receiptNumber'] ?? '',
      studentEmail: data['studentEmail'] ?? '',
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      feeType: data['feeType'] ?? 'Semester Fee',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] ?? 'LKR',
      paymentMethod: data['paymentMethod'] ?? 'Online Card',
      transactionRef: data['transactionRef'] ?? '',
      transactionId: data['transactionId'] ?? data['transactionRef'] ?? '',
      paymentDate: data['paymentDate'] ?? '',
      status: data['status'] ?? 'pending',
      receiptUrl: data['receiptUrl'],
      createdAt: data['createdAt'] ?? data['paymentDate'] ?? '',
      verifiedAt: data['verifiedAt'],
      refundedAt: data['refundedAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'paymentId': paymentId,
      'receiptNumber': receiptNumber,
      'studentEmail': studentEmail,
      'studentId': studentId,
      'studentName': studentName,
      'feeType': feeType,
      'amount': amount,
      'currency': currency,
      'paymentMethod': paymentMethod,
      'transactionRef': transactionRef,
      'transactionId': transactionId,
      'paymentDate': paymentDate,
      'status': status,
      'receiptUrl': receiptUrl,
      'createdAt': createdAt,
      'verifiedAt': verifiedAt,
      'refundedAt': refundedAt,
    };
  }
}
