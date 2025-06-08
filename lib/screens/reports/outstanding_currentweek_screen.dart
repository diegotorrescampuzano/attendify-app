import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/reports/outstanding_currentweek_service.dart';

class OutstandingCurrentWeekScreen extends StatefulWidget {
  const OutstandingCurrentWeekScreen({Key? key}) : super(key: key);

  @override
  State<OutstandingCurrentWeekScreen> createState() => _OutstandingCurrentWeekScreenState();
}

class _OutstandingCurrentWeekScreenState extends State<OutstandingCurrentWeekScreen> {
  static const Color backgroundColor = Color(0xFFF0F0E3);
  static const Color primaryColor = Color(0xFF53A09D);

  final OutstandingCurrentWeekService _service = OutstandingCurrentWeekService();

  List<Map<String, dynamic>> _campuses = [];
  String? _selectedCampusId;

  List<Map<String, dynamic>> _teachers = [];
  List<String> _selectedTeacherIds = [];

  List<Map<String, dynamic>> _teacherLectures = [];
  Set<String> _registeredAttendance = {};

  Map<String, String> subjectNames = {};
  Map<String, String> homeroomNames = {};

  bool _loading = false;

  static const List<String> days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];
  static const Map<String, String> daysEs = {
    'Monday': 'Lunes',
    'Tuesday': 'Martes',
    'Wednesday': 'Miércoles',
    'Thursday': 'Jueves',
    'Friday': 'Viernes',
    'Saturday': 'Sábado',
    'Sunday': 'Domingo',
  };
  static const List<String> slotTimes = [
    '07:00-08:00',
    '08:00-09:00',
    '09:00-10:00',
    '10:00-11:00',
    '11:00-12:00',
    '12:00-13:00',
    '13:00-14:00',
    '14:00-15:00',
  ];

  final Map<String, Color> dayHeaderColors = {
    'Monday': Color(0xFFE3F2FD),
    'Tuesday': Color(0xFFFFF9C4),
    'Wednesday': Color(0xFFE1BEE7),
    'Thursday': Color(0xFFC8E6C9),
    'Friday': Color(0xFFFFCCBC),
    'Saturday': Color(0xFFD7CCC8),
    'Sunday': Color(0xFFFFFDE7),
  };

  @override
  void initState() {
    super.initState();
    _loadCampuses();
    _loadNames();
  }

  Future<void> _loadCampuses() async {
    setState(() => _loading = true);
    try {
      final campuses = await _service.fetchCampuses();
      setState(() {
        _campuses = campuses;
        _selectedCampusId = campuses.isNotEmpty ? campuses.first['id'] : null;
      });
      if (_selectedCampusId != null) {
        await _loadTeachers();
      }
    } catch (e) {
      print('[Screen] Error loading campuses: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando campus: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadTeachers() async {
    if (_selectedCampusId == null) return;
    setState(() => _loading = true);
    try {
      final teachers = await _service.fetchTeachersForCampus(_selectedCampusId!);
      setState(() {
        _teachers = teachers;
        _selectedTeacherIds = teachers.isNotEmpty ? [teachers.first['id']] : [];
      });
      await _loadTeacherLecturesAndAttendance();
    } catch (e) {
      print('[Screen] Error loading teachers: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando docentes: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadTeacherLecturesAndAttendance() async {
    if (_selectedCampusId == null || _selectedTeacherIds.isEmpty) return;
    setState(() => _loading = true);
    try {
      final lectures = await _service.fetchTeacherLectures(
        campusId: _selectedCampusId!,
        teacherIds: _selectedTeacherIds,
      );
      final weekRange = _getCurrentWeekRange();
      final attendance = await _service.fetchRegisteredAttendance(
        campusId: _selectedCampusId!,
        teacherIds: _selectedTeacherIds,
        weekStart: weekRange['start']!,
        weekEnd: weekRange['end']!,
      );
      setState(() {
        _teacherLectures = lectures;
        _registeredAttendance = attendance;
      });
      print('[Screen] Loaded lectures and attendance for week ${weekRange['start']} - ${weekRange['end']}');
      print('[Screen] Registered attendance keys:');
      for (final key in _registeredAttendance) {
        print('[Screen]   $key');
      }
    } catch (e) {
      print('[Screen] Error loading lectures/attendance: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando horarios/asistencias: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadNames() async {
    subjectNames = await _service.fetchNames('subjects');
    homeroomNames = await _service.fetchNames('homerooms');
    setState(() {});
  }

  /// Returns the start (Monday) and end (Sunday) of the current week.
  Map<String, DateTime> _getCurrentWeekRange() {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    final end = start.add(const Duration(days: 6));
    return {
      'start': DateTime(start.year, start.month, start.day),
      'end': DateTime(end.year, end.month, end.day, 23, 59, 59)
    };
  }

  /// Multi-select dropdown for teachers.
  Widget _buildTeacherMultiSelect() {
    return DropdownButtonFormField<String>(
      value: null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Docentes',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items: _teachers.map((teacher) {
        return DropdownMenuItem<String>(
          value: teacher['id'],
          child: Row(
            children: [
              Checkbox(
                value: _selectedTeacherIds.contains(teacher['id']),
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _selectedTeacherIds.add(teacher['id']);
                    } else {
                      _selectedTeacherIds.remove(teacher['id']);
                    }
                  });
                  _loadTeacherLecturesAndAttendance();
                },
              ),
              Text(teacher['name']),
            ],
          ),
        );
      }).toList(),
      onChanged: (_) {},
      selectedItemBuilder: (context) {
        return _teachers.map((teacher) {
          return Text(
            _selectedTeacherIds.contains(teacher['id'])
                ? teacher['name']
                : '',
            style: const TextStyle(color: Colors.black),
          );
        }).toList();
      },
    );
  }

  /// Builds the main schedule table with attendance coloring.
  Widget _buildScheduleTable() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_teacherLectures.isEmpty) {
      return const Center(child: Text('No hay horarios para mostrar.'));
    }

    // Header rows
    final headerRow = <Widget>[
      Container(
        alignment: Alignment.center,
        color: primaryColor.withOpacity(0.1),
        padding: const EdgeInsets.all(8),
        child: const Text('Docente', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      for (final day in days)
        for (int slot = 0; slot < 8; slot++)
          Container(
            alignment: Alignment.center,
            color: dayHeaderColors[day],
            padding: const EdgeInsets.all(8),
            child: Text(
              daysEs[day]!,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
    ];

    final slotRow = <Widget>[
      Container(),
      for (int i = 0; i < days.length * 8; i++)
        Container(
          alignment: Alignment.center,
          color: dayHeaderColors[days[i ~/ 8]],
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            'S${(i % 8) + 1}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
    ];

    final timeRow = <Widget>[
      Container(),
      for (int i = 0; i < days.length * 8; i++)
        Container(
          alignment: Alignment.center,
          color: backgroundColor,
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            slotTimes[i % 8],
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ),
    ];

    // Data rows
    final teacherRows = _teacherLectures.map((lecture) {
      final cells = <Widget>[];
      // First column: teacher name
      cells.add(Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          lecture['teacherName'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ));

      for (final day in days) {
        final dayLectures = (lecture['lectures'][day.toLowerCase()] ?? []) as List<dynamic>;
        for (int slot = 1; slot <= 8; slot++) {
          final slotData = dayLectures.cast<Map<String, dynamic>?>().firstWhere(
                (s) => s != null && (s['slot'] == slot || s['slot'] == slot.toString()),
            orElse: () => null,
          );
          if (slotData == null ||
              slotData['homeroom'] == null ||
              slotData['subject'] == null ||
              slotData['homeroom'] == '' ||
              slotData['subject'] == '') {
            cells.add(Container(
              alignment: Alignment.center,
              color: Colors.grey[100],
              child: Text(
                'Libre',
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ));
          } else {
            // Defensive: always use string for slot, lowercase for day, and string IDs
            final homeroomId = slotData['homeroom'] is DocumentReference
                ? (slotData['homeroom'] as DocumentReference).id
                : slotData['homeroom'].toString().trim();
            final subjectId = slotData['subject'] is DocumentReference
                ? (slotData['subject'] as DocumentReference).id
                : slotData['subject'].toString().trim();
            final subjectName = subjectNames[subjectId] ?? subjectId;
            final homeroomName = homeroomNames[homeroomId] ?? homeroomId;
            final slotStr = slot.toString().trim();
            final dayStr = day.toLowerCase().trim();
            final attendanceKey =
                '${lecture['teacherId']}|$dayStr|$slotStr|$homeroomId|$subjectId';
            final attendanceExists = _registeredAttendance.contains(attendanceKey);

            print('[Screen] Checking attendance for key: $attendanceKey - Exists: $attendanceExists');

            cells.add(Container(
              alignment: Alignment.center,
              color: attendanceExists
                  ? Colors.green.withOpacity(0.4)
                  : Colors.red.withOpacity(0.4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    homeroomName,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    subjectName,
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ));
          }
        }
      }
      while (cells.length < 57) {
        cells.add(Container());
      }
      return TableRow(children: cells);
    }).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        border: TableBorder.all(color: Colors.grey.shade400),
        defaultColumnWidth: const IntrinsicColumnWidth(),
        children: [
          TableRow(children: headerRow),
          TableRow(children: slotRow),
          TableRow(children: timeRow),
          ...teacherRows,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text('Asistencias Pendientes (Semana Actual)'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Campus dropdown
            DropdownButtonFormField<String>(
              value: _selectedCampusId,
              decoration: InputDecoration(
                labelText: 'Campus',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: _campuses.map((campus) {
                return DropdownMenuItem<String>(
                  value: campus['id'],
                  child: Text(campus['name']),
                );
              }).toList(),
              onChanged: (campusId) async {
                setState(() {
                  _selectedCampusId = campusId;
                  _selectedTeacherIds = [];
                  _teachers = [];
                  _teacherLectures = [];
                });
                await _loadTeachers();
              },
            ),
            const SizedBox(height: 12),
            // Teacher multi-select
            if (_teachers.isNotEmpty)
              _buildTeacherMultiSelect(),
            const SizedBox(height: 16),
            // Schedule table
            Expanded(child: _buildScheduleTable()),
          ],
        ),
      ),
    );
  }
}
