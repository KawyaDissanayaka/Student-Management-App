import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exam_registration_model.dart';
import '../models/exam_seating_model.dart';
import '../models/exam_attendance_record_model.dart';
import '../models/exam_result_model.dart';
import '../models/exam_hall_model.dart';

class ExamRegistrationReportData {
  final int total;
  final int approved;
  final int pending;
  final int rejected;
  final int cancelled;
  final List<ExamRegistrationModel> records;

  ExamRegistrationReportData({
    required this.total,
    required this.approved,
    required this.pending,
    required this.rejected,
    required this.cancelled,
    required this.records,
  });

  String toCsv() {
    final buffer = StringBuffer();
    buffer.writeln('Registration ID,Student ID,Student Name,Subject Code,Subject Name,Batch,Registered Date,Status');
    for (final r in records) {
      buffer.writeln('"${r.registrationId}","${r.studentId}","${r.studentName}","${r.subjectCode}","${r.subjectName}","${r.batch}","${r.registeredAt}","${r.status}"');
    }
    return buffer.toString();
  }
}

class ExamAttendanceReportData {
  final int registered;
  final int present;
  final int absent;
  final int late;
  final double attendancePercentage;
  final List<ExamAttendanceRecordModel> records;

  ExamAttendanceReportData({
    required this.registered,
    required this.present,
    required this.absent,
    required this.late,
    required this.attendancePercentage,
    required this.records,
  });

  String toCsv() {
    final buffer = StringBuffer();
    buffer.writeln('Attendance ID,Exam ID,Student ID,Student Name,Hall Name,Seat Number,Verification Method,Marked At,Status');
    for (final r in records) {
      buffer.writeln('"${r.attendanceId}","${r.examId}","${r.studentId}","${r.studentName}","${r.hallName}","${r.seatNumber}","${r.verificationMethod}","${r.markedAt}","${r.status}"');
    }
    return buffer.toString();
  }
}

class ExamSeatingReportData {
  final String hallName;
  final int capacity;
  final int allocatedStudents;
  final int availableSeats;
  final List<ExamSeatingModel> records;

  ExamSeatingReportData({
    required this.hallName,
    required this.capacity,
    required this.allocatedStudents,
    required this.availableSeats,
    required this.records,
  });

  String toCsv() {
    final buffer = StringBuffer();
    buffer.writeln('Seating ID,Exam ID,Hall Name,Seat Number,Student ID,Student Name,Allocated Date,Allocated By');
    for (final r in records) {
      buffer.writeln('"${r.seatingId}","${r.examId}","${r.hallName}","${r.seatNumber}","${r.studentId}","${r.studentName}","${r.allocatedAt}","${r.allocatedBy}"');
    }
    return buffer.toString();
  }
}

class ExamResultReportData {
  final int totalStudents;
  final int passed;
  final int failed;
  final double averageMarks;
  final double highestMarks;
  final double lowestMarks;
  final Map<String, int> gradeDistribution;
  final List<ExamResultModel> records;

  ExamResultReportData({
    required this.totalStudents,
    required this.passed,
    required this.failed,
    required this.averageMarks,
    required this.highestMarks,
    required this.lowestMarks,
    required this.gradeDistribution,
    required this.records,
  });

  String toCsv() {
    final buffer = StringBuffer();
    buffer.writeln('Result ID,Exam ID,Module ID,Subject Name,Student ID,Student Name,Marks,Grade,Grade Point,Status');
    for (final r in records) {
      buffer.writeln('"${r.resultId}","${r.examId}","${r.moduleId}","${r.subjectName}","${r.studentId}","${r.studentName}",${r.marks},"${r.grade}",${r.gradePoint},"${r.status}"');
    }
    return buffer.toString();
  }
}

class ExamReportsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── 1. FETCH REGISTRATION REPORT ──────────────────────────────────────────
  Future<ExamRegistrationReportData> getRegistrationReport({
    String? subjectCode,
    String? batch,
    String? status,
  }) async {
    final snap = await _firestore.collection('exam_registrations').get();
    var list = snap.docs.map((d) => ExamRegistrationModel.fromFirestore(d)).toList();

    if (subjectCode != null && subjectCode != 'All') {
      list = list.where((r) => r.subjectCode.toUpperCase() == subjectCode.toUpperCase()).toList();
    }
    if (batch != null && batch != 'All') {
      list = list.where((r) => r.batch == batch).toList();
    }
    if (status != null && status != 'All') {
      list = list.where((r) => r.status.toLowerCase() == status.toLowerCase()).toList();
    }

    final total = list.length;
    final approved = list.where((r) => r.status == 'Approved' || r.status == 'Registered').length;
    final pending = list.where((r) => r.status == 'Pending').length;
    final rejected = list.where((r) => r.status == 'Rejected').length;
    final cancelled = list.where((r) => r.status == 'Cancelled').length;

    return ExamRegistrationReportData(
      total: total,
      approved: approved,
      pending: pending,
      rejected: rejected,
      cancelled: cancelled,
      records: list,
    );
  }

  // ─── 2. FETCH ATTENDANCE REPORT ────────────────────────────────────────────
  Future<ExamAttendanceReportData> getAttendanceReport({
    String? examId,
    String? hallId,
  }) async {
    final snap = await _firestore.collection('exam_attendance_records').get();
    var list = snap.docs.map((d) => ExamAttendanceRecordModel.fromFirestore(d)).toList();

    if (examId != null && examId != 'All') {
      list = list.where((r) => r.examId == examId).toList();
    }
    if (hallId != null && hallId != 'All') {
      list = list.where((r) => r.hallId == hallId).toList();
    }

    final registered = list.length;
    final present = list.where((r) => r.isPresent).length;
    final absent = list.where((r) => r.isAbsent).length;
    final late = list.where((r) => r.status.toLowerCase() == 'late').length;
    final pct = registered > 0 ? (present / registered) * 100 : 0.0;

    return ExamAttendanceReportData(
      registered: registered,
      present: present,
      absent: absent,
      late: late,
      attendancePercentage: pct,
      records: list,
    );
  }

  // ─── 3. FETCH SEATING ALLOCATION REPORT ─────────────────────────────────────
  Future<ExamSeatingReportData> getSeatingReport({
    String? examId,
    String? hallId,
  }) async {
    final seatSnap = await _firestore.collection('exam_seatings').get();
    var seatList = seatSnap.docs.map((d) => ExamSeatingModel.fromFirestore(d)).toList();

    if (examId != null && examId != 'All') {
      seatList = seatList.where((s) => s.examId == examId).toList();
    }
    if (hallId != null && hallId != 'All') {
      seatList = seatList.where((s) => s.hallId == hallId).toList();
    }

    int capacity = 100;
    String hallName = 'Main Exam Hall';

    if (hallId != null && hallId != 'All') {
      final hallSnap = await _firestore.collection('examHalls').where('hallId', isEqualTo: hallId).limit(1).get();
      if (hallSnap.docs.isNotEmpty) {
        final hall = ExamHallModel.fromFirestore(hallSnap.docs.first);
        capacity = hall.capacity;
        hallName = hall.hallName;
      }
    } else if (seatList.isNotEmpty) {
      hallName = seatList.first.hallName;
    }

    final allocated = seatList.length;
    final available = capacity > allocated ? capacity - allocated : 0;

    return ExamSeatingReportData(
      hallName: hallName,
      capacity: capacity,
      allocatedStudents: allocated,
      availableSeats: available,
      records: seatList,
    );
  }

  // ─── 4. FETCH EXAM RESULT REPORT ───────────────────────────────────────────
  Future<ExamResultReportData> getResultReport({
    String? examId,
    String? moduleId,
    String? status,
  }) async {
    final resSnap = await _firestore.collection('exam_results').get();
    var list = resSnap.docs.map((d) => ExamResultModel.fromFirestore(d)).toList();

    if (examId != null && examId != 'All') {
      list = list.where((r) => r.examId == examId).toList();
    }
    if (moduleId != null && moduleId != 'All') {
      list = list.where((r) => r.moduleId.toUpperCase() == moduleId.toUpperCase()).toList();
    }
    if (status != null && status != 'All') {
      list = list.where((r) => r.status.toLowerCase() == status.toLowerCase()).toList();
    }

    final total = list.length;
    final passed = list.where((r) => !r.isAbsent && r.grade != 'E' && r.grade != 'F').length;
    final failed = list.where((r) => r.isAbsent || r.grade == 'E' || r.grade == 'F').length;

    final presentMarks = list.where((r) => !r.isAbsent).map((r) => r.marks).toList();
    final avg = presentMarks.isNotEmpty ? (presentMarks.reduce((a, b) => a + b) / presentMarks.length) : 0.0;
    final high = presentMarks.isNotEmpty ? presentMarks.reduce((a, b) => a > b ? a : b) : 0.0;
    final low = presentMarks.isNotEmpty ? presentMarks.reduce((a, b) => a < b ? a : b) : 0.0;

    final Map<String, int> distribution = {
      'A+': 0, 'A': 0, 'A-': 0,
      'B+': 0, 'B': 0, 'B-': 0,
      'C+': 0, 'C': 0, 'C-': 0,
      'D+': 0, 'D': 0, 'E': 0, 'AB': 0,
    };

    for (final r in list) {
      if (distribution.containsKey(r.grade)) {
        distribution[r.grade] = (distribution[r.grade] ?? 0) + 1;
      } else {
        distribution[r.grade] = 1;
      }
    }

    return ExamResultReportData(
      totalStudents: total,
      passed: passed,
      failed: failed,
      averageMarks: avg,
      highestMarks: high,
      lowestMarks: low,
      gradeDistribution: distribution,
      records: list,
    );
  }
}
