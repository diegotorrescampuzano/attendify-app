import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Service to fetch outstanding attendance registers filtered by date range and campus.
class OutstandingRegisterService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fetches outstanding attendance records for the given [start] and [end] dates,
  /// filtered by [campusId] if provided, using teacherLectures.
  Future<List<Map<String, dynamic>>> findOutstandingAttendance(
      DateTime start, DateTime end, {String? campusId}) async {
    try {
      print('OutstandingRegisterService: Fetching outstanding attendance from $start to $end for campus $campusId');

      // Query teacherLectures by campus only (date filtering is done in Dart)
      Query lecturesQuery = _db.collection('teacherLectures');
      if (campusId != null) {
        lecturesQuery = lecturesQuery.where(
          'campus',
          isEqualTo: _db.collection('campuses').doc(campusId),
        );
        print('OutstandingRegisterService: Filtering by campus reference /campuses/$campusId');
      }
      final lecturesSnap = await lecturesQuery.get();
      print('OutstandingRegisterService: Found ${lecturesSnap.docs.length} teacherLectures for campus');

      // Fetch attendances in date range
      final attendancesSnap = await _db.collection('attendances')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();
      print('OutstandingRegisterService: Found ${attendancesSnap.docs.length} attendances in range');

      // Build a set of (teacherLectureId, weekday, slot, date) for which attendance exists
      final existingAttendance = <String, Set<String>>{};
      for (final doc in attendancesSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final teacherLectureRef = data['teacherLecture'] as DocumentReference?;
        final date = (data['date'] as Timestamp?)?.toDate();
        final slot = data['slot']?.toString() ?? '';
        final weekday = data['weekday']?.toString()?.toLowerCase() ?? '';
        if (teacherLectureRef != null && date != null && slot.isNotEmpty && weekday.isNotEmpty) {
          final key = '${teacherLectureRef.id}-$weekday-$slot-${DateFormat('yyyy-MM-dd').format(date)}';
          existingAttendance.putIfAbsent(teacherLectureRef.id, () => {}).add(key);
        }
      }

      // Helper: Get all dates in range that match a weekday
      List<DateTime> _datesForWeekdayInRange(String weekday, DateTime start, DateTime end) {
        final List<DateTime> result = [];
        DateTime current = start;
        while (!current.isAfter(end)) {
          if (DateFormat('EEEE').format(current).toLowerCase() == weekday.toLowerCase()) {
            result.add(current);
          }
          current = current.add(const Duration(days: 1));
        }
        return result;
      }

      final outstanding = <Map<String, dynamic>>[];

      for (final doc in lecturesSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final lectureId = doc.id;
        final campusRef = data['campus'] as DocumentReference?;
        String campusName = '';
        if (campusRef != null) {
          final campusSnap = await campusRef.get();
          final campusData = campusSnap.data() as Map<String, dynamic>?;
          campusName = campusData?['name'] ?? campusRef.id;
        }
        final teacherRef = data['teacher'] as DocumentReference?;
        String teacherName = '';
        if (teacherRef != null) {
          final teacherSnap = await teacherRef.get();
          final teacherData = teacherSnap.data() as Map<String, dynamic>?;
          teacherName = teacherData?['name'] ?? teacherRef.id;
        }
        final lecturesMap = data['lectures'] as Map<String, dynamic>?;

        if (lecturesMap == null) continue;

        // For each weekday in the lecture map
        for (final weekday in lecturesMap.keys) {
          final List<dynamic> slots = lecturesMap[weekday] as List<dynamic>;
          // For each slot in the weekday
          for (final slotEntry in slots) {
            final slotMap = slotEntry as Map<String, dynamic>;
            final slot = slotMap['slot']?.toString() ?? '';
            final subjectRef = slotMap['subject'] as DocumentReference?;
            String subjectName = '';
            if (subjectRef != null) {
              final subjectSnap = await subjectRef.get();
              final subjectData = subjectSnap.data() as Map<String, dynamic>?;
              subjectName = subjectData?['name'] ?? subjectRef.id;
            }
            final homeroomRef = slotMap['homeroom'] as DocumentReference?;
            String homeroomName = '';
            if (homeroomRef != null) {
              final homeroomSnap = await homeroomRef.get();
              final homeroomData = homeroomSnap.data() as Map<String, dynamic>?;
              homeroomName = homeroomData?['name'] ?? homeroomRef.id;
            }
            final time = slotMap['time'] ?? '';

            // For each date in the selected range that matches this weekday
            final dates = _datesForWeekdayInRange(weekday, start, end);
            for (final date in dates) {
              final dateStr = DateFormat('yyyy-MM-dd').format(date);
              final attendanceKey = '$lectureId-${weekday.toLowerCase()}-$slot-$dateStr';
              final attended = existingAttendance[lectureId]?.contains(attendanceKey) ?? false;
              if (!attended) {
                outstanding.add({
                  'teacherLectureId': lectureId,
                  'teacherName': teacherName,
                  'campusName': campusName,
                  'date': dateStr,
                  'weekday': weekday,
                  'slot': slot,
                  'subjectName': subjectName,
                  'homeroomName': homeroomName,
                  'time': time,
                  'status': 'Pendiente',
                });
                print('OutstandingRegisterService: Outstanding - $teacherName $subjectName $homeroomName on $weekday slot $slot at $campusName ($dateStr)');
              }
            }
          }
        }
      }
      print('OutstandingRegisterService: Returning ${outstanding.length} outstanding records');
      return outstanding;
    } catch (e) {
      print('OutstandingRegisterService: Error fetching outstanding attendance: $e');
      return [];
    }
  }
}
