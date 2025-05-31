// /lib/services/reports/teacher_summary_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Attendance labels with descriptions and colors - consistent with your attendance process
const Map<String, Map<String, dynamic>> attendanceLabels = {
  'A': {'description': 'Asiste', 'color': 0xFF4CAF50},       // Green
  'T': {'description': 'Tarde', 'color': 0xFFFF9800},        // Orange
  'E': {'description': 'Evasión', 'color': 0xFFF44336},      // Red
  'I': {'description': 'Inasistencia', 'color': 0xFF757575}, // Black54
  'IJ': {'description': 'Inasistencia Justificada', 'color': 0xFF607D8B}, // BlueGrey
  'P': {'description': 'Retiro con acudiente', 'color': 0xFF9C27B0},       // Purple
};

class TeacherSummaryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch all teachers from "users" collection with role "teacher"
  Future<List<Map<String, dynamic>>> fetchTeachers() async {
    final snapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'teacher')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'refId': data['refId'] ?? '',
        'name': data['name'] ?? '',
        'email': data['email'] ?? '',
      };
    }).toList();
  }

  /// Fetch attendance summary grouped by subject and attendance label code for a teacher in date range
  ///
  /// Returns a map: subjectName -> { labelCode -> count }
  Future<Map<String, Map<String, int>>> fetchAttendanceSummary({
    required String teacherRefId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final startTimestamp = Timestamp.fromDate(DateTime(startDate.year, startDate.month, startDate.day));
    final endTimestamp = Timestamp.fromDate(DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59));

    final snapshot = await _firestore
        .collection('attendances')
        .where('teacherId', isEqualTo: teacherRefId)
        .where('date', isGreaterThanOrEqualTo: startTimestamp)
        .where('date', isLessThanOrEqualTo: endTimestamp)
        .get();

    final Map<String, Map<String, int>> summary = {};

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final subjectName = data['subjectName'] ?? 'Sin asignatura';

      final attendanceRecordsDynamic = data['attendanceRecords'];
      if (attendanceRecordsDynamic == null || attendanceRecordsDynamic is! Map<String, dynamic>) {
        continue;
      }

      final attendanceRecords = Map<String, dynamic>.from(attendanceRecordsDynamic);

      // Initialize counts for all known labels for this subject if not exists
      summary.putIfAbsent(subjectName, () => {
        for (var key in attendanceLabels.keys) key: 0,
      });

      for (final studentAttendanceDynamic in attendanceRecords.values) {
        if (studentAttendanceDynamic is! Map<String, dynamic>) continue;

        final label = (studentAttendanceDynamic['label'] ?? '').toString();

        if (label.isEmpty) continue;

        if (summary[subjectName]!.containsKey(label)) {
          summary[subjectName]![label] = (summary[subjectName]![label] ?? 0) + 1;
        }
      }
    }

    return summary;
  }
}
