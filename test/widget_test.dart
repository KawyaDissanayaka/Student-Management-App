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
import 'package:student_management_app/models/lecturer_model.dart';
import 'package:student_management_app/models/attendance_session_model.dart';
import 'package:student_management_app/models/exam_hall_model.dart';
import 'package:student_management_app/models/exam_model.dart';
import 'package:student_management_app/models/exam_registration_model.dart';
import 'package:student_management_app/models/exam_seating_model.dart';
import 'package:student_management_app/models/exam_attendance_record_model.dart';
import 'package:student_management_app/models/exam_result_model.dart';
import 'package:student_management_app/models/fee_structure_model.dart';
import 'package:student_management_app/services/exam_hall_service.dart';
import 'package:student_management_app/services/exam_seating_service.dart';
import 'package:student_management_app/services/exam_reports_service.dart';
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

    test('Lecturer Model Profile Attributes & Serialization', () {
      final lecturer = LecturerModel(
        lecturerId: 'LEC-2001',
        name: 'Dr. John Perera',
        email: 'john.perera@university.lk',
        department: 'Department of Computing',
        designation: 'Senior Lecturer',
        phone: '+94 77 123 4567',
        address: 'Faculty of Computing, Main Campus',
        photoUrl: 'https://example.com/avatar.jpg',
        joinedDate: '2023-01-15',
        status: 'active',
      );

      final map = lecturer.toMap();
      expect(map['lecturerId'], 'LEC-2001');
      expect(map['name'], 'Dr. John Perera');
      expect(map['designation'], 'Senior Lecturer');
      expect(map['phone'], '+94 77 123 4567');
      expect(map['joinedDate'], '2023-01-15');
      expect(map['status'], 'active');
    });

    test('Attendance Session Model & Percentage Calculation Logic', () {
      final session = AttendanceSessionModel(
        sessionId: 'SESS-CS101-123456',
        subjectCode: 'CS101',
        subjectName: 'Mobile Development',
        lecturerId: 'LEC-2001',
        lecturerName: 'Dr. John Perera',
        lecturerEmail: 'john.perera@university.lk',
        hallName: 'LH-01',
        batch: '2026',
        date: '2026-08-18',
        startTime: '09:00',
        endTime: '11:00',
        qrToken: 'QR-SESS-CS101-123456-999',
        expiresAt: '2026-08-18T10:00:00',
        enrolledCount: 35,
        presentCount: 28,
      );

      expect(session.enrolledCount, 35);
      expect(session.presentCount, 28);

      final pendingCount = session.enrolledCount - session.presentCount;
      expect(pendingCount, 7);

      // Attendance % = Present ÷ Conducted Classes × 100
      final double attendancePct = (session.presentCount / session.enrolledCount) * 100;
      expect(attendancePct, 80.0);
    });

    test('Admin Attendance Settings Validation & Rules Logic', () {
      final config = {
        'threshold': 80.0,
        'requiredPercentage': 80.0,
        'minAttendancePercentage': 80.0,
        'qrValidityMinutes': 15,
        'enableLateAttendance': true,
        'lateThresholdMinutes': 10,
        'enableLocationVerification': true,
        'allowedRadiusMeters': 200.0,
        'enableManualAttendance': false,
      };

      // Numeric validations
      expect(config['requiredPercentage'], inInclusiveRange(50.0, 100.0));
      expect(config['qrValidityMinutes'], inInclusiveRange(1, 120));
      expect(config['lateThresholdMinutes'], inInclusiveRange(1, 60));
      expect(config['allowedRadiusMeters'], inInclusiveRange(10.0, 5000.0));

      // Dynamic Late Calculation
      final sessionStart = DateTime(2026, 8, 18, 9, 0); // 09:00 AM
      final onTimeScan = DateTime(2026, 8, 18, 9, 8); // 8 mins late <= 10 threshold -> Present
      final lateScan = DateTime(2026, 8, 18, 9, 15); // 15 mins late > 10 threshold -> Late

      final bool isOnTime = onTimeScan.difference(sessionStart).inMinutes <= (config['lateThresholdMinutes'] as int);
      final bool isLate = lateScan.difference(sessionStart).inMinutes > (config['lateThresholdMinutes'] as int);

      expect(isOnTime, true);
      expect(isLate, true);
    });

    test('Exam Hall Model Attributes & Status Checks', () {
      final hall = ExamHallModel(
        hallId: 'EXH-001',
        hallName: 'Main Exam Hall Alpha',
        building: 'Faculty of Computing',
        floor: '2nd Floor',
        capacity: 120,
        facilities: ['Air Conditioning', 'CCTV Monitoring', 'PA Audio System'],
        status: 'Available',
      );

      expect(hall.hallId, 'EXH-001');
      expect(hall.capacity, 120);
      expect(hall.isAvailable, true);
      expect(hall.isUnderMaintenance, false);
      expect(hall.isInactive, false);

      final map = hall.toMap();
      expect(map['hallName'], 'Main Exam Hall Alpha');
      expect(map['capacity'], 120);
      expect(map['facilities'].length, 3);
    });

    test('Exam Hall Time Conflict & Overlap Detection Logic', () {
      // Slot 1: 09:00 - 12:00
      // Slot 2: 10:00 - 13:00 -> OVERLAP!
      expect(
        ExamHallService.hasTimeConflict(
          startA: '09:00 AM',
          endA: '12:00 PM',
          startB: '10:00 AM',
          endB: '01:00 PM',
        ),
        true,
      );

      // Slot 1: 09:00 - 11:00
      // Slot 2: 11:00 - 13:00 -> NO OVERLAP (contiguous)
      expect(
        ExamHallService.hasTimeConflict(
          startA: '09:00 AM',
          endA: '11:00 AM',
          startB: '11:00 AM',
          endB: '01:00 PM',
        ),
        false,
      );

      // Slot 1: 09:00 - 11:00
      // Slot 2: 14:00 - 16:00 -> NO OVERLAP
      expect(
        ExamHallService.hasTimeConflict(
          startA: '09:00 AM',
          endA: '11:00 AM',
          startB: '02:00 PM',
          endB: '04:00 PM',
        ),
        false,
      );
    });

    test('Exam Hall Assignment Capacity & Eligibility Criteria', () {
      final availableHall = ExamHallModel(
        hallId: 'EXH-001',
        hallName: 'Hall Alpha',
        building: 'Complex A',
        floor: '1st Floor',
        capacity: 100,
        facilities: ['AC'],
        status: 'Available',
      );

      final maintenanceHall = ExamHallModel(
        hallId: 'EXH-002',
        hallName: 'Hall Beta',
        building: 'Complex B',
        floor: '2nd Floor',
        capacity: 150,
        facilities: ['AC'],
        status: 'Maintenance',
      );

      final exam = ExamModel(
        examId: 'EXM-101',
        subjectCode: 'CS101',
        subjectName: 'Mobile Computing',
        examType: 'Final',
        date: '2026-09-15',
        startTime: '09:00 AM',
        endTime: '12:00 PM',
        examHall: 'Not Assigned',
        semester: 'Semester 1',
        academicYear: '2025/2026',
        registeredStudentCount: 85,
      );

      // 1. Available hall with capacity >= 85 is eligible
      expect(availableHall.isAvailable, true);
      expect(exam.registeredStudentCount <= availableHall.capacity, true);

      // 2. Maintenance hall is ineligible
      expect(maintenanceHall.isAvailable, false);

      // 3. Hall with capacity 50 is ineligible for 85 students
      final smallHall = ExamHallModel(
        hallId: 'EXH-003',
        hallName: 'Small Lab',
        building: 'Complex A',
        floor: '3rd Floor',
        capacity: 50,
        facilities: [],
        status: 'Available',
      );
      expect(exam.registeredStudentCount <= smallHall.capacity, false);
    });

    test('Exam Registration Model Attributes & Workflow Status', () {
      final reg = ExamRegistrationModel(
        registrationId: 'EXREG-0001',
        studentDocId: 'doc_123',
        studentId: 'STU-1001',
        studentName: 'Alice Johnson',
        studentEmail: 'alice@uni.lk',
        examId: 'EXM-101',
        examDocId: 'exam_doc_101',
        subjectCode: 'CS101',
        subjectName: 'Mobile App Architecture',
        batch: '2026',
        registeredAt: '2026-08-18T10:00:00',
        status: 'Registered',
      );

      expect(reg.registrationId, 'EXREG-0001');
      expect(reg.isApprovedOrRegistered, true);
      expect(reg.isPending, false);
      expect(reg.isRejected, false);
      expect(reg.isCancelled, false);

      final map = reg.toMap();
      expect(map['registrationId'], 'EXREG-0001');
      expect(map['studentId'], 'STU-1001');
      expect(map['status'], 'Registered');
    });

    test('Exam Registration Deadline & Duplicate Prevention Rules', () {
      // 1. Exam with open future deadline
      final openExam = ExamModel(
        examId: 'EXM-201',
        subjectCode: 'CS201',
        subjectName: 'Cloud Computing',
        examType: 'Final',
        date: '2026-11-20',
        startTime: '09:00 AM',
        endTime: '12:00 PM',
        examHall: 'Main Hall',
        semester: 'Semester 1',
        academicYear: '2025/2026',
        registrationDeadline: '2026-11-15',
      );
      expect(openExam.isPastDeadline, false);

      // 2. Exam with passed past deadline
      final closedExam = ExamModel(
        examId: 'EXM-202',
        subjectCode: 'CS202',
        subjectName: 'Database Systems',
        examType: 'Midterm',
        date: '2026-01-15',
        startTime: '09:00 AM',
        endTime: '11:00 AM',
        examHall: 'Main Hall',
        semester: 'Semester 1',
        academicYear: '2025/2026',
        registrationDeadline: '2026-01-10',
      );
      expect(closedExam.isPastDeadline, true);

      // 3. Duplicate Registration Check Logic
      final existingRegistrations = [
        ExamRegistrationModel(
          registrationId: 'EXREG-0010',
          studentDocId: 'doc1',
          studentId: 'STU-1001',
          studentName: 'Alice',
          studentEmail: 'alice@uni.lk',
          examId: 'EXM-201',
          examDocId: 'doc_201',
          subjectCode: 'CS201',
          subjectName: 'Cloud Computing',
          batch: '2026',
          registeredAt: '2026-08-18T10:00:00',
          status: 'Registered',
        ),
      ];

      bool hasDuplicate(String studentId, String examId) {
        return existingRegistrations.any(
          (r) => r.studentId == studentId && r.examId == examId && r.status != 'Cancelled',
        );
      }

      expect(hasDuplicate('STU-1001', 'EXM-201'), true); // Duplicate!
      expect(hasDuplicate('STU-1002', 'EXM-201'), false); // Eligible new student
      expect(hasDuplicate('STU-1001', 'EXM-202'), false); // Eligible different exam
    });

    test('Exam Seating Model Attributes & Serialization', () {
      final seating = ExamSeatingModel(
        seatingId: 'EXS-EXM-101-001',
        examId: 'EXM-101',
        examDocId: 'doc_101',
        studentId: 'STU-1005',
        studentName: 'Bob Martin',
        studentEmail: 'bob@uni.lk',
        hallId: 'EXH-0001',
        hallName: 'Main Exam Hall Alpha',
        seatNumber: 'SEAT-001',
        allocatedAt: '2026-08-18T10:00:00',
        allocatedBy: 'Admin',
      );

      expect(seating.seatingId, 'EXS-EXM-101-001');
      expect(seating.seatNumber, 'SEAT-001');
      expect(seating.studentId, 'STU-1005');
      expect(seating.hallName, 'Main Exam Hall Alpha');

      final map = seating.toMap();
      expect(map['seatNumber'], 'SEAT-001');
      expect(map['studentName'], 'Bob Martin');
    });

    test('Deterministic Mixed Student Seating Allocation Algorithm', () {
      final registeredStudents = [
        ExamRegistrationModel(registrationId: 'R1', studentDocId: 'd1', studentId: 'STU-001', studentName: 'Student 1', studentEmail: 's1@uni.lk', examId: 'EXM-1', examDocId: 'ed1', subjectCode: 'CS101', subjectName: 'Sub', batch: '2026', registeredAt: ''),
        ExamRegistrationModel(registrationId: 'R2', studentDocId: 'd2', studentId: 'STU-002', studentName: 'Student 2', studentEmail: 's2@uni.lk', examId: 'EXM-1', examDocId: 'ed1', subjectCode: 'CS101', subjectName: 'Sub', batch: '2026', registeredAt: ''),
        ExamRegistrationModel(registrationId: 'R3', studentDocId: 'd3', studentId: 'STU-003', studentName: 'Student 3', studentEmail: 's3@uni.lk', examId: 'EXM-1', examDocId: 'ed1', subjectCode: 'CS101', subjectName: 'Sub', batch: '2026', registeredAt: ''),
        ExamRegistrationModel(registrationId: 'R4', studentDocId: 'd4', studentId: 'STU-004', studentName: 'Student 4', studentEmail: 's4@uni.lk', examId: 'EXM-1', examDocId: 'ed1', subjectCode: 'CS101', subjectName: 'Sub', batch: '2026', registeredAt: ''),
        ExamRegistrationModel(registrationId: 'R5', studentDocId: 'd5', studentId: 'STU-005', studentName: 'Student 5', studentEmail: 's5@uni.lk', examId: 'EXM-1', examDocId: 'ed1', subjectCode: 'CS101', subjectName: 'Sub', batch: '2026', registeredAt: ''),
        ExamRegistrationModel(registrationId: 'R6', studentDocId: 'd6', studentId: 'STU-006', studentName: 'Student 6', studentEmail: 's6@uni.lk', examId: 'EXM-1', examDocId: 'ed1', subjectCode: 'CS101', subjectName: 'Sub', batch: '2026', registeredAt: ''),
      ];

      // 1. Run algorithm with seed 'EXM-1_EXH-1'
      final run1 = ExamSeatingService.deterministicMixStudents(registeredStudents, 'EXM-1_EXH-1');
      final run2 = ExamSeatingService.deterministicMixStudents(registeredStudents, 'EXM-1_EXH-1');

      // 2. Determinism Check: Exact same order for identical seed
      expect(run1.length, 6);
      expect(run2.length, 6);
      for (int i = 0; i < run1.length; i++) {
        expect(run1[i].studentId, run2[i].studentId);
      }

      // 3. Mixed Check: Result is not simply ascending sequential student IDs
      final isExactSequential = run1[0].studentId == 'STU-001' &&
          run1[1].studentId == 'STU-002' &&
          run1[2].studentId == 'STU-003' &&
          run1[3].studentId == 'STU-004';
      expect(isExactSequential, false);

      // 4. Preservation Check: All 6 unique students are preserved without duplicates
      final studentIds = run1.map((s) => s.studentId).toSet();
      expect(studentIds.length, 6);
      expect(studentIds.contains('STU-001'), true);
      expect(studentIds.contains('STU-006'), true);
    });

    test('Seating Capacity & Hall Verification Rules', () {
      final hall = ExamHallModel(
        hallId: 'EXH-01',
        hallName: 'Hall 01',
        building: 'B1',
        floor: 'F1',
        capacity: 4,
        facilities: [],
        status: 'Available',
      );

      final registeredCount = 5;
      final bool isCapacityExceeded = registeredCount > hall.capacity;
      expect(isCapacityExceeded, true); // Cannot allocate 5 students in 4 seats!

      final underMaintenanceHall = ExamHallModel(
        hallId: 'EXH-02',
        hallName: 'Hall 02',
        building: 'B2',
        floor: 'F2',
        capacity: 50,
        facilities: [],
        status: 'Maintenance',
      );
      expect(underMaintenanceHall.isAvailable, false); // Cannot allocate in maintenance hall!
    });

    test('Exam Attendance Record Model Serialization & Verification Rules', () {
      final record = ExamAttendanceRecordModel(
        attendanceId: 'EXATT-0001',
        examId: 'EXM-101',
        examDocId: 'doc_101',
        studentId: 'STU-1001',
        studentName: 'Alice Johnson',
        studentEmail: 'alice@uni.lk',
        hallId: 'EXH-0001',
        hallName: 'Main Exam Hall Alpha',
        seatNumber: 'SEAT-004',
        status: 'Present',
        markedAt: '2026-08-18T09:15:00',
        markedBy: 'Exam Invigilator',
        verificationMethod: 'QR',
        isSeatMatched: true,
      );

      expect(record.attendanceId, 'EXATT-0001');
      expect(record.isPresent, true);
      expect(record.isAbsent, false);
      expect(record.isSeatMatched, true);
      expect(record.verificationMethod, 'QR');

      final map = record.toMap();
      expect(map['studentId'], 'STU-1001');
      expect(map['seatNumber'], 'SEAT-004');
      expect(map['status'], 'Present');
    });

    test('Exam Day Attendance Seat Mismatch Detection & Duplicate Prevention Rules', () {
      // 1. Seat Mismatch Logic
      const allocatedSeat = 'SEAT-004';
      const claimedSeat1 = 'SEAT-004'; // Match
      const claimedSeat2 = 'SEAT-012'; // Mismatch!

      final bool isMatch1 = claimedSeat1.trim().toUpperCase() == allocatedSeat.toUpperCase();
      final bool isMatch2 = claimedSeat2.trim().toUpperCase() == allocatedSeat.toUpperCase();

      expect(isMatch1, true);
      expect(isMatch2, false);

      // 2. Duplicate Attendance Prevention Logic
      final existingRecords = [
        ExamAttendanceRecordModel(
          attendanceId: 'EXATT-001',
          examId: 'EXM-101',
          examDocId: 'ed1',
          studentId: 'STU-1001',
          studentName: 'Alice',
          studentEmail: 'alice@uni.lk',
          hallId: 'EXH-01',
          hallName: 'Main Hall',
          seatNumber: 'SEAT-004',
          status: 'Present',
          markedAt: '2026-08-18T09:05:00',
          markedBy: 'Invigilator 1',
          verificationMethod: 'QR',
        ),
      ];

      bool isAlreadyMarkedPresent(String studentId, String examId) {
        return existingRecords.any(
          (r) => r.studentId == studentId && r.examId == examId && r.isPresent,
        );
      }

      expect(isAlreadyMarkedPresent('STU-1001', 'EXM-101'), true); // Duplicate!
      expect(isAlreadyMarkedPresent('STU-1002', 'EXM-101'), false); // Eligible to mark
      expect(isAlreadyMarkedPresent('STU-1001', 'EXM-102'), false); // Eligible different exam
    });

    test('Exam Result Model Serialization & Attributes', () {
      final result = ExamResultModel(
        resultId: 'EXRES-001',
        examId: 'EXM-101',
        examDocId: 'doc_101',
        moduleId: 'CS201',
        subjectName: 'Cloud Computing',
        studentId: 'STU-1001',
        studentName: 'Alice Johnson',
        studentEmail: 'alice@uni.lk',
        marks: 88.5,
        maxMarks: 100.0,
        grade: 'A',
        gradePoint: 4.0,
        status: 'Draft',
        isAbsent: false,
        submittedBy: 'lecturer@uni.lk',
        updatedAt: '2026-08-18T10:00:00',
      );

      expect(result.resultId, 'EXRES-001');
      expect(result.moduleId, 'CS201');
      expect(result.marks, 88.5);
      expect(result.grade, 'A');
      expect(result.gradePoint, 4.0);
      expect(result.isDraft, true);
      expect(result.isPublished, false);

      final map = result.toMap();
      expect(map['marks'], 88.5);
      expect(map['grade'], 'A');
      expect(map['studentId'], 'STU-1001');
    });

    test('Dynamic Grading & Grade Point Calculation with Configurable Boundaries', () {
      // 1. A+ (90 - 100)
      final resAplus = ExamResultModel.calculateGradeAndPoint(marks: 95.0, isAbsent: false);
      expect(resAplus['grade'], 'A+');
      expect(resAplus['gradePoint'], 4.0);

      // 2. B+ (70 - 74.99)
      final resBplus = ExamResultModel.calculateGradeAndPoint(marks: 72.0, isAbsent: false);
      expect(resBplus['grade'], 'B+');
      expect(resBplus['gradePoint'], 3.3);

      // 3. C (50 - 54.99)
      final resC = ExamResultModel.calculateGradeAndPoint(marks: 52.5, isAbsent: false);
      expect(resC['grade'], 'C');
      expect(resC['gradePoint'], 2.0);

      // 4. Fail / E (< 35)
      final resE = ExamResultModel.calculateGradeAndPoint(marks: 25.0, isAbsent: false);
      expect(resE['grade'], 'E');
      expect(resE['gradePoint'], 0.0);

      // 5. Absent Student University Rule: Marks = 0, Grade = 'AB', GP = 0.0
      final resAbsent = ExamResultModel.calculateGradeAndPoint(marks: 100.0, isAbsent: true);
      expect(resAbsent['grade'], 'AB');
      expect(resAbsent['gradePoint'], 0.0);
    });

    test('Exam Results Workflow & Student Portal Visibility Rules', () {
      // Results in different lifecycle states
      final draftResult = ExamResultModel(
        resultId: 'R1', examId: 'E1', examDocId: 'd1', moduleId: 'CS101', subjectName: 'Intro', studentId: 'S1', studentName: 'S1', studentEmail: 's1@uni.lk', marks: 80, grade: 'A', gradePoint: 4.0, status: 'Draft', updatedAt: '',
      );
      final submittedResult = ExamResultModel(
        resultId: 'R2', examId: 'E1', examDocId: 'd1', moduleId: 'CS101', subjectName: 'Intro', studentId: 'S1', studentName: 'S1', studentEmail: 's1@uni.lk', marks: 80, grade: 'A', gradePoint: 4.0, status: 'Submitted', updatedAt: '',
      );
      final approvedResult = ExamResultModel(
        resultId: 'R3', examId: 'E1', examDocId: 'd1', moduleId: 'CS101', subjectName: 'Intro', studentId: 'S1', studentName: 'S1', studentEmail: 's1@uni.lk', marks: 80, grade: 'A', gradePoint: 4.0, status: 'Approved', updatedAt: '',
      );
      final publishedResult = ExamResultModel(
        resultId: 'R4', examId: 'E1', examDocId: 'd1', moduleId: 'CS101', subjectName: 'Intro', studentId: 'S1', studentName: 'S1', studentEmail: 's1@uni.lk', marks: 80, grade: 'A', gradePoint: 4.0, status: 'Published', updatedAt: '',
      );

      // Lifecycle status checks
      expect(draftResult.isDraft, true);
      expect(submittedResult.isSubmitted, true);
      expect(approvedResult.isApproved, true);
      expect(publishedResult.isPublished, true);
      expect(publishedResult.isLocked, true); // Published results are locked

      // Student Portal Visibility Rule: Only Published results are visible!
      final allResults = [draftResult, submittedResult, approvedResult, publishedResult];
      final visibleToStudents = allResults.where((r) => r.isPublished).toList();

      expect(visibleToStudents.length, 1);
      expect(visibleToStudents.first.resultId, 'R4');
      expect(visibleToStudents.any((r) => r.status == 'Draft'), false);
      expect(visibleToStudents.any((r) => r.status == 'Submitted'), false);
      expect(visibleToStudents.any((r) => r.status == 'Approved'), false);
    });

    test('Examination Reports Aggregation & CSV Generation', () {
      // 1. Registration Report
      final regData = ExamRegistrationReportData(
        total: 10,
        approved: 8,
        pending: 1,
        rejected: 1,
        cancelled: 0,
        records: [
          ExamRegistrationModel(
            registrationId: 'EXREG-001',
            studentDocId: 'd1',
            studentId: 'STU-1001',
            studentName: 'Alice Johnson',
            studentEmail: 'alice@uni.lk',
            examId: 'EXM-101',
            examDocId: 'ed1',
            subjectCode: 'CS101',
            subjectName: 'Computer Science',
            batch: '2026',
            registeredAt: '2026-08-18',
            status: 'Approved',
          ),
        ],
      );
      expect(regData.total, 10);
      expect(regData.approved, 8);
      final regCsv = regData.toCsv();
      expect(regCsv.contains('Registration ID,Student ID,Student Name'), true);
      expect(regCsv.contains('"EXREG-001"'), true);

      // 2. Attendance Report
      final attData = ExamAttendanceReportData(
        registered: 20,
        present: 18,
        absent: 2,
        late: 1,
        attendancePercentage: 90.0,
        records: [
          ExamAttendanceRecordModel(
            attendanceId: 'EXATT-001',
            examId: 'EXM-101',
            examDocId: 'ed1',
            studentId: 'STU-1001',
            studentName: 'Alice',
            studentEmail: 'alice@uni.lk',
            hallId: 'EXH-01',
            hallName: 'Hall 01',
            seatNumber: 'SEAT-001',
            markedAt: '2026-08-18T09:00:00',
            markedBy: 'Admin',
            verificationMethod: 'QR',
          ),
        ],
      );
      expect(attData.attendancePercentage, 90.0);
      expect(attData.present, 18);
      final attCsv = attData.toCsv();
      expect(attCsv.contains('Attendance ID,Exam ID,Student ID'), true);
      expect(attCsv.contains('"EXATT-001"'), true);

      // 3. Seating Report
      final seatData = ExamSeatingReportData(
        hallName: 'Main Exam Hall',
        capacity: 50,
        allocatedStudents: 45,
        availableSeats: 5,
        records: [
          ExamSeatingModel(
            seatingId: 'EXS-001',
            examId: 'EXM-101',
            examDocId: 'ed1',
            studentId: 'STU-1001',
            studentName: 'Alice',
            studentEmail: 'alice@uni.lk',
            hallId: 'EXH-01',
            hallName: 'Main Exam Hall',
            seatNumber: 'SEAT-001',
            allocatedAt: '2026-08-18',
            allocatedBy: 'Admin',
          ),
        ],
      );
      expect(seatData.capacity, 50);
      expect(seatData.availableSeats, 5);
      final seatCsv = seatData.toCsv();
      expect(seatCsv.contains('Seating ID,Exam ID,Hall Name'), true);

      // 4. Results Report
      final resData = ExamResultReportData(
        totalStudents: 30,
        passed: 28,
        failed: 2,
        averageMarks: 74.5,
        highestMarks: 96.0,
        lowestMarks: 32.0,
        gradeDistribution: {'A+': 5, 'A': 10, 'B': 8, 'C': 5, 'E': 2},
        records: [
          ExamResultModel(
            resultId: 'EXRES-001',
            examId: 'EXM-101',
            examDocId: 'ed1',
            moduleId: 'CS101',
            subjectName: 'Computer Science',
            studentId: 'STU-1001',
            studentName: 'Alice',
            studentEmail: 'alice@uni.lk',
            marks: 88.0,
            grade: 'A',
            gradePoint: 4.0,
            status: 'Published',
            updatedAt: '',
          ),
        ],
      );
      expect(resData.passed, 28);
      expect(resData.averageMarks, 74.5);
      expect(resData.gradeDistribution['A+'], 5);
      final resCsv = resData.toCsv();
      expect(resCsv.contains('Result ID,Exam ID,Module ID'), true);
      expect(resCsv.contains('88.0'), true);
    });

    test('Fee Structure Model Attributes & Supported Fee Types', () {
      final fee = FeeStructureModel(
        feeStructureId: 'FEE-1001',
        academicYear: '2025/2026',
        semester: 'Semester 1',
        programme: 'BSc (Hons) in Computing',
        batchId: '2026',
        feeType: 'Semester Fee',
        amount: 150000.0,
        dueDate: '2026-09-30',
        status: 'Active',
        createdAt: '2026-08-18',
        updatedAt: '2026-08-18',
      );

      expect(fee.feeStructureId, 'FEE-1001');
      expect(fee.amount, 150000.0);
      expect(fee.isActive, true);
      expect(fee.isInactive, false);
      expect(FeeStructureModel.supportedFeeTypes.contains('Semester Fee'), true);
      expect(FeeStructureModel.supportedFeeTypes.contains('Registration Fee'), true);
      expect(FeeStructureModel.supportedFeeTypes.contains('Examination Fee'), true);
      expect(FeeStructureModel.supportedFeeTypes.contains('Library Fee'), true);
      expect(FeeStructureModel.supportedFeeTypes.contains('Laboratory Fee'), true);
      expect(FeeStructureModel.supportedFeeTypes.contains('Other Fee'), true);

      final map = fee.toMap();
      expect(map['feeStructureId'], 'FEE-1001');
      expect(map['amount'], 150000.0);
    });

    test('Student Fee Balance & Overdue Payment Status Calculations', () {
      // 1. Balance Calculation: Balance = Total Fee - Paid Amount - Approved Discounts
      final balance1 = FeeStructureModel.calculateBalance(
        totalFee: 150000.0,
        paidAmount: 50000.0,
        approvedDiscounts: 10000.0,
      );
      expect(balance1, 90000.0);

      // Fully Paid Balance
      final balancePaid = FeeStructureModel.calculateBalance(
        totalFee: 150000.0,
        paidAmount: 150000.0,
        approvedDiscounts: 0.0,
      );
      expect(balancePaid, 0.0);

      // Overpaid / Discounted Balance shouldn't be negative
      final balanceExcess = FeeStructureModel.calculateBalance(
        totalFee: 150000.0,
        paidAmount: 160000.0,
        approvedDiscounts: 0.0,
      );
      expect(balanceExcess, 0.0);

      // 2. Status: Paid
      final statusPaid = FeeStructureModel.determinePaymentStatus(
        balance: 0.0,
        paidAmount: 150000.0,
        dueDate: '2026-09-30',
      );
      expect(statusPaid, 'Paid');

      // 3. Status: Partially Paid (Future due date)
      final statusPartial = FeeStructureModel.determinePaymentStatus(
        balance: 50000.0,
        paidAmount: 100000.0,
        dueDate: '2029-12-31',
      );
      expect(statusPartial, 'Partially Paid');

      // 4. Status: Unpaid (Future due date)
      final statusUnpaid = FeeStructureModel.determinePaymentStatus(
        balance: 150000.0,
        paidAmount: 0.0,
        dueDate: '2029-12-31',
      );
      expect(statusUnpaid, 'Unpaid');

      // 5. Status: Overdue (Past due date with positive balance)
      final statusOverdue = FeeStructureModel.determinePaymentStatus(
        balance: 50000.0,
        paidAmount: 0.0,
        dueDate: '2020-01-01',
      );
      expect(statusOverdue, 'Overdue');
    });

    test('Student Finance Privacy & Payment History Status Rules', () {
      // Payment statuses: Pending, Successful, Failed, Refunded
      final successPayment = PaymentModel(
        paymentId: 'PAY-1001',
        studentEmail: 'student1@uni.lk',
        studentId: 'STU-1001',
        studentName: 'Alice Johnson',
        feeType: 'Semester Fee',
        amount: 50000.0,
        paymentMethod: 'Online Card (Visa)',
        transactionRef: 'TXN-991',
        paymentDate: '2026-08-18',
        status: 'success',
      );

      final pendingPayment = PaymentModel(
        paymentId: 'PAY-1002',
        studentEmail: 'student1@uni.lk',
        studentId: 'STU-1001',
        studentName: 'Alice Johnson',
        feeType: 'Library Fee',
        amount: 2500.0,
        paymentMethod: 'Bank Transfer',
        transactionRef: 'TXN-992',
        paymentDate: '2026-08-18',
        status: 'pending',
      );

      final otherStudentPayment = PaymentModel(
        paymentId: 'PAY-1003',
        studentEmail: 'student2@uni.lk',
        studentId: 'STU-1002',
        studentName: 'Bob Smith',
        feeType: 'Semester Fee',
        amount: 75000.0,
        paymentMethod: 'Online Card (Visa)',
        transactionRef: 'TXN-993',
        paymentDate: '2026-08-18',
        status: 'success',
      );

      final allPayments = [successPayment, pendingPayment, otherStudentPayment];

      // Privacy Rule: Alice Johnson must ONLY see payments matching her studentEmail or studentId!
      final alicePayments = allPayments.where((p) => p.studentEmail == 'student1@uni.lk' || p.studentId == 'STU-1001').toList();
      expect(alicePayments.length, 2);
      expect(alicePayments.any((p) => p.studentId == 'STU-1002'), false);

      // Successful vs Pending breakdown
      final aliceSuccessful = alicePayments.where((p) => p.status == 'success').toList();
      expect(aliceSuccessful.length, 1);
      expect(aliceSuccessful.first.amount, 50000.0);
    });
  });
}
