import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class OffTheClockSummaryService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Returns the current week's Monday and today.
  List<DateTime> _currentWeekRangeToToday() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final today = DateTime(now.year, now.month, now.day);
    return [DateTime(monday.year, monday.month, monday.day), today];
  }

  /// Returns a summary by teacher for offTheClock attendances in the given campus for the current week to today.
  /// Each summary contains:
  /// - teacherId, teacherName
  /// - totalOffTheClockTrue, totalOffTheClockFalse
  /// - averageDelay (for offTheClock==false, in minutes)
  /// - records: list of attendance docs for that teacher
  Future<List<Map<String, dynamic>>> getOffTheClockSummary({
    required String campusId,
  }) async {
    try {
      final weekRange = _currentWeekRangeToToday();
      final start = weekRange[0];
      final end = weekRange[1];

      print('OffTheClockSummaryService: Fetching attendances for week $start to $end for campus $campusId');

      // 1. Fetch all attendances for the current week (till today) and campus
      final attendancesSnap = await _db.collection('attendances')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .where('campusId', isEqualTo: campusId)
          .get();
      print('OffTheClockSummaryService: Found ${attendancesSnap.docs.length} attendance records in week');

      // 2. Group by teacher
      final Map<String, List<Map<String, dynamic>>> recordsByTeacher = {};
      for (final doc in attendancesSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final teacherId = data['teacherId']?.toString() ?? 'unknown';
        recordsByTeacher.putIfAbsent(teacherId, () => []).add(data);
      }

      final List<Map<String, dynamic>> summaries = [];

      for (final teacherId in recordsByTeacher.keys) {
        final records = recordsByTeacher[teacherId]!;

        final teacherName = records.first['teacherName']?.toString() ?? 'Sin docente';

        int totalOffTheClockTrue = 0;
        int totalOffTheClockFalse = 0;
        int delaySumMinutesFalse = 0;
        int delayCountFalse = 0;
        int delaySumMinutesTrue = 0;
        int delayCountTrue = 0;

        for (final rec in records) {
          final offTheClock = rec['offTheClock'] == true;
          final createdAt = rec['createdAt'];
          final timeStr = rec['time']?.toString();
          final date = (rec['date'] is Timestamp)
              ? (rec['date'] as Timestamp).toDate()
              : (rec['date'] is String)
              ? DateTime.tryParse(rec['date'])
              : null;
          if (offTheClock) {
            totalOffTheClockTrue++;
          } else {
            totalOffTheClockFalse++;
          }
          // Calculate delay for both true and false
          if (createdAt != null && timeStr != null && date != null) {
            try {
              final endTimeStr = timeStr.split('-').last.trim();
              final endParts = endTimeStr.split(':');
              final endHour = int.parse(endParts[0]);
              final endMinute = int.parse(endParts[1]);
              final endDateTime = DateTime(date.year, date.month, date.day, endHour, endMinute);
              final createdAtDT = createdAt is Timestamp
                  ? createdAt.toDate()
                  : (createdAt is DateTime ? createdAt : DateTime.tryParse(createdAt.toString()));
              if (createdAtDT != null) {
                final delay = createdAtDT.difference(endDateTime);
                final delayMinutes = delay.inMinutes;
                if (delayMinutes > 0) {
                  if (offTheClock) {
                    delaySumMinutesTrue += delayMinutes;
                    delayCountTrue++;
                  } else {
                    delaySumMinutesFalse += delayMinutes;
                    delayCountFalse++;
                  }
                }
              }
            } catch (e) {
              print('OffTheClockSummaryService: Error parsing delay: $e');
            }
          }
        }

        final avgDelayMinutesFalse = delayCountFalse > 0 ? (delaySumMinutesFalse / delayCountFalse).round() : 0;
        final avgDelayMinutesTrue = delayCountTrue > 0 ? (delaySumMinutesTrue / delayCountTrue).round() : 0;

        summaries.add({
          'teacherId': teacherId,
          'teacherName': teacherName,
          'totalOffTheClockTrue': totalOffTheClockTrue,
          'totalOffTheClockFalse': totalOffTheClockFalse,
          'averageDelayMinutes': avgDelayMinutesFalse,
          'averageOffTheClockDelayMinutes': avgDelayMinutesTrue,
          'records': records,
        });

        print('OffTheClockSummaryService: Summary for $teacherName: true=$totalOffTheClockTrue, false=$totalOffTheClockFalse, avgDelayFalse=$avgDelayMinutesFalse min, avgDelayTrue=$avgDelayMinutesTrue min');
      }

      // Sort by teacherName
      summaries.sort((a, b) => (a['teacherName'] ?? '').compareTo(b['teacherName'] ?? ''));

      print('OffTheClockSummaryService: Returning ${summaries.length} teacher summaries');
      return summaries;
    } catch (e) {
      print('OffTheClockSummaryService: Error: $e');
      return [];
    }
  }
}
