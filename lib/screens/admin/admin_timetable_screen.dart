import 'package:flutter/material.dart';
import '../../models/timetable_model.dart';
import '../../services/timetable_service.dart';
import 'add_edit_schedule_screen.dart';
import 'halls_list_screen.dart';

class AdminTimetableScreen extends StatefulWidget {
  const AdminTimetableScreen({super.key});

  @override
  State<AdminTimetableScreen> createState() => _AdminTimetableScreenState();
}

class _AdminTimetableScreenState extends State<AdminTimetableScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TimetableService _timetableService = TimetableService();

  String _selectedDay = 'Monday';
  String _selectedBatchFilter = 'All';

  final List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  final List<String> _batches = ['All', '2024', '2025', '2026', '2027'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCancelDialog(BuildContext context, TimetableModel schedule) {
    final reasonController = TextEditingController(text: 'Lecturer unavailable due to emergency / faculty event');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cancel_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Cancel Lecture', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cancel "${schedule.subjectName}" on ${schedule.dayOfWeek} (${schedule.startTime})?', style: const TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Reason for Cancellation *',
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Dismiss', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              try {
                await _timetableService.cancelLecture(
                  schedule.docId!,
                  schedule,
                  reasonController.text.trim(),
                );
                messenger.showSnackBar(
                  const SnackBar(content: Text('Lecture marked as Cancelled and alerts sent!'), backgroundColor: Colors.orange),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.redAccent),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Confirm Cancel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        title: const Row(
          children: [
            Icon(Icons.calendar_month_rounded, color: Colors.tealAccent),
            SizedBox(width: 8),
            Text('Timetable Management', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.meeting_room_rounded, color: Colors.amberAccent),
            tooltip: 'Manage Lecture Halls',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HallsListScreen()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.tealAccent,
          labelColor: Colors.tealAccent,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Day View', icon: Icon(Icons.view_day_rounded, size: 16)),
            Tab(text: 'Week View', icon: Icon(Icons.view_week_rounded, size: 16)),
            Tab(text: 'Batch View', icon: Icon(Icons.groups_rounded, size: 16)),
            Tab(text: 'Hall View', icon: Icon(Icons.apartment_rounded, size: 16)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEditScheduleScreen()),
          );
        },
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Schedule Lecture', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<List<TimetableModel>>(
        stream: _timetableService.getSchedulesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
          }

          final allSchedules = snapshot.data ?? [];

          return TabBarView(
            controller: _tabController,
            children: [
              _buildDayView(allSchedules),
              _buildWeekView(allSchedules),
              _buildBatchView(allSchedules),
              _buildHallView(allSchedules),
            ],
          );
        },
      ),
    );
  }

  // ─── 1. DAY VIEW ───────────────────────────────────────────────────────────
  Widget _buildDayView(List<TimetableModel> schedules) {
    final daily = schedules.where((s) => s.dayOfWeek.toLowerCase() == _selectedDay.toLowerCase()).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          color: const Color(0xFF1E293B),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _days.map((day) {
                final isSel = day == _selectedDay;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(day),
                    selected: isSel,
                    onSelected: (val) {
                      if (val) setState(() => _selectedDay = day);
                    },
                    selectedColor: Colors.teal,
                    backgroundColor: const Color(0xFF0F172A),
                    labelStyle: TextStyle(color: isSel ? Colors.white : Colors.grey, fontWeight: isSel ? FontWeight.bold : FontWeight.normal),
                    side: BorderSide(color: isSel ? Colors.tealAccent : Colors.white10),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(
          child: daily.isEmpty
              ? Center(child: Text('No lectures scheduled for $_selectedDay.', style: const TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: daily.length,
                  itemBuilder: (context, index) => _buildScheduleCard(daily[index]),
                ),
        ),
      ],
    );
  }

  // ─── 2. WEEK VIEW ──────────────────────────────────────────────────────────
  Widget _buildWeekView(List<TimetableModel> schedules) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: _days.map((day) {
        final daySchedules = schedules.where((s) => s.dayOfWeek.toLowerCase() == day.toLowerCase()).toList();
        if (daySchedules.isEmpty) return const SizedBox();

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.teal.withAlpha(20), borderRadius: BorderRadius.circular(8)),
                child: Text(day.toUpperCase(), style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
              ),
              const SizedBox(height: 8),
              ...daySchedules.map((s) => _buildScheduleCard(s)),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ─── 3. BATCH VIEW ─────────────────────────────────────────────────────────
  Widget _buildBatchView(List<TimetableModel> schedules) {
    final filtered = schedules.where((s) {
      if (_selectedBatchFilter == 'All') return true;
      return s.batch == _selectedBatchFilter;
    }).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: const Color(0xFF1E293B),
          child: Row(
            children: [
              const Text('Filter by Batch: ', style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _selectedBatchFilter,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold),
                underline: const SizedBox(),
                items: _batches.map((b) => DropdownMenuItem(value: b, child: Text(b == 'All' ? 'All Batches' : 'Batch $b'))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedBatchFilter = val);
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No schedules matching batch filter.', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => _buildScheduleCard(filtered[index]),
                ),
        ),
      ],
    );
  }

  // ─── 4. HALL VIEW ──────────────────────────────────────────────────────────
  Widget _buildHallView(List<TimetableModel> schedules) {
    final Map<String, List<TimetableModel>> hallMap = {};
    for (var s in schedules) {
      final key = s.mode == 'Online' ? 'Online Virtual Classes' : s.hallName;
      if (!hallMap.containsKey(key)) hallMap[key] = [];
      hallMap[key]!.add(s);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: hallMap.entries.map((entry) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, size: 16, color: Colors.amberAccent),
                  const SizedBox(width: 6),
                  Text(entry.key, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              const SizedBox(height: 8),
              ...entry.value.map((s) => _buildScheduleCard(s)),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ─── SCHEDULE CARD COMPONENT ───────────────────────────────────────────────
  Widget _buildScheduleCard(TimetableModel s) {
    final isCancelled = s.status == 'cancelled';
    final isRescheduled = s.status == 'rescheduled';
    final isOnline = s.mode.toLowerCase() == 'online';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCancelled
              ? Colors.redAccent.withAlpha(80)
              : (isRescheduled ? Colors.orangeAccent.withAlpha(80) : Colors.white10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.teal.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.tealAccent.withAlpha(80)),
                ),
                child: Text(
                  s.subjectCode,
                  style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isCancelled
                      ? Colors.red.withAlpha(30)
                      : (isRescheduled ? Colors.orange.withAlpha(30) : Colors.green.withAlpha(30)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  s.status.toUpperCase(),
                  style: TextStyle(
                    color: isCancelled ? Colors.redAccent : (isRescheduled ? Colors.orangeAccent : Colors.greenAccent),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(s.subjectName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 6),

          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 14, color: Colors.amberAccent),
              const SizedBox(width: 6),
              Text('${s.startTime} - ${s.endTime} (${s.dayOfWeek})', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(width: 14),
              Icon(isOnline ? Icons.videocam_rounded : Icons.apartment_rounded, size: 14, color: Colors.tealAccent),
              const SizedBox(width: 6),
              Text(isOnline ? 'Online' : s.hallName, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),

          Row(
            children: [
              const Icon(Icons.person_outline, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text('Lecturer: ${s.lecturerName.isNotEmpty ? s.lecturerName : "Faculty Staff"}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const Spacer(),
              Text('Batch ${s.batch}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ),

          if (s.rescheduleReason != null && s.rescheduleReason!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Note: ${s.rescheduleReason}', style: const TextStyle(color: Colors.orangeAccent, fontSize: 11, fontStyle: FontStyle.italic)),
          ],

          const SizedBox(height: 10),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 6),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!isCancelled) ...[
                TextButton.icon(
                  onPressed: () => _showCancelDialog(context, s),
                  icon: const Icon(Icons.cancel_outlined, size: 14, color: Colors.redAccent),
                  label: const Text('Cancel Lecture', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AddEditScheduleScreen(schedule: s)),
                    );
                  },
                  icon: const Icon(Icons.edit_calendar_rounded, size: 14, color: Colors.tealAccent),
                  label: const Text('Reschedule', style: TextStyle(color: Colors.tealAccent, fontSize: 12)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
