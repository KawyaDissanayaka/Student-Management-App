import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/announcement_model.dart';

class AnnouncementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _announcementsRef =>
      _firestore.collection('announcements');

  /// Real-time stream of all announcements ordered by createdDate descending
  Stream<List<AnnouncementModel>> getAnnouncementsStream() {
    return _announcementsRef
        .orderBy('createdDate', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => AnnouncementModel.fromFirestore(d)).toList());
  }

  /// Real-time stream of published, non-expired announcements for a specific Student
  Stream<List<AnnouncementModel>> getStudentAnnouncementsStream(String studentEmail) {
    final cleanEmail = studentEmail.trim().toLowerCase();
    return _announcementsRef
        .where('status', isEqualTo: 'published')
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => AnnouncementModel.fromFirestore(d))
              .where((a) {
                // Not expired
                if (a.effectiveStatus != 'published') return false;
                // Check audience targeting
                if (a.audience == 'all_students' || a.audience == 'all_users') {
                  return true;
                }
                if (a.audience == 'specific_student' &&
                    (a.targetUserEmail?.trim().toLowerCase() == cleanEmail)) {
                  return true;
                }
                return false;
              })
              .toList();
          list.sort((a, b) => b.publishDate.compareTo(a.publishDate));
          return list;
        });
  }

  /// Real-time stream of published, non-expired announcements for a specific Lecturer
  Stream<List<AnnouncementModel>> getLecturerAnnouncementsStream(String lecturerEmail) {
    final cleanEmail = lecturerEmail.trim().toLowerCase();
    return _announcementsRef
        .where('status', isEqualTo: 'published')
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => AnnouncementModel.fromFirestore(d))
              .where((a) {
                // Not expired
                if (a.effectiveStatus != 'published') return false;
                // Check audience targeting
                if (a.audience == 'all_lecturers' || a.audience == 'all_users') {
                  return true;
                }
                if (a.audience == 'specific_lecturer' &&
                    (a.targetUserEmail?.trim().toLowerCase() == cleanEmail)) {
                  return true;
                }
                return false;
              })
              .toList();
          list.sort((a, b) => b.publishDate.compareTo(a.publishDate));
          return list;
        });
  }

  /// Auto-generate next Announcement ID (e.g. ANN-1001, ANN-1002)
  Future<String> generateNextAnnouncementId() async {
    try {
      final snap = await _announcementsRef.get();
      if (snap.docs.isEmpty) {
        return 'ANN-1001';
      }

      int maxNum = 1000;
      for (var doc in snap.docs) {
        final data = doc.data();
        final rawId = data['announcementId']?.toString() ?? '';
        final match = RegExp(r'ANN-(\d+)').firstMatch(rawId);
        if (match != null) {
          final numVal = int.tryParse(match.group(1) ?? '0') ?? 0;
          if (numVal > maxNum) {
            maxNum = numVal;
          }
        }
      }
      return 'ANN-${maxNum + 1}';
    } catch (e) {
      debugPrint('Error generating next announcementId: $e');
      return 'ANN-1001';
    }
  }

  /// Add a new announcement
  Future<void> addAnnouncement(AnnouncementModel announcement) async {
    try {
      final docRef = await _announcementsRef.add(announcement.toMap());
      debugPrint('Announcement added with ID: ${docRef.id}');
    } catch (e) {
      debugPrint('Error adding announcement: $e');
      throw Exception('Failed to create announcement: $e');
    }
  }

  /// Update an existing announcement
  Future<void> updateAnnouncement(AnnouncementModel announcement) async {
    if (announcement.docId == null) return;
    try {
      final data = announcement.toMap();
      // Record update timestamp if it was published
      if (announcement.status.toLowerCase() == 'published') {
        data['updatedAt'] = DateTime.now().toIso8601String();
      }
      await _announcementsRef.doc(announcement.docId).update(data);
      debugPrint('Announcement updated: ${announcement.docId}');
    } catch (e) {
      debugPrint('Error updating announcement: $e');
      throw Exception('Failed to update announcement: $e');
    }
  }

  /// Toggle publish status (Draft <-> Published)
  Future<void> togglePublishStatus(String docId, String currentStatus) async {
    try {
      final newStatus = currentStatus.toLowerCase() == 'published' ? 'draft' : 'published';
      final Map<String, dynamic> updateData = {'status': newStatus};
      if (newStatus == 'published') {
        updateData['publishDate'] = DateTime.now().toIso8601String().substring(0, 10);
      }
      await _announcementsRef.doc(docId).update(updateData);
      debugPrint('Announcement $docId status -> $newStatus');
    } catch (e) {
      debugPrint('Error toggling publish status: $e');
      throw Exception('Failed to update status: $e');
    }
  }

  /// Soft deactivate announcement
  Future<void> deactivateAnnouncement(String docId) async {
    try {
      await _announcementsRef.doc(docId).update({'status': 'deactivated'});
      debugPrint('Announcement $docId deactivated');
    } catch (e) {
      debugPrint('Error deactivating announcement: $e');
      throw Exception('Failed to deactivate announcement: $e');
    }
  }

  /// Reactivate announcement
  Future<void> reactivateAnnouncement(String docId) async {
    try {
      await _announcementsRef.doc(docId).update({'status': 'published'});
      debugPrint('Announcement $docId reactivated');
    } catch (e) {
      debugPrint('Error reactivating announcement: $e');
      throw Exception('Failed to reactivate announcement: $e');
    }
  }
}
