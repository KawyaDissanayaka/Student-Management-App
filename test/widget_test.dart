import 'package:flutter_test/flutter_test.dart';
import 'package:student_management_app/models/student_model.dart';
import 'package:student_management_app/models/assignment_model.dart';
import 'package:student_management_app/models/task_model.dart';
import 'package:student_management_app/models/announcement_model.dart';
import 'package:student_management_app/models/result_model.dart';
import 'package:student_management_app/models/payment_model.dart';
import 'package:student_management_app/models/timetable_model.dart';
import 'package:student_management_app/models/hall_model.dart';
import 'package:student_management_app/models/material_model.dart';
import 'package:student_management_app/models/submission_model.dart';
import 'package:student_management_app/services/student_portal_service.dart';

void main() {
  group('Backend Models & Business Logic Calculations', () {
    test('Student Model serialization and status', () {
      final student = StudentModel(
        studentId: 'STU-1001',
        name: 'John Doe',
        email: 'john@example.com',
        course: 'Computer Science',
        batch: '2026',
        year: 'Year 1',
        semester: 'Semester 1',
        status: 'active',
      );

      final map = student.toMap();
      expect(map['studentId'], 'STU-1001');
      expect(map['status'], 'active');
      expect(map['email'], 'john@example.com');
    });

    test('Assignment Model status logic', () {
      final assignment = AssignmentModel(
        assignmentId: 'ASN-1001',
        title: 'Mobile App Architecture',
        description: 'Design patterns in Flutter',
        subjectDocId: 'sub_123',
        subjectCode: 'CS101',
        subjectName: 'Computer Science',
        lecturerName: 'Dr. Smith',
        createdBy: 'Admin',
        createdDate: DateTime.now().toIso8601String(),
        startDate: '2026-01-01',
        dueDate: '2026-12-31',
        semester: 'Semester 1',
        academicYear: '2025/2026',
        status: 'published',
      );

      expect(assignment.status, 'published');
      expect(assignment.assignmentId, 'ASN-1001');
    });

    test('Task Model status logic', () {
      final task = TaskModel(
        taskId: 'TSK-1001',
        title: 'Review syllabus',
        description: 'Update module content',
        assignedToType: 'lecturer',
        assignedToDocId: 'lec_123',
        assignedToName: 'Jane Doe',
        assignedToEmail: 'jane@example.com',
        assignedToId: 'LEC-1001',
        assignedBy: 'Admin',
        priority: 'high',
        createdDate: DateTime.now().toIso8601String(),
        startDate: '2026-01-01',
        dueDate: '2026-12-31',
        status: 'in_progress',
      );

      expect(task.status, 'in_progress');
      expect(task.priority, 'high');

      // Completed task past due must remain 'completed'
      final completedPastTask = TaskModel(
        taskId: 'TSK-1002',
        title: 'Submit Lab Work',
        description: 'Completed on time',
        assignedBy: 'Dr. Smith',
        priority: 'urgent',
        startDate: '2026-01-01',
        dueDate: '2026-01-10',
        createdDate: '2026-01-01',
        status: 'completed',
      );
      expect(completedPastTask.effectiveStatus, 'completed');

      // Incomplete task past due must become 'overdue'
      final overdueTask = TaskModel(
        taskId: 'TSK-1003',
        title: 'Submit Lab Work',
        description: 'Not yet submitted',
        assignedBy: 'Dr. Smith',
        priority: 'urgent',
        startDate: '2026-01-01',
        dueDate: '2026-01-10',
        createdDate: '2026-01-01',
        status: 'pending',
      );
      expect(overdueTask.effectiveStatus, 'overdue');
    });

    test('Announcement Model auto-expiry logic', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 2)).toIso8601String().substring(0, 10);
      final announcement = AnnouncementModel(
        announcementId: 'ANN-1001',
        title: 'Holiday Notice',
        description: 'Campus closed tomorrow.',
        audience: 'all_users',
        createdBy: 'Admin',
        createdDate: DateTime.now().toIso8601String(),
        publishDate: '2026-01-01',
        expiryDate: pastDate,
        status: 'published',
      );

      expect(announcement.effectiveStatus, 'expired');

      final subjectNotice = AnnouncementModel(
        announcementId: 'ANN-1002',
        title: 'Quiz 01 Schedule',
        description: 'Quiz 01 will be conducted next Monday.',
        audience: 'subject_students',
        subjectCode: 'CS101',
        subjectName: 'Mobile Dev',
        lecturerName: 'Dr. Smith',
        createdBy: 'smith@uni.lk',
        createdDate: '2026-08-17T10:00:00',
        publishDate: '2026-08-17',
        expiryDate: '2026-09-17',
        status: 'published',
        priority: 'Urgent',
      );

      expect(subjectNotice.effectiveStatus, 'published');
      expect(subjectNotice.priority, 'Urgent');
      expect(subjectNotice.message, 'Quiz 01 will be conducted next Monday.');
    });

    test('Official GPA & Academic Results Calculation', () {
      expect(ResultModel.calculateGrade(88.0), 'A+');
      expect(ResultModel.calculateGradePoint(88.0), 4.0);

      expect(ResultModel.calculateGrade(76.0), 'A-');
      expect(ResultModel.calculateGradePoint(76.0), 3.7);

      expect(ResultModel.calculateGrade(66.0), 'B');
      expect(ResultModel.calculateGradePoint(66.0), 3.0);

      final r1 = ResultModel(
        resultId: 'RES-01',
        studentDocId: 's1',
        studentOfficialId: 'STU-1001',
        studentEmail: 'john@example.com',
        studentName: 'John Doe',
        subjectCode: 'CS101',
        subjectName: 'Mobile Dev',
        credits: 3,
        marks: 85.0,
        grade: 'A+',
        gradePoint: 4.0,
        semester: 'Semester 1',
        academicYear: '2025/2026',
        publishedDate: '2026-01-10',
      );

      final r2 = ResultModel(
        resultId: 'RES-02',
        studentDocId: 's1',
        studentOfficialId: 'STU-1001',
        studentEmail: 'john@example.com',
        studentName: 'John Doe',
        subjectCode: 'CS102',
        subjectName: 'Databases',
        credits: 3,
        marks: 72.0,
        grade: 'B+',
        gradePoint: 3.3,
        semester: 'Semester 1',
        academicYear: '2025/2026',
        publishedDate: '2026-01-10',
      );

      final gpa = StudentPortalService.calculateGPA([r1, r2]);
      expect(gpa, closeTo(3.65, 0.01));

      final earnedCredits = StudentPortalService.calculateCompletedCredits([r1, r2]);
      expect(earnedCredits, 6);

      final lockedResult = ResultModel(
        resultId: 'RES-03',
        studentDocId: 's1',
        studentOfficialId: 'STU-1001',
        studentEmail: 'john@example.com',
        studentName: 'John Doe',
        subjectCode: 'CS103',
        subjectName: 'Algorithms',
        credits: 4,
        assignmentMarks: 28.0,
        midtermMarks: 26.0,
        finalExamMarks: 36.0,
        marks: 90.0,
        grade: 'A+',
        gradePoint: 4.0,
        semester: 'Semester 1',
        academicYear: '2025/2026',
        publishedDate: '2026-01-10',
        status: 'locked',
        lockedBy: 'admin@uni.lk',
      );

      expect(lockedResult.isLocked, true);
      expect(lockedResult.assignmentMarks, 28.0);
      expect(lockedResult.midtermMarks, 26.0);
      expect(lockedResult.finalExamMarks, 36.0);
    });

    test('Payment & Timetable Model serialization', () {
      final payment = PaymentModel(
        paymentId: 'TXN-999',
        studentEmail: 'john@example.com',
        studentId: 'STU-1001',
        studentName: 'John Doe',
        feeType: 'Tuition Fee',
        amount: 75000.0,
        paymentMethod: 'Online Card',
        transactionRef: 'TXN-999',
        paymentDate: '2026-08-17',
        status: 'success',
      );

      expect(payment.status, 'success');
      expect(payment.amount, 75000.0);

      final schedule = TimetableModel(
        scheduleId: 'SCH-101',
        subjectCode: 'CS101',
        subjectName: 'Mobile Dev',
        lecturerName: 'Dr. Smith',
        dayOfWeek: 'Monday',
        startTime: '09:00 AM',
        endTime: '11:00 AM',
        hallName: 'Lab 03',
        semester: 'Semester 1',
        academicYear: '2025/2026',
      );

      expect(schedule.dayOfWeek, 'Monday');
      expect(schedule.mode, 'Physical');
      expect(schedule.hall, 'Lab 03');
    });

    test('Timetable Conflict & Time Overlapping Logic', () {
      // Overlapping intervals
      expect(TimetableModel.isTimeOverlapping('09:00 AM', '11:00 AM', '10:00 AM', '12:00 PM'), true);
      expect(TimetableModel.isTimeOverlapping('09:00 AM', '12:00 PM', '10:00 AM', '11:00 AM'), true);
      expect(TimetableModel.isTimeOverlapping('09:00 AM', '11:00 AM', '09:00 AM', '11:00 AM'), true);

      // Non-overlapping intervals (adjacent / disjoint)
      expect(TimetableModel.isTimeOverlapping('09:00 AM', '11:00 AM', '11:00 AM', '01:00 PM'), false);
      expect(TimetableModel.isTimeOverlapping('09:00 AM', '10:00 AM', '01:00 PM', '03:00 PM'), false);
    });

    test('Lecture Hall Model serialization', () {
      final hall = HallModel(
        hallId: 'HALL-01',
        name: 'Auditorium 01',
        building: 'Main Block',
        floor: 'Ground Floor',
        capacity: 150,
        type: 'Auditorium',
        facilities: ['Projector', 'Wi-Fi', 'Air Conditioning'],
        status: 'active',
      );

      final map = hall.toMap();
      expect(map['hallId'], 'HALL-01');
      expect(map['capacity'], 150);
      expect(map['facilities'].length, 3);
    });

    test('Learning Material Model metadata & status logic', () {
      final material = MaterialModel(
        materialId: 'MAT-101',
        title: 'Flutter Widgets & State Management',
        description: 'Comprehensive slides on Flutter reactive state',
        topic: 'State Management',
        subjectCode: 'CS101',
        subjectName: 'Mobile Dev',
        lecturerName: 'Dr. Smith',
        lecturerId: 'LEC-1001',
        fileType: 'PDF',
        fileSize: '4.5 MB',
        downloadUrl: 'https://university.edu/materials/cs101_w1.pdf',
        uploadedDate: '2026-08-17',
        lectureDate: '2026-08-17',
        weekNumber: 1,
        status: 'active',
      );

      expect(material.status, 'active');
      expect(material.topic, 'State Management');
      expect(material.weekNumber, 1);

      final map = material.toMap();
      expect(map['materialId'], 'MAT-101');
      expect(map['fileType'], 'PDF');
    });

    test('Submission Model & Average Marking Logic', () {
      final sub1 = SubmissionModel(
        assignmentId: 'ASN-101',
        assignmentTitle: 'Clean Architecture',
        subjectCode: 'CS101',
        subjectName: 'Mobile Dev',
        studentDocId: 'doc1',
        studentId: 'STU-1001',
        studentName: 'Alice',
        studentEmail: 'alice@uni.lk',
        submittedAt: '2026-08-15T10:00:00',
        isLate: false,
        mark: 85,
        status: 'reviewed',
      );

      final sub2 = SubmissionModel(
        assignmentId: 'ASN-101',
        assignmentTitle: 'Clean Architecture',
        subjectCode: 'CS101',
        subjectName: 'Mobile Dev',
        studentDocId: 'doc2',
        studentId: 'STU-1002',
        studentName: 'Bob',
        studentEmail: 'bob@uni.lk',
        submittedAt: '2026-08-18T10:00:00',
        isLate: true,
        mark: 75,
        status: 'reviewed',
      );

      expect(sub1.isLate, false);
      expect(sub2.isLate, true);

      final reviewedSubs = [sub1, sub2];
      final avg = reviewedSubs.map((s) => s.mark!).reduce((a, b) => a + b) / reviewedSubs.length;
      expect(avg, 80.0);
    });
  });
}
