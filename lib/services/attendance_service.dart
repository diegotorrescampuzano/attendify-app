import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceService {
  /// Guarda el registro de asistencia en lote usando un mapa {studentId: true/false}
  static Future<void> saveAttendance({
    required Map<String, bool> attendanceMap,
    required DocumentReference homeroomRef,
    required DocumentReference gradeRef,
    required DocumentReference educationalLevelRef,
    required DocumentReference campusRef,
  }) async {
    final batch = FirebaseFirestore.instance.batch();
    final timestamp = DateTime.now();

    attendanceMap.forEach((studentId, isPresent) {
      final docRef = FirebaseFirestore.instance.collection('attendance').doc();
      batch.set(docRef, {
        'studentId': studentId,
        'homeroom': homeroomRef,
        'grade': gradeRef,
        'educationalLevel': educationalLevelRef,
        'campus': campusRef,
        'present': isPresent,
        'timestamp': timestamp,
      });
    });

    await batch.commit();
  }
}
