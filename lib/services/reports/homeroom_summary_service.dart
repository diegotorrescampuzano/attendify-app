import 'package:cloud_firestore/cloud_firestore.dart';

const Map<String, Map<String, dynamic>> attendanceLabels = {
  'A': {'description': 'Asiste', 'color': 0xFF4CAF50},
  'T': {'description': 'Tarde', 'color': 0xFFFF9800},
  'E': {'description': 'Evasión', 'color': 0xFFF44336},
  'I': {'description': 'Inasistencia', 'color': 0xFF757575},
  'IJ': {'description': 'Inasistencia Justificada', 'color': 0xFF607D8B},
  'P': {'description': 'Retiro con acudiente', 'color': 0xFF9C27B0},
};

class HomeroomSummaryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch homerooms filtered by partial name match
  Future<List<Map<String, dynamic>>> fetchHomerooms({required String criteria}) async {
    print('Fetching homerooms with criteria: "$criteria"');
    final snapshot = await _firestore.collection('homerooms').get();

    final lowerCriteria = criteria.toLowerCase();

    final filtered = snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'refId': doc.id,
        'name': data['name'] ?? '',
      };
    }).where((homeroom) {
      final name = homeroom['name'].toString().toLowerCase();
      return name.contains(lowerCriteria);
    }).toList();

    print('Filtered homerooms count: ${filtered.length}');
    return filtered;
  }

  /// Fetch students of a homeroom by homeroomRefId
  Future<List<Map<String, dynamic>>> fetchStudentsOfHomeroom(String homeroomRefId) async {
    print('Fetching students for homeroomRefId: $homeroomRefId');
    final snapshot = await _firestore.collection('students')
        .where('homeroom', isEqualTo: _firestore.doc('homerooms/$homeroomRefId'))
        .get();

    final students = snapshot.docs.map((doc) {
      final data = doc.data();
      print('Processing student doc with ID: ${doc.id}');
      return {
        'refId': doc.id,
        'name': data['name'] ?? '',
        'cellphoneContact': data['cellphoneContact'] ?? '',
      };
    }).toList();

    print('Students fetched: ${students.length}');
    return students;
  }

  /// Fetch attendance totals per student in homeroom within date range
  ///
  /// Aggregates attendance across all subjects and dates.
  /// Returns map: studentRefId -> {attendanceType: count, ...}
  Future<Map<String, Map<String, int>>> fetchAttendanceTotalsPerStudent({
    required String homeroomRefId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    print('Fetching attendance totals for homeroomRefId: $homeroomRefId');
    print('Date range: ${startDate.toIso8601String()} to ${endDate.toIso8601String()}');

    final students = await fetchStudentsOfHomeroom(homeroomRefId);
    if (students.isEmpty) {
      print('No students found for homeroom');
      return {};
    }

    final studentIds = students.map((s) => s['refId'] as String).toSet();

    final startTimestamp = Timestamp.fromDate(DateTime(startDate.year, startDate.month, startDate.day));
    final endTimestamp = Timestamp.fromDate(DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59));

    final snapshot = await _firestore
        .collection('attendances')
        .where('date', isGreaterThanOrEqualTo: startTimestamp)
        .where('date', isLessThanOrEqualTo: endTimestamp)
        .get();

    print('Total attendance records fetched: ${snapshot.docs.length}');

    final Map<String, Map<String, int>> attendanceTotals = {};

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final attendanceRecordsDynamic = data['attendanceRecords'];
      if (attendanceRecordsDynamic == null || attendanceRecordsDynamic is! Map<String, dynamic>) {
        continue;
      }
      final attendanceRecords = Map<String, dynamic>.from(attendanceRecordsDynamic);

      for (final entry in attendanceRecords.entries) {
        final studentRefId = entry.key;
        if (!studentIds.contains(studentRefId)) continue; // Only consider students in homeroom

        final studentAttendance = entry.value;
        if (studentAttendance is! Map<String, dynamic>) continue;

        final label = (studentAttendance['label'] ?? '').toString();
        if (label.isEmpty) continue;

        attendanceTotals.putIfAbsent(studentRefId, () => {});
        attendanceTotals[studentRefId]![label] = (attendanceTotals[studentRefId]![label] ?? 0) + 1;
      }
    }

    print('Attendance totals per student computed: ${attendanceTotals.length} students');
    return attendanceTotals;
  }

  /// Calculate overall attendance percentage for the class
  /// Assuming 'A' means present, others absence or late
  double calculateClassAttendancePercentage(Map<String, Map<String, int>> attendanceTotals) {
    int totalRecords = 0;
    int totalPresent = 0;

    for (final counts in attendanceTotals.values) {
      for (final entry in counts.entries) {
        totalRecords += entry.value;
        if (entry.key == 'A') {
          totalPresent += entry.value;
        }
      }
    }
    if (totalRecords == 0) return 0.0;
    final percent = (totalPresent / totalRecords) * 100;
    print('Class attendance percentage calculated: $percent%');
    return percent;
  }
}
