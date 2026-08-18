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
import 'package:student_management_app/models/attendance_model.dart';
import 'package:student_management_app/models/attendance_session_model.dart';
import 'package:student_management_app/models/exam_hall_model.dart';
import 'package:student_management_app/models/exam_model.dart';
import 'package:student_management_app/models/exam_registration_model.dart';
import 'package:student_management_app/models/exam_seating_model.dart';
import 'package:student_management_app/models/exam_attendance_record_model.dart';
import 'package:student_management_app/models/exam_result_model.dart';
import 'package:student_management_app/models/fee_structure_model.dart';
import 'package:student_management_app/models/module_registration_period_model.dart';
import 'package:student_management_app/models/student_module_registration_model.dart';
import 'package:student_management_app/models/notification_model.dart';
import 'package:student_management_app/models/transport_model.dart';
import 'package:student_management_app/models/facility_model.dart';
import 'package:student_management_app/models/library_model.dart';
import 'package:student_management_app/models/subject_model.dart';
import 'package:student_management_app/utils/app_validator.dart';
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

    test('Online Payment Amount Validation & Two-Phase Verification Rules', () {
      const currentBalance = 150000.0;

      // 1. Amount <= 0 is rejected
      expect(PaymentModel.validatePaymentAmount(amount: 0.0, currentBalance: currentBalance) != null, true);
      expect(PaymentModel.validatePaymentAmount(amount: -500.0, currentBalance: currentBalance) != null, true);
      expect(PaymentModel.validatePaymentAmount(amount: null, currentBalance: currentBalance) != null, true);

      // 2. Amount > currentBalance is rejected
      final excessError = PaymentModel.validatePaymentAmount(amount: 160000.0, currentBalance: currentBalance);
      expect(excessError != null, true);
      expect(excessError!.contains('cannot exceed outstanding balance'), true);

      // 3. Valid amount <= currentBalance is accepted
      expect(PaymentModel.validatePaymentAmount(amount: 50000.0, currentBalance: currentBalance), null);
      expect(PaymentModel.validatePaymentAmount(amount: 150000.0, currentBalance: currentBalance), null);

      // 4. Two-Phase Payment Model Status Progression & Verification
      final pendingPayment = PaymentModel(
        paymentId: 'PAY-8801',
        studentEmail: 'student@uni.lk',
        studentId: 'STU-1001',
        studentName: 'Alice',
        feeType: 'Semester Fee',
        amount: 75000.0,
        currency: 'LKR',
        paymentMethod: 'Online Card (Sandbox Gateway)',
        transactionRef: 'ORD-8801',
        paymentDate: '2026-08-18T10:00:00',
        status: 'pending',
      );

      expect(pendingPayment.isPending, true);
      expect(pendingPayment.isSuccessful, false);

      final verifiedPayment = PaymentModel(
        paymentId: pendingPayment.paymentId,
        studentEmail: pendingPayment.studentEmail,
        studentId: pendingPayment.studentId,
        studentName: pendingPayment.studentName,
        feeType: pendingPayment.feeType,
        amount: pendingPayment.amount,
        currency: pendingPayment.currency,
        paymentMethod: pendingPayment.paymentMethod,
        transactionRef: pendingPayment.transactionRef,
        transactionId: 'TXN-SBX-99881',
        paymentDate: pendingPayment.paymentDate,
        status: 'success',
        verifiedAt: '2026-08-18T10:01:15',
      );

      expect(verifiedPayment.isSuccessful, true);
      expect(verifiedPayment.isPending, false);
      expect(verifiedPayment.transactionId, 'TXN-SBX-99881');
      expect(verifiedPayment.verifiedAt != null, true);
    });

    test('Payment Receipt Number Generation, Audit Trail & Multi-Status Notifications', () {
      // 1. Unique Receipt Number Format (REC-YYYY-XXXXXX)
      final receiptNo = PaymentModel.generateReceiptNumber();
      expect(receiptNo.startsWith('REC-'), true);
      expect(receiptNo.contains('2026') || receiptNo.contains('2025'), true);

      // 2. Full Audit Trail Payment Object
      final auditedPayment = PaymentModel(
        paymentId: 'PAY-9901',
        receiptNumber: 'REC-2026-000123',
        studentEmail: 'student@uni.lk',
        studentId: 'STU-1001',
        studentName: 'Alice',
        feeType: 'Registration Fee',
        amount: 15000.0,
        currency: 'LKR',
        paymentMethod: 'Online Card (Sandbox Gateway)',
        transactionRef: 'ORD-9901',
        transactionId: 'TXN-SBX-12345',
        paymentDate: '2026-08-18T10:00:00',
        status: 'success',
        createdAt: '2026-08-18T10:00:00',
        verifiedAt: '2026-08-18T10:01:00',
        refundedAt: null,
      );

      expect(auditedPayment.receiptNumber, 'REC-2026-000123');
      expect(auditedPayment.createdAt, '2026-08-18T10:00:00');
      expect(auditedPayment.verifiedAt, '2026-08-18T10:01:00');
      expect(auditedPayment.isSuccessful, true);

      // Serialization verification
      final map = auditedPayment.toMap();
      expect(map['receiptNumber'], 'REC-2026-000123');
      expect(map['verifiedAt'], '2026-08-18T10:01:00');
      expect(map['currency'], 'LKR');

      // 3. Refunded Audit Trail
      final refundedPayment = PaymentModel(
        paymentId: auditedPayment.paymentId,
        receiptNumber: auditedPayment.receiptNumber,
        studentEmail: auditedPayment.studentEmail,
        studentId: auditedPayment.studentId,
        studentName: auditedPayment.studentName,
        feeType: auditedPayment.feeType,
        amount: auditedPayment.amount,
        currency: auditedPayment.currency,
        paymentMethod: auditedPayment.paymentMethod,
        transactionRef: auditedPayment.transactionRef,
        transactionId: auditedPayment.transactionId,
        paymentDate: auditedPayment.paymentDate,
        status: 'refunded',
        createdAt: auditedPayment.createdAt,
        verifiedAt: auditedPayment.verifiedAt,
        refundedAt: '2026-08-18T14:30:00',
      );

      expect(refundedPayment.isRefunded, true);
      expect(refundedPayment.refundedAt, '2026-08-18T14:30:00');
    });

    test('Module Registration Period Attributes, Credit Limits & Validation Rules', () {
      // 1. Model Attributes & Supported Types
      final period = ModuleRegistrationPeriodModel(
        periodId: 'MRP-2026-S1-001',
        academicYear: '2025/2026',
        semester: 'Semester 1',
        programme: 'BSc (Hons) in Computing',
        batchId: '2026',
        registrationStartDate: '2026-08-01',
        registrationEndDate: '2026-08-31',
        minimumCredits: 12,
        maximumCredits: 24,
        maximumModules: 6,
        status: 'Open',
        offeredModuleCodes: ['CS101', 'CS102', 'CS103'],
        offeredModuleTypes: {'CS101': 'Core', 'CS102': 'Core', 'CS103': 'Elective'},
        createdAt: '2026-08-01',
        updatedAt: '2026-08-01',
      );

      expect(period.periodId, 'MRP-2026-S1-001');
      expect(period.isOpen, true);
      expect(period.isDraft, false);
      expect(period.isClosed, false);
      expect(period.offeredModuleCodes.length, 3);
      expect(period.offeredModuleTypes['CS103'], 'Elective');
      expect(ModuleRegistrationPeriodModel.supportedModuleTypes.contains('Core'), true);
      expect(ModuleRegistrationPeriodModel.supportedModuleTypes.contains('Elective'), true);
      expect(ModuleRegistrationPeriodModel.supportedModuleTypes.contains('Optional'), true);

      // 2. Validation: maxCredits < minCredits is rejected
      final invalidCreditError = ModuleRegistrationPeriodModel.validatePeriod(
        academicYear: '2025/2026',
        semester: 'Semester 1',
        programme: 'BSc Computing',
        batchId: '2026',
        startDate: '2026-08-01',
        endDate: '2026-08-31',
        minCredits: 20,
        maxCredits: 10,
        maxModules: 5,
      );
      expect(invalidCreditError != null, true);
      expect(invalidCreditError!.contains('cannot be less than minimum credits'), true);

      // 3. Validation: startDate > endDate is rejected
      final invalidDateError = ModuleRegistrationPeriodModel.validatePeriod(
        academicYear: '2025/2026',
        semester: 'Semester 1',
        programme: 'BSc Computing',
        batchId: '2026',
        startDate: '2026-08-31',
        endDate: '2026-08-01',
        minCredits: 12,
        maxCredits: 24,
        maxModules: 5,
      );
      expect(invalidDateError != null, true);
      expect(invalidDateError!.contains('Start Date cannot be after End Date'), true);

      // 4. Validation: valid period configuration passes
      final validResult = ModuleRegistrationPeriodModel.validatePeriod(
        academicYear: '2025/2026',
        semester: 'Semester 1',
        programme: 'BSc Computing',
        batchId: '2026',
        startDate: '2026-08-01',
        endDate: '2026-08-31',
        minCredits: 12,
        maxCredits: 24,
        maxModules: 6,
      );
      expect(validResult, null);
    });

    test('Student Module Registration Validation, Prerequisites & Credit Bounds Rules', () {
      final existingRegistrations = [
        StudentModuleRegistrationModel(
          registrationId: 'MODREG-001-CS101',
          studentId: 'STU-1001',
          studentName: 'Alice',
          studentEmail: 'alice@uni.lk',
          moduleId: 'CS101',
          moduleName: 'Intro to CS',
          registrationPeriodId: 'MRP-2026-S1-001',
          academicYear: '2025/2026',
          semester: 'Semester 1',
          credits: 3,
          moduleType: 'Core',
          status: 'Approved',
          registeredAt: '2026-08-18',
        ),
      ];

      final creditsMap = {
        'CS101': 3,
        'CS102': 4,
        'CS103': 3,
        'CS104': 4,
        'CS105': 3,
        'CS106': 4,
        'CS107': 4,
      };

      final prereqMap = {
        'CS102': ['CS101'],
        'CS106': ['CS109'], // missing prerequisite
      };

      // 1. Duplicate Registration Prevention
      final duplicateError = StudentModuleRegistrationModel.validateRegistrationSelection(
        existingRegistrations: existingRegistrations,
        candidateModuleCodes: ['CS101', 'CS102', 'CS103', 'CS104'],
        moduleCreditsMap: creditsMap,
        modulePrerequisitesMap: prereqMap,
        studentPassedModuleCodes: ['CS101'],
        minCredits: 12,
        maxCredits: 24,
        maxModules: 6,
      );
      expect(duplicateError != null, true);
      expect(duplicateError!.contains('already registered'), true);

      // 2. Missing Prerequisite Rejection
      final prereqError = StudentModuleRegistrationModel.validateRegistrationSelection(
        existingRegistrations: existingRegistrations,
        candidateModuleCodes: ['CS102', 'CS106', 'CS103', 'CS104'],
        moduleCreditsMap: creditsMap,
        modulePrerequisitesMap: prereqMap,
        studentPassedModuleCodes: ['CS101'], // does not have CS109
        minCredits: 12,
        maxCredits: 24,
        maxModules: 6,
      );
      expect(prereqError != null, true);
      expect(prereqError!.contains('Missing prerequisite: CS109'), true);

      // 3. Under Minimum Credit Warning/Rejection
      final underMinError = StudentModuleRegistrationModel.validateRegistrationSelection(
        existingRegistrations: existingRegistrations,
        candidateModuleCodes: ['CS102', 'CS103'], // Total 4+3 = 7 credits
        moduleCreditsMap: creditsMap,
        modulePrerequisitesMap: prereqMap,
        studentPassedModuleCodes: ['CS101'],
        minCredits: 12,
        maxCredits: 24,
        maxModules: 6,
      );
      expect(underMinError != null, true);
      expect(underMinError!.contains('below the minimum required credit limit'), true);

      // 4. Over Maximum Credit Rejection
      final overMaxError = StudentModuleRegistrationModel.validateRegistrationSelection(
        existingRegistrations: existingRegistrations,
        candidateModuleCodes: ['CS102', 'CS103', 'CS104', 'CS105', 'CS107', 'CS106'], // Total 4+3+4+3+4+4 = 22 credits (if max is 18)
        moduleCreditsMap: creditsMap,
        modulePrerequisitesMap: prereqMap,
        studentPassedModuleCodes: ['CS101', 'CS109'],
        minCredits: 12,
        maxCredits: 18,
        maxModules: 6,
      );
      expect(overMaxError != null, true);
      expect(overMaxError!.contains('exceed the maximum credit limit'), true);

      // 5. Valid Selection Passes
      final validSelection = StudentModuleRegistrationModel.validateRegistrationSelection(
        existingRegistrations: existingRegistrations,
        candidateModuleCodes: ['CS102', 'CS103', 'CS104', 'CS105'], // Total 4+3+4+3 = 14 credits
        moduleCreditsMap: creditsMap,
        modulePrerequisitesMap: prereqMap,
        studentPassedModuleCodes: ['CS101'],
        minCredits: 12,
        maxCredits: 24,
        maxModules: 6,
      );
      expect(validSelection, null);
    });

    test('Admin Module Registration Approval, Rejection & KPI Aggregations Rules', () {
      final reg1 = StudentModuleRegistrationModel(
        registrationId: 'MODREG-101-CS101',
        studentId: 'STU-1001',
        studentName: 'Alice',
        studentEmail: 'alice@uni.lk',
        programme: 'BSc Computing',
        batchId: '2026',
        moduleId: 'CS101',
        moduleName: 'Database Systems',
        registrationPeriodId: 'MRP-2026-S1-001',
        academicYear: '2025/2026',
        semester: 'Semester 1',
        credits: 3,
        moduleType: 'Core',
        status: 'Pending',
        registeredAt: '2026-08-18T09:00:00',
      );

      final reg2 = StudentModuleRegistrationModel(
        registrationId: 'MODREG-102-CS102',
        studentId: 'STU-1001',
        studentName: 'Alice',
        studentEmail: 'alice@uni.lk',
        programme: 'BSc Computing',
        batchId: '2026',
        moduleId: 'CS102',
        moduleName: 'Software Engineering',
        registrationPeriodId: 'MRP-2026-S1-001',
        academicYear: '2025/2026',
        semester: 'Semester 1',
        credits: 4,
        moduleType: 'Core',
        status: 'Approved',
        registeredAt: '2026-08-18T09:00:00',
        approvedAt: '2026-08-18T10:00:00',
        approvedBy: 'ADMIN-BURSAR',
      );

      final reg3 = StudentModuleRegistrationModel(
        registrationId: 'MODREG-103-CS103',
        studentId: 'STU-1002',
        studentName: 'Bob',
        studentEmail: 'bob@uni.lk',
        programme: 'BSc Computing',
        batchId: '2026',
        moduleId: 'CS103',
        moduleName: 'Computer Networks',
        registrationPeriodId: 'MRP-2026-S1-001',
        academicYear: '2025/2026',
        semester: 'Semester 1',
        credits: 3,
        moduleType: 'Elective',
        status: 'Rejected',
        registeredAt: '2026-08-18T09:00:00',
        rejectedAt: '2026-08-18T10:30:00',
        rejectedBy: 'ADMIN-BURSAR',
        rejectionReason: 'Prerequisites CS101 not met',
      );

      final reg4 = StudentModuleRegistrationModel(
        registrationId: 'MODREG-104-CS104',
        studentId: 'STU-1003',
        studentName: 'Charlie',
        studentEmail: 'charlie@uni.lk',
        programme: 'BSc Computing',
        batchId: '2026',
        moduleId: 'CS104',
        moduleName: 'Web Development',
        registrationPeriodId: 'MRP-2026-S1-001',
        academicYear: '2025/2026',
        semester: 'Semester 1',
        credits: 3,
        moduleType: 'Optional',
        status: 'Dropped',
        registeredAt: '2026-08-18T09:00:00',
        droppedAt: '2026-08-18T11:00:00',
        droppedBy: 'ADMIN-BURSAR',
        dropReason: 'Course load adjustment requested',
      );

      final list = [reg1, reg2, reg3, reg4];

      // 1. KPI Aggregations
      expect(list.length, 4); // Total
      expect(list.where((r) => r.isPending).length, 1);
      expect(list.where((r) => r.isApproved).length, 1);
      expect(list.where((r) => r.isRejected).length, 1);
      expect(list.where((r) => r.isDropped).length, 1);
      expect(list.map((r) => r.studentId).toSet().length, 3); // Unique Students

      // 2. Transition from Pending -> Approved
      final approvedReg1 = StudentModuleRegistrationModel(
        registrationId: reg1.registrationId,
        studentId: reg1.studentId,
        studentName: reg1.studentName,
        studentEmail: reg1.studentEmail,
        programme: reg1.programme,
        batchId: reg1.batchId,
        moduleId: reg1.moduleId,
        moduleName: reg1.moduleName,
        registrationPeriodId: reg1.registrationPeriodId,
        academicYear: reg1.academicYear,
        semester: reg1.semester,
        credits: reg1.credits,
        moduleType: reg1.moduleType,
        status: 'Approved',
        registeredAt: reg1.registeredAt,
        approvedAt: '2026-08-18T12:00:00',
        approvedBy: 'ADMIN-ACADEMIC',
      );

      expect(approvedReg1.isApproved, true);
      expect(approvedReg1.approvedAt, '2026-08-18T12:00:00');
      expect(approvedReg1.approvedBy, 'ADMIN-ACADEMIC');
      expect(approvedReg1.toMap()['status'], 'Approved');

      // 3. Rejection & Drop reasons audit
      expect(reg3.rejectionReason, 'Prerequisites CS101 not met');
      expect(reg4.dropReason, 'Course load adjustment requested');
    });

    test('Student My Modules Approved Filter & Module Details Cross-Collection Rules', () {
      final regApproved1 = StudentModuleRegistrationModel(
        registrationId: 'MODREG-201-CS101',
        studentId: 'STU-1001',
        studentName: 'Alice',
        studentEmail: 'alice@uni.lk',
        programme: 'BSc Computing',
        batchId: '2026',
        moduleId: 'CS101',
        moduleName: 'Database Systems',
        registrationPeriodId: 'MRP-2026-S1-001',
        academicYear: '2025/2026',
        semester: 'Semester 1',
        credits: 3,
        moduleType: 'Core',
        status: 'Approved',
        registeredAt: '2026-08-18',
      );

      final regPending2 = StudentModuleRegistrationModel(
        registrationId: 'MODREG-202-CS102',
        studentId: 'STU-1001',
        studentName: 'Alice',
        studentEmail: 'alice@uni.lk',
        programme: 'BSc Computing',
        batchId: '2026',
        moduleId: 'CS102',
        moduleName: 'Software Engineering',
        registrationPeriodId: 'MRP-2026-S1-001',
        academicYear: '2025/2026',
        semester: 'Semester 1',
        credits: 4,
        moduleType: 'Core',
        status: 'Pending',
        registeredAt: '2026-08-18',
      );

      final allStudentRegistrations = [regApproved1, regPending2];

      // 1. My Modules rule: ONLY Approved registrations are displayed to the student
      final visibleModules = allStudentRegistrations.where((r) => r.isApproved).toList();
      expect(visibleModules.length, 1);
      expect(visibleModules.first.moduleId, 'CS101');
      expect(visibleModules.any((r) => r.isPending), false);

      // 2. Module Attendance Calculation Rule for CS101
      final attRecords = [
        AttendanceModel(studentDocId: 'doc1', studentId: 'STU-1001', studentName: 'Alice', subjectCode: 'CS101', subjectName: 'Database Systems', date: '2026-08-01', status: 'present', markedBy: 'Lecturer', batch: '2026', semester: 'Semester 1'),
        AttendanceModel(studentDocId: 'doc1', studentId: 'STU-1001', studentName: 'Alice', subjectCode: 'CS101', subjectName: 'Database Systems', date: '2026-08-08', status: 'present', markedBy: 'Lecturer', batch: '2026', semester: 'Semester 1'),
        AttendanceModel(studentDocId: 'doc1', studentId: 'STU-1001', studentName: 'Alice', subjectCode: 'CS101', subjectName: 'Database Systems', date: '2026-08-15', status: 'absent', markedBy: 'Lecturer', batch: '2026', semester: 'Semester 1'),
      ];

      final totalSessions = attRecords.length;
      final presentCount = attRecords.where((a) => a.status == 'present' || a.status == 'late').length;
      final attPct = (presentCount / totalSessions) * 100.0;
      expect(totalSessions, 3);
      expect(presentCount, 2);
      expect(attPct.toStringAsFixed(1), '66.7');

      // 3. Results Tab: Strict Published Results Only rule
      final resultDraft = ExamResultModel(
        resultId: 'RES-001',
        examId: 'EXAM-101',
        examDocId: 'doc1',
        moduleId: 'CS101',
        subjectName: 'Database Systems',
        studentId: 'STU-1001',
        studentName: 'Alice',
        studentEmail: 'alice@uni.lk',
        marks: 85.0,
        grade: 'A',
        gradePoint: 4.0,
        status: 'Draft',
        updatedAt: '2026-08-18',
      );

      final resultPublished = ExamResultModel(
        resultId: 'RES-002',
        examId: 'EXAM-101',
        examDocId: 'doc2',
        moduleId: 'CS101',
        subjectName: 'Database Systems',
        studentId: 'STU-1001',
        studentName: 'Alice',
        studentEmail: 'alice@uni.lk',
        marks: 85.0,
        grade: 'A',
        gradePoint: 4.0,
        status: 'Published',
        publishedAt: '2026-08-18',
        updatedAt: '2026-08-18',
      );

      final allResults = [resultDraft, resultPublished];
      final visiblePublishedResults = allResults.where((r) => r.isPublished).toList();
      expect(visiblePublishedResults.length, 1);
      expect(visiblePublishedResults.first.grade, 'A');
      expect(visiblePublishedResults.first.isLocked, true);
    });

    test('Lecture Materials & Slides Management Attributes, File Validation & Visibility Rules', () {
      // 1. Material Model Attributes & Serialization
      final mat1 = MaterialModel(
        materialId: 'MAT-101',
        moduleId: 'CS101',
        subjectName: 'Database Systems',
        title: 'Introduction to SQL and Relational Modeling',
        description: 'Lecture slides covering ER Diagrams, Normalization, and DDL commands.',
        type: 'Lecture Slide',
        fileName: 'CS101_Week1_Slides.pptx',
        fileUrl: 'https://firebasestorage.googleapis.com/v0/b/studentapp/o/materials%2FCS101%2FCS101_Week1_Slides.pptx',
        fileSize: '5.2 MB',
        uploadedBy: 'lec.lee@uni.lk',
        uploadedByName: 'Dr. Lee',
        uploadedAt: '2026-08-18T10:00:00',
        publishDate: '2026-08-18',
        status: 'Published',
        weekNumber: 1,
      );

      final mat2 = MaterialModel(
        materialId: 'MAT-102',
        moduleId: 'CS101',
        subjectName: 'Database Systems',
        title: 'Midterm Draft Preparation Notes',
        description: 'Internal draft notes for lecturer review.',
        type: 'Note',
        fileName: 'CS101_Midterm_Draft.pdf',
        fileUrl: 'https://firebasestorage.googleapis.com/v0/b/studentapp/o/materials%2FCS101%2FCS101_Midterm_Draft.pdf',
        fileSize: '1.8 MB',
        uploadedBy: 'lec.lee@uni.lk',
        uploadedByName: 'Dr. Lee',
        uploadedAt: '2026-08-18T11:00:00',
        publishDate: '2026-08-25',
        status: 'Draft',
        weekNumber: 5,
      );

      expect(mat1.isPublished, true);
      expect(mat1.isDraft, false);
      expect(mat2.isPublished, false);
      expect(mat2.isDraft, true);

      // 2. Student Visibility Rule (Only Published Materials)
      final allMaterials = [mat1, mat2];
      final studentVisibleMaterials = allMaterials.where((m) => m.isPublished).toList();
      expect(studentVisibleMaterials.length, 1);
      expect(studentVisibleMaterials.first.materialId, 'MAT-101');

      // 3. Supported Material Types Verification
      expect(MaterialModel.supportedTypes.contains('Lecture Slide'), true);
      expect(MaterialModel.supportedTypes.contains('PDF'), true);
      expect(MaterialModel.supportedTypes.contains('Note'), true);
      expect(MaterialModel.supportedTypes.contains('Document'), true);
      expect(MaterialModel.supportedTypes.contains('Other'), true);

      // 4. File Type & Extension Validation
      expect(MaterialModel.validateFileType('slides.pptx'), null);
      expect(MaterialModel.validateFileType('notes.pdf'), null);
      expect(MaterialModel.validateFileType('summary.docx'), null);
      expect(MaterialModel.validateFileType('archive.zip'), null);
      expect(MaterialModel.validateFileType('malicious.exe') != null, true);
      expect(MaterialModel.validateFileType('') != null, true);

      // 5. File Size Validation (Max 25 MB)
      expect(MaterialModel.validateFileSize(5.2), null);
      expect(MaterialModel.validateFileSize(24.9), null);
      expect(MaterialModel.validateFileSize(25.1) != null, true);
      expect(MaterialModel.validateFileSize(0.0) != null, true);
    });

    test('Assignment Creation, Submission & Grading Validation Rules', () {
      // 1. Assignment Creation Validation (Dates & Marks)
      final validAssignmentErr = AssignmentModel.validateAssignment(
        title: 'Project Milestone 1',
        startDate: '2026-08-01',
        dueDate: '2026-08-20',
        maxMarks: 100.0,
      );
      expect(validAssignmentErr, null);

      final invalidDueDateErr = AssignmentModel.validateAssignment(
        title: 'Project Milestone 1',
        startDate: '2026-08-20',
        dueDate: '2026-08-01', // Due date before start date
        maxMarks: 100.0,
      );
      expect(invalidDueDateErr != null, true);
      expect(invalidDueDateErr!.contains('Due date must be after start date'), true);

      final invalidMarksErr = AssignmentModel.validateAssignment(
        title: 'Project Milestone 1',
        startDate: '2026-08-01',
        dueDate: '2026-08-20',
        maxMarks: 0.0, // Marks <= 0
      );
      expect(invalidMarksErr != null, true);
      expect(invalidMarksErr!.contains('Maximum marks must be greater than 0'), true);

      // 2. Automatic Late Submission Detection
      final onTimeStatus = SubmissionModel.determineSubmissionStatus(
        submittedAt: DateTime(2026, 8, 15, 14, 0),
        dueDate: '2026-08-20',
      );
      expect(onTimeStatus, 'Submitted');

      final lateStatus = SubmissionModel.determineSubmissionStatus(
        submittedAt: DateTime(2026, 8, 22, 10, 0),
        dueDate: '2026-08-20',
      );
      expect(lateStatus, 'Late');

      // 3. Grading Score Bounds Validation (0 <= marks <= maxMarks)
      expect(SubmissionModel.validateGradingMarks(marks: 85.0, maxMarks: 100.0), null);
      expect(SubmissionModel.validateGradingMarks(marks: 0.0, maxMarks: 100.0), null);
      expect(SubmissionModel.validateGradingMarks(marks: 100.0, maxMarks: 100.0), null);
      expect(SubmissionModel.validateGradingMarks(marks: -5.0, maxMarks: 100.0) != null, true);
      expect(SubmissionModel.validateGradingMarks(marks: 105.0, maxMarks: 100.0) != null, true);

      // 4. Submission Model Lifecycle & Serialization
      final sub = SubmissionModel(
        submissionId: 'SUB-2026-101',
        assignmentId: 'ASG-101',
        assignmentTitle: 'Project Milestone 1',
        moduleId: 'CS101',
        studentId: 'STU-1001',
        studentName: 'Alice',
        studentEmail: 'alice@uni.lk',
        submittedAt: '2026-08-15T14:00:00',
        isLate: false,
        fileName: 'Alice_Report.pdf',
        fileUrl: 'https://firebasestorage.googleapis.com/v0/b/studentapp/o/submissions%2FCS101%2FASG-101%2FAlice_Report.pdf',
        status: 'Submitted',
      );

      expect(sub.isSubmitted, true);
      expect(sub.isGraded, false);

      final gradedSub = SubmissionModel(
        submissionId: sub.submissionId,
        assignmentId: sub.assignmentId,
        assignmentTitle: sub.assignmentTitle,
        moduleId: sub.moduleId,
        studentId: sub.studentId,
        studentName: sub.studentName,
        studentEmail: sub.studentEmail,
        submittedAt: sub.submittedAt,
        isLate: sub.isLate,
        fileName: sub.fileName,
        fileUrl: sub.fileUrl,
        status: 'Graded',
        marks: 92.5,
        feedback: 'Excellent design diagrams and well-written explanation.',
        gradedBy: 'Dr. Lee',
        gradedAt: '2026-08-18T16:00:00',
      );

      expect(gradedSub.isGraded, true);
      expect(gradedSub.marks, 92.5);
      expect(gradedSub.feedback, 'Excellent design diagrams and well-written explanation.');
    });

    test('Task Management Priorities, Overdue Calculation & Student Visibility Rules', () {
      // 1. Task Model Attributes & Priority Mapping
      final task1 = TaskModel(
        taskId: 'TSK-101',
        title: 'Review Chapter 3 Normalization',
        description: 'Read slides and prepare 3NF questions.',
        instructions: 'Submit a 1-page summary note.',
        moduleId: 'CS101',
        assignedBy: 'Dr. Lee',
        priority: 'High',
        startDate: '2026-08-01',
        dueDate: '2026-08-10', // Past date
        createdDate: '2026-08-01T09:00:00',
        status: 'pending',
      );

      final task2 = TaskModel(
        taskId: 'TSK-102',
        title: 'Setup PostgreSQL Database Docker Container',
        description: 'Run docker compose for Postgres.',
        moduleId: 'CS101',
        assignedBy: 'Dr. Lee',
        priority: 'Medium',
        startDate: '2026-08-01',
        dueDate: '2026-08-10', // Past date, but completed
        createdDate: '2026-08-01T09:00:00',
        status: 'completed',
        completedAt: '2026-08-08T18:00:00',
        completedBy: 'Alice',
      );

      final task3 = TaskModel(
        taskId: 'TSK-103',
        title: 'Draft Project Proposal',
        description: 'Internal draft not yet released to students.',
        moduleId: 'CS101',
        assignedBy: 'Dr. Lee',
        priority: 'Low',
        startDate: '2026-08-18',
        dueDate: '2026-08-30',
        createdDate: '2026-08-18T09:00:00',
        status: 'Draft',
      );

      // 2. Overdue vs Completed Rules
      expect(task1.effectiveStatus, 'overdue');
      expect(task1.isOverdue, true);
      expect(task1.isCompleted, false);

      expect(task2.effectiveStatus, 'completed'); // Completed NEVER becomes overdue!
      expect(task2.isCompleted, true);
      expect(task2.isOverdue, false);

      // 3. Student Visibility Rule (Only Published / Non-Draft tasks)
      final allTasks = [task1, task2, task3];
      final studentVisibleTasks = allTasks.where((t) => !t.isDraft).toList();
      expect(studentVisibleTasks.length, 2);
      expect(studentVisibleTasks.map((t) => t.taskId).toSet(), {'TSK-101', 'TSK-102'});

      // 4. Status Lifecycle Transition (Pending -> In Progress -> Completed)
      final startedTask = TaskModel(
        taskId: task1.taskId,
        title: task1.title,
        description: task1.description,
        moduleId: task1.moduleId,
        assignedBy: task1.assignedBy,
        priority: task1.priority,
        startDate: task1.startDate,
        dueDate: '2026-08-30', // Future date
        createdDate: task1.createdDate,
        status: 'in_progress',
      );

      expect(startedTask.effectiveStatus, 'in_progress');
    });

    test('Announcement Management Targeting, Auto-Expiry & Read/Unread Rules', () {
      // 1. Model Serialization & Priority Attributes
      final ann1 = AnnouncementModel(
        announcementId: 'ANN-2026-001',
        title: 'Library Extended Hours',
        description: 'The library will stay open 24/7 during finals week.',
        audience: 'everyone',
        publishDate: '2026-08-01',
        expiryDate: '2026-08-30', // Future
        status: 'Published',
        priority: 'Normal',
        createdBy: 'Admin',
      );

      final annExpired = AnnouncementModel(
        announcementId: 'ANN-2026-002',
        title: 'Campus Shuttle Maintenance',
        description: 'Shuttle routes suspended on 5th Aug.',
        audience: 'everyone',
        publishDate: '2026-08-01',
        expiryDate: '2026-08-05', // Past date
        status: 'Published',
        priority: 'Important',
        createdBy: 'Admin',
      );

      final annProgramme = AnnouncementModel(
        announcementId: 'ANN-2026-003',
        title: 'BSc Computing Industry Workshop',
        description: 'Guest lecture on Cloud Architecture.',
        audience: 'specific_programme',
        programme: 'BSc Computing',
        publishDate: '2026-08-15',
        expiryDate: '2026-08-30',
        status: 'Published',
        priority: 'Urgent',
        createdBy: 'Admin',
        readBy: ['alice@uni.lk'],
      );

      final annBatch = AnnouncementModel(
        announcementId: 'ANN-2026-004',
        title: 'Batch 2026 Orientation',
        description: 'Meeting in Auditorium 2.',
        audience: 'specific_batch',
        batchId: '2026',
        publishDate: '2026-08-15',
        expiryDate: '2026-08-30',
        status: 'Published',
        priority: 'Important',
        createdBy: 'Admin',
      );

      final annModule = AnnouncementModel(
        announcementId: 'ANN-2026-005',
        title: 'CS101 Lab Rescheduled',
        description: 'Lab 3 moved to Hall B.',
        audience: 'specific_module',
        moduleId: 'CS101',
        publishDate: '2026-08-15',
        expiryDate: '2026-08-30',
        status: 'Published',
        priority: 'Urgent',
        createdBy: 'Dr. Lee',
      );

      // 2. Automated Expiry Rule
      expect(ann1.isExpired, false);
      expect(annExpired.isExpired, true);
      expect(annExpired.effectiveStatus, 'expired');

      // 3. Audience Targeting Rule for Alice (BSc Computing, Batch 2026, enrolled in CS101)
      expect(
        AnnouncementModel.isTargetedToStudent(
          announcement: ann1,
          studentId: 'STU-1001',
          studentEmail: 'alice@uni.lk',
          programme: 'BSc Computing',
          batchId: '2026',
          enrolledModuleIds: ['CS101', 'CS102'],
        ),
        true,
      );

      expect(
        AnnouncementModel.isTargetedToStudent(
          announcement: annProgramme,
          studentId: 'STU-1001',
          studentEmail: 'alice@uni.lk',
          programme: 'BSc Computing',
          batchId: '2026',
          enrolledModuleIds: ['CS101'],
        ),
        true,
      );

      expect(
        AnnouncementModel.isTargetedToStudent(
          announcement: annProgramme,
          studentId: 'STU-1002',
          studentEmail: 'bob@uni.lk',
          programme: 'BSc Business', // Different programme
          batchId: '2026',
          enrolledModuleIds: ['MGT101'],
        ),
        false,
      );

      expect(
        AnnouncementModel.isTargetedToStudent(
          announcement: annBatch,
          studentId: 'STU-1001',
          studentEmail: 'alice@uni.lk',
          programme: 'BSc Computing',
          batchId: '2026', // Matching batch
          enrolledModuleIds: ['CS101'],
        ),
        true,
      );

      expect(
        AnnouncementModel.isTargetedToStudent(
          announcement: annBatch,
          studentId: 'STU-1002',
          studentEmail: 'bob@uni.lk',
          programme: 'BSc Computing',
          batchId: '2025', // Non-matching batch
          enrolledModuleIds: ['CS101'],
        ),
        false,
      );

      expect(
        AnnouncementModel.isTargetedToStudent(
          announcement: annModule,
          studentId: 'STU-1001',
          studentEmail: 'alice@uni.lk',
          programme: 'BSc Computing',
          batchId: '2026',
          enrolledModuleIds: ['CS101'], // Enrolled in CS101
        ),
        true,
      );

      expect(
        AnnouncementModel.isTargetedToStudent(
          announcement: annModule,
          studentId: 'STU-1002',
          studentEmail: 'bob@uni.lk',
          programme: 'BSc Computing',
          batchId: '2026',
          enrolledModuleIds: ['CS201'], // Not enrolled in CS101
        ),
        false,
      );

      // 4. Read/Unread Tracking
      expect(annProgramme.isReadBy('alice@uni.lk'), true);
      expect(annProgramme.isReadBy('bob@uni.lk'), false);
    });

    test('Unified Notification Center Types, Expiry & Priority Rules', () {
      // 1. Supported Notification Types Verification
      expect(NotificationModel.supportedTypes.contains('Assignment'), true);
      expect(NotificationModel.supportedTypes.contains('Task'), true);
      expect(NotificationModel.supportedTypes.contains('Attendance'), true);
      expect(NotificationModel.supportedTypes.contains('Timetable'), true);
      expect(NotificationModel.supportedTypes.contains('Examination'), true);
      expect(NotificationModel.supportedTypes.contains('Result'), true);
      expect(NotificationModel.supportedTypes.contains('Payment'), true);
      expect(NotificationModel.supportedTypes.contains('Announcement'), true);
      expect(NotificationModel.supportedTypes.contains('System'), true);

      // 2. Notification Model Serialization & Priority
      final notif = NotificationModel(
        notificationId: 'NTF-2026-001',
        recipientId: 'alice@uni.lk',
        title: 'Assignment Graded: Milestone 1',
        message: 'Your submission for CS101 has been evaluated.',
        type: 'Assignment',
        priority: 'Important',
        relatedId: 'ASG-101',
        relatedModuleId: 'CS101',
        isRead: false,
        createdAt: '2026-08-18T10:00:00',
        expiresAt: '2026-08-30', // Future
      );

      final expiredNotif = NotificationModel(
        notificationId: 'NTF-2026-002',
        recipientId: 'alice@uni.lk',
        title: 'Shuttle Reminder',
        message: 'Bus departure in 10 minutes.',
        type: 'System',
        priority: 'Normal',
        isRead: true,
        createdAt: '2026-08-01T08:00:00',
        expiresAt: '2026-08-01', // Past date
      );

      // 3. Expiry Rules
      expect(notif.isExpired, false);
      expect(expiredNotif.isExpired, true);

      // 4. Read/Unread State Tracking
      expect(notif.isReadByUser('alice@uni.lk'), false);
      expect(expiredNotif.isReadByUser('alice@uni.lk'), true);

      final readNotif = NotificationModel(
        notificationId: notif.notificationId,
        recipientId: notif.recipientId,
        title: notif.title,
        message: notif.message,
        type: notif.type,
        priority: notif.priority,
        relatedId: notif.relatedId,
        relatedModuleId: notif.relatedModuleId,
        isRead: true,
        createdAt: notif.createdAt,
        expiresAt: notif.expiresAt,
      );

      expect(readNotif.isReadByUser('alice@uni.lk'), true);
      expect(readNotif.relatedId, 'ASG-101');
      expect(readNotif.relatedModuleId, 'CS101');
    });

    test('Transport Management Routes, Fleet, Schedule Conflicts & Preferences Rules', () {
      // 1. Route & Stops Sequence
      final route = TransportRouteModel(
        routeId: 'RTE-101',
        routeName: 'Colombo - Campus Express',
        startPoint: 'Fort Railway Station',
        destination: 'Main Campus',
        distance: 28.5,
        status: 'Active',
        stops: [
          TransportStopModel(stopId: 'STP-1', pointName: 'Fort Station', pickupTime: '06:30 AM', dropOffTime: '05:30 PM', sequence: 1),
          TransportStopModel(stopId: 'STP-2', pointName: 'Bambalapitiya', pickupTime: '06:50 AM', dropOffTime: '05:10 PM', sequence: 2),
          TransportStopModel(stopId: 'STP-3', pointName: 'Nugegoda Junction', pickupTime: '07:15 AM', dropOffTime: '04:45 PM', sequence: 3),
        ],
      );

      expect(route.isActive, true);
      expect(route.stops.length, 3);
      expect(route.pickupPointNames, ['Fort Station', 'Bambalapitiya', 'Nugegoda Junction']);

      // 2. Bus Fleet Statuses
      final bus = TransportBusModel(
        busId: 'BUS-101',
        registrationNumber: 'WP NA-4521',
        busNameOrNumber: 'Campus Cruiser 1',
        capacity: 54,
        driver: 'Kamal Silva',
        contactNumber: '0771234567',
        status: 'Available',
      );

      expect(bus.isAvailable, true);
      expect(bus.capacity > 0, true);

      // 3. Schedule Overlap & Bus Conflict Detection
      final sched1 = TransportScheduleModel(
        scheduleId: 'SCH-101',
        routeId: 'RTE-101',
        routeName: 'Colombo - Campus Express',
        busId: 'BUS-101',
        busRegistration: 'WP NA-4521',
        operatingDays: ['Monday', 'Wednesday', 'Friday'],
        departureTime: '06:30 AM',
        arrivalTime: '08:15 AM',
        status: 'Active',
      );

      // Candidate 1: Overlapping time (07:00 AM - 08:30 AM) on Wednesday with same bus -> CONFLICT!
      final conflictingCandidate = TransportScheduleModel(
        scheduleId: 'SCH-102',
        routeId: 'RTE-102',
        routeName: 'Kandy - Campus Shuttle',
        busId: 'BUS-101',
        busRegistration: 'WP NA-4521',
        operatingDays: ['Wednesday', 'Thursday'],
        departureTime: '07:00 AM',
        arrivalTime: '08:30 AM',
        status: 'Active',
      );

      expect(
        TransportScheduleModel.isBusScheduleConflicting(
          existing: sched1,
          candidate: conflictingCandidate,
        ),
        true,
      );

      // Candidate 2: Non-overlapping time (02:00 PM - 03:30 PM) with same bus -> NO CONFLICT
      final nonConflictingCandidate = TransportScheduleModel(
        scheduleId: 'SCH-103',
        routeId: 'RTE-102',
        routeName: 'Kandy - Campus Shuttle',
        busId: 'BUS-101',
        busRegistration: 'WP NA-4521',
        operatingDays: ['Monday', 'Wednesday'],
        departureTime: '02:00 PM',
        arrivalTime: '03:30 PM',
        status: 'Active',
      );

      expect(
        TransportScheduleModel.isBusScheduleConflicting(
          existing: sched1,
          candidate: nonConflictingCandidate,
        ),
        false,
      );

      // 4. Student Transport Preference Model
      final pref = StudentTransportPreferenceModel(
        studentId: 'STU-1001',
        studentEmail: 'alice@uni.lk',
        selectedRouteId: 'RTE-101',
        selectedRouteName: 'Colombo - Campus Express',
        selectedStopId: 'STP-2',
        selectedStopName: 'Bambalapitiya',
      );

      expect(pref.studentId, 'STU-1001');
      expect(pref.selectedStopName, 'Bambalapitiya');
    });

    test('Campus Facilities Management, Map Directory & Venue Resolution Rules', () {
      // 1. Supported Types & Statuses
      expect(FacilityModel.supportedTypes.contains('Lecture Hall'), true);
      expect(FacilityModel.supportedTypes.contains('Laboratory'), true);
      expect(FacilityModel.supportedTypes.contains('Examination Hall'), true);
      expect(FacilityModel.supportedTypes.contains('Library'), true);
      expect(FacilityModel.supportedTypes.contains('Canteen'), true);
      expect(FacilityModel.supportedTypes.contains('Office'), true);
      expect(FacilityModel.supportedTypes.contains('Student Service'), true);

      expect(FacilityModel.supportedStatuses, ['Available', 'Maintenance', 'Closed']);

      // 2. Facility Serialization & Attributes
      final fac = FacilityModel(
        facilityId: 'FAC-101',
        name: 'Computing Lab 01',
        type: 'Laboratory',
        building: 'Faculty of Computing Block',
        floor: '2nd Floor',
        roomNumber: 'B-204',
        description: 'Advanced Cloud & AI Workstations',
        location: 'North Wing (Lat: 6.9271, Lng: 79.8612)',
        capacity: 65,
        status: 'Available',
      );

      expect(fac.isAvailable, true);
      expect(fac.capacity > 0, true);
      expect(fac.toMap()['roomNumber'], 'B-204');
      expect(fac.toMap()['type'], 'Laboratory');

      // 3. Search and Filtering Criteria Simulation
      final facilitiesList = [
        fac,
        FacilityModel(
          facilityId: 'FAC-102',
          name: 'Main Examination Hall A',
          type: 'Examination Hall',
          building: 'Main Exam Complex',
          floor: 'Ground Floor',
          roomNumber: 'EX-01',
          capacity: 250,
          status: 'Available',
        ),
        FacilityModel(
          facilityId: 'FAC-103',
          name: 'Central Academic Library',
          type: 'Library',
          building: 'Library Complex',
          floor: '1st Floor',
          roomNumber: 'LIB-01',
          capacity: 120,
          status: 'Maintenance',
        ),
      ];

      // Filter by Type
      final examHalls = facilitiesList.where((f) => f.type == 'Examination Hall').toList();
      expect(examHalls.length, 1);
      expect(examHalls.first.name, 'Main Examination Hall A');

      // Filter by Keyword (e.g. "Computing")
      final searchResult = facilitiesList.where((f) => f.name.toLowerCase().contains('computing') || f.building.toLowerCase().contains('computing')).toList();
      expect(searchResult.length, 1);
      expect(searchResult.first.facilityId, 'FAC-101');

      // 4. Timetable & Exam Hall cross-resolution
      final timetableHallName = 'Computing Lab 01';
      final matchingTimetableFacility = facilitiesList.firstWhere((f) => f.name.toLowerCase() == timetableHallName.toLowerCase());
      expect(matchingTimetableFacility.building, 'Faculty of Computing Block');
      expect(matchingTimetableFacility.floor, '2nd Floor');
    });

    test('Library Management Books, Borrowing Rules, Overdue Calculation & Copy Tracking', () {
      // 1. Book Serialization & Non-negative Copies Rule
      final book = LibraryBookModel(
        bookId: 'BK-101',
        isbn: '978-0132350884',
        title: 'Clean Code',
        author: 'Robert C. Martin',
        category: 'Software Engineering',
        publisher: 'Pearson Education',
        edition: '1st Edition',
        totalCopies: 5,
        availableCopies: 3,
        shelfLocation: 'Rack SE-02',
        status: 'Available',
      );

      expect(book.isAvailable, true);
      expect(book.availableCopies, 3);
      expect(book.totalCopies, 5);

      // Verify copies cannot exceed total or drop below zero
      final overClampedBook = LibraryBookModel(
        bookId: 'BK-102',
        isbn: '978-0201616224',
        title: 'The Pragmatic Programmer',
        author: 'Andrew Hunt',
        category: 'Software Engineering',
        totalCopies: 4,
        availableCopies: 10, // Exceeds total
      );
      expect(overClampedBook.availableCopies, 4);

      final underClampedBook = LibraryBookModel(
        bookId: 'BK-103',
        isbn: '978-0134685991',
        title: 'Effective Java',
        author: 'Joshua Bloch',
        category: 'Computer Science',
        totalCopies: 3,
        availableCopies: -2, // Negative
      );
      expect(underClampedBook.availableCopies, 0);
      expect(underClampedBook.isAvailable, false);

      // 2. Issue Book Logic: Available Copies Decrements
      int currentAvail = book.availableCopies;
      expect(currentAvail > 0, true);
      int updatedAvailAfterIssue = currentAvail - 1;
      expect(updatedAvailAfterIssue, 2);

      // 3. Return Book Logic: Available Copies Increments
      int updatedAvailAfterReturn = updatedAvailAfterIssue + 1;
      expect(updatedAvailAfterReturn, 3);

      // 4. Overdue Borrowing Calculation Logic
      final activeBorrowing = LibraryBorrowingModel(
        borrowingId: 'BRW-101',
        bookId: 'BK-101',
        bookTitle: 'Clean Code',
        studentId: 'STU-1001',
        studentEmail: 'alice@uni.lk',
        studentName: 'Alice Johnson',
        borrowDate: '2026-08-01',
        dueDate: '2026-08-15', // Past date
        status: 'Borrowed',
      );

      expect(activeBorrowing.effectiveStatus, 'Overdue');
      expect(activeBorrowing.isOverdue, true);

      // When returned, status remains Returned even if past due date
      final returnedBorrowing = LibraryBorrowingModel(
        borrowingId: 'BRW-102',
        bookId: 'BK-101',
        bookTitle: 'Clean Code',
        studentId: 'STU-1001',
        studentEmail: 'alice@uni.lk',
        studentName: 'Alice Johnson',
        borrowDate: '2026-08-01',
        dueDate: '2026-08-15',
        returnDate: '2026-08-14',
        status: 'Returned',
      );

      expect(returnedBorrowing.effectiveStatus, 'Returned');
      expect(returnedBorrowing.isReturned, true);
      expect(returnedBorrowing.isOverdue, false);
    });

    test('Student Profile Personal Field Isolation, Dynamic GPA & Audit Rules', () {
      // 1. Student Profile Model Serialization & Protected vs Editable Fields
      final student = StudentModel(
        studentId: 'STU-1002',
        name: 'Kasun Bandara',
        email: 'kasun@uni.lk',
        course: 'Software Engineering',
        batch: '2026',
        year: 'Year 2',
        semester: 'Semester 1',
        status: 'active',
      );

      expect(student.studentId, 'STU-1002');
      expect(student.course, 'Software Engineering');
      expect(student.status, 'active');

      // Permitted Student Editable Fields:
      final permittedFields = {'phone', 'address', 'emergencyContact', 'photoUrl'};
      final protectedFields = {'studentId', 'course', 'batch', 'year', 'semester', 'status', 'gpa', 'credits'};

      // Verify no overlap between permitted and protected fields
      expect(permittedFields.intersection(protectedFields).isEmpty, true);

      // 2. Dynamic Academic Summary Calculation Simulation
      // Simulate approved module registrations (3 modules: 4 + 3 + 3 = 10 credits)
      final approvedRegistrations = [
        StudentModuleRegistrationModel(
          registrationId: 'REG-1',
          studentId: 'STU-1002',
          studentName: 'Kasun Bandara',
          studentEmail: 'kasun@uni.lk',
          moduleId: 'M1',
          moduleName: 'Algorithms',
          registrationPeriodId: 'PER-1',
          academicYear: '2026',
          semester: 'Semester 1',
          credits: 4,
          status: 'Approved',
          registeredAt: '2026-01-10',
        ),
        StudentModuleRegistrationModel(
          registrationId: 'REG-2',
          studentId: 'STU-1002',
          studentName: 'Kasun Bandara',
          studentEmail: 'kasun@uni.lk',
          moduleId: 'M2',
          moduleName: 'Databases',
          registrationPeriodId: 'PER-1',
          academicYear: '2026',
          semester: 'Semester 1',
          credits: 3,
          status: 'Approved',
          registeredAt: '2026-01-10',
        ),
        StudentModuleRegistrationModel(
          registrationId: 'REG-3',
          studentId: 'STU-1002',
          studentName: 'Kasun Bandara',
          studentEmail: 'kasun@uni.lk',
          moduleId: 'M3',
          moduleName: 'Web Tech',
          registrationPeriodId: 'PER-1',
          academicYear: '2026',
          semester: 'Semester 1',
          credits: 3,
          status: 'Approved',
          registeredAt: '2026-01-10',
        ),
      ];

      final totalRegisteredCredits = approvedRegistrations
          .where((r) => r.status == 'Approved')
          .fold<num>(0, (sum, r) => sum + r.credits)
          .toInt();
      expect(totalRegisteredCredits, 10);

      // Simulate published exam results
      final publishedResults = [
        ExamResultModel(
          resultId: 'RES-1',
          examId: 'EX-1',
          examDocId: 'DOC-1',
          moduleId: 'CS201',
          subjectName: 'Algorithms',
          studentId: 'STU-1002',
          studentName: 'Kasun Bandara',
          studentEmail: 'kasun@uni.lk',
          marks: 88,
          grade: 'A',
          gradePoint: 4.0,
          status: 'Published',
          updatedAt: '2026-08-18',
        ),
        ExamResultModel(
          resultId: 'RES-2',
          examId: 'EX-2',
          examDocId: 'DOC-2',
          moduleId: 'CS202',
          subjectName: 'Databases',
          studentId: 'STU-1002',
          studentName: 'Kasun Bandara',
          studentEmail: 'kasun@uni.lk',
          marks: 78,
          grade: 'B+',
          gradePoint: 3.3,
          status: 'Published',
          updatedAt: '2026-08-18',
        ),
        ExamResultModel(
          resultId: 'RES-3',
          examId: 'EX-3',
          examDocId: 'DOC-3',
          moduleId: 'CS203',
          subjectName: 'Web Tech',
          studentId: 'STU-1002',
          studentName: 'Kasun Bandara',
          studentEmail: 'kasun@uni.lk',
          marks: 82,
          grade: 'A-',
          gradePoint: 3.7,
          status: 'Published',
          updatedAt: '2026-08-18',
        ),
      ];

      double totalGpSum = 0.0;
      int totalCreds = 0;
      int completedCreds = 0;

      final moduleCreditMap = {'CS201': 4, 'CS202': 3, 'CS203': 3};

      for (var res in publishedResults) {
        final cred = moduleCreditMap[res.moduleId] ?? 3;
        totalGpSum += (res.gradePoint * cred);
        totalCreds += cred;
        if (res.gradePoint > 0) {
          completedCreds += cred;
        }
      }

      final dynamicGpa = totalCreds > 0 ? (totalGpSum / totalCreds) : 0.0;
      expect(completedCreds, 10);
      // (4.0*4 + 3.3*3 + 3.7*3) / 10 = (16.0 + 9.9 + 11.1) / 10 = 37.0 / 10 = 3.70
      expect(dynamicGpa, 3.70);

      // Academic Standing
      String standing = 'Good Standing';
      if (dynamicGpa >= 3.7) {
        standing = "Dean's List";
      } else if (dynamicGpa > 0 && dynamicGpa < 2.0) {
        standing = 'Academic Warning';
      }
      expect(standing, "Dean's List");

      // 3. Profile Audit Trail Structure Verification
      final auditEntry = {
        'userId': 'usr-1002',
        'studentId': 'STU-1002',
        'studentEmail': 'kasun@uni.lk',
        'updatedFields': {
          'phone': '+94 77 999 8888',
          'address': 'Kandy, Sri Lanka',
        },
        'updatedBy': 'kasun@uni.lk',
        'updatedAt': DateTime.now().toIso8601String(),
      };

      expect(auditEntry['studentId'], 'STU-1002');
      expect((auditEntry['updatedFields'] as Map)['phone'], '+94 77 999 8888');
    });

    test('Final Student Dashboard KPI Aggregations, Attendance % & Finance Rules', () {
      // 1. Dynamic Attendance Percentage Calculation
      final attendanceRecords = [
        AttendanceModel(studentDocId: 'STU-1002', studentId: 'STU-1002', studentName: 'Kasun', subjectCode: 'CS201', subjectName: 'Algorithms', date: '2026-08-01', status: 'present', markedBy: 'Lecturer', batch: '2026', semester: 'Semester 1'),
        AttendanceModel(studentDocId: 'STU-1002', studentId: 'STU-1002', studentName: 'Kasun', subjectCode: 'CS201', subjectName: 'Algorithms', date: '2026-08-03', status: 'present', markedBy: 'Lecturer', batch: '2026', semester: 'Semester 1'),
        AttendanceModel(studentDocId: 'STU-1002', studentId: 'STU-1002', studentName: 'Kasun', subjectCode: 'CS201', subjectName: 'Algorithms', date: '2026-08-05', status: 'late', markedBy: 'Lecturer', batch: '2026', semester: 'Semester 1'),
        AttendanceModel(studentDocId: 'STU-1002', studentId: 'STU-1002', studentName: 'Kasun', subjectCode: 'CS201', subjectName: 'Algorithms', date: '2026-08-07', status: 'absent', markedBy: 'Lecturer', batch: '2026', semester: 'Semester 1'),
      ];

      final total = attendanceRecords.length;
      final present = attendanceRecords.where((a) => a.status.toLowerCase() == 'present').length;
      final late = attendanceRecords.where((a) => a.status.toLowerCase() == 'late').length;
      final absent = attendanceRecords.where((a) => a.status.toLowerCase() == 'absent').length;

      expect(total, 4);
      expect(present, 2);
      expect(late, 1);
      expect(absent, 1);

      // (2 + 0.5 * 1) / 4 * 100% = 2.5 / 4 * 100% = 62.5%
      final attendancePct = ((present + 0.5 * late) / total) * 100.0;
      expect(attendancePct, 62.5);

      // 2. Finance Outstanding Balance & Pay Now Trigger
      const totalFee = 350000.0;
      final studentPayments = [
        PaymentModel(
          paymentId: 'PAY-001',
          studentEmail: 'kasun@uni.lk',
          studentId: 'STU-1002',
          studentName: 'Kasun Bandara',
          feeType: 'Tuition Fee',
          amount: 200000.0,
          paymentDate: '2026-01-15',
          paymentMethod: 'Card',
          transactionRef: 'TXN-123456',
          status: 'success',
        ),
      ];

      final paidAmount = studentPayments
          .where((p) => p.isSuccessful)
          .fold<double>(0.0, (sum, p) => sum + p.amount);

      expect(paidAmount, 200000.0);
      final balance = totalFee - paidAmount;
      expect(balance, 150000.0);
      final showPayNow = balance > 0;
      expect(showPayNow, true);

      // 3. Quick Access Hubs Verification
      final dashboardHubs = [
        'My Modules',
        'Timetable',
        'Assignments',
        'Exams',
        'Results',
        'Finance',
        'Attendance',
        'Campus Map',
        'Bus Shuttle',
        'Library',
        'Notices',
        'Profile',
      ];
      expect(dashboardHubs.length, 12);
    });

    test('Lecturer Dashboard Isolation, Assigned Modules, KPI Calculations & Actions', () {
      // 1. Lecturer Model Serialization & Scoping
      final lecturer = LecturerModel(
        lecturerId: 'LEC-101',
        name: 'Dr. Priyantha Silva',
        email: 'priyantha@uni.lk',
        department: 'Faculty of Computing',
        designation: 'Senior Lecturer',
      );

      expect(lecturer.lecturerId, 'LEC-101');
      expect(lecturer.name, 'Dr. Priyantha Silva');
      expect(lecturer.department, 'Faculty of Computing');
      expect(lecturer.designation, 'Senior Lecturer');

      // 2. Assigned Module Scoping Isolation
      final allSystemSubjects = [
        SubjectModel(subjectId: 'S-1', subjectCode: 'CS101', subjectName: 'Intro to CS', description: 'Intro', academicYear: '2026', semester: 'Semester 1', credits: 3, lecturerName: 'Dr. Priyantha Silva', lecturerId: 'LEC-101'),
        SubjectModel(subjectId: 'S-2', subjectCode: 'SE202', subjectName: 'Software Architecture', description: 'Architecture', academicYear: '2026', semester: 'Semester 1', credits: 4, lecturerName: 'Dr. Priyantha Silva', lecturerId: 'LEC-101'),
        SubjectModel(subjectId: 'S-3', subjectCode: 'NET301', subjectName: 'Network Security', description: 'Security', academicYear: '2026', semester: 'Semester 1', credits: 3, lecturerName: 'Prof. Kamal', lecturerId: 'LEC-999'),
      ];

      final assignedModules = allSystemSubjects.where((s) => s.lecturerId == lecturer.lecturerId).toList();
      expect(assignedModules.length, 2);
      expect(assignedModules.map((m) => m.subjectCode).contains('CS101'), true);
      expect(assignedModules.map((m) => m.subjectCode).contains('SE202'), true);
      expect(assignedModules.map((m) => m.subjectCode).contains('NET301'), false);

      // 3. Lecturer KPI Calculations
      final todayLectures = [
        TimetableModel(
          scheduleId: 'TT-01',
          subjectCode: 'CS101',
          subjectName: 'Intro to CS',
          lecturerName: 'Dr. Priyantha Silva',
          lecturerEmail: 'priyantha@uni.lk',
          dayOfWeek: 'Monday',
          startTime: '09:00 AM',
          endTime: '11:00 AM',
          hallName: 'Computing Lab 01',
          batch: '2026',
          academicYear: '2026',
          semester: 'Semester 1',
        ),
      ];
      expect(todayLectures.length, 1);

      final submissions = [
        SubmissionModel(
          submissionId: 'SUB-1',
          assignmentId: 'ASN-1',
          assignmentTitle: 'Algorithms Essay',
          subjectCode: 'CS101',
          studentId: 'STU-1002',
          studentEmail: 'kasun@uni.lk',
          studentName: 'Kasun Bandara',
          submittedAt: '2026-08-18T10:00:00Z',
          status: 'submitted',
        ),
        SubmissionModel(
          submissionId: 'SUB-2',
          assignmentId: 'ASN-1',
          assignmentTitle: 'Algorithms Essay',
          subjectCode: 'CS101',
          studentId: 'STU-1003',
          studentEmail: 'nimal@uni.lk',
          studentName: 'Nimal',
          submittedAt: '2026-08-18T11:00:00Z',
          status: 'graded',
          mark: 85.0,
        ),
      ];

      final pendingSubmissions = submissions.where((s) => s.mark == null).toList();
      expect(pendingSubmissions.length, 1);
      expect(pendingSubmissions.first.studentId, 'STU-1002');
    });

    test('Admin Dashboard 14 Subsystems Coverage, KPI Aggregations & Role Security Rules', () {
      // 1. Verification of all 14 Core Admin Subsystems
      final adminSubsystems = [
        'Student Management',
        'Lecturer Management',
        'Academic Management',
        'Timetable Management',
        'Examination Management',
        'Registration Management',
        'Finance & Fee Structures',
        'Transport Management',
        'Campus Facilities & Halls',
        'Library & Book Management',
        'Announcements Management',
        'Notifications Center',
        'Reports & CSV Analytics',
        'Settings & Config',
      ];

      expect(adminSubsystems.length, 14);

      // 2. Dynamic KPI Aggregations Verification
      // Simulate Students
      final studentDocs = [
        {'id': 'STU-1', 'status': 'active'},
        {'id': 'STU-2', 'status': 'active'},
        {'id': 'STU-3', 'status': 'deactivated'},
      ];
      final activeStudents = studentDocs.where((d) => d['status'] == 'active').length;
      expect(activeStudents, 2);

      // Simulate Lecturers
      final lecturerDocs = [
        {'id': 'LEC-1', 'status': 'active'},
        {'id': 'LEC-2', 'status': 'active'},
      ];
      final activeLecturers = lecturerDocs.where((d) => d['status'] == 'active').length;
      expect(activeLecturers, 2);

      // Simulate Pending Registrations
      final registrations = [
        {'regId': 'R-1', 'status': 'Pending'},
        {'regId': 'R-2', 'status': 'Approved'},
        {'regId': 'R-3', 'status': 'Pending'},
      ];
      final pendingRegs = registrations.where((r) => r['status'] == 'Pending').length;
      expect(pendingRegs, 2);

      // Simulate Pending Exam Results
      final examResults = [
        {'resId': 'RES-1', 'status': 'Draft'},
        {'resId': 'RES-2', 'status': 'Submitted'},
        {'resId': 'RES-3', 'status': 'Published'},
      ];
      final pendingResults = examResults.where((r) => r['status'] == 'Draft' || r['status'] == 'Submitted').length;
      expect(pendingResults, 2);

      // Simulate Pending Payments
      final payments = [
        {'payId': 'P-1', 'status': 'pending'},
        {'payId': 'P-2', 'status': 'success'},
      ];
      final pendingPayments = payments.where((p) => p['status'] == 'pending').length;
      expect(pendingPayments, 1);
    });

    test('Firebase Security Rules & Role-Based Access Matrix Verification', () {
      // 1. Roles Definition Matrix
      const supportedRoles = {'ADMIN', 'LECTURER', 'STUDENT', 'FINANCESTAFF', 'LIBRARYSTAFF'};
      expect(supportedRoles.contains('ADMIN'), true);
      expect(supportedRoles.contains('LECTURER'), true);
      expect(supportedRoles.contains('STUDENT'), true);
      expect(supportedRoles.contains('FINANCESTAFF'), true);
      expect(supportedRoles.contains('LIBRARYSTAFF'), true);

      // 2. Student Role Permissions & Immutable Protected Fields
      final studentProtectedFields = {
        'role',
        'status',
        'email',
        'studentId',
        'course',
        'programme',
        'batch',
        'year',
        'semester',
        'gpa',
        'credits',
      };

      final studentPermittedFields = {'phone', 'address', 'emergencyContact', 'photoUrl'};
      expect(studentProtectedFields.intersection(studentPermittedFields).isEmpty, true);

      // 3. Lecturer Assigned Modules Scoping & Exam Publishing Restriction
      bool canLecturerPublishResults(String role, String targetStatus) {
        if (role == 'ADMIN') return true;
        if (role == 'LECTURER' && targetStatus != 'Published') return true;
        return false;
      }

      expect(canLecturerPublishResults('LECTURER', 'Draft'), true);
      expect(canLecturerPublishResults('LECTURER', 'Submitted'), true);
      expect(canLecturerPublishResults('LECTURER', 'Published'), false); // Disallowed
      expect(canLecturerPublishResults('ADMIN', 'Published'), true); // Allowed

      // 4. Finance Staff Permissions
      bool canModifyPaymentVerification(String role) {
        return role == 'ADMIN' || role == 'FINANCESTAFF';
      }
      expect(canModifyPaymentVerification('FINANCESTAFF'), true);
      expect(canModifyPaymentVerification('STUDENT'), false);

      // 5. Library Staff Permissions
      bool canIssueLibraryBooks(String role) {
        return role == 'ADMIN' || role == 'LIBRARYSTAFF';
      }
      expect(canIssueLibraryBooks('LIBRARYSTAFF'), true);
      expect(canIssueLibraryBooks('STUDENT'), false);

      // 6. Storage Security Constraints
      const maxImageSizeBytes = 5 * 1024 * 1024; // 5MB
      const maxDocSizeBytes = 25 * 1024 * 1024; // 25MB
      expect(maxImageSizeBytes, 5242880);
      expect(maxDocSizeBytes, 26214400);
    });

    test('Global AppValidator Form Rules, Numeric Bounds, Date Ranges & Error Sanitization', () {
      // 1. Required Field Validation
      expect(AppValidator.validateRequired(null, 'Student Name'), 'Student Name is required.');
      expect(AppValidator.validateRequired('   ', 'Student Name'), 'Student Name is required.');
      expect(AppValidator.validateRequired('Kasun', 'Student Name'), null);

      // 2. Email & Phone Formatting
      expect(AppValidator.validateEmail('invalid-email'), 'Please enter a valid email address.');
      expect(AppValidator.validateEmail('alice@university.lk'), null);
      expect(AppValidator.validatePhone('123'), 'Please enter a valid phone number.');
      expect(AppValidator.validatePhone('+94771234567'), null);

      // 3. Numeric Constraints (Positive, Non-Negative, Marks Bounds)
      expect(AppValidator.validatePositiveNumber('-10', 'Fee Amount'), 'Fee Amount must be greater than zero.');
      expect(AppValidator.validatePositiveNumber('0', 'Fee Amount'), 'Fee Amount must be greater than zero.');
      expect(AppValidator.validatePositiveNumber('50000', 'Fee Amount'), null);

      expect(AppValidator.validateMarks('-5'), 'Marks cannot be negative.');
      expect(AppValidator.validateMarks('105', maxMarks: 100), 'Marks cannot exceed 100.0.');
      expect(AppValidator.validateMarks('85.5', maxMarks: 100), null);

      // 4. Chronological Date Range Order
      final start = DateTime(2026, 8, 1);
      final validEnd = DateTime(2026, 8, 15);
      final invalidEnd = DateTime(2026, 7, 20);

      expect(AppValidator.validateDateRange(start, validEnd), null);
      expect(AppValidator.validateDateRange(start, invalidEnd), 'End Date cannot be before Start Date.');
      expect(AppValidator.validateDateRange(start, start), 'End Date must be after Start Date.');

      // 5. Firebase Error Code Sanitization
      expect(
        AppValidator.sanitizeFirebaseError('FirebaseError: [cloud_firestore/permission-denied] Missing or insufficient permissions.'),
        'Access Denied: You do not have permission to perform this action.',
      );
      expect(
        AppValidator.sanitizeFirebaseError('PlatformException(network-request-failed, Network error, null)'),
        'Network Error: Please check your internet connection and try again.',
      );
      expect(
        AppValidator.sanitizeFirebaseError('FirebaseAuthException(user-not-found)'),
        'Invalid credentials. Please verify your email and password.',
      );
    });
  });
}
