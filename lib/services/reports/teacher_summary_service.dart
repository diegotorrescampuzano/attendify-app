import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherSummaryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fetch all campuses
  Future<List<Map<String, dynamic>>> fetchCampuses() async {
    final snapshot = await _db.collection('campuses').get();
    return snapshot.docs
        .map((doc) => {'id': doc.id, ...((doc.data() as Map<String, dynamic>?) ?? {})})
        .toList();
  }

  /// Fetch all teachers for a campus
  Future<List<Map<String, dynamic>>> fetchTeachers({required String campusId}) async {
    final campusRef = _db.collection('campuses').doc(campusId);
    final snapshot = await _db
        .collection('teachers')
        .where('assignedCampuses', arrayContains: campusRef)
        .get();
    return snapshot.docs
        .map((doc) => {'id': doc.id, ...((doc.data() as Map<String, dynamic>?) ?? {})})
        .toList();
  }

  /// Fetch attendance records for a teacher in a date range, grouped by homeroom and subject
  Future<List<Map<String, dynamic>>> fetchTeacherAttendanceSummary({
    required String teacherId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final snapshot = await _db
        .collection('attendances')
        .where('teacherId', isEqualTo: teacherId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    // Map: 'homeroomName|subjectName' -> {homeroomName, subjectName, counts: {A: x, E: y, ...}}
    final Map<String, Map<String, dynamic>> grouped = {};

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final homeroomName = data['homeroomName'] ?? '';
      final subjectName = data['subjectName'] ?? '';
      final groupKey = '$homeroomName|$subjectName';
      grouped.putIfAbsent(groupKey, () => {
        'homeroomName': homeroomName,
        'subjectName': subjectName,
        'counts': <String, int>{},
      });
      final counts = grouped[groupKey]!['counts'] as Map<String, int>;
      final attendanceRecords = data['attendanceRecords'] as Map<String, dynamic>? ?? {};
      for (final rec in attendanceRecords.values) {
        final label = rec['label'] ?? '';
        counts[label] = (counts[label] ?? 0) + 1;
      }
    }

    return grouped.values.toList();
  }
}
