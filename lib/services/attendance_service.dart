import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const Map<String, Map<String, dynamic>> attendanceLabels = {
  'A': {'description': 'Asiste', 'color': Color(0xFF4CAF50)},
  'T': {'description': 'Tarde', 'color': Color(0xFFFF9800)},
  'E': {'description': 'Evasión', 'color': Color(0xFFF44336)},
  'I': {'description': 'Inasistencia', 'color': Colors.black54},
  'IJ': {'description': 'Inasistencia Justificada', 'color': Color(0xFF607D8B)},
  'P': {'description': 'Retiro con acudiente', 'color': Color(0xFF9C27B0)},
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

  Future<Map<String, Map<String, String>>> loadFullAttendance(String docId) async {
    final doc = await _db.collection('attendances').doc(docId).get();
    if (!doc.exists) return {};

    final data = doc.data()!;
    final attendanceRecords = data['attendanceRecords'] as Map<String, dynamic>? ?? {};

    return attendanceRecords.map((studentId, record) {
      final label = record['label'] as String? ?? 'A';
      final notes = record['notes'] as String? ?? '';
      return MapEntry(studentId, {'label': label, 'notes': notes});
    });
  }

  /// Now requires a students list to save student names
  Future<void> saveFullAttendance({
    required String docId,
    required Map<String, dynamic> generalInfo,
    required Map<String, String> attendanceMap,
    required Map<String, String> notesMap,
    required DateTime date,
    required String timeSlot,
    required String teacherId,
    required String teacherName,
    required List<Map<String, dynamic>> students,
  }) async {
    final timestamp = Timestamp.now();

    bool offTheClock = false;
    try {
      final slotParts = timeSlot.split('-');
      if (slotParts.length == 2) {
        final start = slotParts[0].trim();
        final end = slotParts[1].trim();
        final format = DateFormat('HH:mm');
        final now = DateTime.now();

        final startTime = format.parse(start);
        final endTime = format.parse(end);

        final nowMinutes = now.hour * 60 + now.minute;
        final slotStartMinutes = startTime.hour * 60 + startTime.minute;
        final slotEndMinutes = endTime.hour * 60 + endTime.minute;

        if (nowMinutes < slotStartMinutes || nowMinutes > slotEndMinutes) {
          offTheClock = true;
        }
      }
    } catch (e) {
      print('AttendanceService: Error parsing slot time for offTheClock: $e');
    }

    final attendanceRecords = <String, Map<String, dynamic>>{};
    attendanceMap.forEach((studentId, label) {
      final labelInfo = attendanceLabels[label] ?? attendanceLabels['A']!;
      final student = students.firstWhere(
            (s) => s['id'] == studentId,
        orElse: () => {'name': 'Nombre no disponible'},
      );
      attendanceRecords[studentId] = {
        'label': label,
        'studentName': student['name'],
        'labelDescription': labelInfo['description'],
        'labelColor': labelInfo['color'].value.toRadixString(16).padLeft(8, '0'),
        'notes': notesMap[studentId] ?? '',
        'timestamp': timestamp,
        'offTheClock': offTheClock,
      };
    });

    final dateTimestamp = Timestamp.fromDate(DateTime(date.year, date.month, date.day));

    final dataToSave = {
      'date': dateTimestamp,
      'time': timeSlot,
      ...generalInfo,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'offTheClock': offTheClock, // <-- Added here at root level
      'attendanceRecords': attendanceRecords,
      'createdAt': timestamp,
      'updatedAt': timestamp,
    };

    print('AttendanceService: Saving attendance for docId $docId, offTheClock: $offTheClock');
    await _db.collection('attendances').doc(docId).set(dataToSave);
  }
}
