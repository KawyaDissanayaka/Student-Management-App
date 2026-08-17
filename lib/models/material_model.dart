import 'package:cloud_firestore/cloud_firestore.dart';

class MaterialModel {
  final String? docId;
  final String materialId;
  final String title;
  final String description;
  final String subjectCode;
  final String subjectName;
  final String lecturerName;
  final String fileType; // 'PDF', 'PPTX', 'DOCX', 'ZIP', 'LINK'
  final String fileSize; // '2.4 MB'
  final String downloadUrl;
  final String uploadedDate; // ISO string or YYYY-MM-DD
  final int weekNumber;

  MaterialModel({
    this.docId,
    required this.materialId,
    required this.title,
    this.description = '',
    required this.subjectCode,
    required this.subjectName,
    required this.lecturerName,
    required this.fileType,
    required this.fileSize,
    required this.downloadUrl,
    required this.uploadedDate,
    this.weekNumber = 1,
  });

  factory MaterialModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MaterialModel(
      docId: doc.id,
      materialId: data['materialId'] ?? doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      subjectCode: data['subjectCode'] ?? '',
      subjectName: data['subjectName'] ?? '',
      lecturerName: data['lecturerName'] ?? '',
      fileType: data['fileType'] ?? 'PDF',
      fileSize: data['fileSize'] ?? '1.0 MB',
      downloadUrl: data['downloadUrl'] ?? '',
      uploadedDate: data['uploadedDate'] ?? '',
      weekNumber: (data['weekNumber'] ?? 1) as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'materialId': materialId,
      'title': title,
      'description': description,
      'subjectCode': subjectCode,
      'subjectName': subjectName,
      'lecturerName': lecturerName,
      'fileType': fileType,
      'fileSize': fileSize,
      'downloadUrl': downloadUrl,
      'uploadedDate': uploadedDate,
      'weekNumber': weekNumber,
    };
  }
}
