import 'package:cloud_firestore/cloud_firestore.dart';

class StudentScheduleService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> fetchCampuses() async {
    final snapshot = await _db.collection('campuses').get();
    return snapshot.docs
        .map((doc) => {'id': doc.id, ...((doc.data() as Map<String, dynamic>?) ?? {})})
        .toList();
  }

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

  Future<List<Map<String, dynamic>>> fetchStudents({required String homeroomId}) async {
    final homeroomDoc = await _db.collection('homerooms').doc(homeroomId).get();
    final studentRefs = List<DocumentReference>.from(homeroomDoc['students'] ?? []);
    final students = <Map<String, dynamic>>[];
    for (final ref in studentRefs) {
      final studentDoc = await ref.get();
      final data = (studentDoc.data() as Map<String, dynamic>?) ?? {};
      students.add({'id': studentDoc.id, ...data});
    }
    return students;
  }

  /// Returns a map: day (lowercase) -> slot (1-8) -> attendance info or null if none
  Future<Map<String, Map<int, Map<String, dynamic>?>>> fetchStudentWeekSchedule({
    required String studentId,
    required String homeroomName,
    required DateTime weekStart,
    required DateTime weekEnd,
  }) async {
    // Days in lowercase, as in Firestore
    final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    Map<String, Map<int, Map<String, dynamic>?>> schedule = {
      for (final day in days) day: {for (int slot = 1; slot <= 8; slot++) slot: null}
    };

    final snapshot = await _db
        .collection('attendances')
        .where('homeroomName', isEqualTo: homeroomName)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(weekEnd))
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final day = (data['day'] ?? '').toString().toLowerCase();
      final slot = int.tryParse(data['slot']?.toString() ?? '') ?? 0;
      if (!days.contains(day) || slot == 0) continue;
      final attendanceRecords = data['attendanceRecords'] as Map<String, dynamic>? ?? {};
      if (attendanceRecords.containsKey(studentId)) {
        final rec = attendanceRecords[studentId] as Map<String, dynamic>;
        schedule[day]![slot] = {
          'subject': data['subjectName'] ?? '',
          'homeroom': data['homeroomName'] ?? '',
          'label': rec['label'],
        };
      } else {
        // If attendance exists for slot but not for this student, show subject and pendiente
        schedule[day]![slot] = {
          'subject': data['subjectName'] ?? '',
          'homeroom': data['homeroomName'] ?? '',
          'label': null,
        };
      }
    }
    return schedule;
  }
}
