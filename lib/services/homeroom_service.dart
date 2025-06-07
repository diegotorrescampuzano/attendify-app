import 'package:cloud_firestore/cloud_firestore.dart';

/// Service to fetch homerooms enriched with lecture details and related metadata.
/// It extracts homerooms from today's lectures and fetches additional fields:
/// campusId, educationalLevelId, gradeId, students list,
/// and also fetches the corresponding names from campuses, educationalLevels, and grades collections.
/// This data is necessary to pass along in the flow for attendance and other features.
class HomeroomService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fetches homerooms with lecture details and additional metadata including names
  /// from the provided [lecturesForToday] map.
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

              // Avoid processing duplicates
              if (!homeroomMap.containsKey(homeroomId)) {
                final homeroomSnap = await homeroomRef.get();
                if (!homeroomSnap.exists) {
                  print('HomeroomService: Homeroom document $homeroomId does not exist');
                  continue;
                }
                final homeroomData = homeroomSnap.data() as Map<String, dynamic>;

                // Fetch subject name and id from subject reference if available
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

                // Fetch campus name
                if (campusRef is DocumentReference) {
                  final campusSnap = await _db.collection('campuses').doc(campusRef.id).get();
                  if (campusSnap.exists) {
                    campusName = (campusSnap.data() as Map<String, dynamic>)['name'] ?? '';
                  } else {
                    print('HomeroomService: Campus document ${campusRef.id} does not exist');
                  }
                }

                // Fetch educational level name
                if (educationalLevelRef is DocumentReference) {
                  final eduLevelSnap = await _db.collection('educationalLevels').doc(educationalLevelRef.id).get();
                  if (eduLevelSnap.exists) {
                    educationalLevelName = (eduLevelSnap.data() as Map<String, dynamic>)['name'] ?? '';
                  } else {
                    print('HomeroomService: EducationalLevel document ${educationalLevelRef.id} does not exist');
                  }
                }

                // Fetch grade name
                if (gradeRef is DocumentReference) {
                  final gradeSnap = await _db.collection('grades').doc(gradeRef.id).get();
                  if (gradeSnap.exists) {
                    gradeName = (gradeSnap.data() as Map<String, dynamic>)['name'] ?? '';
                  } else {
                    print('HomeroomService: Grade document ${gradeRef.id} does not exist');
                  }
                }

                homeroomMap[homeroomId] = {
                  'id': homeroomId,
                  'name': homeroomData['name'] ?? 'Sin nombre',
                  'description': homeroomData['description'] ?? '',
                  'slot': lecture['slot'] ?? '',
                  'subjectName': subjectName,
                  'subjectId': subjectId, // Added subjectId here
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

                print('HomeroomService: Added homeroom $homeroomId with subject "$subjectName", '
                    'campus "$campusName", educational level "$educationalLevelName", grade "$gradeName"');
              }
            }
          }
        }
      }

      print('HomeroomService: Returning ${homeroomMap.length} homerooms with full details');
      return homeroomMap.values.toList();
    } catch (e) {
      print('HomeroomService: Error fetching homerooms with lecture details: $e');
      return [];
    }
  }

  /// Fetches students for a given homeroom reference.
  /// Returns a list of student maps with their data.
  static Future<List<Map<String, dynamic>>> getStudentsFromHomeroom(DocumentReference homeroomRef) async {
    try {
      final homeroomSnap = await homeroomRef.get();
      if (!homeroomSnap.exists) {
        print('HomeroomService: Homeroom ${homeroomRef.id} does not exist');
        return [];
      }
      final homeroomData = homeroomSnap.data() as Map<String, dynamic>;
      final studentsRefs = homeroomData['students'] as List<dynamic>? ?? [];

      print('HomeroomService: Found ${studentsRefs.length} student references in homeroom ${homeroomRef.id}');

      // Fetch each student document by reference
      final students = <Map<String, dynamic>>[];
      for (final ref in studentsRefs) {
        if (ref is DocumentReference) {
          final studentSnap = await ref.get();
          if (studentSnap.exists) {
            final data = studentSnap.data() as Map<String, dynamic>;
            students.add({
              'id': studentSnap.id,
              ...data,
            });
          } else {
            print('HomeroomService: Student document ${ref.id} does not exist');
          }
        }
      }
      print('HomeroomService: Returning ${students.length} students for homeroom ${homeroomRef.id}');
      return students;
    } catch (e) {
      print('HomeroomService: Error fetching students for homeroom ${homeroomRef.id}: $e');
      return [];
    }
  }
}
