import 'package:flutter/material.dart';
import '../../services/student_portal_service.dart';
import '../../services/fee_service.dart';
import '../../models/payment_model.dart';
import '../../models/fee_structure_model.dart';
import 'student_payment_receipt_modal.dart';

class StudentPaymentsScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const StudentPaymentsScreen({super.key, this.userData});

  @override
  State<StudentPaymentsScreen> createState() => _StudentPaymentsScreenState();
}

class _StudentPaymentsScreenState extends State<StudentPaymentsScreen> {
  final StudentPortalService _portalService = StudentPortalService();
  final FeeService _feeService = FeeService();

  void _showMakePaymentModal(BuildContext context, double currentBalance, List<FeeStructureModel> feeItems) {
    final amountController = TextEditingController(text: currentBalance > 0 ? '${currentBalance.toInt()}' : '50000');
    final cardNoController = TextEditingController(text: '4532 •••• •••• 8891');
    final expiryController = TextEditingController(text: '08/29');
    final cvvController = TextEditingController(text: '342');
    String selectedFeeType = feeItems.isNotEmpty ? feeItems.first.feeType : 'Semester Fee';
    String selectedPaymentMethod = 'Online Card (Visa/MasterCard)';
    bool isProcessing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                initialValue: selectedFeeType,
                dropdownColor: const Color(0xFF0F172A),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Payment Category',
                  labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: FeeStructureModel.supportedFeeTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setModalState(() => selectedFeeType = val);
                },
              ),
              const SizedBox(height: 12),

              // Payment Method Selector
              DropdownButtonFormField<String>(
                initialValue: selectedPaymentMethod,
                dropdownColor: const Color(0xFF0F172A),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Payment Method',
                  labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: const [
                  DropdownMenuItem(value: 'Online Card (Visa/MasterCard)', child: Text('Online Card (Visa / MasterCard)')),
                  DropdownMenuItem(value: 'Bank Transfer', child: Text('Direct Bank Transfer / Slip')),
                  DropdownMenuItem(value: 'Mobile Wallet', child: Text('Mobile Wallet (eZ Cash / Genie)')),
                ],
                onChanged: (val) {
                  if (val != null) setModalState(() => selectedPaymentMethod = val);
                },
              ),
              const SizedBox(height: 12),

              // Amount Field
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                  labelText: 'Card Number / Account Ref',
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
                              const SnackBar(content: Text('Please enter a valid amount greater than zero.'), backgroundColor: Colors.redAccent),
                            );
                            return;
                          }

                          setModalState(() => isProcessing = true);
                          final messenger = ScaffoldMessenger.of(context);
                          final nav = Navigator.of(ctx);

                          final email = widget.userData?['email'] ?? '';
                          final studentId = widget.userData?['studentId'] ?? 'STU-1002';
                          final studentName = widget.userData?['fullName'] ?? widget.userData?['name'] ?? 'Student';
                          final ref = 'PAY-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';

                          try {
                            final payment = PaymentModel(
                              paymentId: ref,
                              studentEmail: email,
                              studentId: studentId,
                              studentName: studentName,
                              feeType: selectedFeeType,
                              amount: amt,
                              paymentMethod: selectedPaymentMethod,
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
    final studentId = widget.userData?['studentId'] ?? '';
    final studentName = widget.userData?['fullName'] ?? widget.userData?['name'] ?? 'Student';
    final programme = widget.userData?['course'] ?? widget.userData?['programme'] ?? 'All';
    final batch = widget.userData?['batch'] ?? '2026';

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
            Text('Student Finance & Fees', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
      ),
      body: StreamBuilder<List<FeeStructureModel>>(
        stream: _feeService.getActiveFeeStructuresStream(
          programme: programme,
          batchId: batch,
        ),
        builder: (context, feeSnapshot) {
          if (feeSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
          }

          final feeItems = feeSnapshot.data ?? [];

          return StreamBuilder<List<PaymentModel>>(
            stream: _portalService.getStudentPaymentsStream(email),
            builder: (context, paymentSnapshot) {
              if (paymentSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
              }

              final payments = paymentSnapshot.data ?? [];
              final successfulPayments = payments.where((p) => p.status.toLowerCase() == 'success' || p.status.toLowerCase() == 'successful').toList();

              // Calculate dynamic financial metrics
              final double totalApplicableFees = feeItems.fold(0.0, (acc, f) => acc + f.amount);
              final double totalPaid = successfulPayments.fold(0.0, (acc, p) => acc + p.amount);
              final double outstandingBalance = FeeStructureModel.calculateBalance(
                totalFee: totalApplicableFees,
                paidAmount: totalPaid,
              );

              // Determine earliest next due date
              String nextDueDate = 'N/A';
              bool isAnyOverdue = false;
              if (feeItems.isNotEmpty) {
                final sortedByDate = List<FeeStructureModel>.from(feeItems)..sort((a, b) => a.dueDate.compareTo(b.dueDate));
                nextDueDate = sortedByDate.first.dueDate;
                isAnyOverdue = sortedByDate.any((f) => f.isPastDueDate);
              }

              // Overall status
              final overallStatus = FeeStructureModel.determinePaymentStatus(
                balance: outstandingBalance,
                paidAmount: totalPaid,
                dueDate: nextDueDate != 'N/A' ? nextDueDate : DateTime.now().toIso8601String().substring(0, 10),
              );

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ─── 1. OVERALL BALANCE KPI CARD ───────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E293B), Color(0xFF334155)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _statusBorderColor(overallStatus)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('OUTSTANDING BALANCE', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _statusColor(overallStatus).withAlpha(30),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: _statusColor(overallStatus).withAlpha(90)),
                              ),
                              child: Text(
                                overallStatus.toUpperCase(),
                                style: TextStyle(color: _statusColor(overallStatus), fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        Text(
                          'LKR ${outstandingBalance.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: _statusColor(overallStatus),
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
                                const Text('Total Program Fees', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                Text('LKR ${totalApplicableFees.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text('Total Paid', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                Text('LKR ${totalPaid.toStringAsFixed(2)}', style: const TextStyle(color: Colors.tealAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Next Due Date', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                Row(
                                  children: [
                                    if (isAnyOverdue && outstandingBalance > 0)
                                      const Icon(Icons.warning_amber_rounded, size: 12, color: Colors.redAccent),
                                    const SizedBox(width: 2),
                                    Text(
                                      nextDueDate,
                                      style: TextStyle(
                                        color: isAnyOverdue && outstandingBalance > 0 ? Colors.redAccent : Colors.amberAccent,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ─── 2. PAY NOW ACTION BUTTON ──────────────────────────────
                  if (outstandingBalance > 0)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showMakePaymentModal(context, outstandingBalance, feeItems),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.payment_rounded, color: Colors.white),
                        label: const Text('Make Online Payment (Pay Now)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  const SizedBox(height: 22),

                  // ─── 3. APPLICABLE FEE BREAKDOWN ───────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Fee Structure Breakdown', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                      Text('${feeItems.length} Applicable Items', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (feeItems.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
                      child: const Center(
                        child: Text('No active fee structures configured for your batch yet.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ),
                    )
                  else
                    ...feeItems.map((f) {
                      final isOverdue = f.isPastDueDate && outstandingBalance > 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.indigo.withAlpha(40),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(f.feeType, style: const TextStyle(color: Colors.indigoAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                                ),
                                Text(
                                  'LKR ${f.amount.toStringAsFixed(2)}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${f.programme} • ${f.semester}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                Row(
                                  children: [
                                    Icon(Icons.event_rounded, size: 12, color: isOverdue ? Colors.redAccent : Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Due: ${f.dueDate}',
                                      style: TextStyle(color: isOverdue ? Colors.redAccent : Colors.grey, fontSize: 11, fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 22),

                  // ─── 4. PAYMENT HISTORY & RECEIPTS ──────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Payment History & Receipts', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                      Text('${payments.length} Transactions', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (payments.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(14)),
                      child: const Center(
                        child: Text('No payment transaction records logged yet.', style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  else
                    ...payments.map((p) {
                      final isSuccess = p.status.toLowerCase() == 'success' || p.status.toLowerCase() == 'successful';
                      final dateStr = p.paymentDate.length >= 10 ? p.paymentDate.substring(0, 10) : p.paymentDate;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: _paymentStatusBgColor(p.status),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    _paymentStatusIcon(p.status),
                                    color: _paymentStatusColor(p.status),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p.feeType, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                      const SizedBox(height: 2),
                                      Text('ID: ${p.paymentId} • $dateStr', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                      Text('Method: ${p.paymentMethod}', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'LKR ${p.amount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: isSuccess ? Colors.tealAccent : Colors.redAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _paymentStatusColor(p.status).withAlpha(30),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        p.status.toUpperCase(),
                                        style: TextStyle(color: _paymentStatusColor(p.status), fontSize: 9, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            // View Receipt Button for successful transactions
                            if (isSuccess) ...[
                              const SizedBox(height: 10),
                              const Divider(color: Colors.white10, height: 1),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () {
                                    StudentPaymentReceiptModal.show(
                                      context,
                                      payment: p,
                                      studentName: studentName,
                                      studentId: studentId,
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.tealAccent,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  ),
                                  icon: const Icon(Icons.receipt_rounded, size: 14),
                                  label: const Text('View Official Receipt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.greenAccent;
      case 'partially paid':
        return Colors.amberAccent;
      case 'overdue':
        return Colors.redAccent;
      case 'unpaid':
      default:
        return Colors.orangeAccent;
    }
  }

  Color _statusBorderColor(String status) {
    return _statusColor(status).withAlpha(80);
  }

  Color _paymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'successful':
        return Colors.greenAccent;
      case 'pending':
        return Colors.amberAccent;
      case 'refunded':
        return Colors.cyanAccent;
      case 'failed':
      case 'cancelled':
      default:
        return Colors.redAccent;
    }
  }

  Color _paymentStatusBgColor(String status) {
    return _paymentStatusColor(status).withAlpha(30);
  }

  IconData _paymentStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'successful':
        return Icons.check_circle_rounded;
      case 'pending':
        return Icons.hourglass_top_rounded;
      case 'refunded':
        return Icons.replay_rounded;
      case 'failed':
      case 'cancelled':
      default:
        return Icons.cancel_rounded;
    }
  }
}
