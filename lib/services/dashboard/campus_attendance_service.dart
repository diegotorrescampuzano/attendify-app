import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DashboardService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get teacher document data by their refId (e.g. "teacher_001")
  static Future<Map<String, dynamic>?> getTeacherDataByRefId(String refId) async {
    print('DashboardService: Fetching teacher data for refId: $refId');
    final doc = await _firestore.collection('teachers').doc(refId).get();
    if (!doc.exists) {
      print('DashboardService: No teacher document found for refId: $refId');
      return null;
    }
    final data = doc.data();
    print('DashboardService: Teacher data found: $data');
    return data;
  }

  /// Get attendance summary by grade filtered by campusId
  static Future<List<Map<String, dynamic>>> getAttendanceSummaryByGradeFilteredByCampus(String campusId) async {
    print('DashboardService: Getting attendance summary for campusId: $campusId');

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // 1. Get educational levels for the campus
    final campusDocRef = _firestore.collection('campuses').doc(campusId);
    final educationalLevelsSnap = await _firestore
        .collection('educationalLevels')
        .where('campusId', isEqualTo: campusDocRef)
        .get();

    if (educationalLevelsSnap.docs.isEmpty) {
      print('DashboardService: No educational levels found for campusId: $campusId');
      return [];
    }
    final educationalLevelIds = educationalLevelsSnap.docs.map((d) => d.id).toList();
    print('DashboardService: Found educationalLevelIds: $educationalLevelIds');

    // 2. Convert educationalLevelIds to DocumentReferences for querying grades
    final educationalLevelRefs = educationalLevelIds
        .map((id) => _firestore.collection('educationalLevels').doc(id))
        .toList();

    // 3. Get grades under those educational levels (query by DocumentReference)
    final gradesSnap = await _firestore
        .collection('grades')
        .where('educationalLevelId', whereIn: educationalLevelRefs)
        .get();

    if (gradesSnap.docs.isEmpty) {
      print('DashboardService: No grades found for educationalLevelIds: $educationalLevelIds');
      return [];
    }
    final grades = {for (var doc in gradesSnap.docs) doc.id: doc.data()};
    final gradeIds = grades.keys.toList();
    print('DashboardService: Found gradeIds: $gradeIds');

    // 4. Convert gradeIds to DocumentReferences for querying homerooms
    final gradeRefs = gradeIds.map((id) => _firestore.collection('grades').doc(id)).toList();

    // 5. Get homerooms under those grades (query by DocumentReference)
    final homeroomsSnap = await _firestore
        .collection('homerooms')
        .where('gradeId', whereIn: gradeRefs)
        .get();

    if (homeroomsSnap.docs.isEmpty) {
      print('DashboardService: No homerooms found for gradeIds: $gradeIds');
      return [];
    }
    final homerooms = {for (var doc in homeroomsSnap.docs) doc.id: doc.data()};
    final homeroomRefs = homerooms.keys.map((id) => _firestore.collection('homerooms').doc(id)).toList();
    print('DashboardService: Found homeroomIds: ${homerooms.keys.toList()}');

    // 6. Get students belonging to those homerooms (client-side filter)
    final studentsSnap = await _firestore.collection('students').get();
    final students = studentsSnap.docs.where((doc) {
      final homeroomRef = doc.data()['homeroom'];
      if (homeroomRef is DocumentReference) {
        return homeroomRefs.any((ref) => ref.id == homeroomRef.id);
      }
      return false;
    }).map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();

    if (students.isEmpty) {
      print('DashboardService: No students found for homerooms: ${homerooms.keys.toList()}');
      return [];
    }
    print('DashboardService: Found ${students.length} students for campusId: $campusId');

    // 7. Fetch today's attendance documents (date is Timestamp)
    final attendancesSnap = await _firestore
        .collection('attendances')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    if (attendancesSnap.docs.isEmpty) {
      print('DashboardService: No attendance documents found for today');
    } else {
      print('DashboardService: Found ${attendancesSnap.docs.length} attendance documents for today');
    }

    // Map studentId to attendance label for today
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

    // 8. Calculate expected and actual attendance by grade
    final Map<String, int> expectedByGrade = {};
    final Map<String, int> asisteByGrade = {};
    final Map<String, int> conNovedadByGrade = {};

    for (var student in students) {
      final homeroomRef = student['homeroom'];
      String homeroomId;
      if (homeroomRef is DocumentReference) {
        homeroomId = homeroomRef.id;
      } else if (homeroomRef is String) {
        homeroomId = homeroomRef;
      } else {
        continue;
      }

      final homeroom = homerooms[homeroomId];
      if (homeroom == null) continue;

      final gradeRef = homeroom['gradeId'];
      String gradeId;
      if (gradeRef is DocumentReference) {
        gradeId = gradeRef.id;
      } else if (gradeRef is String) {
        gradeId = gradeRef;
      } else {
        continue;
      }

      expectedByGrade[gradeId] = (expectedByGrade[gradeId] ?? 0) + 1;

      final label = studentLabels[student['id']];
      if (label == 'A') {
        asisteByGrade[gradeId] = (asisteByGrade[gradeId] ?? 0) + 1;
      } else if (label != null) {
        conNovedadByGrade[gradeId] = (conNovedadByGrade[gradeId] ?? 0) + 1;
      }
    }

    // 9. Prepare summary list
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

    print('DashboardService: Returning summary: $summary');
    return summary;
  }
}
