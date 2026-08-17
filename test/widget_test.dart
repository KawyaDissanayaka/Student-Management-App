import 'package:flutter_test/flutter_test.dart';
import 'package:student_management_app/models/student_model.dart';
import 'package:student_management_app/models/assignment_model.dart';
import 'package:student_management_app/models/task_model.dart';
import 'package:student_management_app/models/announcement_model.dart';

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
    });
  });
}
