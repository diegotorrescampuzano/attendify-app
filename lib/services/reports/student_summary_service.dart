import 'package:cloud_firestore/cloud_firestore.dart';

const Map<String, Map<String, dynamic>> attendanceLabels = {
  'A': {'description': 'Asiste', 'color': 0xFF4CAF50},
  'T': {'description': 'Tarde', 'color': 0xFFFF9800},
  'E': {'description': 'Evasión', 'color': 0xFFF44336},
  'I': {'description': 'Inasistencia', 'color': 0xFF757575},
  'IJ': {'description': 'Inasistencia Justificada', 'color': 0xFF607D8B},
  'P': {'description': 'Retiro con acudiente', 'color': 0xFF9C27B0},
};

class StudentSummaryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Fetch all campuses
  Future<List<Map<String, dynamic>>> fetchCampuses() async {
    final snapshot = await _db.collection('campuses').get();
    return snapshot.docs
        .map((doc) => {
      'id': doc.id,
      ...((doc.data() as Map<String, dynamic>?) ?? {})
    })
        .toList();
  }

  // Fetch homerooms for a campus (campusId is the string, e.g., 'c01')
  Future<List<Map<String, dynamic>>> fetchHomerooms({required String campusId}) async {
    final campusRef = _db.collection('campuses').doc(campusId);
    final snapshot = await _db
        .collection('homerooms')
        .where('campusId', isEqualTo: campusRef)
        .get();
    return snapshot.docs
        .map((doc) => {
      'id': doc.id,
      ...((doc.data() as Map<String, dynamic>?) ?? {})
    })
        .toList();
  }

  // Fetch students for a homeroom (by resolving references in the students array)
  Future<List<Map<String, dynamic>>> fetchStudents({
    required String campusId,
    required String? homeroomId,
    String? criteriaType,
    String? criteriaValue,
  }) async {
    if (homeroomId == null) return [];
    final homeroomDoc =
    await _db.collection('homerooms').doc(homeroomId).get();
    final studentRefs = List<DocumentReference>.from(homeroomDoc['students'] ?? []);
    final students = <Map<String, dynamic>>[];
    for (final ref in studentRefs) {
      final studentDoc = await ref.get();
      final data = (studentDoc.data() as Map<String, dynamic>?) ?? {};
      // Optionally filter by name or cellphone if criteria is provided
      if (criteriaType == 'name' &&
          criteriaValue != null &&
          criteriaValue.isNotEmpty &&
          !(data['name'] ?? '').toString().toLowerCase().contains(criteriaValue.toLowerCase())) {
        continue;
      }
      if (criteriaType == 'cellPhone' &&
          criteriaValue != null &&
          criteriaValue.isNotEmpty &&
          !(data['cellphoneContact'] ?? '').toString().contains(criteriaValue)) {
        continue;
      }
      students.add({'id': studentDoc.id, ...data});
    }
    return students;
  }

  // Fetch attendance records for a student in a date range
  Future<List<Map<String, dynamic>>> fetchStudentAttendanceRecords({
    required String studentId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final snapshot = await _db
        .collection('attendances')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    List<Map<String, dynamic>> result = [];
    for (final doc in snapshot.docs) {
      final data = (doc.data() as Map<String, dynamic>? ?? {});
      final attendanceRecords = data['attendanceRecords'] as Map<String, dynamic>? ?? {};
      if (attendanceRecords.containsKey(studentId)) {
        final rec = attendanceRecords[studentId] as Map<String, dynamic>;
        result.add({
          'date': data['date'],
          'subjectName': data['subjectName'] ?? '',
          'slot': data['slot'] ?? '',
          'teacherName': data['teacherName'] ?? '',
          'label': rec['label'],
          'details': rec['notes'] ?? '', // Use 'notes' as the field for notes
        });
      }
    }
    // Sort by date descending
    result.sort((a, b) {
      final ad = a['date'] is Timestamp ? (a['date'] as Timestamp).toDate() : DateTime.now();
      final bd = b['date'] is Timestamp ? (b['date'] as Timestamp).toDate() : DateTime.now();
      return bd.compareTo(ad);
    });
    return result;
  }
}
