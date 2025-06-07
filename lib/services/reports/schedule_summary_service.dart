import 'package:cloud_firestore/cloud_firestore.dart';

/// Service to fetch campuses, teachers, and schedules for the schedule summary report.
class ScheduleSummaryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fetch all campuses.
  Future<List<Map<String, dynamic>>> fetchCampuses() async {
    print('Fetching campuses...');
    final snapshot = await _db.collection('campuses').get();
    final campuses = snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'] ?? doc.id,
      };
    }).toList();
    print('Loaded ${campuses.length} campuses');
    return campuses;
  }

  /// Fetch teachers assigned to a campus.
  Future<List<Map<String, dynamic>>> fetchTeachersForCampus(String campusId) async {
    print('Fetching teachers for campus $campusId...');
    final snapshot = await _db
        .collection('teachers')
        .where('assignedCampuses', arrayContainsAny: [
      _db.doc('campuses/$campusId'),
      campusId
    ])
        .get();
    final teachers = snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'] ?? doc.id,
      };
    }).toList();
    print('Loaded ${teachers.length} teachers for campus $campusId');
    return teachers;
  }

  /// Fetch teacher lectures for the given campus and teacher IDs.
  /// Relationships are by teacherId, but teacherName is returned for UI.
  Future<List<Map<String, dynamic>>> fetchTeacherLectures({
    required String campusId,
    required List<String> teacherIds,
  }) async {
    print('Fetching teacher lectures for campus $campusId and teachers $teacherIds...');
    final snapshot = await _db
        .collection('teacherLectures')
        .where('campus', isEqualTo: _db.doc('campuses/$campusId'))
        .get();

    // Build a lookup for teacherId -> name
    final teacherDocs = await _db.collection('teachers')
        .where(FieldPath.documentId, whereIn: teacherIds)
        .get();
    final teacherIdToName = {
      for (var doc in teacherDocs.docs) doc.id: doc.data()['name'] ?? doc.id
    };

    final lectures = <Map<String, dynamic>>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      String teacherId = '';
      if (data['teacher'] is DocumentReference) {
        teacherId = (data['teacher'] as DocumentReference).id;
      }
      if (!teacherIds.contains(teacherId)) continue;

      final teacherName = teacherIdToName[teacherId] ?? teacherId;

      lectures.add({
        'teacherId': teacherId,
        'teacherName': teacherName,
        'lectures': data['lectures'] ?? {},
      });
    }
    print('Loaded ${lectures.length} teacher lectures');
    return lectures;
  }

  /// Fetch subject and homeroom names for lookup.
  Future<Map<String, String>> fetchNames(String collection) async {
    print('Fetching $collection names...');
    final snapshot = await _db.collection(collection).get();
    final names = <String, String>{
      for (var doc in snapshot.docs)
        doc.id: (doc.data()['name'] ?? doc.id).toString()
    };
    print('Loaded ${names.length} $collection names');
    return names;
  }
}
