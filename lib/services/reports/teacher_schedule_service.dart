import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherScheduleService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> fetchCampuses() async {
    final snapshot = await _db.collection('campuses').get();
    return snapshot.docs
        .map((doc) => {'id': doc.id, ...((doc.data() as Map<String, dynamic>?) ?? {})})
        .toList();
  }

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

  Future<String> resolveReferenceName(dynamic field) async {
    if (field == null) return '';
    if (field is String) return field;
    if (field is DocumentReference) {
      final doc = await field.get();
      return (doc.data() as Map<String, dynamic>?)?['name'] ?? '';
    }
    // Handle _JsonDocumentReference and emulator/web types
    if (field.runtimeType.toString().contains('DocumentReference')) {
      final doc = await (field as dynamic).get();
      return (doc.data() as Map<String, dynamic>?)?['name'] ?? '';
    }
    return '';
  }

  Future<Map<String, Map<int, Map<String, String>>>> fetchTeacherSchedule({
    required String teacherId,
    required String campusId,
  }) async {
    final days = [
      'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
    ];
    final schedule = {
      for (final day in days) day: {for (int slot = 1; slot <= 8; slot++) slot: {'subject': 'Libre', 'homeroom': ''}}
    };

    final snapshot = await _db
        .collection('teacherLectures')
        .where('teacher', isEqualTo: _db.collection('teachers').doc(teacherId))
        .where('campus', isEqualTo: _db.collection('campuses').doc(campusId))
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return schedule;

    final data = snapshot.docs.first.data() as Map<String, dynamic>;
    final lectures = data['lectures'] as Map<String, dynamic>? ?? {};

    for (final day in days) {
      final dayLectures = lectures[day] as List<dynamic>? ?? [];
      for (final lecture in dayLectures) {
        final slot = lecture['slot'] ?? 0;

        final subjectField = lecture['subjectName'] ?? lecture['subject'];
        final homeroomField = lecture['homeroomName'] ?? lecture['homeroom'];

        final subject = await resolveReferenceName(subjectField);
        final homeroom = await resolveReferenceName(homeroomField);

        if (slot is int && slot >= 1 && slot <= 8) {
          schedule[day]![slot] = {
            'subject': subject.isNotEmpty ? subject : 'Libre',
            'homeroom': homeroom,
          };
        }
      }
    }
    return schedule;
  }
}
