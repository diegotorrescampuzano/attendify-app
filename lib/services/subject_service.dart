import 'package:cloud_firestore/cloud_firestore.dart';

class SubjectService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Given a homeroom document reference and current weekday,
  /// fetch the list of subject references for that day,
  /// then fetch subject documents and return list of maps with name & description.
  static Future<List<Map<String, dynamic>>> getSubjectsForHomeroomByDay(
      DocumentReference homeroomRef, String weekday) async {
    try {
      final homeroomSnap = await homeroomRef.get();
      if (!homeroomSnap.exists) return [];

      final homeroomData = homeroomSnap.data() as Map<String, dynamic>;

      // The 'subjects' field is a map with keys as weekdays, each containing an array of subject refs
      final subjectsMap = homeroomData['subjects'] as Map<String, dynamic>?;

      if (subjectsMap == null || !subjectsMap.containsKey(weekday)) return [];

      final List<dynamic> subjectRefsDynamic = subjectsMap[weekday];

      // Filter to DocumentReference type
      final List<DocumentReference> subjectRefs = subjectRefsDynamic
          .whereType<DocumentReference>()
          .toList();

      if (subjectRefs.isEmpty) return [];

      // Fetch all subject documents in batch
      final subjectSnaps = await Future.wait(subjectRefs.map((ref) => ref.get()));

      // Map to list of subject data with id, name, description
      final subjects = subjectSnaps.where((snap) => snap.exists).map((snap) {
        final data = snap.data() as Map<String, dynamic>;
        return {
          'id': snap.id,
          'name': data['name'] ?? 'Sin nombre',
          'description': data['description'] ?? '',
        };
      }).toList();

      return subjects;
    } catch (e) {
      print('Error fetching subjects for homeroom: $e');
      return [];
    }
  }
}
