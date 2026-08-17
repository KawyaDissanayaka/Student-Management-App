import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/subject_model.dart';
import '../../models/material_model.dart';

class LecturerMaterialsView extends StatefulWidget {
  final SubjectModel subject;
  final String lecturerEmail;
  final String lecturerName;
  final String? lecturerId;

  const LecturerMaterialsView({
    super.key,
    required this.subject,
    required this.lecturerEmail,
    required this.lecturerName,
    this.lecturerId,
  });

  @override
  State<LecturerMaterialsView> createState() => _LecturerMaterialsViewState();
}

class _LecturerMaterialsViewState extends State<LecturerMaterialsView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _searchQuery = '';
  String _selectedFileType = 'All';
  String _selectedStatus = 'All';
  String _selectedWeek = 'All';

  final List<String> _fileTypes = ['All', 'PDF', 'PPTX', 'DOCX', 'ZIP', 'MP4'];
  final List<String> _statuses = ['All', 'active', 'inactive'];
  final List<String> _weeks = ['All', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'];

  void _showUploadEditMaterialDialog({MaterialModel? existingMaterial}) {
    final isEditing = existingMaterial != null;
    final titleController = TextEditingController(text: existingMaterial?.title ?? '');
    final topicController = TextEditingController(text: existingMaterial?.topic ?? 'Lecture Notes');
    final descController = TextEditingController(text: existingMaterial?.description ?? '');
    final weekController = TextEditingController(text: existingMaterial != null ? '${existingMaterial.weekNumber}' : '1');
    final dateController = TextEditingController(
      text: existingMaterial != null && existingMaterial.lectureDate.isNotEmpty
          ? existingMaterial.lectureDate
          : DateTime.now().toIso8601String().substring(0, 10),
    );

    String selectedFileType = existingMaterial?.fileType ?? 'PDF';
    String selectedStatus = existingMaterial?.status ?? 'active';
    String fileSizeStr = existingMaterial?.fileSize ?? '3.5 MB';
    String fileUrlStr = existingMaterial?.downloadUrl ?? 'https://university.edu/storage/${widget.subject.subjectCode}/lecture_${DateTime.now().millisecondsSinceEpoch}.pdf';
    bool isProcessing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(isEditing ? Icons.edit_note_rounded : Icons.cloud_upload_rounded, color: Colors.tealAccent),
                        const SizedBox(width: 8),
                        Text(
                          isEditing ? 'Edit Learning Material' : 'Upload Learning Material',
                          style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Subject: ${widget.subject.subjectCode} - ${widget.subject.subjectName}', style: const TextStyle(color: Colors.amberAccent, fontSize: 12)),
                const SizedBox(height: 16),

                // Material Title
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Lecture / Slide Title *',
                    labelStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),

                // Topic / Chapter
                TextField(
                  controller: topicController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Topic / Chapter Title *',
                    labelStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),

                // Week Number & File Type
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: weekController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Week Number *',
                          labelStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedFileType,
                        dropdownColor: const Color(0xFF0F172A),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'File Type',
                          labelStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: ['PDF', 'PPTX', 'DOCX', 'ZIP', 'MP4'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() {
                              selectedFileType = val;
                              fileSizeStr = val == 'MP4' ? '45.0 MB' : (val == 'ZIP' ? '12.4 MB' : '3.8 MB');
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Lecture Date Picker field
                TextField(
                  controller: dateController,
                  readOnly: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Lecture Date (YYYY-MM-DD)',
                    labelStyle: const TextStyle(color: Colors.grey),
                    suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18, color: Colors.tealAccent),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.tryParse(dateController.text) ?? DateTime.now(),
                      firstDate: DateTime(2025, 1, 1),
                      lastDate: DateTime(2030, 12, 31),
                      builder: (context, child) => Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: const ColorScheme.dark(primary: Colors.tealAccent, onPrimary: Colors.black, surface: Color(0xFF1E293B)),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      dateController.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                    }
                  },
                ),
                const SizedBox(height: 12),

                // Description
                TextField(
                  controller: descController,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Notes / Description for Students',
                    labelStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),

                // Status Dropdown
                DropdownButtonFormField<String>(
                  initialValue: selectedStatus,
                  dropdownColor: const Color(0xFF0F172A),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Visibility Status',
                    labelStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Active (Visible to Enrolled Students)', style: TextStyle(color: Colors.greenAccent))),
                    DropdownMenuItem(value: 'inactive', child: Text('Inactive (Hidden from Students)', style: TextStyle(color: Colors.orangeAccent))),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedStatus = val);
                  },
                ),
                const SizedBox(height: 20),

                // File Attachment Preview Badge
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      Icon(
                        selectedFileType == 'PDF' ? Icons.picture_as_pdf_rounded : (selectedFileType == 'MP4' ? Icons.video_file_rounded : Icons.description_rounded),
                        color: Colors.tealAccent,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Validated Attachment ($selectedFileType)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            Text('Estimated Size: $fileSizeStr • Ready for Sync', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                      ),
                      const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 18),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isProcessing
                        ? null
                        : () async {
                            final title = titleController.text.trim();
                            final topic = topicController.text.trim();
                            if (title.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter a title for the material.'), backgroundColor: Colors.redAccent),
                              );
                              return;
                            }

                            setModalState(() => isProcessing = true);
                            final messenger = ScaffoldMessenger.of(context);
                            final nav = Navigator.of(ctx);

                            try {
                              final materialData = {
                                'materialId': existingMaterial?.materialId ?? 'MAT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                                'title': title,
                                'topic': topic.isNotEmpty ? topic : 'General Lecture Notes',
                                'description': descController.text.trim(),
                                'subjectCode': widget.subject.subjectCode,
                                'subjectName': widget.subject.subjectName,
                                'lecturerName': widget.lecturerName,
                                'lecturerId': widget.lecturerId ?? 'LEC-1001',
                                'fileType': selectedFileType,
                                'fileSize': fileSizeStr,
                                'downloadUrl': fileUrlStr,
                                'uploadedDate': DateTime.now().toIso8601String().substring(0, 10),
                                'lectureDate': dateController.text.trim(),
                                'weekNumber': int.tryParse(weekController.text.trim()) ?? 1,
                                'status': selectedStatus,
                              };

                              if (!isEditing) {
                                await _firestore.collection('materials').add(materialData);
                                messenger.showSnackBar(
                                  SnackBar(content: Text('Material "$title" uploaded and published!'), backgroundColor: Colors.green),
                                );
                              } else {
                                await _firestore.collection('materials').doc(existingMaterial.docId).update(materialData);
                                messenger.showSnackBar(
                                  SnackBar(content: Text('Material "$title" updated successfully!'), backgroundColor: Colors.green),
                                );
                              }

                              nav.pop();
                            } catch (e) {
                              setModalState(() => isProcessing = false);
                              messenger.showSnackBar(
                                SnackBar(content: Text('Operation failed: $e'), backgroundColor: Colors.redAccent),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: isProcessing
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Icon(isEditing ? Icons.save_rounded : Icons.cloud_upload_rounded, color: Colors.white),
                    label: Text(
                      isEditing ? 'Save Changes' : 'Publish Learning Material',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMaterialPreview(BuildContext context, MaterialModel material) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              material.fileType == 'PDF' ? Icons.picture_as_pdf_rounded : Icons.description_rounded,
              color: Colors.tealAccent,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                material.title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Topic: ${material.topic}', style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 4),
            Text('Subject: ${material.subjectCode} - ${material.subjectName}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 4),
            Text('Week: Week ${material.weekNumber} • Type: ${material.fileType} • Size: ${material.fileSize}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            if (material.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Divider(color: Colors.white10),
              const SizedBox(height: 6),
              Text(material.description, style: const TextStyle(color: Colors.grey, fontSize: 12, height: 1.3)),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: Colors.grey))),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Downloading "${material.title}" (${material.fileSize})...'), backgroundColor: Colors.teal),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            icon: const Icon(Icons.download_rounded, size: 16, color: Colors.white),
            label: const Text('Download File', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUploadEditMaterialDialog(),
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.cloud_upload_rounded, color: Colors.white),
        label: const Text('Upload Material', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1E293B),
            child: Column(
              children: [
                TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search material by title, topic or notes...',
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
                    children: [
                      // File Type Filter
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)),
                        child: DropdownButton<String>(
                          value: _selectedFileType,
                          dropdownColor: const Color(0xFF0F172A),
                          style: const TextStyle(color: Colors.tealAccent, fontSize: 12, fontWeight: FontWeight.bold),
                          underline: const SizedBox(),
                          items: _fileTypes.map((t) => DropdownMenuItem(value: t, child: Text(t == 'All' ? 'All Types' : t))).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedFileType = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Week Filter
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)),
                        child: DropdownButton<String>(
                          value: _selectedWeek,
                          dropdownColor: const Color(0xFF0F172A),
                          style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold),
                          underline: const SizedBox(),
                          items: _weeks.map((w) => DropdownMenuItem(value: w, child: Text(w == 'All' ? 'All Weeks' : 'Week $w'))).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedWeek = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Status Filter
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)),
                        child: DropdownButton<String>(
                          value: _selectedStatus,
                          dropdownColor: const Color(0xFF0F172A),
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          underline: const SizedBox(),
                          items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase()))).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedStatus = val);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Materials Stream List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('materials')
                  .where('subjectCode', isEqualTo: widget.subject.subjectCode)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error loading materials: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
                }

                final docs = snapshot.data?.docs ?? [];
                final materials = docs.map((d) => MaterialModel.fromFirestore(d)).where((m) {
                  final matchesSearch = m.title.toLowerCase().contains(_searchQuery) ||
                      m.topic.toLowerCase().contains(_searchQuery) ||
                      m.description.toLowerCase().contains(_searchQuery);

                  final matchesType = _selectedFileType == 'All' || m.fileType.toLowerCase() == _selectedFileType.toLowerCase();
                  final matchesStatus = _selectedStatus == 'All' || m.status.toLowerCase() == _selectedStatus.toLowerCase();
                  final matchesWeek = _selectedWeek == 'All' || '${m.weekNumber}' == _selectedWeek;

                  return matchesSearch && matchesType && matchesStatus && matchesWeek;
                }).toList();

                if (materials.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open_rounded, size: 56, color: Colors.grey.withAlpha(80)),
                        const SizedBox(height: 12),
                        const Text('No learning materials found matching filter.', style: TextStyle(color: Colors.grey, fontSize: 14)),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => _showUploadEditMaterialDialog(),
                          icon: const Icon(Icons.add_rounded, color: Colors.tealAccent),
                          label: const Text('Upload First Slide / PDF', style: TextStyle(color: Colors.tealAccent)),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: materials.length,
                  itemBuilder: (context, index) {
                    final m = materials[index];
                    final isActive = m.status.toLowerCase() == 'active';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isActive ? Colors.white10 : Colors.red.withAlpha(50)),
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
                                    decoration: BoxDecoration(color: Colors.teal.withAlpha(30), borderRadius: BorderRadius.circular(6)),
                                    child: Text('Week ${m.weekNumber}', style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: Colors.amber.withAlpha(30), borderRadius: BorderRadius.circular(6)),
                                    child: Text(m.fileType, style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isActive ? Colors.green.withAlpha(30) : Colors.red.withAlpha(30),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  m.status.toUpperCase(),
                                  style: TextStyle(color: isActive ? Colors.greenAccent : Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          Text(m.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text('Topic: ${m.topic}', style: const TextStyle(color: Colors.tealAccent, fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text('Uploaded: ${m.uploadedDate} • Size: ${m.fileSize}', style: const TextStyle(color: Colors.grey, fontSize: 11)),

                          if (m.description.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(m.description, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          ],

                          const SizedBox(height: 12),
                          const Divider(color: Colors.white10, height: 1),
                          const SizedBox(height: 6),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // View & Download
                              TextButton.icon(
                                onPressed: () => _showMaterialPreview(context, m),
                                icon: const Icon(Icons.visibility_rounded, size: 16, color: Colors.tealAccent),
                                label: const Text('Preview / Download', style: TextStyle(color: Colors.tealAccent, fontSize: 12)),
                              ),

                              Row(
                                children: [
                                  // Edit Button
                                  IconButton(
                                    icon: const Icon(Icons.edit_rounded, size: 18, color: Colors.amberAccent),
                                    tooltip: 'Edit Material',
                                    onPressed: () => _showUploadEditMaterialDialog(existingMaterial: m),
                                  ),

                                  // Toggle Active/Inactive Status
                                  IconButton(
                                    icon: Icon(
                                      isActive ? Icons.visibility_off_rounded : Icons.check_circle_outline_rounded,
                                      size: 18,
                                      color: isActive ? Colors.orangeAccent : Colors.greenAccent,
                                    ),
                                    tooltip: isActive ? 'Deactivate (Hide from Students)' : 'Activate (Make Visible)',
                                    onPressed: () async {
                                      if (m.docId != null) {
                                        final nextStatus = isActive ? 'inactive' : 'active';
                                        await _firestore.collection('materials').doc(m.docId).update({'status': nextStatus});
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Material marked as ${nextStatus.toUpperCase()}!'),
                                              backgroundColor: isActive ? Colors.orange : Colors.green,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
