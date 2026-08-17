import 'package:cloud_firestore/cloud_firestore.dart';

class MaterialModel {
  final String? docId;
  final String materialId;
  final String title;
  final String description;
  final String topic;
  final String subjectCode;
  final String subjectName;
  final String lecturerName;
  final String? lecturerId;
  final String fileType; // 'PDF', 'PPTX', 'DOCX', 'ZIP', 'MP4', 'LINK'
  final String fileSize; // '2.4 MB'
  final String downloadUrl;
  final String uploadedDate; // ISO string or YYYY-MM-DD
  final String lectureDate; // YYYY-MM-DD
  final int weekNumber;
  final String status; // 'active' | 'inactive'

  MaterialModel({
    this.docId,
    required this.materialId,
    required this.title,
    this.description = '',
    this.topic = 'General Lecture Notes',
    required this.subjectCode,
    required this.subjectName,
    required this.lecturerName,
    this.lecturerId,
    required this.fileType,
    required this.fileSize,
    required this.downloadUrl,
    required this.uploadedDate,
    this.lectureDate = '',
    this.weekNumber = 1,
    this.status = 'active',
  });

  factory MaterialModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MaterialModel(
      docId: doc.id,
      materialId: data['materialId'] ?? doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      topic: data['topic'] ?? 'General Lecture Notes',
      subjectCode: data['subjectCode'] ?? '',
      subjectName: data['subjectName'] ?? '',
      lecturerName: data['lecturerName'] ?? '',
      lecturerId: data['lecturerId'],
      fileType: data['fileType'] ?? 'PDF',
      fileSize: data['fileSize'] ?? '1.0 MB',
      downloadUrl: data['downloadUrl'] ?? '',
      uploadedDate: data['uploadedDate'] ?? '',
      lectureDate: data['lectureDate'] ?? (data['uploadedDate'] ?? ''),
      weekNumber: (data['weekNumber'] ?? 1) as int,
      status: data['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'materialId': materialId,
      'title': title,
      'description': description,
      'topic': topic,
      'subjectCode': subjectCode,
      'subjectName': subjectName,
      'lecturerName': lecturerName,
      'lecturerId': lecturerId,
      'fileType': fileType,
      'fileSize': fileSize,
      'downloadUrl': downloadUrl,
      'uploadedDate': uploadedDate,
      'lectureDate': lectureDate,
      'weekNumber': weekNumber,
      'status': status,
    };
  }
}
