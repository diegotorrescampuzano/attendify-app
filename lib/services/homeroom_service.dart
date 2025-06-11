import 'package:cloud_firestore/cloud_firestore.dart';

/// Service to fetch homerooms enriched with lecture details and related metadata.
/// This version allows multiple entries for the same homeroom with different slots.
class HomeroomService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fetches homerooms with lecture details and additional metadata including names
  /// from the provided [lecturesForToday] map. Allows multiple entries for same homeroom
  /// with different slots.
  static Future<List<Map<String, dynamic>>> getHomeroomsWithLectureDetails(
      Map<String, dynamic> lecturesForToday) async {
    try {
      final homeroomMap = <String, Map<String, dynamic>>{};

      // Iterate over all lectures for today (key is weekday, value is list of lectures)
      for (final dayLectures in lecturesForToday.values) {
        if (dayLectures is List) {
          for (final lecture in dayLectures) {
            final homeroomRef = lecture['homeroom'];
            if (homeroomRef is DocumentReference) {
              final homeroomId = homeroomRef.id;
              final slotValue = lecture['slot'];
              final slotString = slotValue != null ? slotValue.toString() : '';

              // Create unique key using homeroom ID + slot combination
              final uniqueKey = '${homeroomId}_$slotString';

              if (!homeroomMap.containsKey(uniqueKey)) {
                final homeroomSnap = await homeroomRef.get();
                if (!homeroomSnap.exists) {
                  print('HomeroomService: Homeroom document $homeroomId does not exist (slot $slotString)');
                  continue;
                }
                final homeroomData = homeroomSnap.data() as Map<String, dynamic>;

                // Fetch subject details
                String subjectName = '';
                String? subjectId;
                final subjectRef = lecture['subject'];
                if (subjectRef is DocumentReference) {
                  subjectId = subjectRef.id;
                  final subjectSnap = await subjectRef.get();
                  if (subjectSnap.exists) {
                    final subjectData = subjectSnap.data() as Map<String, dynamic>;
                    subjectName = subjectData['name'] ?? '';
                  } else {
                    print('HomeroomService: Subject document ${subjectRef.id} does not exist');
                  }
                }

                // Extract references from homeroom document
                final campusRef = homeroomData['campusId'];
                final educationalLevelRef = homeroomData['educationalLevelId'];
                final gradeRef = homeroomData['gradeId'];
                final studentsList = homeroomData['students'] as List<dynamic>? ?? [];

                // Initialize names as empty strings
                String campusName = '';
                String educationalLevelName = '';
                String gradeName = '';

                // Parallel fetching of related documents
                final fetchOperations = <Future>[];

                if (campusRef is DocumentReference) {
                  fetchOperations.add(_db.collection('campuses').doc(campusRef.id).get()
                      .then((campusSnap) => campusName = campusSnap.data()?['name'] ?? ''));
                }

                // Fetch educational level name
                if (educationalLevelRef is DocumentReference) {
                  fetchOperations.add(_db.collection('educationalLevels').doc(educationalLevelRef.id).get()
                      .then((eduSnap) => educationalLevelName = eduSnap.data()?['name'] ?? ''));
                }

                // Fetch grade name
                if (gradeRef is DocumentReference) {
                  fetchOperations.add(_db.collection('grades').doc(gradeRef.id).get()
                      .then((gradeSnap) => gradeName = gradeSnap.data()?['name'] ?? ''));
                }

                // Wait for all parallel fetch operations
                await Future.wait(fetchOperations);

                homeroomMap[uniqueKey] = {
                  'id': homeroomId,
                  'name': homeroomData['name'] ?? 'Sin nombre',
                  'description': homeroomData['description'] ?? '',
                  'slot': slotString,
                  'subjectName': subjectName,
                  'subjectId': subjectId,
                  'time': lecture['time'] ?? '',
                  'ref': homeroomRef,
                  'campusId': campusRef is DocumentReference ? campusRef.id : null,
                  'campusName': campusName,
                  'educationalLevelId': educationalLevelRef is DocumentReference ? educationalLevelRef.id : null,
                  'educationalLevelName': educationalLevelName,
                  'gradeId': gradeRef is DocumentReference ? gradeRef.id : null,
                  'gradeName': gradeName,
                  'students': studentsList,
                };

                print('HomeroomService: Added homeroom $homeroomId (slot $slotString) '
                    'with subject "$subjectName", campus "$campusName"');
              }
            }
          }
        }
      }

      print('HomeroomService: Returning ${homeroomMap.length} homeroom entries');
      return homeroomMap.values.toList();
    } catch (e) {
      print('HomeroomService: Critical error fetching homerooms: ${e.toString()}');
      return [];
    }
  }

  /// Fetches students for a given homeroom reference [optimized version]
  static Future<List<Map<String, dynamic>>> getStudentsFromHomeroom(DocumentReference homeroomRef) async {
    try {
      final homeroomSnap = await homeroomRef.get();
      if (!homeroomSnap.exists) return [];
      final studentsRefs = (homeroomSnap.data() as Map<String, dynamic>)['students'] as List<dynamic>? ?? [];
      final students = await Future.wait(
        studentsRefs.whereType<DocumentReference>().map((ref) async {
          final studentSnap = await ref.get();
          return studentSnap.exists
              ? {'id': studentSnap.id, ...(studentSnap.data() as Map<String, dynamic>)}
              : null;
        }),
      );
      return students.whereType<Map<String, dynamic>>().toList();
    } catch (e) {
      print('HomeroomService: Student fetch error: ${e.toString()}');
      return [];
    }
  }
}
