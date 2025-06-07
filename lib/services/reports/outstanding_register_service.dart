import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Service to fetch and process outstanding attendance records.
class OutstandingRegisterService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fetch all teacher lectures with nested lectures map.
  Future<List<TeacherLecture>> fetchTeacherLectures() async {
    print('Fetching teacher lectures...');
    final snapshot = await _db.collection('teacherLectures').get();

    print('Fetched ${snapshot.docs.length} teacher lectures');
    return snapshot.docs.map((doc) {
      final data = doc.data();

      // Extract campus ID from DocumentReference or String
      String campusId = '';
      if (data['campus'] is DocumentReference) {
        campusId = (data['campus'] as DocumentReference).id;
      } else if (data['campus'] is String) {
        campusId = data['campus'] ?? '';
      }

      // Extract teacherId from either a 'teacherId' string or a 'teacher' DocumentReference
      String teacherId = '';
      if (data['teacherId'] != null && data['teacherId'] is String) {
        teacherId = data['teacherId'];
      } else if (data['teacher'] is DocumentReference) {
        teacherId = (data['teacher'] as DocumentReference).id;
      }
      // Defensive: teacherName from field if present, else fallback to empty
      final teacherName = data['teacherName']?.toString() ?? '';

      // Parse nested lectures map by weekday
      final lecturesRaw = data['lectures'] as Map<String, dynamic>? ?? {};

      final lecturesByWeekday = <String, List<LectureSlot>>{};

      lecturesRaw.forEach((weekday, slotsList) {
        if (slotsList is List) {
          final slots = <LectureSlot>[];
          for (var slotEntry in slotsList) {
            if (slotEntry is Map<String, dynamic>) {
              String homeroomId = '';
              if (slotEntry['homeroom'] is DocumentReference) {
                homeroomId = (slotEntry['homeroom'] as DocumentReference).id;
              } else if (slotEntry['homeroom'] is String) {
                homeroomId = slotEntry['homeroom'] ?? '';
              }

              String subjectId = '';
              if (slotEntry['subject'] is DocumentReference) {
                subjectId = (slotEntry['subject'] as DocumentReference).id;
              } else if (slotEntry['subject'] is String) {
                subjectId = slotEntry['subject'] ?? '';
              }

              int slotNumber = 0;
              if (slotEntry['slot'] is int) {
                slotNumber = slotEntry['slot'];
              } else if (slotEntry['slot'] is String) {
                slotNumber = int.tryParse(slotEntry['slot']) ?? 0;
              }

              String timeRange = slotEntry['time'] ?? '';

              slots.add(LectureSlot(
                homeroomId: homeroomId,
                slotNumber: slotNumber,
                subjectId: subjectId,
                timeRange: timeRange,
              ));
            }
          }
          lecturesByWeekday[weekday] = slots;
        }
      });

      print('TeacherLecture: teacherId=$teacherId, teacherName=$teacherName, campusId=$campusId');
      return TeacherLecture(
        teacherId: teacherId,
        teacherName: teacherName,
        campusId: campusId,
        lecturesByWeekday: lecturesByWeekday,
      );
    }).toList();
  }

  /// Fetch attendance records within date range.
  Future<List<AttendanceRecord>> fetchAttendances(DateTime start, DateTime end) async {
    print('Fetching attendances from $start to $end...');
    final startTimestamp = Timestamp.fromDate(DateTime(start.year, start.month, start.day));
    final endTimestamp = Timestamp.fromDate(DateTime(end.year, end.month, end.day, 23, 59, 59));

    final snapshot = await _db
        .collection('attendances')
        .where('date', isGreaterThanOrEqualTo: startTimestamp)
        .where('date', isLessThanOrEqualTo: endTimestamp)
        .get();

    print('Fetched ${snapshot.docs.length} attendance records');
    final List<AttendanceRecord> records = [];

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final teacherId = data['teacherId']?.toString() ?? '';
      final dateTimestamp = data['date'] as Timestamp?;
      final date = dateTimestamp?.toDate() ?? DateTime.now();

      int slotNumber = 0;
      if (data['slot'] is int) {
        slotNumber = data['slot'];
      } else if (data['slot'] is String) {
        slotNumber = int.tryParse(data['slot']) ?? 0;
      }

      records.add(AttendanceRecord(
        teacherId: teacherId,
        date: DateTime(date.year, date.month, date.day),
        slotNumber: slotNumber,
      ));
    }

    return records;
  }

  /// Identify missing attendance by comparing schedules vs attendances.
  Future<List<OutstandingAttendance>> findOutstandingAttendance(DateTime start, DateTime end) async {
    final lectures = await fetchTeacherLectures();
    final attendances = await fetchAttendances(start, end);

    // Build a set of existing attendance keys for quick lookup
    final attendanceSet = <String>{};
    for (var att in attendances) {
      final key = '${att.teacherId}_${_formatDate(att.date)}_${att.slotNumber}';
      attendanceSet.add(key);
    }

    final List<OutstandingAttendance> outstanding = [];
    final datesInRange = _datesInRange(start, end);

    for (var lecture in lectures) {
      for (var date in datesInRange) {
        final weekdayName = _weekdayName(date);
        final slotsForDay = lecture.lecturesByWeekday[weekdayName.toLowerCase()] ?? [];

        for (var slot in slotsForDay) {
          final key = '${lecture.teacherId}_${_formatDate(date)}_${slot.slotNumber}';
          if (!attendanceSet.contains(key)) {
            outstanding.add(OutstandingAttendance(
              campus: lecture.campusId,
              teacherId: lecture.teacherId,
              teacherName: lecture.teacherName,
              date: date,
              day: weekdayName,
              timeRange: slot.timeRange,
              slotNumber: slot.slotNumber,
              subject: slot.subjectId,
              homeroom: slot.homeroomId,
            ));
          }
        }
      }
    }

    print('Outstanding records found: ${outstanding.length}');
    outstanding.sort((a, b) {
      final cmpCampus = a.campus.compareTo(b.campus);
      if (cmpCampus != 0) return cmpCampus;
      final cmpTeacher = a.teacherName.compareTo(b.teacherName);
      if (cmpTeacher != 0) return cmpTeacher;
      final cmpDate = a.date.compareTo(b.date);
      if (cmpDate != 0) return cmpDate;
      return a.slotNumber.compareTo(b.slotNumber);
    });

    return outstanding;
  }

  List<DateTime> _datesInRange(DateTime start, DateTime end) {
    final days = <DateTime>[];
    for (var i = 0; i <= end.difference(start).inDays; i++) {
      days.add(DateTime(start.year, start.month, start.day).add(Duration(days: i)));
    }
    return days;
  }

  String _weekdayName(DateTime date) {
    return DateFormat('EEEE').format(date); // e.g., Monday
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}

class TeacherLecture {
  final String teacherId;
  final String teacherName;
  final String campusId;
  final Map<String, List<LectureSlot>> lecturesByWeekday;

  TeacherLecture({
    required this.teacherId,
    required this.teacherName,
    required this.campusId,
    required this.lecturesByWeekday,
  });
}

class LectureSlot {
  final String homeroomId;
  final int slotNumber;
  final String subjectId;
  final String timeRange;

  LectureSlot({
    required this.homeroomId,
    required this.slotNumber,
    required this.subjectId,
    required this.timeRange,
  });
}

class AttendanceRecord {
  final String teacherId;
  final DateTime date;
  final int slotNumber;

  AttendanceRecord({
    required this.teacherId,
    required this.date,
    required this.slotNumber,
  });
}

class OutstandingAttendance {
  final String campus;
  final String teacherId;
  final String teacherName;
  final DateTime date;
  final String day;
  final String timeRange;
  final int slotNumber;
  final String subject;
  final String homeroom;

  OutstandingAttendance({
    required this.campus,
    required this.teacherId,
    required this.teacherName,
    required this.date,
    required this.day,
    required this.timeRange,
    required this.slotNumber,
    required this.subject,
    required this.homeroom,
  });
}
