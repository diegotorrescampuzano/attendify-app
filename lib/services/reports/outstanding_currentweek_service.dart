import 'package:cloud_firestore/cloud_firestore.dart';

/// Service to fetch outstanding attendance for the current week.
class OutstandingCurrentWeekService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fetch all campuses.
  Future<List<Map<String, dynamic>>> fetchCampuses() async {
    print('[Service] Fetching campuses...');
    final snapshot = await _db.collection('campuses').get();
    final campuses = snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'] ?? doc.id,
      };
    }).toList();
    print('[Service] Loaded ${campuses.length} campuses');
    return campuses;
  }

  /// Fetch teachers assigned to a campus.
  Future<List<Map<String, dynamic>>> fetchTeachersForCampus(String campusId) async {
    print('[Service] Fetching teachers for campus $campusId...');
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
    print('[Service] Loaded ${teachers.length} teachers for campus $campusId');
    return teachers;
  }

  /// Fetch teacher lectures for the given campus and teacher IDs.
  Future<List<Map<String, dynamic>>> fetchTeacherLectures({
    required String campusId,
    required List<String> teacherIds,
  }) async {
    print('[Service] Fetching teacher lectures for campus $campusId and teachers $teacherIds...');
    final snapshot = await _db
        .collection('teacherLectures')
        .where('campus', isEqualTo: _db.doc('campuses/$campusId'))
        .get();

    // Lookup teacherId -> name
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
    print('[Service] Loaded ${lectures.length} teacher lectures');
    return lectures;
  }

  /// Fetch attendance records for the current week for selected teachers.
  /// Returns a Set of keys: "$teacherId|$day|$slot|$homeroomId|$subjectId"
  Future<Set<String>> fetchRegisteredAttendance({
    required String campusId,
    required List<String> teacherIds,
    required DateTime weekStart,
    required DateTime weekEnd,
  }) async {
    print('[Service] Fetching attendances for campus $campusId, teachers $teacherIds, week $weekStart - $weekEnd');
    if (teacherIds.isEmpty) return {};

    // Firestore whereIn limit: 10. Batch if needed.
    final List<List<String>> teacherIdBatches = [];
    for (var i = 0; i < teacherIds.length; i += 10) {
      teacherIdBatches.add(teacherIds.sublist(i, i + 10 > teacherIds.length ? teacherIds.length : i + 10));
    }

    final Set<String> registered = {};
    for (final batch in teacherIdBatches) {
      final snapshot = await _db
          .collection('attendances')
          .where('campusId', isEqualTo: campusId)
          .where('teacherId', whereIn: batch)
          .where('date', isGreaterThanOrEqualTo: weekStart)
          .where('date', isLessThanOrEqualTo: weekEnd)
          .get();

      print('[Service] Fetched ${snapshot.docs.length} attendance docs for batch $batch');
      for (final doc in snapshot.docs) {
        final data = doc.data();
        // Defensive: always use string for slot, lowercase for day, and string IDs
        final teacherId = data['teacherId']?.toString() ?? '';
        final day = (data['day']?.toString() ?? '').toLowerCase();
        final slot = data['slot']?.toString() ?? '';
        final homeroomId = data['homeroomId']?.toString() ??
            (data['homeroom'] is DocumentReference ? (data['homeroom'] as DocumentReference).id : '');
        final subjectId = data['subjectId']?.toString() ??
            (data['subject'] is DocumentReference ? (data['subject'] as DocumentReference).id : '');

        final key = '$teacherId|$day|$slot|$homeroomId|$subjectId';
        registered.add(key);
        print('[Service] Registered attendance key: $key');
      }
    }
    print('[Service] Total registered attendance keys: ${registered.length}');
    return registered;
  }

  /// Fetch subject and homeroom names for lookup.
  Future<Map<String, String>> fetchNames(String collection) async {
    print('[Service] Fetching $collection names...');
    final snapshot = await _db.collection(collection).get();
    final names = <String, String>{
      for (var doc in snapshot.docs)
        doc.id: (doc.data()['name'] ?? doc.id).toString()
    };
    print('[Service] Loaded ${names.length} $collection names');
    return names;
  }
}
