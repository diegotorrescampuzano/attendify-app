import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class OutstandingRegisterService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Returns the current week's Monday and today.
  List<DateTime> _currentWeekRangeToToday() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final today = DateTime(now.year, now.month, now.day);
    return [DateTime(monday.year, monday.month, monday.day), today];
  }

  Future<List<Map<String, dynamic>>> findOutstandingAttendance({
    required String campusId,
  }) async {
    try {
      final weekRange = _currentWeekRangeToToday();
      final start = weekRange[0];
      final end = weekRange[1];

      print('OutstandingRegisterService: Fetching outstanding attendance for week $start to $end for campus $campusId');

      // 1. Get all teacherLectures for this campus
      final teacherLecturesSnap = await _db.collection('teacherLectures')
          .where('campus', isEqualTo: _db.collection('campuses').doc(campusId))
          .get();
      print('OutstandingRegisterService: Found ${teacherLecturesSnap.docs.length} teacherLectures for campus');

      // 2. Fetch ALL attendances for the current week (till today) and campus
      final attendancesSnap = await _db.collection('attendances')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .where('campusId', isEqualTo: campusId)
          .get();
      print('OutstandingRegisterService: Found ${attendancesSnap.docs.length} attendance records in week');

      // Debug: Print all attendance records found, with field names and types
      for (final doc in attendancesSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        print('Attendance doc:');
        data.forEach((key, value) {
          print('  $key: $value (${value.runtimeType})');
        });
      }

      // 3. Build a set of keys for which attendance exists (date_homeroom_slot)
      final existingAttendance = <String>{};
      for (final doc in attendancesSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final date = (data['date'] is Timestamp)
            ? (data['date'] as Timestamp).toDate()
            : (data['date'] is String)
            ? DateTime.tryParse(data['date'])
            : null;
        final homeroomId = data['homeroomId']?.toString();
        final slot = data['slot']?.toString();
        if (date != null && homeroomId != null && slot != null) {
          final key = '${DateFormat('yyyy-MM-dd').format(date)}_${homeroomId}_$slot';
          existingAttendance.add(key);
          print('OutstandingRegisterService: Found attendance record (key): $key');
        }
      }

      // 4. Generate a list of dates for the current week up to today
      final List<DateTime> datesInRange = [];
      DateTime current = start;
      while (!current.isAfter(end)) {
        datesInRange.add(current);
        current = current.add(const Duration(days: 1));
      }

      String _spanishDayName(DateTime date) => DateFormat.EEEE('es_ES').format(date);
      String _englishWeekdayName(DateTime date) => DateFormat('EEEE', 'en_US').format(date).toLowerCase();

      final outstanding = <Map<String, dynamic>>[];

      // 5. For each teacherLecture, check all scheduled slots
      for (final doc in teacherLecturesSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final lecturesMap = data['lectures'] as Map<String, dynamic>?;
        if (lecturesMap == null) continue;

        // Get teacher name for display
        String teacherName = '';
        final teacherRef = data['teacher'] as DocumentReference?;
        if (teacherRef != null) {
          final teacherSnap = await teacherRef.get();
          final teacherData = teacherSnap.data() as Map<String, dynamic>?;
          teacherName = teacherData?['name'] ?? teacherRef.id;
        }

        for (final date in datesInRange) {
          final weekday = _englishWeekdayName(date);
          final dateStr = DateFormat('yyyy-MM-dd').format(date);

          if (!lecturesMap.containsKey(weekday)) continue;
          final slots = lecturesMap[weekday] as List<dynamic>;

          for (final slotEntry in slots) {
            final slotMap = slotEntry as Map<String, dynamic>;
            final slot = slotMap['slot']?.toString() ?? '';
            final homeroomRef = slotMap['homeroom'] as DocumentReference?;
            if (homeroomRef == null || slot.isEmpty) continue;
            final homeroomId = homeroomRef.id;

            final attendanceKey = '${dateStr}_${homeroomId}_$slot';
            print('OutstandingRegisterService: Checking attendance key: $attendanceKey');
            if (existingAttendance.contains(attendanceKey)) {
              print('OutstandingRegisterService: Attendance exists for $attendanceKey');
              continue;
            }

            // If we get here, this is an outstanding attendance record
            print('OutstandingRegisterService: Outstanding attendance found for $attendanceKey');

            // Fetch additional data for display
            String homeroomName = homeroomId;
            String subjectName = '';
            String gradeName = '';
            final subjectRef = slotMap['subject'] as DocumentReference?;
            if (subjectRef != null) {
              final subjectSnap = await subjectRef.get();
              final subjectData = subjectSnap.data() as Map<String, dynamic>?;
              subjectName = subjectData?['name'] ?? subjectRef.id;
            }
            final homeroomSnap = await homeroomRef.get();
            final homeroomData = homeroomSnap.data() as Map<String, dynamic>?;
            homeroomName = homeroomData?['name'] ?? homeroomId;
            final gradeRef = homeroomData?['gradeId'] as DocumentReference?;
            if (gradeRef != null) {
              final gradeSnap = await gradeRef.get();
              final gradeData = gradeSnap.data() as Map<String, dynamic>?;
              gradeName = gradeData?['name'] ?? gradeRef.id;
            }
            // Get campus name
            String campusName = campusId;
            final campusRef = _db.collection('campuses').doc(campusId);
            final campusSnap = await campusRef.get();
            final campusData = campusSnap.data() as Map<String, dynamic>?;
            campusName = campusData?['name'] ?? campusId;

            outstanding.add({
              'teacherName': teacherName,
              'campusName': campusName,
              'date': dateStr,
              'weekday': weekday,
              'spanishDayName': _spanishDayName(date),
              'slot': slot,
              'time': slotMap['time'] ?? '',
              'subjectName': subjectName,
              'homeroomId': homeroomId,
              'homeroomName': homeroomName,
              'gradeId': gradeRef?.id ?? '',
              'gradeName': gradeName,
              'status': 'Pendiente',
            });

            print('OutstandingRegisterService: Added outstanding record for $teacherName on $dateStr at $campusName, homeroom $homeroomName, slot $slot');
          }
        }
      }

      // Sort: teacherName ASC, date DESC, slot DESC
      outstanding.sort((a, b) {
        final teacherComp = (a['teacherName'] ?? '').compareTo(b['teacherName'] ?? '');
        if (teacherComp != 0) return teacherComp;
        final dateA = DateTime.tryParse(a['date'] ?? '') ?? DateTime(1900);
        final dateB = DateTime.tryParse(b['date'] ?? '') ?? DateTime(1900);
        if (dateA != dateB) return dateB.compareTo(dateA);
        final slotA = int.tryParse(a['slot']?.toString() ?? '0') ?? 0;
        final slotB = int.tryParse(b['slot']?.toString() ?? '0') ?? 0;
        return slotB.compareTo(slotA);
      });

      print('OutstandingRegisterService: Returning ${outstanding.length} outstanding records');
      return outstanding;
    } catch (e) {
      print('OutstandingRegisterService: Error fetching outstanding attendance: $e');
      return [];
    }
  }
}
