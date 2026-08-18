import 'package:cloud_firestore/cloud_firestore.dart';

class MaterialModel {
  final String? docId;
  final String materialId;
  final String moduleId; // subjectCode
  final String subjectName;
  final String title;
  final String description;
  final String type; // 'Lecture Slide', 'PDF', 'Note', 'Document', 'Other'
  final String fileName;
  final String fileUrl; // downloadUrl
  final String fileSize; // e.g. '3.5 MB'
  final String uploadedBy; // lecturerEmail or lecturerId
  final String uploadedByName; // lecturerName
  final String uploadedAt; // ISO timestamp
  final String publishDate; // YYYY-MM-DD
  final String status; // 'Draft', 'Published', 'active', 'inactive'
  final int weekNumber;
  final String topic;

  MaterialModel({
    this.docId,
    required this.materialId,
    String? moduleId,
    String? subjectCode,
    this.subjectName = '',
    required this.title,
    this.description = '',
    String? type,
    String? fileType,
    this.fileName = '',
    String? fileUrl,
    String? downloadUrl,
    this.fileSize = '3.5 MB',
    String? uploadedBy,
    String? lecturerId,
    String? lecturerEmail,
    String? uploadedByName,
    String? lecturerName,
    String? uploadedAt,
    String? uploadedDate,
    String? publishDate,
    String? lectureDate,
    this.status = 'Published',
    this.weekNumber = 1,
    this.topic = 'General Lecture Notes',
  })  : moduleId = moduleId ?? subjectCode ?? '',
        type = type ?? fileType ?? 'Lecture Slide',
        fileUrl = fileUrl ?? downloadUrl ?? '',
        uploadedBy = uploadedBy ?? lecturerId ?? lecturerEmail ?? 'Lecturer',
        uploadedByName = uploadedByName ?? lecturerName ?? 'Lecturer',
        uploadedAt = uploadedAt ?? uploadedDate ?? DateTime.now().toIso8601String(),
        publishDate = publishDate ?? lectureDate ?? uploadedDate ?? '';

  // Backwards compatibility getters
  String get subjectCode => moduleId;
  String get downloadUrl => fileUrl;
  String get uploadedDate => publishDate.isNotEmpty ? publishDate : (uploadedAt.length >= 10 ? uploadedAt.substring(0, 10) : uploadedAt);
  String get lectureDate => uploadedDate;
  String get fileType => type;
  String get lecturerName => uploadedByName;
  String? get lecturerId => uploadedBy;

  bool get isPublished => status.toLowerCase() == 'published' || status.toLowerCase() == 'active';
  bool get isDraft => status.toLowerCase() == 'draft' || status.toLowerCase() == 'inactive';

  static const List<String> supportedTypes = [
    'Lecture Slide',
    'PDF',
    'Note',
    'Document',
    'Other',
  ];

  static const List<String> supportedExtensions = [
    'pdf',
    'pptx',
    'ppt',
    'docx',
    'doc',
    'zip',
    'txt',
    'mp4',
  ];

  /// Validate file type and extension
  static String? validateFileType(String fileName) {
    if (fileName.isEmpty) return 'File name cannot be empty';
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == fileName.length - 1) {
      return 'Invalid file extension. Allowed formats: ${supportedExtensions.join(", ")}';
    }
    final ext = fileName.substring(dotIndex + 1).toLowerCase();
    if (!supportedExtensions.contains(ext)) {
      return 'File extension ".$ext" is not supported. Allowed formats: ${supportedExtensions.join(", ")}';
    }
    return null;
  }

  /// Validate file size (max 25MB)
  static String? validateFileSize(double sizeInMB) {
    if (sizeInMB <= 0) return 'File cannot be 0 MB';
    if (sizeInMB > 25.0) {
      return 'File size exceeds maximum allowable limit of 25 MB';
    }
    return null;
  }

  factory MaterialModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final modId = data['moduleId'] ?? data['subjectCode'] ?? '';
    final url = data['fileUrl'] ?? data['downloadUrl'] ?? '';
    final rawType = data['type'] ?? data['fileType'] ?? 'Lecture Slide';
    final rawStatus = data['status'] ?? 'Published';

    return MaterialModel(
      docId: doc.id,
      materialId: data['materialId'] ?? doc.id,
      moduleId: modId,
      subjectName: data['subjectName'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: rawType,
      fileName: data['fileName'] ?? '${data['title'] ?? "file"}.pdf',
      fileUrl: url,
      fileSize: data['fileSize'] ?? '3.5 MB',
      uploadedBy: data['uploadedBy'] ?? data['lecturerId'] ?? data['lecturerEmail'] ?? 'Lecturer',
      uploadedByName: data['uploadedByName'] ?? data['lecturerName'] ?? 'Lecturer',
      uploadedAt: data['uploadedAt'] ?? data['uploadedDate'] ?? DateTime.now().toIso8601String(),
      publishDate: data['publishDate'] ?? data['lectureDate'] ?? data['uploadedDate'] ?? '',
      status: rawStatus,
      weekNumber: (data['weekNumber'] as num?)?.toInt() ?? 1,
      topic: data['topic'] ?? 'General Lecture Notes',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'materialId': materialId,
      'moduleId': moduleId,
      'subjectCode': moduleId,
      'subjectName': subjectName,
      'title': title,
      'description': description,
      'type': type,
      'fileType': type,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'downloadUrl': fileUrl,
      'fileSize': fileSize,
      'uploadedBy': uploadedBy,
      'uploadedByName': uploadedByName,
      'lecturerName': uploadedByName,
      'lecturerId': uploadedBy,
      'uploadedAt': uploadedAt,
      'publishDate': publishDate,
      'lectureDate': publishDate,
      'uploadedDate': publishDate,
      'status': status,
      'weekNumber': weekNumber,
      'topic': topic,
    };
  }
}
