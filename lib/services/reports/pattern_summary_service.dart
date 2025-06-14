import 'package:cloud_firestore/cloud_firestore.dart';

class PatternSummaryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fetches all campuses
  Future<List<Map<String, dynamic>>> fetchCampuses() async {
    final snapshot = await _db.collection('campuses').get();
    return snapshot.docs
        .map((doc) => {'id': doc.id, ...((doc.data() as Map<String, dynamic>?) ?? {})})
        .toList();
  }

  /// Fetches all homerooms for a campus
  Future<List<Map<String, dynamic>>> fetchHomerooms({required String campusId}) async {
    final campusRef = _db.collection('campuses').doc(campusId);
    final snapshot = await _db
        .collection('homerooms')
        .where('campusId', isEqualTo: campusRef)
        .get();
    return snapshot.docs
        .map((doc) => {'id': doc.id, ...((doc.data() as Map<String, dynamic>?) ?? {})})
        .toList();
  }

  /// Returns the first day of the current week (Monday)
  DateTime getFirstDayOfWeek() {
    final now = DateTime.now();
    return now.subtract(Duration(days: now.weekday - 1));
  }

  /// Fetches all attendances for a campus from the start of the week to today,
  /// and returns a list of students with non-"Asiste" attendance records,
  /// grouped by student and attendance type.
  Future<List<Map<String, dynamic>>> fetchPatternSummaryForCampus(String campusId) async {
    final DateTime weekStart = getFirstDayOfWeek();
    final DateTime today = DateTime.now();

    // Get all homerooms for this campus
    final homerooms = await fetchHomerooms(campusId: campusId);
    final homeroomIds = homerooms.map((h) => h['id'] as String).toList();

    // Query attendances by date and homeroom
    final snapshot = await _db
        .collection('attendances')
        .where('campusId', isEqualTo: campusId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(today))
        .get();

    // Map: studentId -> { name, homeroomName, Map<label, count> }
    final Map<String, Map<String, dynamic>> studentPatterns = {};

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final homeroomId = data['homeroomId'];
      if (!homeroomIds.contains(homeroomId)) continue;

      final attendanceRecords = data['attendanceRecords'] as Map<String, dynamic>? ?? {};
      attendanceRecords.forEach((studentId, record) {
        final label = record['label'];
        if (label == 'A') return; // Only interested in non-Asiste
        final studentName = record['studentName'] ?? '';
        final homeroomName = data['homeroomName'] ?? '';

        studentPatterns.putIfAbsent(studentId, () => {
          'studentId': studentId,
          'studentName': studentName,
          'homeroomName': homeroomName,
          'patterns': <String, int>{},
        });
        final patterns = studentPatterns[studentId]!['patterns'] as Map<String, int>;
        patterns[label] = (patterns[label] ?? 0) + 1;
      });
    }

    // Convert to list and sort by most non-Asiste records
    final result = studentPatterns.values.toList();
    result.sort((a, b) {
      final aCount = (a['patterns'] as Map<String, int>).values.fold(0, (p, v) => p + v);
      final bCount = (b['patterns'] as Map<String, int>).values.fold(0, (p, v) => p + v);
      return bCount.compareTo(aCount);
    });
    return result;
  }
}
