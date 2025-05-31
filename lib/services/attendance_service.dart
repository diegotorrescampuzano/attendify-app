import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

const Map<String, Map<String, dynamic>> attendanceLabels = {
  'A': {'description': 'Asiste', 'color': Color(0xFF4CAF50)},       // Green
  'T': {'description': 'Tarde', 'color': Color(0xFFFF9800)},        // Orange
  'E': {'description': 'Evasión', 'color': Color(0xFFF44336)},      // Red
  'I': {'description': 'Inasistencia', 'color': Colors.black54},    // Black54
  'IJ': {'description': 'Inasistencia Justificada', 'color': Color(0xFF607D8B)}, // BlueGrey
  'P': {'description': 'Retiro con acudiente', 'color': Color(0xFF9C27B0)},       // Purple
};

class AttendanceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String generateDocId({
    required String homeroomId,
    required String subjectId,
    required DateTime date,
    required String timeSlot,
  }) {
    final dateStr = '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    final timeClean = timeSlot.replaceAll(':', '').replaceAll(' ', '');
    return '${homeroomId}_${subjectId}_${dateStr}_${timeClean}';
  }

  Future<Map<String, String>> loadAttendance(String docId) async {
    final doc = await _db.collection('attendances').doc(docId).get();
    if (!doc.exists) return {};
    final data = doc.data()!;
    final attendanceRecords = data['attendanceRecords'] as Map<String, dynamic>? ?? {};
    return attendanceRecords.map((studentId, record) {
      final label = record['label'] as String? ?? 'A';
      return MapEntry(studentId, label);
    });
  }

  Future<void> saveAttendance({
    required String docId,
    required Map<String, dynamic> generalInfo,
    required Map<String, String> attendanceMap,
    required DateTime date,
    required String timeSlot,
    required String teacherId,
    required String teacherName,
  }) async {
    final timestamp = Timestamp.now();

    final attendanceRecords = <String, Map<String, dynamic>>{};
    attendanceMap.forEach((studentId, label) {
      final labelInfo = attendanceLabels[label] ?? attendanceLabels['A']!;
      attendanceRecords[studentId] = {
        'label': label,
        'labelDescription': labelInfo['description'],
        'labelColor': labelInfo['color'].value.toRadixString(16).padLeft(8, '0'),
        'notes': '',
        'timestamp': timestamp,
      };
    });

    final dateTimestamp = Timestamp.fromDate(DateTime(date.year, date.month, date.day));

    final dataToSave = {
      'date': dateTimestamp,
      'time': timeSlot,
      ...generalInfo,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'attendanceRecords': attendanceRecords,
      'createdAt': timestamp,
      'updatedAt': timestamp,
    };

    await _db.collection('attendances').doc(docId).set(dataToSave);
  }
}
