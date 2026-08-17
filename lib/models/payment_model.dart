import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String? docId;
  final String paymentId;
  final String studentEmail;
  final String studentId;
  final String studentName;
  final String feeType; // 'Tuition Fee', 'Exam Fee', 'Library Fine', 'Lab Fee'
  final double amount;
  final String paymentMethod; // 'Online Card', 'Bank Transfer', 'Mobile Wallet'
  final String transactionRef;
  final String paymentDate; // ISO string
  final String status; // 'success', 'pending', 'failed', 'cancelled'
  final String? receiptUrl;

  PaymentModel({
    this.docId,
    required this.paymentId,
    required this.studentEmail,
    required this.studentId,
    required this.studentName,
    required this.feeType,
    required this.amount,
    required this.paymentMethod,
    required this.transactionRef,
    required this.paymentDate,
    this.status = 'success',
    this.receiptUrl,
  });

  factory PaymentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PaymentModel(
      docId: doc.id,
      paymentId: data['paymentId'] ?? doc.id,
      studentEmail: data['studentEmail'] ?? '',
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      feeType: data['feeType'] ?? 'Tuition Fee',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: data['paymentMethod'] ?? 'Online Card',
      transactionRef: data['transactionRef'] ?? '',
      paymentDate: data['paymentDate'] ?? '',
      status: data['status'] ?? 'success',
      receiptUrl: data['receiptUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'paymentId': paymentId,
      'studentEmail': studentEmail,
      'studentId': studentId,
      'studentName': studentName,
      'feeType': feeType,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'transactionRef': transactionRef,
      'paymentDate': paymentDate,
      'status': status,
      'receiptUrl': receiptUrl,
    };
  }
}
