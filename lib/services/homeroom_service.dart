import 'package:cloud_firestore/cloud_firestore.dart';

class HomeroomService {
  /// Fetch homerooms enriched with lecture details (subject name, slot, time)
  /// based on the lecturesForToday map from CampusService.
  static Future<List<Map<String, dynamic>>> getHomeroomsWithLectureDetails(
      Map<String, dynamic> lecturesForToday) async {
    try {
      final homeroomMap = <String, Map<String, dynamic>>{};

      for (final dayLectures in lecturesForToday.values) {
        if (dayLectures is List) {
          for (final lecture in dayLectures) {
            final homeroomRef = lecture['homeroom'];
            if (homeroomRef is DocumentReference) {
              final homeroomId = homeroomRef.id;
              if (!homeroomMap.containsKey(homeroomId)) {
                final homeroomSnap = await homeroomRef.get();
                if (!homeroomSnap.exists) continue;
                final homeroomData = homeroomSnap.data() as Map<String, dynamic>;

                // Fetch subject name
                String subjectName = '';
                final subjectRef = lecture['subject'];
                if (subjectRef is DocumentReference) {
                  final subjectSnap = await subjectRef.get();
                  if (subjectSnap.exists) {
                    final subjectData = subjectSnap.data() as Map<String, dynamic>;
                    subjectName = subjectData['name'] ?? '';
                  }
                }

                homeroomMap[homeroomId] = {
                  'id': homeroomId,
                  'name': homeroomData['name'] ?? 'Sin nombre',
                  'description': homeroomData['description'] ?? '',
                  'slot': lecture['slot'] ?? '',
                  'subjectName': subjectName,
                  'time': lecture['time'] ?? '',
                  'ref': homeroomRef,
                };
              }
            }
          }
        }
      }

      return homeroomMap.values.toList();
    } catch (e) {
      print('HomeroomService: Error fetching homerooms with lecture details: $e');
      return [];
    }
  }
}
