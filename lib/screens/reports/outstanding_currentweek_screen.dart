import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

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

  Map<String, String> _subjectNames = {};
  Map<String, String> _homeroomNames = {};

  bool _loading = false;

  int _lastRed = 0;
  int _lastGreen = 0;
  int _lastLibre = 0;

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
    _subjectNames = await _service.fetchNames('subjects');
    _homeroomNames = await _service.fetchNames('homerooms');
    setState(() {});
  }

  Map<String, DateTime> _getCurrentWeekRange() {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    final end = start.add(const Duration(days: 6));
    return {
      'start': DateTime(start.year, start.month, start.day),
      'end': DateTime(end.year, end.month, end.day, 23, 59, 59)
    };
  }

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

  Widget _buildColorLegend() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                color: Colors.red.withOpacity(0.4),
              ),
              const SizedBox(width: 8),
              const Text('Asistencias pendientes por registrar', style: TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                color: Colors.green.withOpacity(0.4),
              ),
              const SizedBox(width: 8),
              const Text('Asistencias registradas', style: TextStyle(fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleTable({void Function(int, int, int)? onStats}) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_teacherLectures.isEmpty) {
      if (onStats != null) onStats(0, 0, 0);
      return const Center(child: Text('No hay horarios para mostrar.'));
    }

    int redCount = 0;
    int greenCount = 0;
    int libreCount = 0;

    final headerRow = <Widget>[
      Container(
        alignment: Alignment.centerLeft,
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

    final teacherRows = _teacherLectures.map((lecture) {
      final cells = <Widget>[];
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
            libreCount++;
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
            final homeroomId = slotData['homeroom'] is DocumentReference
                ? (slotData['homeroom'] as DocumentReference).id
                : slotData['homeroom'].toString().trim();
            final subjectId = slotData['subject'] is DocumentReference
                ? (slotData['subject'] as DocumentReference).id
                : slotData['subject'].toString().trim();
            final subjectName = _subjectNames[subjectId] ?? subjectId;
            final homeroomName = _homeroomNames[homeroomId] ?? homeroomId;
            final slotStr = slot.toString().trim();
            final dayStr = day.toLowerCase().trim();
            final attendanceKey =
                '${lecture['teacherId']}|$dayStr|$slotStr|$homeroomId|$subjectId';
            final attendanceExists = _registeredAttendance.contains(attendanceKey);

            print('[Screen] Checking attendance for key: $attendanceKey - Exists: $attendanceExists');

            if (attendanceExists) {
              greenCount++;
            } else {
              redCount++;
            }

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

    if (onStats != null) onStats(redCount, greenCount, libreCount);

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

  Widget _buildChartIfSingleTeacher() {
    if (_teacherLectures.length != 1) return const SizedBox.shrink();
    final total = _lastRed + _lastGreen + _lastLibre;
    if (total == 0) return const SizedBox.shrink();

    final sections = <PieChartSectionData>[
      if (_lastRed > 0)
        PieChartSectionData(
          value: _lastRed.toDouble(),
          color: Colors.red.withOpacity(0.7),
          title: 'Pendientes\n${((_lastRed / total) * 100).toStringAsFixed(1)}%',
          titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      if (_lastGreen > 0)
        PieChartSectionData(
          value: _lastGreen.toDouble(),
          color: Colors.green.withOpacity(0.7),
          title: 'Registradas\n${((_lastGreen / total) * 100).toStringAsFixed(1)}%',
          titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      if (_lastLibre > 0)
        PieChartSectionData(
          value: _lastLibre.toDouble(),
          color: Colors.grey.withOpacity(0.5),
          title: 'Libre\n${((_lastLibre / total) * 100).toStringAsFixed(1)}%',
          titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            "Resumen de asistencias del docente",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 40,
                sectionsSpace: 2,
                borderData: FlBorderData(show: false),
                pieTouchData: PieTouchData(enabled: false),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Custom legend with totals
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildChartLegendDot(Colors.red.withOpacity(0.7)),
              const SizedBox(width: 6),
              Text('Pendientes: $_lastRed', style: const TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(width: 16),
              _buildChartLegendDot(Colors.green.withOpacity(0.7)),
              const SizedBox(width: 6),
              Text('Registradas: $_lastGreen', style: const TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(width: 16),
              _buildChartLegendDot(Colors.grey.withOpacity(0.5)),
              const SizedBox(width: 6),
              Text('Libre: $_lastLibre', style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegendDot(Color color) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
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
            if (_teachers.isNotEmpty)
              _buildTeacherMultiSelect(),
            const SizedBox(height: 16),
            _buildColorLegend(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Builder(
                      builder: (context) {
                        return _buildScheduleTable(
                          onStats: (r, g, l) {
                            _lastRed = r;
                            _lastGreen = g;
                            _lastLibre = l;
                          },
                        );
                      },
                    ),
                    _buildChartIfSingleTeacher(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
