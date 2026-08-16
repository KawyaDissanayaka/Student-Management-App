import 'package:flutter/material.dart';
import '../../models/enrollment_model.dart';
import '../../services/enrollment_service.dart';
import 'enroll_student_screen.dart';

class EnrollmentsListScreen extends StatefulWidget {
  const EnrollmentsListScreen({super.key});

  @override
  State<EnrollmentsListScreen> createState() => _EnrollmentsListScreenState();
}

class _EnrollmentsListScreenState extends State<EnrollmentsListScreen> {
  final EnrollmentService _enrollmentService = EnrollmentService();
  String _searchQuery = '';
  String _selectedSubjectFilter = 'All';
  String _selectedSemesterFilter = 'All';
  String _selectedYearFilter = 'All';
  String _selectedStatusFilter = 'All';

  String _formatDate(String isoString, {bool time = false}) {
    if (isoString.isEmpty) return 'N/A';
    try {
      final parts = isoString.split('T');
      final datePart = parts.first;
      if (time && parts.length > 1) {
        final timePart = parts[1].split('.').first;
        final timeSub = timePart.substring(0, timePart.length > 5 ? 5 : timePart.length);
        return '$datePart $timeSub';
      }
      return datePart;
    } catch (_) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text(
          'Student Enrollments',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Enroll Student', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EnrollStudentScreen()),
          );
        },
      ),
      body: StreamBuilder<List<EnrollmentModel>>(
        stream: _enrollmentService.getEnrollmentsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.teal));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading enrollments: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
          }

          final enrollments = snapshot.data ?? [];

          // Dynamically extract unique subject names/codes, semesters, and years for filters
          final subjects = {'All', ...enrollments.map((e) => e.subjectName)};
          final semesters = {'All', ...enrollments.map((e) => e.semester)};
          final academicYears = {'All', ...enrollments.map((e) => e.academicYear)};
          final statuses = {'All', 'active', 'inactive'};

          // Filter & Search application
          final filteredEnrollments = enrollments.where((enrollment) {
            // Search Match
            final matchesSearch = enrollment.studentId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                enrollment.studentName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                enrollment.subjectName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                enrollment.subjectCode.toLowerCase().contains(_searchQuery.toLowerCase());

            // Subject Filter
            final matchesSubject = _selectedSubjectFilter == 'All' || enrollment.subjectName == _selectedSubjectFilter;

            // Semester Filter
            final matchesSemester = _selectedSemesterFilter == 'All' || enrollment.semester == _selectedSemesterFilter;

            // Academic Year Filter
            final matchesYear = _selectedYearFilter == 'All' || enrollment.academicYear == _selectedYearFilter;

            // Status Filter
            final matchesStatus = _selectedStatusFilter == 'All' || enrollment.status.toLowerCase() == _selectedStatusFilter.toLowerCase();

            return matchesSearch && matchesSubject && matchesSemester && matchesYear && matchesStatus;
          }).toList();

          return Column(
            children: [
              // Search & Filter Header Section
              Container(
                color: const Color(0xFF1E293B),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Search Field
                    TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search Student ID, Name, or Subject...',
                        hintStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: const Icon(Icons.search, color: Colors.tealAccent),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Filters Scrollable Row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterDropdown(
                            label: 'Subject',
                            value: _selectedSubjectFilter,
                            items: subjects.toList(),
                            onChanged: (val) => setState(() => _selectedSubjectFilter = val!),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterDropdown(
                            label: 'Semester',
                            value: _selectedSemesterFilter,
                            items: semesters.toList(),
                            onChanged: (val) => setState(() => _selectedSemesterFilter = val!),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterDropdown(
                            label: 'Year',
                            value: _selectedYearFilter,
                            items: academicYears.toList(),
                            onChanged: (val) => setState(() => _selectedYearFilter = val!),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterDropdown(
                            label: 'Status',
                            value: _selectedStatusFilter,
                            items: statuses.toList(),
                            onChanged: (val) => setState(() => _selectedStatusFilter = val!),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Enrollments List
              Expanded(
                child: filteredEnrollments.isEmpty
                    ? const Center(
                        child: Text(
                          'No enrollments found.',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredEnrollments.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final enrollment = filteredEnrollments[index];
                          return _buildEnrollmentCard(enrollment);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    // If selected value is no longer in items list (e.g. database changed), fall back to 'All'
    final currentValue = items.contains(value) ? value : 'All';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          dropdownColor: const Color(0xFF1E293B),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          onChanged: onChanged,
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text('$label: $item'),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEnrollmentCard(EnrollmentModel enrollment) {
    final bool isActive = enrollment.status.toLowerCase() == 'active';
    final formattedDate = _formatDate(enrollment.enrollmentDate);

    return Card(
      color: const Color(0xFF1E293B),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.white10),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showEnrollmentDetails(enrollment),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Student details & Status badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          enrollment.studentName,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ID: ${enrollment.studentId}',
                          style: const TextStyle(color: Colors.tealAccent, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green.withAlpha(40) : Colors.red.withAlpha(40),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isActive ? Colors.green : Colors.redAccent),
                    ),
                    child: Text(
                      enrollment.status.toUpperCase(),
                      style: TextStyle(
                        color: isActive ? Colors.greenAccent : Colors.redAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.white10, height: 20),
              // Subject Details Row
              Row(
                children: [
                  const Icon(Icons.menu_book_rounded, color: Colors.grey, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${enrollment.subjectName} (${enrollment.subjectCode})',
                      style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Metadata Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded, color: Colors.grey, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        enrollment.lecturerName,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                  Text(
                    '${enrollment.semester} • ${enrollment.academicYear} • $formattedDate',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEnrollmentDetails(EnrollmentModel enrollment) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bool isActive = enrollment.status.toLowerCase() == 'active';
            final formattedDate = _formatDate(enrollment.enrollmentDate, time: true);

            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title / Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Enrollment Details',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 24),

                  // Detail Fields
                  _buildDetailRow('Student Name', enrollment.studentName),
                  _buildDetailRow('Student ID', enrollment.studentId),
                  _buildDetailRow('Student Email', enrollment.studentEmail),
                  _buildDetailRow('Subject Name', enrollment.subjectName),
                  _buildDetailRow('Subject Code', enrollment.subjectCode),
                  _buildDetailRow('Lecturer', enrollment.lecturerName),
                  _buildDetailRow('Semester', enrollment.semester),
                  _buildDetailRow('Academic Year', enrollment.academicYear),
                  _buildDetailRow('Enrollment Date', formattedDate),
                  _buildDetailRow('Status', enrollment.status.toUpperCase(),
                      color: isActive ? Colors.greenAccent : Colors.redAccent),
                  const SizedBox(height: 24),

                  // Deactivate/Activate Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final newStatus = isActive ? 'inactive' : 'active';
                        await _enrollmentService.updateEnrollmentStatus(enrollment.docId!, newStatus);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Enrollment status updated to $newStatus successfully!'),
                              backgroundColor: Colors.teal,
                            ),
                          );
                        }
                      },
                      icon: Icon(
                        isActive ? Icons.cancel_outlined : Icons.check_circle_outline_rounded,
                        color: Colors.white,
                      ),
                      label: Text(
                        isActive ? 'Deactivate Enrollment' : 'Activate Enrollment',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isActive ? Colors.redAccent : Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(color: color ?? Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
