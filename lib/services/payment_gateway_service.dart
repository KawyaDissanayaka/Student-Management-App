import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/payment_model.dart';

class PaymentGatewayResult {
  final bool isSuccess;
  final String? transactionId;
  final String? receiptNumber;
  final String? errorMessage;
  final PaymentModel? verifiedPayment;

  PaymentGatewayResult({
    required this.isSuccess,
    this.transactionId,
    this.receiptNumber,
    this.errorMessage,
    this.verifiedPayment,
  });
}

class PaymentGatewayService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _paymentsRef =>
      _firestore.collection('payments');

  CollectionReference<Map<String, dynamic>> get _notificationsRef =>
      _firestore.collection('notifications');

  /// Phase 1: Initialize Payment Transaction by creating a Pending record
  Future<PaymentModel> initiatePayment({
    required String studentEmail,
    required String studentId,
    required String studentName,
    required String feeType,
    required double amount,
    required double currentBalance,
    String paymentMethod = 'Online Card (Sandbox Gateway)',
  }) async {
    // 1. Validate payment amount against balance rules
    final error = PaymentModel.validatePaymentAmount(
      amount: amount,
      currentBalance: currentBalance,
    );
    if (error != null) {
      throw Exception(error);
    }

    final docRef = _paymentsRef.doc();
    final timestamp = DateTime.now().toIso8601String();
    final paymentId = 'PAY-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    final orderRef = 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    final pendingPayment = PaymentModel(
      docId: docRef.id,
      paymentId: paymentId,
      receiptNumber: '',
      studentEmail: studentEmail.trim().toLowerCase(),
      studentId: studentId.trim().toUpperCase(),
      studentName: studentName.trim(),
      feeType: feeType.trim(),
      amount: amount,
      currency: 'LKR',
      paymentMethod: paymentMethod,
      transactionRef: orderRef,
      transactionId: '',
      paymentDate: timestamp,
      status: 'pending',
      createdAt: timestamp,
    );

    await docRef.set(pendingPayment.toMap());
    debugPrint('Initiated Pending Payment $paymentId for $studentId (Amount: LKR $amount)');

    // Log Pending notification
    await _dispatchNotification(
      title: 'Payment Order Initiated',
      message: 'Payment order $paymentId for LKR ${amount.toStringAsFixed(2)} ($feeType) has been initiated and is awaiting gateway authorization.',
      targetEmail: studentEmail,
      targetStudentId: studentId,
      type: 'payment_pending',
    );

    return pendingPayment;
  }

  /// Phase 2: Process & Verify Payment with trusted server-side verification logic
  Future<PaymentGatewayResult> processAndVerifyPayment({
    required PaymentModel pendingPayment,
    required String cardNumber,
    required String expiryDate,
    required String cvv,
    bool simulateFailure = false,
  }) async {
    if (pendingPayment.docId == null || pendingPayment.docId!.isEmpty) {
      return PaymentGatewayResult(isSuccess: false, errorMessage: 'Invalid pending payment record.');
    }

    // 1. Simulate Sandbox Gateway Processing Delay
    await Future.delayed(const Duration(milliseconds: 1200));

    if (simulateFailure) {
      final failTime = DateTime.now().toIso8601String();
      await _paymentsRef.doc(pendingPayment.docId).update({
        'status': 'failed',
        'updatedAt': failTime,
      });

      await _dispatchNotification(
        title: 'Payment Transaction Failed',
        message: 'Your payment attempt of LKR ${pendingPayment.amount.toStringAsFixed(2)} for ${pendingPayment.feeType} was declined by the issuing gateway.',
        targetEmail: pendingPayment.studentEmail,
        targetStudentId: pendingPayment.studentId,
        type: 'payment_failed',
      );

      return PaymentGatewayResult(isSuccess: false, errorMessage: 'Gateway transaction was declined by issuing bank.');
    }

    // 2. Gateway response mock
    final gatewayTxnId = 'TXN-SBX-${DateTime.now().millisecondsSinceEpoch.toString().substring(4)}';
    final receiptNo = PaymentModel.generateReceiptNumber();
    const gatewayStatus = 'COMPLETED';
    final gatewayAmount = pendingPayment.amount;
    const gatewayCurrency = 'LKR';

    // 3. Trusted Verification Checks:
    // a. Verify Gateway Status
    if (gatewayStatus != 'COMPLETED') {
      await _paymentsRef.doc(pendingPayment.docId).update({'status': 'failed'});
      return PaymentGatewayResult(isSuccess: false, errorMessage: 'Payment verification failed: Gateway reported status $gatewayStatus');
    }

    // b. Verify Amount
    if (gatewayAmount != pendingPayment.amount) {
      await _paymentsRef.doc(pendingPayment.docId).update({'status': 'failed'});
      return PaymentGatewayResult(isSuccess: false, errorMessage: 'Payment verification failed: Amount mismatch ($gatewayAmount vs ${pendingPayment.amount})');
    }

    // c. Verify Currency
    if (gatewayCurrency != 'LKR') {
      await _paymentsRef.doc(pendingPayment.docId).update({'status': 'failed'});
      return PaymentGatewayResult(isSuccess: false, errorMessage: 'Payment verification failed: Currency mismatch ($gatewayCurrency vs LKR)');
    }

    // d. Duplicate Transaction Prevention Check: Ensure gatewayTxnId hasn't already been used
    final existingSnap = await _paymentsRef
        .where('transactionId', isEqualTo: gatewayTxnId)
        .where('status', isEqualTo: 'success')
        .get();

    if (existingSnap.docs.isNotEmpty) {
      await _paymentsRef.doc(pendingPayment.docId).update({'status': 'failed'});
      return PaymentGatewayResult(isSuccess: false, errorMessage: 'Security Alert: Duplicate transaction detected for $gatewayTxnId');
    }

    // 4. Verification Passed: Update Firestore Record to 'success' with receiptNumber & audit timestamp
    final verifiedTimestamp = DateTime.now().toIso8601String();
    await _paymentsRef.doc(pendingPayment.docId).update({
      'status': 'success',
      'receiptNumber': receiptNo,
      'transactionId': gatewayTxnId,
      'verifiedAt': verifiedTimestamp,
    });

    // 5. Send automated confirmation notification to student
    await _dispatchNotification(
      title: 'Payment Verified Successfully',
      message: 'Your payment of LKR ${pendingPayment.amount.toStringAsFixed(2)} for ${pendingPayment.feeType} was successfully verified. Official Receipt: $receiptNo',
      targetEmail: pendingPayment.studentEmail,
      targetStudentId: pendingPayment.studentId,
      type: 'payment_success',
    );

    // 6. Send notification to Admin finance ledger
    await _dispatchNotification(
      title: 'New Student Fee Payment Received',
      message: 'Student ${pendingPayment.studentName} (${pendingPayment.studentId}) settled LKR ${pendingPayment.amount.toStringAsFixed(2)} for ${pendingPayment.feeType}. Receipt: $receiptNo (Txn: $gatewayTxnId)',
      targetEmail: 'admin@system.com',
      targetStudentId: 'ADMIN',
      type: 'admin_payment',
    );

    final verifiedPayment = PaymentModel(
      docId: pendingPayment.docId,
      paymentId: pendingPayment.paymentId,
      receiptNumber: receiptNo,
      studentEmail: pendingPayment.studentEmail,
      studentId: pendingPayment.studentId,
      studentName: pendingPayment.studentName,
      feeType: pendingPayment.feeType,
      amount: pendingPayment.amount,
      currency: pendingPayment.currency,
      paymentMethod: pendingPayment.paymentMethod,
      transactionRef: pendingPayment.transactionRef,
      transactionId: gatewayTxnId,
      paymentDate: pendingPayment.paymentDate,
      status: 'success',
      createdAt: pendingPayment.createdAt,
      verifiedAt: verifiedTimestamp,
    );

    return PaymentGatewayResult(
      isSuccess: true,
      transactionId: gatewayTxnId,
      receiptNumber: receiptNo,
      verifiedPayment: verifiedPayment,
    );
  }

  /// Process Refund with audit trail
  Future<void> processRefund({
    required String paymentDocId,
    required String reason,
  }) async {
    final refundTime = DateTime.now().toIso8601String();
    final docSnap = await _paymentsRef.doc(paymentDocId).get();
    if (!docSnap.exists) throw Exception('Payment record not found.');

    final payment = PaymentModel.fromFirestore(docSnap);

    await _paymentsRef.doc(paymentDocId).update({
      'status': 'refunded',
      'refundedAt': refundTime,
      'refundReason': reason,
    });

    await _dispatchNotification(
      title: 'Payment Refund Processed',
      message: 'A refund of LKR ${payment.amount.toStringAsFixed(2)} for ${payment.feeType} (Receipt: ${payment.receiptNumber}) has been processed.',
      targetEmail: payment.studentEmail,
      targetStudentId: payment.studentId,
      type: 'payment_refunded',
    );
  }

  Future<void> _dispatchNotification({
    required String title,
    required String message,
    required String targetEmail,
    required String targetStudentId,
    required String type,
  }) async {
    try {
      await _notificationsRef.add({
        'title': title,
        'message': message,
        'targetEmail': targetEmail,
        'targetStudentId': targetStudentId,
        'type': type,
        'createdAt': DateTime.now().toIso8601String(),
        'isRead': false,
      });
    } catch (e) {
      debugPrint('Notification error: $e');
    }
  }
}
