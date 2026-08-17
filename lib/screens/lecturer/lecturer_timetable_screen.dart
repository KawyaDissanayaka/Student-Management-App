import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/timetable_model.dart';
import '../../models/hall_model.dart';

class LecturerTimetableScreen extends StatefulWidget {
  final String lecturerEmail;
  final String lecturerName;
  final String? lecturerId;

  const LecturerTimetableScreen({
    super.key,
    required this.lecturerEmail,
    required this.lecturerName,
    this.lecturerId,
  });

  @override
  State<LecturerTimetableScreen> createState() => _LecturerTimetableScreenState();
}

class _LecturerTimetableScreenState extends State<LecturerTimetableScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _searchQuery = '';
  String _selectedDayFilter = 'All';
  String _selectedTypeFilter = 'All';

  final List<String> _days = ['All', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  final List<String> _classTypes = ['All', 'Lecture', 'Lab', 'Tutorial', 'Workshop'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getTodayDayName() {
    final now = DateTime.now();
    const dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return dayNames[now.weekday - 1];
  }

  String _computeDynamicStatus(TimetableModel t) {
    if (t.status.toLowerCase() == 'cancelled') return 'cancelled';
    if (t.status.toLowerCase() == 'rescheduled') return 'rescheduled';

    final todayName = _getTodayDayName();
    if (t.dayOfWeek.toLowerCase() == todayName.toLowerCase()) {
      final now = DateTime.now();
      final currentMinutes = now.hour * 60 + now.minute;
      final startMin = TimetableModel.parseTimeToMinutes(t.startTime);
      final endMin = TimetableModel.parseTimeToMinutes(t.endTime);

      if (currentMinutes >= startMin && currentMinutes <= endMin) {
        return 'ongoing';
      } else if (currentMinutes > endMin) {
        return 'completed';
      } else {
        return 'upcoming';
      }
    }
    return 'upcoming';
  }

  void _showHallDetailsModal(BuildContext context, TimetableModel timetable) async {
    HallModel? hallData;

    try {
      final snap = await _firestore
          .collection('lecture_halls')
          .where('name', isEqualTo: timetable.hallName)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        hallData = HallModel.fromFirestore(snap.docs.first);
      }
    } catch (_) {}

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.meeting_room_rounded, color: Colors.amberAccent),
                    const SizedBox(width: 8),
                    Text(
                      timetable.hallName,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 4),
            Text('${timetable.subjectCode} - ${timetable.subjectName}', style: const TextStyle(color: Colors.tealAccent, fontSize: 13, fontWeight: FontWeight.w600)),
            Text('${timetable.dayOfWeek} • ${timetable.startTime} - ${timetable.endTime}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Building / Complex:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      Text(hallData?.building.isNotEmpty == true ? hallData!.building : 'Main Academic Block', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Floor Level:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      Text(hallData?.floor.isNotEmpty == true ? hallData!.floor : 'Floor 02', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Seating Capacity:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      Text('${hallData?.capacity ?? timetable.hallCapacity} Students', style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Class Type:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      Text(timetable.classType, style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            const Text('AVAILABLE HALL FACILITIES', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 8),

            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: (hallData?.facilities.isNotEmpty == true ? hallData!.facilities : ['Air Conditioning', 'Multimedia Projector', 'Audio System', 'High-Speed Wi-Fi'])
                  .map((fac) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.teal.withAlpha(30), borderRadius: BorderRadius.circular(6)),
                        child: Text(fac, style: const TextStyle(color: Colors.tealAccent, fontSize: 11, fontWeight: FontWeight.w600)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cleanEmail = widget.lecturerEmail.trim().toLowerCase();

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
            const Text('My Timetable & Schedule', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            Text('${widget.lecturerName} • Academic Schedule', style: const TextStyle(color: Colors.amberAccent, fontSize: 11)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amberAccent,
          labelColor: Colors.amberAccent,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: "Today's Classes", icon: Icon(Icons.today_rounded, size: 16)),
            Tab(text: 'Weekly Schedule', icon: Icon(Icons.calendar_view_week_rounded, size: 16)),
            Tab(text: 'All Sessions', icon: Icon(Icons.list_alt_rounded, size: 16)),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('timetables').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.amberAccent));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading timetable: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
          }

          final docs = snapshot.data?.docs ?? [];
          final allLecturerClasses = docs
              .map((d) => TimetableModel.fromFirestore(d))
              .where((t) {
                final matchEmail = t.lecturerEmail.trim().toLowerCase() == cleanEmail;
                final matchName = t.lecturerName.trim().toLowerCase() == widget.lecturerName.trim().toLowerCase();
                final matchId = widget.lecturerId != null && widget.lecturerId!.isNotEmpty && t.lecturerId == widget.lecturerId;
                return matchEmail || matchName || matchId;
              })
              .toList();

          // Sort by day order then start time
          const dayWeights = {'monday': 1, 'tuesday': 2, 'wednesday': 3, 'thursday': 4, 'friday': 5, 'saturday': 6, 'sunday': 7};
          allLecturerClasses.sort((a, b) {
            final dayA = dayWeights[a.dayOfWeek.toLowerCase()] ?? 8;
            final dayB = dayWeights[b.dayOfWeek.toLowerCase()] ?? 8;
            if (dayA != dayB) return dayA.compareTo(dayB);
            return TimetableModel.parseTimeToMinutes(a.startTime).compareTo(TimetableModel.parseTimeToMinutes(b.startTime));
          });

          final todayName = _getTodayDayName();
          final todayClasses = allLecturerClasses.where((t) => t.dayOfWeek.toLowerCase() == todayName.toLowerCase()).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              // 1. TODAY'S CLASSES TAB
              _buildTodayTab(todayClasses, todayName),

              // 2. WEEKLY SCHEDULE TAB
              _buildWeeklyTab(allLecturerClasses),

              // 3. ALL SESSIONS TAB
              _buildAllSessionsTab(allLecturerClasses),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTodayTab(List<TimetableModel> todayClasses, String todayName) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          color: const Color(0xFF1E293B),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("TODAY IS ${todayName.toUpperCase()}", style: const TextStyle(color: Colors.amberAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text('${todayClasses.length} lecture sessions scheduled today', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.amber.withAlpha(30), borderRadius: BorderRadius.circular(8)),
                child: Text('${todayClasses.length} Today', style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ),

        Expanded(
          child: todayClasses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy_rounded, size: 56, color: Colors.grey.withAlpha(80)),
                      const SizedBox(height: 12),
                      Text('No lectures scheduled for today ($todayName).', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: todayClasses.length,
                  itemBuilder: (context, index) {
                    return _buildTimetableCard(todayClasses[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildWeeklyTab(List<TimetableModel> allClasses) {
    final filtered = allClasses.where((t) {
      if (_selectedDayFilter == 'All') return true;
      return t.dayOfWeek.toLowerCase() == _selectedDayFilter.toLowerCase();
    }).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          color: const Color(0xFF1E293B),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _days.map((d) {
                final isSel = d == _selectedDayFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(d == 'All' ? 'ALL DAYS' : d.toUpperCase()),
                    selected: isSel,
                    onSelected: (val) {
                      if (val) setState(() => _selectedDayFilter = d);
                    },
                    selectedColor: Colors.amber[700],
                    backgroundColor: const Color(0xFF0F172A),
                    labelStyle: TextStyle(color: isSel ? Colors.white : Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                    side: BorderSide(color: isSel ? Colors.amberAccent : Colors.white10),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 56, color: Colors.grey.withAlpha(80)),
                      const SizedBox(height: 12),
                      Text('No classes found for $_selectedDayFilter.', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return _buildTimetableCard(filtered[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAllSessionsTab(List<TimetableModel> allClasses) {
    final filtered = allClasses.where((t) {
      final matchesSearch = t.subjectCode.toLowerCase().contains(_searchQuery) ||
          t.subjectName.toLowerCase().contains(_searchQuery) ||
          t.hallName.toLowerCase().contains(_searchQuery);

      final matchesType = _selectedTypeFilter == 'All' || t.classType.toLowerCase() == _selectedTypeFilter.toLowerCase();
      return matchesSearch && matchesType;
    }).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          color: const Color(0xFF1E293B),
          child: Column(
            children: [
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search by module code, name or hall...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
                onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
              ),
              const SizedBox(height: 10),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _classTypes.map((type) {
                    final isSel = type == _selectedTypeFilter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(type == 'All' ? 'ALL TYPES' : type.toUpperCase()),
                        selected: isSel,
                        onSelected: (val) {
                          if (val) setState(() => _selectedTypeFilter = type);
                        },
                        selectedColor: Colors.teal,
                        backgroundColor: const Color(0xFF0F172A),
                        labelStyle: TextStyle(color: isSel ? Colors.white : Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                        side: BorderSide(color: isSel ? Colors.tealAccent : Colors.white10),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No timetable sessions matching query.', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return _buildTimetableCard(filtered[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTimetableCard(TimetableModel t) {
    final dynStatus = _computeDynamicStatus(t);
    Color statusColor;
    String statusLabel;

    switch (dynStatus) {
      case 'ongoing':
        statusColor = Colors.greenAccent;
        statusLabel = '🔴 ONGOING NOW';
        break;
      case 'completed':
        statusColor = Colors.grey;
        statusLabel = 'COMPLETED';
        break;
      case 'cancelled':
        statusColor = Colors.redAccent;
        statusLabel = 'CANCELLED';
        break;
      case 'rescheduled':
        statusColor = Colors.orangeAccent;
        statusLabel = 'RESCHEDULED';
        break;
      default:
        statusColor = Colors.cyanAccent;
        statusLabel = 'UPCOMING';
    }

    return InkWell(
      onTap: () => _showHallDetailsModal(context, t),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: dynStatus == 'ongoing' ? Colors.greenAccent.withAlpha(120) : Colors.white10,
            width: dynStatus == 'ongoing' ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Colors.amber.withAlpha(30), borderRadius: BorderRadius.circular(6)),
                      child: Text(t.subjectCode, style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Colors.cyan.withAlpha(20), borderRadius: BorderRadius.circular(6)),
                      child: Text(t.classType.toUpperCase(), style: const TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: statusColor.withAlpha(30), borderRadius: BorderRadius.circular(6)),
                  child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Text(t.subjectName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),

            Row(
              children: [
                const Icon(Icons.schedule_rounded, size: 14, color: Colors.amberAccent),
                const SizedBox(width: 6),
                Text('${t.dayOfWeek} • ${t.startTime} - ${t.endTime}', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 6),

            Row(
              children: [
                const Icon(Icons.location_on_rounded, size: 14, color: Colors.tealAccent),
                const SizedBox(width: 6),
                Text('${t.hallName} • Batch ${t.batch}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const Spacer(),
                const Icon(Icons.info_outline_rounded, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                const Text('Hall Details', style: TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
