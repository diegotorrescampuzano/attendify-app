import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for handling campus-related Firestore operations
class CampusService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Gets the campuses assigned to the teacher with given [refId]
  /// Includes additional fields: 'zone'
  /// Also fetches the teacher's lectures for the current day from 'teacherLectures' collection
  static Future<List<Map<String, dynamic>>> getCampusesAndLecturesForTeacher(String refId) async {
    print('CampusService: Fetching campuses and today\'s lectures for teacher refId: $refId');

    // Fetch teacher document by refId
    final teacherDoc = await _db.collection('teachers').doc(refId).get();

    if (!teacherDoc.exists) {
      print('CampusService: No teacher document found for refId: $refId');
      return [];
    }

    // Extract assignedCampuses references array
    final assignedRefs = teacherDoc.data()?['assignedCampuses'] as List<dynamic>?;

    if (assignedRefs == null || assignedRefs.isEmpty) {
      print('CampusService: No assigned campuses found for teacher $refId');
      return [];
    }

    print('CampusService: Found ${assignedRefs.length} assigned campuses for teacher $refId');

    // Get current weekday name in lowercase to match lecture keys (e.g., 'monday')
    final now = DateTime.now();
    final weekdayMap = {
      DateTime.monday: 'monday',
      DateTime.tuesday: 'tuesday',
      DateTime.wednesday: 'wednesday',
      DateTime.thursday: 'thursday',
      DateTime.friday: 'friday',
      DateTime.saturday: 'saturday',
      DateTime.sunday: 'sunday',
    };
    final todayKey = weekdayMap[now.weekday] ?? 'monday'; // fallback to monday if unknown

    // Fetch campus documents and corresponding lectures concurrently
    final campusesWithLectures = await Future.wait(assignedRefs.map((ref) async {
      final campusDoc = await (ref as DocumentReference).get();

      if (!campusDoc.exists) {
        print('CampusService: Campus document ${ref.id} does not exist');
        return null;
      }

      // Cast doc.data() to Map<String, dynamic> to access fields safely
      final campusData = campusDoc.data() as Map<String, dynamic>;

      final zone = campusData['zone'] ?? 'unknown';

      print('CampusService: Campus ${campusDoc.id} - zone: $zone');

      // Compose the teacherLectures doc ID: format "teacherRefId-campusId"
      final teacherLecturesDocId = '$refId-${campusDoc.id}';

      // Fetch teacher lectures document for this campus
      final lecturesDoc = await _db.collection('teacherLectures').doc(teacherLecturesDocId).get();

      Map<String, dynamic> lecturesForToday = {};
      if (lecturesDoc.exists) {
        final lecturesData = lecturesDoc.data() as Map<String, dynamic>?;

        if (lecturesData != null && lecturesData.containsKey('lectures')) {
          final lecturesMap = lecturesData['lectures'] as Map<String, dynamic>?;

          if (lecturesMap != null && lecturesMap.containsKey(todayKey)) {
            // Extract only today's lectures array
            final todayLectures = lecturesMap[todayKey] as List<dynamic>? ?? [];
            lecturesForToday = {
              todayKey: todayLectures,
            };
            print('CampusService: Found ${todayLectures.length} lectures for teacher $refId at campus ${campusDoc.id} on $todayKey');
          } else {
            print('CampusService: No lectures found for today ($todayKey) for teacher $refId at campus ${campusDoc.id}');
          }
        } else {
          print('CampusService: Lectures data missing or malformed for teacher $refId at campus ${campusDoc.id}');
        }
      } else {
        print('CampusService: No lectures document found for teacher $refId at campus ${campusDoc.id}');
      }

      return {
        'id': campusDoc.id,
        'name': campusData['name'] ?? '',
        'description': campusData['description'] ?? '',
        'zone': zone,
        // 'homerooms' removed as requested
        'lecturesForToday': lecturesForToday, // Only today's lectures keyed by weekday
      };
    }));

    // Filter out any null results (in case some campus docs were missing)
    final filteredCampuses = campusesWithLectures.whereType<Map<String, dynamic>>().toList();

    print('CampusService: Returning ${filteredCampuses.length} campuses with today\'s lectures for teacher $refId');
    return filteredCampuses;
  }
}
