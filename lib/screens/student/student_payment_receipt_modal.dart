import 'package:flutter/material.dart';
import '../../models/payment_model.dart';

class StudentPaymentReceiptModal extends StatelessWidget {
  final PaymentModel payment;
  final String studentName;
  final String studentId;

  const StudentPaymentReceiptModal({
    super.key,
    required this.payment,
    required this.studentName,
    required this.studentId,
  });

  static void show(
    BuildContext context, {
    required PaymentModel payment,
    required String studentName,
    required String studentId,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StudentPaymentReceiptModal(
        payment: payment,
        studentName: studentName,
        studentId: studentId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSuccess = payment.status.toLowerCase() == 'success' || payment.status.toLowerCase() == 'successful';
    final dateStr = payment.paymentDate.length >= 10 ? payment.paymentDate.substring(0, 10) : payment.paymentDate;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close pill
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),

            // ─── OFFICIAL RECEIPT CARD ─────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(90),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Receipt Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E1B4B),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.tealAccent.withAlpha(40),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.receipt_long_rounded, color: Colors.tealAccent, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'UNIVERSITY OF HIGHER EDUCATION',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5),
                              ),
                              Text(
                                'OFFICIAL PAYMENT RECEIPT',
                                style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                              Text('Finance & Bursar Division', style: TextStyle(color: Colors.white60, fontSize: 10)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Receipt Body
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Amount Banner
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('AMOUNT PAID', style: TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.bold)),
                              Text(
                                'LKR ${payment.amount.toStringAsFixed(2)}',
                                style: const TextStyle(color: Color(0xFF1E1B4B), fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Details Table
                        _receiptRow('Official Receipt No', payment.receiptNumber.isNotEmpty ? payment.receiptNumber : 'REC-2026-${payment.paymentId}', isMonospace: true),
                        _receiptRow('Payment Order ID', payment.paymentId, isMonospace: true),
                        _receiptRow('Gateway Transaction ID', payment.transactionId.isNotEmpty ? payment.transactionId : payment.transactionRef, isMonospace: true),
                        _receiptRow('Payment Date & Time', dateStr),
                        _receiptRow('Candidate Name', studentName.isNotEmpty ? studentName : payment.studentName),
                        _receiptRow('Student ID', studentId.isNotEmpty ? studentId : payment.studentId, isMonospace: true),
                        _receiptRow('Fee Category', payment.feeType),
                        _receiptRow('Payment Method', payment.paymentMethod),
                        const SizedBox(height: 8),

                        // Status Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Payment Status', style: TextStyle(color: Colors.black54, fontSize: 12)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: isSuccess ? Colors.green[100] : Colors.red[100],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded, size: 12, color: isSuccess ? Colors.green[800] : Colors.red[800]),
                                  const SizedBox(width: 4),
                                  Text(
                                    isSuccess ? 'SUCCESSFUL (PAID)' : payment.status.toUpperCase(),
                                    style: TextStyle(color: isSuccess ? Colors.green[800] : Colors.red[800], fontWeight: FontWeight.bold, fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        const Divider(color: Colors.black12, height: 1),
                        const SizedBox(height: 12),

                        // Footer Note & QR pass
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                'This is an electronically generated receipt verified by the Bursar Division. No physical signature required.',
                                style: TextStyle(color: Colors.black45, fontSize: 9, height: 1.3),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.qr_code_2_rounded, size: 44, color: Color(0xFF1E1B4B)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Save / Close Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Receipt saved / ready for download.'), backgroundColor: Colors.teal),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.download_rounded, color: Colors.white, size: 18),
                label: const Text('Save / Download Receipt', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value, {bool isMonospace = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                fontFamily: isMonospace ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
