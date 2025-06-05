import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DashboardService {
  static Future<List<Map<String, dynamic>>> getAttendanceSummaryByGrade() async {
    final firestore = FirebaseFirestore.instance;
    final todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // 1. Fetch all grades
    final gradesSnap = await firestore.collection('grades').get();
    final grades = {for (var doc in gradesSnap.docs) doc.id: doc.data()};

    // 2. Fetch all homerooms
    final homeroomsSnap = await firestore.collection('homerooms').get();
    final homerooms = {for (var doc in homeroomsSnap.docs) doc.id: doc.data()};

    // 3. Fetch all students
    final studentsSnap = await firestore.collection('students').get();
    final students = studentsSnap.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();

    // 4. Fetch today's attendance records
    // Assuming attendance documents are named with date or have a 'date' field as string yyyy-MM-dd
    final attendancesSnap = await firestore
        .collection('attendances')
        .where('date', isEqualTo: DateTime.parse(todayDate))
        .get();

    // Map studentId to their attendance label for today
    final Map<String, String> studentLabels = {};
    for (var doc in attendancesSnap.docs) {
      final data = doc.data();
      final attendanceRecords = data['attendanceRecords'] as Map<String, dynamic>? ?? {};
      attendanceRecords.forEach((studentId, record) {
        if (record is Map && record['label'] != null) {
          studentLabels[studentId] = record['label'];
        }
      });
    }

    // 5. Calculate expected and actual attendance by grade
    final Map<String, int> expectedByGrade = {};
    final Map<String, int> asisteByGrade = {};
    final Map<String, int> conNovedadByGrade = {};

    for (var student in students) {
      // Extract homeroom ID from DocumentReference or string
      final homeroomRef = student['homeroom'];
      String homeroomId;
      if (homeroomRef is DocumentReference) {
        homeroomId = homeroomRef.id;
      } else if (homeroomRef is String) {
        homeroomId = homeroomRef;
      } else {
        continue; // skip if no valid homeroom
      }

      final homeroom = homerooms[homeroomId];
      if (homeroom == null) continue;

      // Extract grade ID from DocumentReference or string
      final gradeRef = homeroom['gradeId'];
      String gradeId;
      if (gradeRef is DocumentReference) {
        gradeId = gradeRef.id;
      } else if (gradeRef is String) {
        gradeId = gradeRef;
      } else {
        continue; // skip if no valid grade
      }

      expectedByGrade[gradeId] = (expectedByGrade[gradeId] ?? 0) + 1;

      final label = studentLabels[student['id']];
      if (label == 'A') {
        asisteByGrade[gradeId] = (asisteByGrade[gradeId] ?? 0) + 1;
      } else if (label != null) {
        conNovedadByGrade[gradeId] = (conNovedadByGrade[gradeId] ?? 0) + 1;
      }
    }

    // 6. Prepare summary list
    final List<Map<String, dynamic>> summary = [];
    expectedByGrade.forEach((gradeId, expectedCount) {
      final gradeName = grades[gradeId]?['name'] ?? gradeId;
      summary.add({
        'gradeId': gradeId,
        'gradeName': gradeName,
        'expected': expectedCount,
        'asiste': asisteByGrade[gradeId] ?? 0,
        'conNovedad': conNovedadByGrade[gradeId] ?? 0,
      });
    });

    return summary;
  }
}
