import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/exam_model.dart';
import '../../models/exam_hall_model.dart';
import '../../models/exam_registration_model.dart';
import '../../models/exam_seating_model.dart';
import '../../services/exam_seating_service.dart';
import '../../services/exam_registration_service.dart';

class AdminExamSeatingScreen extends StatefulWidget {
  final ExamModel exam;

  const AdminExamSeatingScreen({super.key, required this.exam});

  @override
  State<AdminExamSeatingScreen> createState() => _AdminExamSeatingScreenState();
}

class _AdminExamSeatingScreenState extends State<AdminExamSeatingScreen> {
  final ExamSeatingService _seatingService = ExamSeatingService();
  final ExamRegistrationService _regService = ExamRegistrationService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  bool _isGridView = true;
  bool _isProcessing = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Find the assigned hall model from Firestore
  Future<ExamHallModel?> _fetchAssignedHall() async {
    if (widget.exam.hallId == null || widget.exam.hallId!.isEmpty) {
      return null;
    }
    try {
      final snap = await FirebaseFirestore.instance
          .collection('examHalls')
          .where('hallId', isEqualTo: widget.exam.hallId)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        return ExamHallModel.fromFirestore(snap.docs.first);
      }
    } catch (_) {}
    return null;
  }

  // ─── GENERATE / REGENERATE CONFIRMATION DIALOG ──────────────────────────────
  void _confirmGenerateSeating({
    required ExamHallModel hall,
    required int registeredCount,
    required bool isRegeneration,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Icon(isRegeneration ? Icons.restart_alt_rounded : Icons.auto_awesome_rounded, color: isRegeneration ? Colors.amberAccent : Colors.tealAccent),
            const SizedBox(width: 8),
            Text(
              isRegeneration ? 'Regenerate Seating Plan' : 'Generate Seating Plan',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exam: ${widget.exam.subjectCode} • ${widget.exam.subjectName}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text('Venue: ${hall.hallName} (${hall.hallId})', style: const TextStyle(color: Colors.white70, fontSize: 13)),
            Text('Hall Capacity: ${hall.capacity} Seats', style: const TextStyle(color: Colors.tealAccent, fontSize: 12)),
            Text('Registered Students: $registeredCount Students', style: const TextStyle(color: Colors.amberAccent, fontSize: 12)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isRegeneration ? Colors.amber.withAlpha(20) : Colors.teal.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isRegeneration ? Colors.amberAccent.withAlpha(80) : Colors.tealAccent.withAlpha(80)),
              ),
              child: Text(
                isRegeneration
                    ? '⚠️ Warning: Regenerating will safely replace all previous seat numbers with a new mixed randomized distribution.'
                    : 'A deterministic mixed desk distribution will be generated. Each registered student will receive a unique seat number.',
                style: TextStyle(color: isRegeneration ? Colors.amberAccent : Colors.white70, fontSize: 11),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isProcessing = true);

              try {
                final allocs = await _seatingService.generateSeatingArrangement(
                  exam: widget.exam,
                  hall: hall,
                  allocatedBy: 'Admin',
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Successfully allocated ${allocs.length} seats in ${hall.hallName}!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                final msg = e.toString().replaceAll('Exception: ', '');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(msg), backgroundColor: Colors.redAccent, duration: const Duration(seconds: 4)),
                  );
                }
              } finally {
                if (mounted) setState(() => _isProcessing = false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: isRegeneration ? Colors.amber[700] : Colors.teal),
            icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
            label: Text(
              isRegeneration ? 'Yes, Regenerate' : 'Generate Now',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ─── CLEAR SEATING CONFIRMATION ─────────────────────────────────────────────
  void _confirmClearSeating() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Clear Seating Plan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Text('Are you sure you want to clear all seat allocations for ${widget.exam.subjectCode}? Students will no longer see assigned seat numbers.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isProcessing = true);
              try {
                await _seatingService.clearSeatingArrangement(widget.exam.examId, examDocId: widget.exam.docId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Seating arrangement cleared successfully.'), backgroundColor: Colors.amber),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
                  );
                }
              } finally {
                if (mounted) setState(() => _isProcessing = false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Clear All Seats', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Exam Seating & Hall Plan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            Text('${widget.exam.subjectCode} • ${widget.exam.examType}', style: const TextStyle(color: Colors.tealAccent, fontSize: 11)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded, color: Colors.amberAccent),
            tooltip: _isGridView ? 'Switch to List View' : 'Switch to Desk Grid View',
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
        ],
      ),
      body: FutureBuilder<ExamHallModel?>(
        future: _fetchAssignedHall(),
        builder: (context, hallSnapshot) {
          final assignedHall = hallSnapshot.data;

          return StreamBuilder<List<ExamRegistrationModel>>(
            stream: _regService.getRegistrationsForExamStream(widget.exam.examId, examDocId: widget.exam.docId),
            builder: (context, regSnapshot) {
              final registrations = regSnapshot.data ?? [];
              final validRegistrations = registrations.where((r) => r.isApprovedOrRegistered).toList();

              return StreamBuilder<List<ExamSeatingModel>>(
                stream: _seatingService.getSeatingForExamStream(widget.exam.examId, examDocId: widget.exam.docId),
                builder: (context, seatingSnapshot) {
                  if (seatingSnapshot.connectionState == ConnectionState.waiting || hallSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
                  }

                  final seatings = seatingSnapshot.data ?? [];
                  final isGenerated = seatings.isNotEmpty;

                  final hallCapacity = assignedHall?.capacity ?? widget.exam.hallCapacity ?? 0;
                  final registeredCount = validRegistrations.isNotEmpty ? validRegistrations.length : widget.exam.registeredStudentCount;
                  final allocatedCount = seatings.length;
                  final remainingSeats = hallCapacity > 0 ? (hallCapacity - allocatedCount) : 0;
                  final isCapacityExceeded = registeredCount > hallCapacity && hallCapacity > 0;

                  // Filter seatings for search
                  final filteredSeatings = seatings.where((s) {
                    return _searchQuery.isEmpty ||
                        s.studentName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        s.studentId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        s.seatNumber.toLowerCase().contains(_searchQuery.toLowerCase());
                  }).toList();

                  return Column(
                    children: [
                      // 1. Exam & Assigned Hall Banner
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E293B),
                          border: Border(bottom: BorderSide(color: Colors.white10)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.exam.subjectName,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${widget.exam.date} • ${widget.exam.startTime} - ${widget.exam.endTime}',
                                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isGenerated ? Colors.green.withAlpha(30) : Colors.orange.withAlpha(30),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: isGenerated ? Colors.greenAccent.withAlpha(80) : Colors.orangeAccent.withAlpha(80)),
                                  ),
                                  child: Text(
                                    isGenerated ? 'SEATING ALLOCATED' : 'NOT ALLOCATED',
                                    style: TextStyle(
                                      color: isGenerated ? Colors.greenAccent : Colors.orangeAccent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Venue Details
                            Row(
                              children: [
                                const Icon(Icons.meeting_room_rounded, size: 14, color: Colors.tealAccent),
                                const SizedBox(width: 4),
                                Text(
                                  assignedHall != null ? '${assignedHall.hallName} (${assignedHall.hallId})' : 'Venue: ${widget.exam.examHall}',
                                  style: const TextStyle(color: Colors.tealAccent, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                if (assignedHall != null) ...[
                                  const SizedBox(width: 8),
                                  Text('• ${assignedHall.building}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),

                      // 2. Metric KPI Cards Strip (Hall Capacity, Registered, Allocated, Remaining)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        color: const Color(0xFF0F172A),
                        child: Row(
                          children: [
                            Expanded(child: _buildMetricCard('Hall Capacity', '$hallCapacity', Colors.indigoAccent, Icons.event_seat_rounded)),
                            const SizedBox(width: 6),
                            Expanded(child: _buildMetricCard('Registered', '$registeredCount', Colors.amberAccent, Icons.how_to_reg_rounded)),
                            const SizedBox(width: 6),
                            Expanded(child: _buildMetricCard('Allocated', '$allocatedCount', Colors.greenAccent, Icons.check_circle_rounded)),
                            const SizedBox(width: 6),
                            Expanded(child: _buildMetricCard('Remaining', '$remainingSeats', remainingSeats >= 0 ? Colors.cyanAccent : Colors.redAccent, Icons.chair_rounded)),
                          ],
                        ),
                      ),

                      // 3. Status Alerts & Action Buttons
                      if (assignedHall == null && (widget.exam.hallId == null || widget.exam.hallId!.isEmpty))
                        Container(
                          margin: const EdgeInsets.all(12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.orangeAccent.withAlpha(80)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'No examination hall has been assigned to this exam yet. Please assign a hall before generating seating.',
                                  style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (isCapacityExceeded)
                        Container(
                          margin: const EdgeInsets.all(12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.redAccent.withAlpha(80)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Capacity Error: $registeredCount registered students exceed hall capacity ($hallCapacity seats). Seating allocation is disabled until a larger hall is assigned.',
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        // Action Buttons Bar
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isProcessing || isCapacityExceeded || assignedHall == null
                                      ? null
                                      : () => _confirmGenerateSeating(
                                            hall: assignedHall,
                                            registeredCount: registeredCount,
                                            isRegeneration: isGenerated,
                                          ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isGenerated ? Colors.amber[700] : Colors.teal,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: _isProcessing
                                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : Icon(isGenerated ? Icons.restart_alt_rounded : Icons.auto_awesome_rounded, color: Colors.white, size: 16),
                                  label: Text(
                                    isGenerated ? 'Regenerate Seating Plan' : 'Generate Seating Arrangement',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                              ),
                              if (isGenerated) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
                                  tooltip: 'Clear Seating Plan',
                                  onPressed: _isProcessing ? null : () => _confirmClearSeating(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],

                      // 4. Search Filter (if seating generated)
                      if (isGenerated)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            decoration: InputDecoration(
                              hintText: 'Search by Student Name, ID, or Seat (e.g. SEAT-001)...',
                              hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                              prefixIcon: const Icon(Icons.search_rounded, color: Colors.tealAccent, size: 18),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, color: Colors.grey, size: 16),
                                      onPressed: () => setState(() {
                                        _searchController.clear();
                                        _searchQuery = '';
                                      }),
                                    )
                                  : null,
                              filled: true,
                              fillColor: const Color(0xFF1E293B),
                              contentPadding: const EdgeInsets.symmetric(vertical: 6),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                            ),
                            onChanged: (val) => setState(() => _searchQuery = val.trim()),
                          ),
                        ),

                      // 5. Seating Arrangement Content (Grid or List)
                      Expanded(
                        child: !isGenerated
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.event_seat_rounded, size: 52, color: Colors.grey),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'No seating arrangement generated yet.',
                                        style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        assignedHall != null
                                            ? 'Click "Generate Seating Arrangement" above to allocate desks for $registeredCount registered students.'
                                            : 'Assign a hall to this exam first, then generate seating.',
                                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : filteredSeatings.isEmpty
                                ? const Center(child: Text('No seat allocations match search query.', style: TextStyle(color: Colors.grey)))
                                : _isGridView
                                    ? _buildDeskGridView(filteredSeatings)
                                    : _buildListView(filteredSeatings),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // ─── DESK GRID VIEW (Visual Layout) ─────────────────────────────────────────
  Widget _buildDeskGridView(List<ExamSeatingModel> seatings) {
    return GridView.builder(
      padding: const EdgeInsets.all(14),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.6,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: seatings.length,
      itemBuilder: (context, index) {
        final seat = seatings[index];

        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.tealAccent.withAlpha(80)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.teal, borderRadius: BorderRadius.circular(4)),
                    child: Text(
                      seat.seatNumber,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'monospace'),
                    ),
                  ),
                  const Icon(Icons.desktop_windows_rounded, size: 14, color: Colors.tealAccent),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    seat.studentName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    seat.studentId,
                    style: const TextStyle(color: Colors.amberAccent, fontSize: 10, fontFamily: 'monospace'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── LIST VIEW ─────────────────────────────────────────────────────────────
  Widget _buildListView(List<ExamSeatingModel> seatings) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      itemCount: seatings.length,
      itemBuilder: (context, index) {
        final seat = seatings[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              Container(
                width: 75,
                padding: const EdgeInsets.symmetric(vertical: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.tealAccent.withAlpha(80)),
                ),
                child: Text(
                  seat.seatNumber,
                  style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(seat.studentName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('${seat.studentId} • ${seat.studentEmail}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.green.withAlpha(30), borderRadius: BorderRadius.circular(4)),
                child: const Text('ALLOCATED', style: TextStyle(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 9), overflow: TextOverflow.ellipsis)),
              Icon(icon, size: 10, color: color),
            ],
          ),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
