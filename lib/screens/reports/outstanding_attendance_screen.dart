import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../services/reports/outstanding_currentweek_service.dart';

const Color backgroundColor = Color(0xFFF0F0E3);
const Color primaryColor = Color(0xFF53A09D);

const List<String> days = [
  'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
];
const Map<String, String> daysEs = {
  'monday': 'Lunes',
  'tuesday': 'Martes',
  'wednesday': 'Miércoles',
  'thursday': 'Jueves',
  'friday': 'Viernes',
  'saturday': 'Sábado',
  'sunday': 'Domingo',
};
const List<String> slotTimes = [
  '07:00-08:00',
  '08:00-09:00',
  '09:00-10:00',
  '10:00-11:00',
  '11:00-12:00',
  '12:00-13:00',
  '13:00-14:00',
  '14:00-15:00',
];

class OutstandingAttendanceScreen extends StatefulWidget {
  const OutstandingAttendanceScreen({Key? key}) : super(key: key);

  @override
  State<OutstandingAttendanceScreen> createState() => _OutstandingAttendanceScreenState();
}

class _OutstandingAttendanceScreenState extends State<OutstandingAttendanceScreen> {
  final OutstandingCurrentWeekService _service = OutstandingCurrentWeekService();

  List<Map<String, dynamic>> _campuses = [];
  String? _selectedCampusId;
  List<Map<String, dynamic>> _teachers = [];
  String? _selectedTeacherId;

  Map<String, Map<int, Map<String, dynamic>>> _teacherSchedule = {};
  Set<String> _registeredAttendance = {};
  Map<String, String> _subjectNames = {};
  Map<String, String> _homeroomNames = {};

  bool _loading = false;
  int _registeredCount = 0;
  int _pendingCount = 0;
  int _libreCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCampuses();
    _loadNames();
  }

  Future<void> _loadCampuses() async {
    setState(() => _loading = true);
    final campuses = await _service.fetchCampuses();
    setState(() {
      _campuses = campuses;
      _selectedCampusId = null;
      _teachers = [];
      _selectedTeacherId = null;
      _teacherSchedule = {};
      _registeredAttendance = {};
      _loading = false;
    });
  }

  Future<void> _loadTeachers() async {
    if (_selectedCampusId == null) return;
    setState(() => _loading = true);
    final teachers = await _service.fetchTeachersForCampus(_selectedCampusId!);
    setState(() {
      _teachers = teachers;
      _selectedTeacherId = null;
      _teacherSchedule = {};
      _registeredAttendance = {};
      _loading = false;
    });
  }

  Future<void> _loadNames() async {
    _subjectNames = await _service.fetchNames('subjects');
    _homeroomNames = await _service.fetchNames('homerooms');
    setState(() {});
  }

  Future<void> _loadOutstandingSchedule() async {
    if (_selectedTeacherId == null || _selectedCampusId == null) return;
    setState(() => _loading = true);

    // Fetch teacher lectures
    final lecturesList = await _service.fetchTeacherLectures(
      campusId: _selectedCampusId!,
      teacherIds: [_selectedTeacherId!],
    );
    Map<String, Map<int, Map<String, dynamic>>> schedule = {
      for (final day in days) day: {for (int slot = 1; slot <= 8; slot++) slot: {'libre': true}}
    };
    String teacherId = _selectedTeacherId!;
    // Build schedule from lectures
    if (lecturesList.isNotEmpty) {
      final lectures = lecturesList.first['lectures'] as Map<String, dynamic>? ?? {};
      for (final day in days) {
        final dayLectures = lectures[day] as List<dynamic>? ?? [];
        for (final lecture in dayLectures) {
          final slot = lecture['slot'] is int ? lecture['slot'] : int.tryParse(lecture['slot'].toString());
          final homeroom = lecture['homeroom'] ?? '';
          final subject = lecture['subject'] ?? '';
          if (slot != null && slot >= 1 && slot <= 8) {
            schedule[day]![slot] = {
              'libre': false,
              'homeroom': homeroom,
              'subject': subject,
              'slot': slot,
              'day': day,
            };
          }
        }
      }
    }

    // Fetch registered attendance
    final weekRange = _getCurrentWeekRange();
    final registered = await _service.fetchRegisteredAttendance(
      campusId: _selectedCampusId!,
      teacherIds: [teacherId],
      weekStart: weekRange['start']!,
      weekEnd: weekRange['end']!,
    );

    setState(() {
      _teacherSchedule = schedule;
      _registeredAttendance = registered;
      _loading = false;
    });
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

  String getReferenceIdOrValue(dynamic ref) {
    if (ref == null) return '';
    if (ref is DocumentReference) return ref.id;
    if (ref is String) return ref;
    return ref.toString();
  }

  Map<String, int> _calculateChartCounts() {
    int libre = 0;
    int registered = 0;
    int pending = 0;
    for (final day in days) {
      for (int slot = 1; slot <= 8; slot++) {
        final info = _teacherSchedule[day]?[slot];
        if (info == null || info['libre'] == true) {
          libre++;
        } else {
          final homeroomId = getReferenceIdOrValue(info['homeroom']);
          final subjectId = getReferenceIdOrValue(info['subject']);
          final slotStr = slot.toString();
          final dayStr = day.toLowerCase();
          final key = '$_selectedTeacherId|$dayStr|$slotStr|$homeroomId|$subjectId';
          if (_registeredAttendance.contains(key)) {
            registered++;
          } else {
            pending++;
          }
        }
      }
    }
    _libreCount = libre;
    _registeredCount = registered;
    _pendingCount = pending;
    return {'Libre': libre, 'Registrada': registered, 'Pendiente': pending};
  }

  Widget _buildScheduleTable() {
    if (_teacherSchedule.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Text('No hay horario para mostrar.'),
      );
    }
    _calculateChartCounts();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(primaryColor.withOpacity(0.1)),
          columns: [
            const DataColumn(label: Text('Slot/Hora')),
            ...days.map((d) => DataColumn(label: Text(daysEs[d]!))),
          ],
          rows: List<DataRow>.generate(8, (slotIdx) {
            final slotNum = slotIdx + 1;
            return DataRow(
              cells: [
                DataCell(Text('S$slotNum\n${slotTimes[slotIdx]}')),
                ...days.map((day) {
                  final info = _teacherSchedule[day]?[slotNum];
                  if (info == null || info['libre'] == true) {
                    return DataCell(Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.13),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Libre',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ));
                  }
                  final homeroomId = getReferenceIdOrValue(info['homeroom']);
                  final subjectId = getReferenceIdOrValue(info['subject']);
                  final slotStr = slotNum.toString();
                  final dayStr = day.toLowerCase();
                  final key = '$_selectedTeacherId|$dayStr|$slotStr|$homeroomId|$subjectId';
                  final registered = _registeredAttendance.contains(key);
                  final homeroomName = _homeroomNames[homeroomId] ?? homeroomId;
                  final subjectName = _subjectNames[subjectId] ?? subjectId;
                  return DataCell(Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: registered
                          ? Colors.green.withOpacity(0.4)
                          : Colors.red.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          homeroomName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        Text(
                          subjectName,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ));
                }).toList(),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildChartButton() {
    if (_teacherSchedule.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.pie_chart),
        label: const Text('Ver gráfico de registro'),
        onPressed: () => _showChartDialog(),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  void _showChartDialog() {
    final counts = _calculateChartCounts();
    final libre = counts['Libre'] ?? 0;
    final registrada = counts['Registrada'] ?? 0;
    final pendiente = counts['Pendiente'] ?? 0;
    final total = libre + registrada + pendiente;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Resumen de registro de asistencias',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 220,
                child: PieChart(
                  PieChartData(
                    sections: [
                      if (pendiente > 0)
                        PieChartSectionData(
                          color: Colors.red,
                          value: pendiente.toDouble(),
                          title: '${((pendiente / total) * 100).toStringAsFixed(1)}%',
                          radius: 60,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      if (registrada > 0)
                        PieChartSectionData(
                          color: Colors.green,
                          value: registrada.toDouble(),
                          title: '${((registrada / total) * 100).toStringAsFixed(1)}%',
                          radius: 60,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      if (libre > 0)
                        PieChartSectionData(
                          color: Colors.grey,
                          value: libre.toDouble(),
                          title: '${((libre / total) * 100).toStringAsFixed(1)}%',
                          radius: 60,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('Pendiente ($pendiente)'),
                  const SizedBox(width: 16),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('Registrada ($registrada)'),
                  const SizedBox(width: 16),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('Libre ($libre)'),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text('Cerrar', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Asistencias pendientes del docente'),
        backgroundColor: primaryColor,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedCampusId,
              items: _campuses.map((campus) {
                return DropdownMenuItem<String>(
                  value: campus['id'],
                  child: Text(campus['name']),
                );
              }).toList(),
              decoration: InputDecoration(
                labelText: 'Campus',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (v) {
                setState(() {
                  _selectedCampusId = v;
                  _selectedTeacherId = null;
                  _teachers = [];
                  _teacherSchedule = {};
                  _registeredAttendance = {};
                });
                _loadTeachers();
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedTeacherId,
              items: _teachers.map((teacher) {
                return DropdownMenuItem<String>(
                  value: teacher['id'],
                  child: Text(teacher['name']),
                );
              }).toList(),
              decoration: InputDecoration(
                labelText: 'Docente',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (v) {
                setState(() {
                  _selectedTeacherId = v;
                  _teacherSchedule = {};
                  _registeredAttendance = {};
                });
                _loadOutstandingSchedule();
              },
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildScheduleTable()),
            _buildChartButton(),
          ],
        ),
      ),
    );
  }
}
