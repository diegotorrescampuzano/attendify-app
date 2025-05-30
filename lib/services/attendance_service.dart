import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceService {
  /// Guarda el registro de asistencia en lote usando un mapa {studentId: tipoAsistencia}
  static Future<void> saveAttendance({
    required Map<String, String> attendanceMap,
    required DocumentReference homeroomRef,
    required DocumentReference gradeRef,
    required DocumentReference educationalLevelRef,
    required DocumentReference campusRef,
  }) async {
    final batch = FirebaseFirestore.instance.batch();
    final timestamp = DateTime.now();

    attendanceMap.forEach((studentId, attendanceType) {
      final docRef = FirebaseFirestore.instance.collection('attendance').doc();
      batch.set(docRef, {
        'studentId': studentId,
        'homeroom': homeroomRef,
        'grade': gradeRef,
        'educationalLevel': educationalLevelRef,
        'campus': campusRef,
        'attendanceType': attendanceType, // A, T, E, I, IJ, P
        'timestamp': timestamp,
      });
    });

    await batch.commit();
  }
}
