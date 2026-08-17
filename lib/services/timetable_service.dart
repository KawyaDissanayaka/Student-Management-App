import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/timetable_model.dart';
import '../models/notification_model.dart';
import 'notification_service.dart';

class TimetableConflictResult {
  final bool hasConflict;
  final String? errorMessage;

  TimetableConflictResult.ok()
      : hasConflict = false,
        errorMessage = null;

  TimetableConflictResult.conflict(this.errorMessage) : hasConflict = true;
}

class TimetableService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  CollectionReference<Map<String, dynamic>> get _timetableRef => _firestore.collection('timetable');

  Stream<List<TimetableModel>> getSchedulesStream() {
    return _timetableRef.snapshots().map((snap) => snap.docs.map((d) => TimetableModel.fromFirestore(d)).toList());
  }

  /// Checks strict real-time conflict rules before saving
  Future<TimetableConflictResult> checkConflicts({
    String? currentDocId,
    required String dayOfWeek,
    required String startTime,
    required String endTime,
    required String hallId,
    required String hallName,
    required String lecturerEmail,
    required String lecturerName,
    required String batch,
    required String course,
    required int enrolledCount,
    required int hallCapacity,
    required String mode,
  }) async {
    // 1. Time validity check
    final startMin = TimetableModel.parseTimeToMinutes(startTime);
    final endMin = TimetableModel.parseTimeToMinutes(endTime);
    if (startMin >= endMin) {
      return TimetableConflictResult.conflict('Invalid Time: Start Time ($startTime) must be earlier than End Time ($endTime).');
    }

    // 2. Capacity Check (Physical Mode only)
    if (mode.toLowerCase() == 'physical' && enrolledCount > hallCapacity && hallCapacity > 0) {
      return TimetableConflictResult.conflict(
        'Hall Capacity Exceeded: Hall "$hallName" capacity ($hallCapacity seats) cannot accommodate $enrolledCount enrolled students.',
      );
    }

    // Query active schedules for the same day
    final query = await _timetableRef.where('dayOfWeek', isEqualTo: dayOfWeek).get();
    final activeSchedules = query.docs
        .map((d) => TimetableModel.fromFirestore(d))
        .where((s) => s.status != 'cancelled' && s.docId != currentDocId)
        .toList();

    for (var s in activeSchedules) {
      final overlaps = TimetableModel.isTimeOverlapping(startTime, endTime, s.startTime, s.endTime);
      if (!overlaps) continue;

      // 3. Hall Occupancy Collision Check
      if (mode.toLowerCase() == 'physical' && s.mode.toLowerCase() == 'physical' && s.hallName.toLowerCase() == hallName.toLowerCase()) {
        return TimetableConflictResult.conflict(
          'Hall Conflict ❌: "$hallName" is already booked for "${s.subjectCode} - ${s.subjectName}" from ${s.startTime} to ${s.endTime}.',
        );
      }

      // 4. Lecturer Double-Booking Check
      if (lecturerEmail.isNotEmpty && s.lecturerEmail.trim().toLowerCase() == lecturerEmail.trim().toLowerCase()) {
        return TimetableConflictResult.conflict(
          'Lecturer Conflict ❌: Lecturer "$lecturerName" already has a scheduled lecture ("${s.subjectCode}") from ${s.startTime} to ${s.endTime}.',
        );
      }

      // 5. Student / Batch Collision Check
      final batchMatches = (batch != 'All' && s.batch != 'All' && batch == s.batch) || (course != 'All' && s.course != 'All' && course == s.course);
      if (batchMatches) {
        return TimetableConflictResult.conflict(
          'Batch Conflict ❌: Students in Batch $batch / $course already have "${s.subjectCode} - ${s.subjectName}" scheduled from ${s.startTime} to ${s.endTime}.',
        );
      }
    }

    return TimetableConflictResult.ok();
  }

  /// Add new verified timetable schedule
  Future<String> addSchedule(TimetableModel schedule) async {
    try {
      final conflict = await checkConflicts(
        dayOfWeek: schedule.dayOfWeek,
        startTime: schedule.startTime,
        endTime: schedule.endTime,
        hallId: schedule.hallId,
        hallName: schedule.hallName,
        lecturerEmail: schedule.lecturerEmail,
        lecturerName: schedule.lecturerName,
        batch: schedule.batch,
        course: schedule.course,
        enrolledCount: schedule.enrolledCount,
        hallCapacity: schedule.hallCapacity,
        mode: schedule.mode,
      );

      if (conflict.hasConflict) {
        throw Exception(conflict.errorMessage);
      }

      final docRef = await _timetableRef.add(schedule.toMap());

      // Send announcement/notification to enrolled students & lecturer
      await _dispatchScheduleNotification(
        title: 'New Lecture Scheduled: ${schedule.subjectCode}',
        message: '${schedule.subjectName} has been scheduled on ${schedule.dayOfWeek} (${schedule.startTime} - ${schedule.endTime}) in ${schedule.hallName}.',
        type: 'Timetable',
        subjectCode: schedule.subjectCode,
      );

      return docRef.id;
    } catch (e) {
      debugPrint('Error adding schedule: $e');
      rethrow;
    }
  }

  /// Update / Reschedule lecture and notify stakeholders
  Future<void> rescheduleLecture(String docId, TimetableModel schedule, String reason) async {
    try {
      final conflict = await checkConflicts(
        currentDocId: docId,
        dayOfWeek: schedule.dayOfWeek,
        startTime: schedule.startTime,
        endTime: schedule.endTime,
        hallId: schedule.hallId,
        hallName: schedule.hallName,
        lecturerEmail: schedule.lecturerEmail,
        lecturerName: schedule.lecturerName,
        batch: schedule.batch,
        course: schedule.course,
        enrolledCount: schedule.enrolledCount,
        hallCapacity: schedule.hallCapacity,
        mode: schedule.mode,
      );

      if (conflict.hasConflict) {
        throw Exception(conflict.errorMessage);
      }

      final map = schedule.toMap();
      map['status'] = 'rescheduled';
      map['rescheduleReason'] = reason;
      map['updatedAt'] = DateTime.now().toIso8601String();

      await _timetableRef.doc(docId).update(map);

      // Send Alert to Lecturer & Students
      await _dispatchScheduleNotification(
        title: 'Lecture Rescheduled: ${schedule.subjectCode}',
        message: '${schedule.subjectName} is moved to ${schedule.dayOfWeek} (${schedule.startTime} - ${schedule.endTime}) in ${schedule.hallName}. Reason: $reason',
        type: 'Timetable',
        subjectCode: schedule.subjectCode,
      );
    } catch (e) {
      debugPrint('Error rescheduling lecture: $e');
      rethrow;
    }
  }

  /// Cancel lecture and notify stakeholders
  Future<void> cancelLecture(String docId, TimetableModel schedule, String reason) async {
    try {
      await _timetableRef.doc(docId).update({
        'status': 'cancelled',
        'rescheduleReason': reason,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Send Cancellation Alert
      await _dispatchScheduleNotification(
        title: 'Lecture Cancelled: ${schedule.subjectCode}',
        message: 'The lecture for ${schedule.subjectName} on ${schedule.dayOfWeek} (${schedule.startTime}) has been cancelled. Note: $reason',
        type: 'Timetable',
        subjectCode: schedule.subjectCode,
      );
    } catch (e) {
      debugPrint('Error cancelling lecture: $e');
      rethrow;
    }
  }

  Future<void> _dispatchScheduleNotification({
    required String title,
    required String message,
    required String type,
    required String subjectCode,
  }) async {
    try {
      final nowIso = DateTime.now().toIso8601String();
      final notif = NotificationModel(
        notificationId: 'NTF-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        title: title,
        message: message,
        audience: 'all_users',
        sentBy: 'Administration Division',
        sentDate: nowIso,
        createdDate: nowIso,
        type: type,
        status: 'sent',
      );
      await _notificationService.sendNotification(notif);
    } catch (e) {
      debugPrint('Notification dispatch note: $e');
    }
  }
}
