import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/timetable_model.dart';
import '../../models/subject_model.dart';
import '../../models/lecturer_model.dart';
import '../../models/hall_model.dart';
import '../../services/timetable_service.dart';
import '../../services/hall_service.dart';

class AddEditScheduleScreen extends StatefulWidget {
  final TimetableModel? schedule;

  const AddEditScheduleScreen({super.key, this.schedule});

  @override
  State<AddEditScheduleScreen> createState() => _AddEditScheduleScreenState();
}

class _AddEditScheduleScreenState extends State<AddEditScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  final TimetableService _timetableService = TimetableService();
  final HallService _hallService = HallService();

  late TextEditingController _idController;
  late TextEditingController _meetingLinkController;
  late TextEditingController _rescheduleReasonController;

  SubjectModel? _selectedSubject;
  LecturerModel? _selectedLecturer;
  HallModel? _selectedHall;

  String _selectedDay = 'Monday';
  String _startTime = '09:00 AM';
  String _endTime = '11:00 AM';
  String _selectedClassType = 'Lecture';
  String _selectedMode = 'Physical';
  String _selectedBatch = '2026';
  String _selectedSemester = 'Semester 1';
  String _academicYear = '2025/2026';

  int _enrolledCount = 0;
  bool _isSubmitting = false;

  final List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  final List<String> _classTypes = ['Lecture', 'Lab', 'Tutorial', 'Workshop'];
  final List<String> _batches = ['2024', '2025', '2026', '2027', 'All'];

  @override
  void initState() {
    super.initState();
    final s = widget.schedule;
    _idController = TextEditingController(text: s?.scheduleId ?? 'SCH-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    _meetingLinkController = TextEditingController(text: s?.meetingLink ?? '');
    _rescheduleReasonController = TextEditingController(text: s?.rescheduleReason ?? '');

    if (s != null) {
      _selectedDay = s.dayOfWeek;
      _startTime = s.startTime;
      _endTime = s.endTime;
      _selectedClassType = s.classType;
      _selectedMode = s.mode;
      _selectedBatch = s.batch;
      _selectedSemester = s.semester;
      _academicYear = s.academicYear;
      _enrolledCount = s.enrolledCount;
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _meetingLinkController.dispose();
    _rescheduleReasonController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool isStart) async {
    final currentStr = isStart ? _startTime : _endTime;
    final initialMin = TimetableModel.parseTimeToMinutes(currentStr);
    final initialTime = TimeOfDay(hour: initialMin ~/ 60, minute: initialMin % 60);

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: Colors.tealAccent, onPrimary: Colors.black, surface: Color(0xFF1E293B)),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
      final minute = picked.minute.toString().padLeft(2, '0');
      final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
      final formatted = '${hour.toString().padLeft(2, '0')}:$minute $period';

      setState(() {
        if (isStart) {
          _startTime = formatted;
        } else {
          _endTime = formatted;
        }
      });
    }
  }

  Future<void> _fetchEnrolledCount(String subjectCode) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('enrollments')
          .where('subjectCode', isEqualTo: subjectCode)
          .where('status', isEqualTo: 'active')
          .get();
      if (mounted) {
        setState(() {
          _enrolledCount = snap.docs.length;
        });
      }
    } catch (_) {}
  }

  Future<void> _saveSchedule() async {
    if (!_formKey.currentState!.validate()) return;

    final isEditing = widget.schedule != null;

    final subjectCode = _selectedSubject?.subjectCode ?? widget.schedule?.subjectCode ?? '';
    final subjectName = _selectedSubject?.subjectName ?? widget.schedule?.subjectName ?? '';
    final lecturerName = _selectedLecturer?.name ?? widget.schedule?.lecturerName ?? '';
    final lecturerEmail = _selectedLecturer?.email ?? widget.schedule?.lecturerEmail ?? '';
    final lecturerId = _selectedLecturer?.lecturerId ?? widget.schedule?.lecturerId ?? '';
    final hallId = _selectedHall?.hallId ?? widget.schedule?.hallId ?? '';
    final hallName = _selectedHall?.name ?? widget.schedule?.hallName ?? 'Main Hall';
    final hallCapacity = _selectedHall?.capacity ?? widget.schedule?.hallCapacity ?? 50;

    if (subjectCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Subject.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    if (lecturerName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an assigned Lecturer.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    try {
      final schedule = TimetableModel(
        docId: widget.schedule?.docId,
        scheduleId: _idController.text.trim().toUpperCase(),
        subjectCode: subjectCode,
        subjectName: subjectName,
        lecturerDocId: _selectedLecturer?.docId ?? widget.schedule?.lecturerDocId ?? '',
        lecturerId: lecturerId,
        lecturerName: lecturerName,
        lecturerEmail: lecturerEmail,
        batch: _selectedBatch,
        course: _selectedSubject?.subjectCode ?? widget.schedule?.course ?? 'All',
        semester: _selectedSemester,
        academicYear: _academicYear,
        dayOfWeek: _selectedDay,
        startTime: _startTime,
        endTime: _endTime,
        hallId: hallId,
        hallName: hallName,
        classType: _selectedClassType,
        mode: _selectedMode,
        meetingLink: _meetingLinkController.text.trim(),
        enrolledCount: _enrolledCount,
        hallCapacity: hallCapacity,
        status: isEditing ? 'rescheduled' : 'active',
        rescheduleReason: _rescheduleReasonController.text.trim(),
      );

      if (!isEditing) {
        await _timetableService.addSchedule(schedule);
        messenger.showSnackBar(
          const SnackBar(content: Text('Lecture schedule created & notifications dispatched!'), backgroundColor: Colors.green),
        );
      } else {
        await _timetableService.rescheduleLecture(
          widget.schedule!.docId!,
          schedule,
          _rescheduleReasonController.text.trim().isNotEmpty ? _rescheduleReasonController.text.trim() : 'Administrative Timetable Revision',
        );
        messenger.showSnackBar(
          const SnackBar(content: Text('Lecture rescheduled & alerts sent to students/lecturer!'), backgroundColor: Colors.green),
        );
      }

      nav.pop();
    } catch (e) {
      final err = e.toString().replaceAll('Exception: ', '');
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                SizedBox(width: 8),
                Text('Schedule Conflict', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
              ],
            ),
            content: Text(err, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4)),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                child: const Text('Review & Correct', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.schedule != null;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'Reschedule Lecture' : 'Create Lecture Schedule',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('subjects').snapshots(),
        builder: (context, subjectSnap) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('lecturers').snapshots(),
            builder: (context, lecSnap) {
              return StreamBuilder<List<HallModel>>(
                stream: _hallService.getActiveHallsStream(),
                builder: (context, hallSnap) {
                  final subjects = (subjectSnap.data?.docs ?? [])
                      .map((d) => SubjectModel.fromFirestore(d as DocumentSnapshot<Map<String, dynamic>>))
                      .where((s) => s.status.toLowerCase() == 'active')
                      .toList();

                  final lecturers = (lecSnap.data?.docs ?? [])
                      .map((d) => LecturerModel.fromFirestore(d as DocumentSnapshot<Map<String, dynamic>>))
                      .where((l) => l.status.toLowerCase() == 'active')
                      .toList();

                  final halls = hallSnap.data ?? [];

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Subject Selector
                          const Text('Subject & Academic Allocation', style: TextStyle(color: Colors.tealAccent, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          const SizedBox(height: 10),

                          DropdownButtonFormField<SubjectModel>(
                            initialValue: _selectedSubject,
                            dropdownColor: const Color(0xFF1E293B),
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Select Subject *',
                              labelStyle: const TextStyle(color: Colors.grey),
                              filled: true,
                              fillColor: const Color(0xFF1E293B),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            items: subjects.map((s) {
                              return DropdownMenuItem(
                                value: s,
                                child: Text('${s.subjectCode} - ${s.subjectName}', style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedSubject = val;
                                  _selectedSemester = val.semester;
                                  _academicYear = val.academicYear;
                                  // Attempt to match assigned lecturer
                                  final matchLec = lecturers.where((l) => l.name == val.lecturerName || l.lecturerId == val.lecturerId).toList();
                                  if (matchLec.isNotEmpty) {
                                    _selectedLecturer = matchLec.first;
                                  }
                                });
                                _fetchEnrolledCount(val.subjectCode);
                              }
                            },
                          ),
                          const SizedBox(height: 14),

                          // Lecturer Selector
                          DropdownButtonFormField<LecturerModel>(
                            initialValue: _selectedLecturer,
                            dropdownColor: const Color(0xFF1E293B),
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Assigned Lecturer *',
                              labelStyle: const TextStyle(color: Colors.grey),
                              filled: true,
                              fillColor: const Color(0xFF1E293B),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            items: lecturers.map((l) {
                              return DropdownMenuItem(
                                value: l,
                                child: Text('${l.name} (${l.lecturerId})', style: const TextStyle(fontSize: 13)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedLecturer = val);
                            },
                          ),
                          const SizedBox(height: 14),

                          // Batch & Class Type
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _selectedBatch,
                                  dropdownColor: const Color(0xFF1E293B),
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'Target Batch',
                                    labelStyle: const TextStyle(color: Colors.grey),
                                    filled: true,
                                    fillColor: const Color(0xFF1E293B),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  items: _batches.map((b) => DropdownMenuItem(value: b, child: Text('Batch $b', style: const TextStyle(fontSize: 13)))).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedBatch = val);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _selectedClassType,
                                  dropdownColor: const Color(0xFF1E293B),
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'Class Type',
                                    labelStyle: const TextStyle(color: Colors.grey),
                                    filled: true,
                                    fillColor: const Color(0xFF1E293B),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  items: _classTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13)))).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedClassType = val);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),

                          // Day & Time Section
                          const Text('Schedule & Timing', style: TextStyle(color: Colors.tealAccent, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          const SizedBox(height: 10),

                          DropdownButtonFormField<String>(
                            initialValue: _selectedDay,
                            dropdownColor: const Color(0xFF1E293B),
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Day of Week *',
                              labelStyle: const TextStyle(color: Colors.grey),
                              filled: true,
                              fillColor: const Color(0xFF1E293B),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            items: _days.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 13)))).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedDay = val);
                            },
                          ),
                          const SizedBox(height: 14),

                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => _pickTime(true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E293B),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.white24),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Start Time', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.access_time_rounded, size: 16, color: Colors.tealAccent),
                                            const SizedBox(width: 6),
                                            Text(_startTime, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: InkWell(
                                  onTap: () => _pickTime(false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E293B),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.white24),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('End Time', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.alarm_on_rounded, size: 16, color: Colors.amberAccent),
                                            const SizedBox(width: 6),
                                            Text(_endTime, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),

                          // Hall & Mode Allocation
                          const Text('Venue & Delivery Mode', style: TextStyle(color: Colors.tealAccent, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          const SizedBox(height: 10),

                          Row(
                            children: [
                              Expanded(
                                child: ChoiceChip(
                                  label: const Center(child: Text('Physical Class')),
                                  selected: _selectedMode == 'Physical',
                                  onSelected: (val) {
                                    if (val) setState(() => _selectedMode = 'Physical');
                                  },
                                  selectedColor: Colors.teal,
                                  backgroundColor: const Color(0xFF1E293B),
                                  labelStyle: TextStyle(
                                    color: _selectedMode == 'Physical' ? Colors.white : Colors.grey,
                                    fontWeight: _selectedMode == 'Physical' ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ChoiceChip(
                                  label: const Center(child: Text('Online Virtual')),
                                  selected: _selectedMode == 'Online',
                                  onSelected: (val) {
                                    if (val) setState(() => _selectedMode = 'Online');
                                  },
                                  selectedColor: Colors.teal,
                                  backgroundColor: const Color(0xFF1E293B),
                                  labelStyle: TextStyle(
                                    color: _selectedMode == 'Online' ? Colors.white : Colors.grey,
                                    fontWeight: _selectedMode == 'Online' ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          if (_selectedMode == 'Physical') ...[
                            DropdownButtonFormField<HallModel>(
                              initialValue: _selectedHall,
                              dropdownColor: const Color(0xFF1E293B),
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Lecture Hall / Lab *',
                                labelStyle: const TextStyle(color: Colors.grey),
                                filled: true,
                                fillColor: const Color(0xFF1E293B),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              items: halls.map((h) {
                                return DropdownMenuItem(
                                  value: h,
                                  child: Text('${h.name} (${h.capacity} Seats)', style: const TextStyle(fontSize: 13)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedHall = val);
                              },
                            ),
                            const SizedBox(height: 10),

                            // Capacity vs Enrolled comparison badge
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Enrolled Students: $_enrolledCount', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                  Text('Hall Capacity: ${_selectedHall?.capacity ?? widget.schedule?.hallCapacity ?? 50} Seats',
                                      style: TextStyle(
                                        color: (_selectedHall != null && _enrolledCount > _selectedHall!.capacity) ? Colors.redAccent : Colors.tealAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      )),
                                ],
                              ),
                            ),
                          ] else ...[
                            TextFormField(
                              controller: _meetingLinkController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Online Meeting / Zoom Link *',
                                labelStyle: const TextStyle(color: Colors.grey),
                                prefixIcon: const Icon(Icons.videocam_rounded, color: Colors.indigoAccent),
                                filled: true,
                                fillColor: const Color(0xFF1E293B),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              validator: (v) => (_selectedMode == 'Online' && (v == null || v.trim().isEmpty)) ? 'Link required for online class' : null,
                            ),
                          ],
                          const SizedBox(height: 16),

                          if (isEditing) ...[
                            TextFormField(
                              controller: _rescheduleReasonController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Reason for Rescheduling / Change *',
                                labelStyle: const TextStyle(color: Colors.grey),
                                prefixIcon: const Icon(Icons.info_outline_rounded, color: Colors.orangeAccent),
                                filled: true,
                                fillColor: const Color(0xFF1E293B),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          const SizedBox(height: 20),

                          // Submit Action Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isSubmitting ? null : _saveSchedule,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: _isSubmitting
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.event_available_rounded, color: Colors.white),
                              label: Text(
                                isEditing ? 'Confirm Reschedule & Notify' : 'Check Conflicts & Save Schedule',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
