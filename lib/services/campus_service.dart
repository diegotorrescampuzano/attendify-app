import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for handling campus-related Firestore operations
class CampusService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Gets the campuses assigned to the teacher with given [refId]
  static Future<List<Map<String, dynamic>>> getCampusesForTeacher(String refId) async {
    final teacherDoc = await _db.collection('teachers').doc(refId).get();
    final assignedRefs = teacherDoc.data()?['assignedCampuses'] as List<dynamic>?;

    if (assignedRefs == null || assignedRefs.isEmpty) {
      return [];
    }

    final campuses = await Future.wait(assignedRefs.map((ref) async {
      final doc = await (ref as DocumentReference).get();
      return {
        'id': doc.id,
        'name': doc['name'],
        'description': doc['description'],
      };
    }));

    return campuses;
  }
}
