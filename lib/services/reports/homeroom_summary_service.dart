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
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> fetchCampuses() async {
    final snapshot = await _db.collection('campuses').get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<List<Map<String, dynamic>>> fetchHomerooms({required String campusId}) async {
    final snapshot = await _db
        .collection('homerooms')
        .where('campusId', isEqualTo: _db.doc('campuses/$campusId'))
        .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<List<String>> fetchAttendanceTypes() async {
    return attendanceLabels.keys.toList();
  }

  Future<List<Map<String, dynamic>>> fetchAttendanceSummary({
    required List<String> homeroomIds,
    required List<String> attendanceTypes,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (homeroomIds.isEmpty || attendanceTypes.isEmpty) return [];
    // Get all attendance docs for selected homerooms and date range
    final snapshot = await _db
        .collection('attendances')
        .where('homeroomId', whereIn: homeroomIds)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    List<Map<String, dynamic>> result = [];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final attendanceRecords = data['attendanceRecords'] as Map<String, dynamic>? ?? {};
      attendanceRecords.forEach((studentId, rec) {
        if (attendanceTypes.contains(rec['label'])) {
          result.add({
            'studentId': studentId,
            'studentName': rec['studentName'] ?? '',
            'homeroomId': data['homeroomId'],
            'homeroomName': data['homeroomName'] ?? '',
            'label': rec['label'],
            'date': data['date'],
            'subjectName': data['subjectName'],
            'slot': data['slot'],
            'teacherName': data['teacherName'] ?? rec['teacherName'] ?? '',
          });
        }
      });
    }
    return result;
  }
}
