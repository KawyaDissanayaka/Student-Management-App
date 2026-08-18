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
  String _selectedMaterialType = 'All';
  String _selectedStatus = 'All';
  String _selectedWeek = 'All';

  final List<String> _materialTypes = ['All', 'Lecture Slide', 'PDF', 'Note', 'Document', 'Other'];
  final List<String> _statuses = ['All', 'Published', 'Draft'];
  final List<String> _weeks = ['All', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'];

  void _showUploadEditMaterialDialog({MaterialModel? existingMaterial}) {
    final isEditing = existingMaterial != null;
    final titleController = TextEditingController(text: existingMaterial?.title ?? '');
    final descController = TextEditingController(text: existingMaterial?.description ?? '');
    final weekController = TextEditingController(text: existingMaterial != null ? '${existingMaterial.weekNumber}' : '1');
    final fileNameController = TextEditingController(
      text: existingMaterial?.fileName ?? 'Lecture_Slides_${widget.subject.subjectCode}_Week1.pdf',
    );
    final dateController = TextEditingController(
      text: existingMaterial != null && existingMaterial.publishDate.isNotEmpty
          ? existingMaterial.publishDate
          : DateTime.now().toIso8601String().substring(0, 10),
    );

    String selectedType = existingMaterial?.type ?? 'Lecture Slide';
    String selectedStatus = existingMaterial?.status ?? 'Published';
    String fileSizeStr = existingMaterial?.fileSize ?? '4.2 MB';
    double uploadProgress = 0.0;
    bool isUploading = false;
    String? validationError;

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
                          isEditing ? 'Edit Lecture Material' : 'Upload Lecture Material',
                          style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Assigned Module: ${widget.subject.subjectCode} - ${widget.subject.subjectName}', style: const TextStyle(color: Colors.tealAccent, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 14),

                if (validationError != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: Colors.red.withAlpha(30), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.redAccent)),
                    child: Text(validationError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),

                // 1. Material Title
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Material Title *',
                    labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 10),

                // 2. Material Type & Week
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedType,
                        dropdownColor: const Color(0xFF0F172A),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Material Type *',
                          labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: ['Lecture Slide', 'PDF', 'Note', 'Document', 'Other'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() {
                              selectedType = val;
                              if (val == 'Lecture Slide') {
                                fileNameController.text = 'Lecture_Slides_${widget.subject.subjectCode}_Week${weekController.text}.pptx';
                                fileSizeStr = '5.8 MB';
                              } else if (val == 'PDF' || val == 'Note') {
                                fileNameController.text = 'Lecture_Notes_${widget.subject.subjectCode}_Week${weekController.text}.pdf';
                                fileSizeStr = '3.2 MB';
                              } else {
                                fileNameController.text = 'Document_${widget.subject.subjectCode}.docx';
                                fileSizeStr = '1.9 MB';
                              }
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: weekController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Week No *',
                          labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 3. File Selection & Name
                TextField(
                  controller: fileNameController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'File Name (e.g. filename.pdf, .pptx) *',
                    labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                    prefixIcon: const Icon(Icons.attach_file_rounded, color: Colors.tealAccent, size: 18),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 10),

                // 4. Publish Date & Status
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: dateController,
                        readOnly: true,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Publish Date',
                          labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                          suffixIcon: const Icon(Icons.calendar_today_rounded, size: 16, color: Colors.tealAccent),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedStatus,
                        dropdownColor: const Color(0xFF0F172A),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Status *',
                          labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Published', child: Text('Published (Live)', style: TextStyle(color: Colors.greenAccent))),
                          DropdownMenuItem(value: 'Draft', child: Text('Draft (Hidden)', style: TextStyle(color: Colors.amberAccent))),
                        ],
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedStatus = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 5. Description / Syllabus Notes
                TextField(
                  controller: descController,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Material Notes / Description',
                    labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),

                // Storage Reference & File Info Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white10)),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_done_rounded, color: Colors.tealAccent, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Firebase Storage Path Reference', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                            Text('materials/${widget.subject.subjectCode}/${fileNameController.text.trim()} ($fileSizeStr)', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Upload Progress Bar
                if (isUploading) ...[
                  LinearProgressIndicator(value: uploadProgress > 0 ? uploadProgress : null, color: Colors.tealAccent, backgroundColor: Colors.white12),
                  const SizedBox(height: 8),
                  Center(child: Text('Uploading to Firebase Storage: ${(uploadProgress * 100).toInt()}%', style: const TextStyle(color: Colors.tealAccent, fontSize: 11))),
                  const SizedBox(height: 12),
                ],

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: isUploading
                        ? null
                        : () async {
                            final title = titleController.text.trim();
                            final fileName = fileNameController.text.trim();

                            if (title.isEmpty) {
                              setModalState(() => validationError = 'Material title is required.');
                              return;
                            }

                            final fileTypeError = MaterialModel.validateFileType(fileName);
                            if (fileTypeError != null) {
                              setModalState(() => validationError = fileTypeError);
                              return;
                            }

                            setModalState(() {
                              validationError = null;
                              isUploading = true;
                              uploadProgress = 0.3;
                            });

                            final messenger = ScaffoldMessenger.of(context);
                            final nav = Navigator.of(ctx);

                            // Simulate upload progress steps
                            await Future.delayed(const Duration(milliseconds: 300));
                            setModalState(() => uploadProgress = 0.7);
                            await Future.delayed(const Duration(milliseconds: 300));
                            setModalState(() => uploadProgress = 1.0);

                            try {
                              final materialId = existingMaterial?.materialId ?? 'MAT-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
                              final storageFileUrl = 'https://firebasestorage.googleapis.com/v0/b/studentapp/o/materials%2F${widget.subject.subjectCode}%2F$fileName?alt=media';

                              final data = MaterialModel(
                                materialId: materialId,
                                moduleId: widget.subject.subjectCode,
                                subjectName: widget.subject.subjectName,
                                title: title,
                                description: descController.text.trim(),
                                type: selectedType,
                                fileName: fileName,
                                fileUrl: storageFileUrl,
                                fileSize: fileSizeStr,
                                uploadedBy: widget.lecturerEmail,
                                uploadedByName: widget.lecturerName,
                                uploadedAt: existingMaterial?.uploadedAt ?? DateTime.now().toIso8601String(),
                                publishDate: dateController.text.trim(),
                                status: selectedStatus,
                                weekNumber: int.tryParse(weekController.text.trim()) ?? 1,
                                topic: 'Week ${weekController.text.trim()} - $title',
                              ).toMap();

                              if (!isEditing) {
                                await _firestore.collection('materials').add(data);
                                nav.pop();
                                messenger.showSnackBar(
                                  SnackBar(content: Text('Material "$title" uploaded ($selectedStatus)!'), backgroundColor: Colors.green),
                                );
                              } else {
                                await _firestore.collection('materials').doc(existingMaterial.docId).update(data);
                                nav.pop();
                                messenger.showSnackBar(
                                  SnackBar(content: Text('Material "$title" updated!'), backgroundColor: Colors.green),
                                );
                              }
                            } catch (e) {
                              setModalState(() {
                                isUploading = false;
                                validationError = 'Operation failed: $e';
                              });
                            }
                          },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    icon: Icon(isEditing ? Icons.save_rounded : Icons.cloud_upload_rounded, color: Colors.white, size: 16),
                    label: Text(
                      isEditing ? 'Save Changes' : 'Upload & Save Material',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
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

  void _showDeleteConfirmation(BuildContext context, MaterialModel material) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Delete Material', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete "${material.title}"?\nThis will remove the file from student access.',
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              final nav = Navigator.of(ctx);
              final messenger = ScaffoldMessenger.of(context);

              if (material.docId != null) {
                await _firestore.collection('materials').doc(material.docId).delete();
                nav.pop();
                messenger.showSnackBar(
                  SnackBar(content: Text('Material "${material.title}" deleted.'), backgroundColor: Colors.redAccent),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          // Filter Bar
          Container(
            padding: const EdgeInsets.all(14),
            color: const Color(0xFF1E293B),
            child: Column(
              children: [
                TextField(
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search material by title or notes...',
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 18),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                ),
                const SizedBox(height: 8),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Material Type Filter
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(6)),
                        child: DropdownButton<String>(
                          value: _selectedMaterialType,
                          dropdownColor: const Color(0xFF0F172A),
                          style: const TextStyle(color: Colors.tealAccent, fontSize: 11, fontWeight: FontWeight.bold),
                          underline: const SizedBox(),
                          items: _materialTypes.map((t) => DropdownMenuItem(value: t, child: Text(t == 'All' ? 'All Types' : t))).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedMaterialType = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Status Filter
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(6)),
                        child: DropdownButton<String>(
                          value: _selectedStatus,
                          dropdownColor: const Color(0xFF0F172A),
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          underline: const SizedBox(),
                          items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s == 'All' ? 'All Statuses' : s))).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedStatus = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Week Filter
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(6)),
                        child: DropdownButton<String>(
                          value: _selectedWeek,
                          dropdownColor: const Color(0xFF0F172A),
                          style: const TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold),
                          underline: const SizedBox(),
                          items: _weeks.map((w) => DropdownMenuItem(value: w, child: Text(w == 'All' ? 'All Weeks' : 'Week $w'))).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedWeek = val);
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
                  .where('moduleId', isEqualTo: widget.subject.subjectCode)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
                }

                final docs = snapshot.data?.docs ?? [];
                final materials = docs.map((d) => MaterialModel.fromFirestore(d)).where((m) {
                  final matchesSearch = m.title.toLowerCase().contains(_searchQuery) ||
                      m.description.toLowerCase().contains(_searchQuery);

                  final matchesType = _selectedMaterialType == 'All' || m.type.toLowerCase() == _selectedMaterialType.toLowerCase();
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
                        const Text('No lecture materials uploaded yet.', style: TextStyle(color: Colors.grey, fontSize: 14)),
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
                  padding: const EdgeInsets.all(14),
                  itemCount: materials.length,
                  itemBuilder: (context, index) {
                    final m = materials[index];
                    final isPub = m.isPublished;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isPub ? Colors.white10 : Colors.amber.withAlpha(50)),
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
                                    decoration: BoxDecoration(color: Colors.teal.withAlpha(30), borderRadius: BorderRadius.circular(4)),
                                    child: Text('Week ${m.weekNumber}', style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 10)),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: Colors.cyan.withAlpha(30), borderRadius: BorderRadius.circular(4)),
                                    child: Text(m.type, style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 10)),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isPub ? Colors.green.withAlpha(30) : Colors.amber.withAlpha(30),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isPub ? 'PUBLISHED' : 'DRAFT',
                                  style: TextStyle(color: isPub ? Colors.greenAccent : Colors.amberAccent, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          Text(m.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 3),
                          Text('File: ${m.fileName} • ${m.fileSize}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                          Text('Publish Date: ${m.publishDate.isNotEmpty ? m.publishDate : m.uploadedAt.substring(0, 10)}', style: const TextStyle(color: Colors.white60, fontSize: 11)),

                          if (m.description.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(m.description, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          ],

                          const SizedBox(height: 10),
                          const Divider(color: Colors.white10, height: 1),
                          const SizedBox(height: 6),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Uploaded by: ${m.uploadedByName.isNotEmpty ? m.uploadedByName : "Lecturer"}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                              Row(
                                children: [
                                  // Edit Button
                                  IconButton(
                                    icon: const Icon(Icons.edit_rounded, size: 16, color: Colors.amberAccent),
                                    tooltip: 'Edit Material',
                                    onPressed: () => _showUploadEditMaterialDialog(existingMaterial: m),
                                  ),
                                  // Delete Button
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                                    tooltip: 'Delete Material',
                                    onPressed: () => _showDeleteConfirmation(context, m),
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
