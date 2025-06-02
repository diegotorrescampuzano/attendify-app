import 'package:cloud_firestore/cloud_firestore.dart';

const Map<String, Map<String, dynamic>> attendanceLabels = {
  'A': {'description': 'Asiste', 'color': 0xFF4CAF50},
  'T': {'description': 'Tarde', 'color': 0xFFFF9800},
  'E': {'description': 'Evasión', 'color': 0xFFF44336},
  'I': {'description': 'Inasistencia', 'color': 0xFF757575},
  'IJ': {'description': 'Inasistencia Justificada', 'color': 0xFF607D8B},
  'P': {'description': 'Retiro con acudiente', 'color': 0xFF9C27B0},
};

class PatternSummaryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch all students with their homeroom references
  Future<List<Map<String, dynamic>>> fetchAllStudents() async {
    final snapshot = await _firestore.collection('students').get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'refId': doc.id,
        'name': data['name'] ?? '',
        'homeroom': data['homeroom'], // Firestore DocumentReference or null
      };
    }).toList();
  }

  /// Fetch homeroom names for given homeroom references
  Future<Map<String, String>> fetchHomeroomNames(Set<String> homeroomIds) async {
    if (homeroomIds.isEmpty) return {};

    final Map<String, String> homeroomNames = {};
    final batchSize = 10;
    final homeroomIdList = homeroomIds.toList();

    for (var i = 0; i < homeroomIdList.length; i += batchSize) {
      final batch = homeroomIdList.sublist(
          i, i + batchSize > homeroomIdList.length ? homeroomIdList.length : i + batchSize);
      final snapshot = await _firestore
          .collection('homerooms')
          .where(FieldPath.documentId, whereIn: batch)
          .get();

      for (final doc in snapshot.docs) {
        homeroomNames[doc.id] = doc.data()['name'] ?? '';
      }
    }
    return homeroomNames;
  }

  /// Fetch attendance records for all students within date range
  /// Returns map: studentRefId -> list of absence dates (sorted)
  Future<Map<String, List<DateTime>>> fetchAbsenceDatesPerStudent({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final startTimestamp = Timestamp.fromDate(DateTime(startDate.year, startDate.month, startDate.day));
    final endTimestamp = Timestamp.fromDate(DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59));

    final snapshot = await _firestore
        .collection('attendances')
        .where('date', isGreaterThanOrEqualTo: startTimestamp)
        .where('date', isLessThanOrEqualTo: endTimestamp)
        .get();

    final Map<String, List<DateTime>> absenceDates = {};

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final attendanceRecordsDynamic = data['attendanceRecords'];
      if (attendanceRecordsDynamic == null || attendanceRecordsDynamic is! Map<String, dynamic>) {
        continue;
      }
      final attendanceRecords = Map<String, dynamic>.from(attendanceRecordsDynamic);

      final dateTimestamp = data['date'] as Timestamp?;
      if (dateTimestamp == null) continue;
      final date = dateTimestamp.toDate();

      for (final entry in attendanceRecords.entries) {
        final studentRefId = entry.key;

        final studentAttendance = entry.value;
        if (studentAttendance is! Map<String, dynamic>) continue;

        final label = (studentAttendance['label'] ?? '').toString();
        // Consider these labels as absences for pattern detection
        if (label == 'I' || label == 'IJ' || label == 'E') {
          absenceDates.putIfAbsent(studentRefId, () => []);
          absenceDates[studentRefId]!.add(date);
        }
      }
    }

    // Sort dates for each student
    for (final dates in absenceDates.values) {
      dates.sort();
    }

    return absenceDates;
  }

  /// Detect continuous absence streaks and high absence counts
  /// Returns map studentRefId -> { 'name': studentName, 'homeroomId': ..., 'homeroomName': ..., 'maxStreak': int, 'totalAbsences': int }
  Map<String, Map<String, dynamic>> analyzeAbsencePatterns(
      Map<String, List<DateTime>> absenceDates,
      Map<String, Map<String, dynamic>> studentsMap,
      Map<String, String> homeroomNames,
      ) {
    final Map<String, Map<String, dynamic>> result = {};

    for (final entry in absenceDates.entries) {
      final studentId = entry.key;
      final dates = entry.value;

      int maxStreak = 0;
      int currentStreak = 1;

      for (int i = 1; i < dates.length; i++) {
        final diff = dates[i].difference(dates[i - 1]).inDays;
        if (diff == 1) {
          currentStreak++;
        } else {
          if (currentStreak > maxStreak) maxStreak = currentStreak;
          currentStreak = 1;
        }
      }
      if (currentStreak > maxStreak) maxStreak = currentStreak;

      final totalAbsences = dates.length;
      final studentData = studentsMap[studentId];
      final studentName = studentData?['name'] ?? 'Desconocido';
      final homeroomRef = studentData?['homeroom'];
      String homeroomId = '';
      String homeroomName = '';
      if (homeroomRef != null && homeroomRef is DocumentReference<dynamic>) {
        homeroomId = homeroomRef.id;
        homeroomName = homeroomNames[homeroomId] ?? '';
      }

      result[studentId] = {
        'name': studentName,
        'homeroomId': homeroomId,
        'homeroomName': homeroomName,
        'maxStreak': maxStreak,
        'totalAbsences': totalAbsences,
      };
    }

    return result;
  }
}
