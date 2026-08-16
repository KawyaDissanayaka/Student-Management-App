import 'package:flutter/material.dart';
import '../../models/lecturer_model.dart';
import '../../services/lecturer_service.dart';
import 'add_lecturer_screen.dart';

class LecturersListScreen extends StatefulWidget {
  const LecturersListScreen({super.key});

  @override
  State<LecturersListScreen> createState() => _LecturersListScreenState();
}

class _LecturersListScreenState extends State<LecturersListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final LecturerService _lecturerService = LecturerService();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text(
          'Lecturers Management',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.amber[800],
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Lecturer', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddLecturerScreen()),
          );
        },
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by Name, Email, or Lecturer ID...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.amberAccent),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim().toLowerCase();
                });
              },
            ),
          ),

          // Live Lecturer List Stream
          Expanded(
            child: StreamBuilder<List<LecturerModel>>(
              stream: _lecturerService.getLecturersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.amberAccent),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading lecturers: ${snapshot.error}',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  );
                }

                final lecturers = snapshot.data ?? [];

                final filteredLecturers = lecturers.where((l) {
                  final q = _searchQuery;
                  return l.name.toLowerCase().contains(q) ||
                      l.email.toLowerCase().contains(q) ||
                      l.lecturerId.toLowerCase().contains(q) ||
                      l.department.toLowerCase().contains(q);
                }).toList();

                if (filteredLecturers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.school_outlined, size: 64, color: Colors.grey[600]),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No lecturers added yet'
                              : 'No lecturers matching "$_searchQuery"',
                          style: const TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AddLecturerScreen()),
                            );
                          },
                          icon: const Icon(Icons.person_add_rounded, color: Colors.black),
                          label: const Text('Add First Lecturer', style: TextStyle(color: Colors.black)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  itemCount: filteredLecturers.length,
                  itemBuilder: (context, index) {
                    final lecturer = filteredLecturers[index];
                    return _buildLecturerCard(context, lecturer);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLecturerCard(BuildContext context, LecturerModel lecturer) {
    final isActive = lecturer.status.toLowerCase() == 'active';

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.amber.withAlpha(40),
          child: Text(
            lecturer.name.isNotEmpty ? lecturer.name[0].toUpperCase() : 'L',
            style: const TextStyle(
              color: Colors.amberAccent,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                lecturer.name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isActive ? Colors.green.withAlpha(50) : Colors.red.withAlpha(50),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: isActive ? Colors.greenAccent : Colors.redAccent),
              ),
              child: Text(
                isActive ? 'ACTIVE' : 'INACTIVE',
                style: TextStyle(
                  color: isActive ? Colors.greenAccent : Colors.redAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${lecturer.lecturerId} • ${lecturer.department}',
              style: const TextStyle(color: Colors.amberAccent, fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              lecturer.email,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        onTap: () => _showLecturerDetails(context, lecturer),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.indigoAccent),
              tooltip: 'Edit Details',
              onPressed: () => _showEditDialog(context, lecturer),
            ),
            IconButton(
              icon: Icon(
                isActive ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
                color: isActive ? Colors.greenAccent : Colors.grey,
                size: 32,
              ),
              tooltip: isActive ? 'Deactivate Lecturer' : 'Activate Lecturer',
              onPressed: () async {
                if (lecturer.docId != null) {
                  await _lecturerService.toggleLecturerStatus(lecturer.docId!, lecturer.status);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Lecturer "${lecturer.name}" status updated to ${isActive ? 'INACTIVE' : 'ACTIVE'}',
                        ),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLecturerDetails(BuildContext context, LecturerModel lecturer) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.badge_rounded, color: Colors.amberAccent, size: 28),
                const SizedBox(width: 12),
                Text(
                  lecturer.name,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 24),
            _detailRow('Lecturer ID', lecturer.lecturerId),
            _detailRow('Email', lecturer.email),
            _detailRow('Department', lecturer.department),
            _detailRow('Status', lecturer.status.toUpperCase()),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, LecturerModel lecturer) {
    final nameCtrl = TextEditingController(text: lecturer.name);
    final emailCtrl = TextEditingController(text: lecturer.email);
    final deptCtrl = TextEditingController(text: lecturer.department);
    String statusVal = lecturer.status;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('Edit Lecturer Details', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: Colors.grey)),
                ),
                TextField(
                  controller: emailCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Email', labelStyle: TextStyle(color: Colors.grey)),
                ),
                TextField(
                  controller: deptCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Department', labelStyle: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: statusVal.toLowerCase(),
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Status', labelStyle: TextStyle(color: Colors.grey)),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => statusVal = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.pop(ctx),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent),
              child: const Text('Save Changes', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              onPressed: () async {
                Navigator.pop(ctx);
                final updated = LecturerModel(
                  docId: lecturer.docId,
                  lecturerId: lecturer.lecturerId,
                  name: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  department: deptCtrl.text.trim(),
                  status: statusVal,
                );
                await _lecturerService.updateLecturer(updated);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lecturer details updated!')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
