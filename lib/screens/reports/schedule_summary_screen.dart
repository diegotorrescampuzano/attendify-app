import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/reports/schedule_summary_service.dart';

class ScheduleSummaryScreen extends StatefulWidget {
  const ScheduleSummaryScreen({Key? key}) : super(key: key);

  @override
  State<ScheduleSummaryScreen> createState() => _ScheduleSummaryScreenState();
}

class _ScheduleSummaryScreenState extends State<ScheduleSummaryScreen> {
  static const Color backgroundColor = Color(0xFFF0F0E3);
  static const Color primaryColor = Color(0xFF53A09D);

  final ScheduleSummaryService _service = ScheduleSummaryService();

  List<Map<String, dynamic>> _campuses = [];
  String? _selectedCampusId;

  List<Map<String, dynamic>> _teachers = [];
  List<String> _selectedTeacherIds = [];

  List<Map<String, dynamic>> _teacherLectures = [];

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

  // Assign a fixed color to each day for header columns
  final Map<String, Color> dayHeaderColors = {
    'Monday': Color(0xFFE3F2FD),     // Light Blue
    'Tuesday': Color(0xFFFFF9C4),    // Light Yellow
    'Wednesday': Color(0xFFE1BEE7),  // Light Purple
    'Thursday': Color(0xFFC8E6C9),   // Light Green
    'Friday': Color(0xFFFFCCBC),     // Light Orange
    'Saturday': Color(0xFFD7CCC8),   // Light Brown
    'Sunday': Color(0xFFFFFDE7),     // Light Cream
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
      print('Error loading campuses: $e');
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
      await _loadTeacherLectures();
    } catch (e) {
      print('Error loading teachers: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando docentes: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadTeacherLectures() async {
    if (_selectedCampusId == null || _selectedTeacherIds.isEmpty) return;
    setState(() => _loading = true);
    try {
      final lectures = await _service.fetchTeacherLectures(
        campusId: _selectedCampusId!,
        teacherIds: _selectedTeacherIds,
      );
      setState(() {
        _teacherLectures = lectures;
      });
    } catch (e) {
      print('Error loading teacher lectures: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando horarios: $e')),
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

  /// Assigns a deterministic color to a string (subject)
  Color getColorForString(String input) {
    final colors = [
      Colors.teal[200]!,
      Colors.blue[200]!,
      Colors.orange[200]!,
      Colors.purple[200]!,
      Colors.amber[200]!,
      Colors.green[200]!,
      Colors.red[200]!,
      Colors.indigo[200]!,
      Colors.pink[200]!,
      Colors.brown[200]!,
    ];
    return colors[input.hashCode.abs() % colors.length];
  }

  /// Multi-select dropdown for teachers
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
                  _loadTeacherLectures();
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

  Widget _buildScheduleTable() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_teacherLectures.isEmpty) {
      return const Center(child: Text('No hay horarios para mostrar.'));
    }

    // 1. First row: "Docente", then 56 day columns (8 per day), each day block colored
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
            color: dayHeaderColors[day], // color by day
            padding: const EdgeInsets.all(8),
            child: Text(
              daysEs[day]!,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
    ];

    // 2. Second row: empty, then S1..S8 for each day
    final slotRow = <Widget>[
      Container(),
      for (int i = 0; i < days.length * 8; i++)
        Container(
          alignment: Alignment.center,
          color: dayHeaderColors[days[i ~/ 8]], // match day color
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            'S${(i % 8) + 1}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
    ];

    // 3. Third row: empty, then time range for each slot
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

    // 4. Teacher rows
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

      // For each day and slot, show homeroom + subject or "Libre"
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
            final subjectId = slotData['subject'] is DocumentReference
                ? (slotData['subject'] as DocumentReference).id
                : slotData['subject'].toString();
            final homeroomId = slotData['homeroom'] is DocumentReference
                ? (slotData['homeroom'] as DocumentReference).id
                : slotData['homeroom'].toString();
            final subjectName = subjectNames[subjectId] ?? subjectId;
            final homeroomName = homeroomNames[homeroomId] ?? homeroomId;
            final subjectColor = getColorForString(subjectName);
            cells.add(Container(
              alignment: Alignment.center,
              color: subjectColor.withOpacity(0.45),
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
      // Ensure exactly 57 cells
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
        title: const Text('Horario de Docentes'),
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
