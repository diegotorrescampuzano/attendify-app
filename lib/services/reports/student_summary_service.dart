// /lib/services/reports/student_summary_service.dart

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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch students from 'students' collection, optionally filtered by name, homeroom, or cellphoneContact
  Future<List<Map<String, dynamic>>> fetchStudents({String query = ''}) async {
    print('Fetching students with query: "$query"');
    final snapshot = await _firestore.collection('students').get();

    print('Total students fetched from Firestore: ${snapshot.docs.length}');

    final lowerQuery = query.toLowerCase();

    final filteredStudents = snapshot.docs
        .map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      print('Processing student doc with ID: ${doc.id}'); // Log doc ID
      return {
        'refId': doc.id, // Use doc.id as refId
        'name': data['name'] ?? '',
        'homeroom': data['homeroom'] ?? '',
        'cellphoneContact': data['cellphoneContact'] ?? '',
      };
    })
        .where((data) {
      final name = data['name'].toString().toLowerCase();
      final homeroom = data['homeroom'].toString().toLowerCase();
      final cellphone = data['cellphoneContact'].toString().toLowerCase();
      final matches = query.isEmpty || name.contains(query) || homeroom.contains(query) || cellphone.contains(query);
      return matches;
    })
        .toList();

    print('Filtered students count: ${filteredStudents.length}');
    print('Student refIds after processing: ${filteredStudents.map((s) => s['refId']).toList()}'); // Log refIds

    return filteredStudents;
  }

  /// Fetch detailed attendance for a student in a date range
  ///
  Future<Map<String, Map<String, String>>> fetchStudentAttendanceDetail({
    required String studentRefId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    print('Fetching attendance detail for studentRefId: $studentRefId');
    print('Date range: ${startDate.toIso8601String()} to ${endDate.toIso8601String()}');

    final startTimestamp = Timestamp.fromDate(DateTime(startDate.year, startDate.month, startDate.day));
    final endTimestamp = Timestamp.fromDate(DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59));

    final snapshot = await _firestore
        .collection('attendances')
        .where('date', isGreaterThanOrEqualTo: startTimestamp)
        .where('date', isLessThanOrEqualTo: endTimestamp)
        .get();

    print('Total attendance records fetched: ${snapshot.docs.length}');

    final Map<String, Map<String, String>> detail = {}; // subjectName -> date -> label

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final subjectName = data['subjectName'] ?? 'Sin asignatura';
      final dateTimestamp = data['date'] as Timestamp?;
      final dateStr = dateTimestamp != null
          ? '${dateTimestamp.toDate().year.toString().padLeft(4, '0')}-${dateTimestamp.toDate().month.toString().padLeft(2, '0')}-${dateTimestamp.toDate().day.toString().padLeft(2, '0')}'
          : '';

      final attendanceRecordsDynamic = data['attendanceRecords'];
      if (attendanceRecordsDynamic == null || attendanceRecordsDynamic is! Map<String, dynamic>) {
        continue;
      }
      final attendanceRecords = Map<String, dynamic>.from(attendanceRecordsDynamic);

      if (attendanceRecords.containsKey(studentRefId)) {
        final studentAttendance = attendanceRecords[studentRefId];
        if (studentAttendance is Map<String, dynamic>) {
          final label = (studentAttendance['label'] ?? '').toString();
          detail.putIfAbsent(subjectName, () => {});
          detail[subjectName]![dateStr] = label;
          print('Attendance for subject "$subjectName" on $dateStr: $label');
        }
      }
    }
    print('Attendance detail map constructed with ${detail.length} subjects');
    return detail;
  }
}
