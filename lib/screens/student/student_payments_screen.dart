import 'package:flutter/material.dart';
import '../../services/student_portal_service.dart';
import '../../models/payment_model.dart';

class StudentPaymentsScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const StudentPaymentsScreen({super.key, this.userData});

  @override
  State<StudentPaymentsScreen> createState() => _StudentPaymentsScreenState();
}

class _StudentPaymentsScreenState extends State<StudentPaymentsScreen> {
  final StudentPortalService _portalService = StudentPortalService();

  static const double totalCourseFees = 450000.0; // LKR Total Course Fee (e.g. 3 Years)

  void _showMakePaymentModal(BuildContext context, double currentBalance) {
    final amountController = TextEditingController(text: currentBalance > 0 ? '${currentBalance.toInt()}' : '50000');
    final cardNoController = TextEditingController(text: '4532 •••• •••• 8891');
    final expiryController = TextEditingController(text: '08/29');
    final cvvController = TextEditingController(text: '342');
    String selectedFeeType = 'Tuition Fee';
    bool isProcessing = false;

    showModalBottomSheet(
      context: context,
      isScrollable: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.credit_card_rounded, color: Colors.tealAccent),
                      SizedBox(width: 8),
                      Text('Online Payment Gateway', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 14),

              // Fee Type Selector
              DropdownButtonFormField<String>(
                value: selectedFeeType,
                dropdownColor: const Color(0xFF0F172A),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Payment Category',
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: const [
                  DropdownMenuItem(value: 'Tuition Fee', child: Text('Semester Tuition Fee Installment')),
                  DropdownMenuItem(value: 'Exam Fee', child: Text('Repeat / Late Exam Fee')),
                  DropdownMenuItem(value: 'Lab Fee', child: Text('Computing & Science Lab Access Fee')),
                  DropdownMenuItem(value: 'Library Fine', child: Text('Library Overdue Fine')),
                ],
                onChanged: (val) {
                  if (val != null) setModalState(() => selectedFeeType = val);
                },
              ),
              const SizedBox(height: 12),

              // Amount Field
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Payment Amount (LKR)',
                  labelStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.payments_outlined, color: Colors.tealAccent),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),

              // Card details
              TextField(
                controller: cardNoController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Card Number',
                  labelStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.credit_card, color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: expiryController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'MM/YY',
                        labelStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: cvvController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'CVV',
                        labelStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isProcessing
                      ? null
                      : () async {
                          final amt = double.tryParse(amountController.text.trim()) ?? 0.0;
                          if (amt <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a valid amount.'), backgroundColor: Colors.redAccent),
                            );
                            return;
                          }

                          setModalState(() => isProcessing = true);
                          final messenger = ScaffoldMessenger.of(context);
                          final nav = Navigator.of(ctx);

                          final email = widget.userData?['email'] ?? '';
                          final studentId = widget.userData?['studentId'] ?? 'STU-1002';
                          final studentName = widget.userData?['fullName'] ?? 'Student';
                          final ref = 'TXN-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';

                          try {
                            final payment = PaymentModel(
                              paymentId: ref,
                              studentEmail: email,
                              studentId: studentId,
                              studentName: studentName,
                              feeType: selectedFeeType,
                              amount: amt,
                              paymentMethod: 'Visa / MasterCard Gateway',
                              transactionRef: ref,
                              paymentDate: DateTime.now().toIso8601String(),
                              status: 'success',
                            );

                            await _portalService.processPayment(payment);

                            nav.pop();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Payment of LKR ${amt.toStringAsFixed(0)} successful! Receipt: $ref'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            setModalState(() => isProcessing = false);
                            messenger.showSnackBar(
                              SnackBar(content: Text('Payment failed: $e'), backgroundColor: Colors.redAccent),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: isProcessing
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.lock_outline_rounded, color: Colors.white),
                  label: const Text('Pay Securely with Gateway', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.userData?['email'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          children: [
            Icon(Icons.account_balance_wallet_rounded, color: Colors.tealAccent),
            SizedBox(width: 8),
            Text('Fees & Payments', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: StreamBuilder<List<PaymentModel>>(
        stream: _portalService.getStudentPaymentsStream(email),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
          }

          final payments = snapshot.data ?? [];
          final successfulPayments = payments.where((p) => p.status == 'success').toList();

          double totalPaid = 0.0;
          for (var p in successfulPayments) {
            totalPaid += p.amount;
          }

          // If no payments recorded in db yet, set default baseline
          if (totalPaid == 0 && payments.isEmpty) {
            totalPaid = 300000.0;
          }

          final double outstandingBalance = (totalCourseFees - totalPaid).clamp(0.0, totalCourseFees);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Balance Summary Card
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF334155)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: outstandingBalance > 0 ? Colors.orangeAccent.withAlpha(80) : Colors.greenAccent.withAlpha(80)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('OUTSTANDING BALANCE', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: outstandingBalance > 0 ? Colors.orange.withAlpha(30) : Colors.green.withAlpha(30),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            outstandingBalance > 0 ? 'PAYMENT DUE' : 'FULLY SETTLED',
                            style: TextStyle(color: outstandingBalance > 0 ? Colors.orangeAccent : Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'LKR ${outstandingBalance.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: outstandingBalance > 0 ? Colors.orangeAccent : Colors.greenAccent,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: Colors.white10, height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Course Fees', style: TextStyle(color: Colors.grey, fontSize: 11)),
                            Text('LKR ${totalCourseFees.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Total Paid to Date', style: TextStyle(color: Colors.grey, fontSize: 11)),
                            Text('LKR ${totalPaid.toStringAsFixed(0)}', style: const TextStyle(color: Colors.tealAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Pay Now Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showMakePaymentModal(context, outstandingBalance),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.payment_rounded, color: Colors.white),
                  label: const Text('Make Online Payment (Pay Now)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 24),

              const Text('Payment History & Receipts', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              if (payments.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(14)),
                  child: const Center(
                    child: Text('No payment transaction records found in ledger.', style: TextStyle(color: Colors.grey)),
                  ),
                )
              else
                ...payments.map((p) {
                  final isSuccess = p.status == 'success';
                  final dateStr = p.paymentDate.length >= 10 ? p.paymentDate.substring(0, 10) : p.paymentDate;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSuccess ? Colors.green.withAlpha(30) : Colors.red.withAlpha(30),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded,
                            color: isSuccess ? Colors.greenAccent : Colors.redAccent,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.feeType, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 2),
                              Text('Ref: ${p.transactionRef} • $dateStr', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'LKR ${p.amount.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: isSuccess ? Colors.tealAccent : Colors.redAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(p.status.toUpperCase(), style: TextStyle(color: isSuccess ? Colors.greenAccent : Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}
