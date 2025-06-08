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

  /// Generates the document ID for an attendance record.
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

  /// Loads all attendance records for a given document.
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

  /// Saves attendance for all students, including the day field.
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
    final now = Timestamp.now();

    // Get existing document to check if it's a creation or update
    final docRef = _db.collection('attendances').doc(docId);
    final docSnap = await docRef.get();

    bool isNewDocument = !docSnap.exists;

    // Try to preserve existing createdAt if updating
    Timestamp? existingCreatedAt;
    Map<String, dynamic>? existingAttendanceRecords;
    if (!isNewDocument) {
      final data = docSnap.data();
      existingCreatedAt = data?['createdAt'] as Timestamp?;
      existingAttendanceRecords = data?['attendanceRecords'] as Map<String, dynamic>?;
    }

    bool offTheClock = false;
    try {
      final slotParts = timeSlot.split('-');
      if (slotParts.length == 2) {
        final start = slotParts[0].trim();
        final end = slotParts[1].trim();
        final format = DateFormat('HH:mm');
        final nowDateTime = DateTime.now();

        final startTime = format.parse(start);
        final endTime = format.parse(end);

        final nowMinutes = nowDateTime.hour * 60 + nowDateTime.minute;
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

      // Preserve createdAt for each student attendance record if exists
      Timestamp? studentCreatedAt;
      if (existingAttendanceRecords != null && existingAttendanceRecords.containsKey(studentId)) {
        final existingRecord = existingAttendanceRecords[studentId] as Map<String, dynamic>?;
        if (existingRecord != null && existingRecord['createdAt'] is Timestamp) {
          studentCreatedAt = existingRecord['createdAt'] as Timestamp;
        }
      }

      attendanceRecords[studentId] = {
        'label': label,
        'studentName': student['name'],
        'labelDescription': labelInfo['description'],
        'labelColor': labelInfo['color'].value.toRadixString(16).padLeft(8, '0'),
        'notes': notesMap[studentId] ?? '',
        'offTheClock': offTheClock,
        'createdAt': studentCreatedAt ?? now,
        'updatedAt': now,
      };
    });

    final dateTimestamp = Timestamp.fromDate(DateTime(date.year, date.month, date.day));

    // Compute the day of the week (e.g. "monday")
    String getDayOfWeek(DateTime date) {
      const days = [
        'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
      ];
      return days[date.weekday - 1];
    }

    // Add the day field to the generalInfo
    final generalInfoWithDay = Map<String, dynamic>.from(generalInfo)
      ..['day'] = getDayOfWeek(date);

    final dataToSave = {
      'date': dateTimestamp,
      'time': timeSlot,
      ...generalInfoWithDay,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'offTheClock': offTheClock,
      'attendanceRecords': attendanceRecords,
      'createdAt': existingCreatedAt ?? now,
      'updatedAt': now,
    };

    print('AttendanceService: Saving attendance for docId $docId, day: ${generalInfoWithDay['day']}, offTheClock: $offTheClock, isNew: $isNewDocument');
    await docRef.set(dataToSave);
  }
}
