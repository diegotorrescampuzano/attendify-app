import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../services/reports/student_schedule_service.dart';

const Color backgroundColor = Color(0xFFF0F0E3);
const Color primaryColor = Color(0xFF53A09D);

const Map<String, Map<String, dynamic>> attendanceLabels = {
  'A': {'description': 'Asiste', 'color': 0xFF4CAF50},
  'T': {'description': 'Tarde', 'color': 0xFFFF9800},
  'E': {'description': 'Evasión', 'color': 0xFFF44336},
  'I': {'description': 'Inasistencia', 'color': 0xFF757575},
  'IJ': {'description': 'Inasistencia Justificada', 'color': 0xFF607D8B},
  'P': {'description': 'Retiro con acudiente', 'color': 0xFF9C27B0},
};

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
  'Session 1',
  'Session 2',
  'Session 3',
  'Session 4',
  'Session 5',
  'Session 6',
  'Session 7',
  'Session 8',
];

class StudentScheduleScreen extends StatefulWidget {
  const StudentScheduleScreen({Key? key}) : super(key: key);

  @override
  State<StudentScheduleScreen> createState() => _StudentScheduleScreenState();
}

class _StudentScheduleScreenState extends State<StudentScheduleScreen> {
  final StudentScheduleService _service = StudentScheduleService();

  List<Map<String, dynamic>> _campuses = [];
  String? _selectedCampusId;
  List<Map<String, dynamic>> _homerooms = [];
  String? _selectedHomeroomId;
  List<Map<String, dynamic>> _students = [];
  String? _selectedStudentId;
  String? _selectedHomeroomName;

  Map<String, Map<int, Map<String, dynamic>?>> _schedule = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadCampuses();
  }

  Future<void> _loadCampuses() async {
    setState(() => _loading = true);
    final campuses = await _service.fetchCampuses();
    setState(() {
      _campuses = campuses;
      _selectedCampusId = null;
      _homerooms = [];
      _selectedHomeroomId = null;
      _students = [];
      _selectedStudentId = null;
      _schedule = {};
      _loading = false;
    });
  }

  Future<void> _loadHomerooms() async {
    if (_selectedCampusId == null) return;
    setState(() => _loading = true);
    final homerooms = await _service.fetchHomerooms(campusId: _selectedCampusId!);
    setState(() {
      _homerooms = homerooms;
      _selectedHomeroomId = null;
      _students = [];
      _selectedStudentId = null;
      _schedule = {};
      _loading = false;
    });
  }

  Future<void> _loadStudents() async {
    if (_selectedHomeroomId == null) return;
    setState(() => _loading = true);
    final students = await _service.fetchStudents(homeroomId: _selectedHomeroomId!);
    setState(() {
      _students = students;
      _selectedStudentId = null;
      _schedule = {};
      _selectedHomeroomName = _homerooms.firstWhere(
            (h) => h['id'] == _selectedHomeroomId,
        orElse: () => {'name': ''},
      )['name'];
      _loading = false;
    });
  }

  Future<void> _loadSchedule() async {
    if (_selectedStudentId == null || _selectedHomeroomName == null) return;
    setState(() => _loading = true);
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    final schedule = await _service.fetchStudentWeekSchedule(
      studentId: _selectedStudentId!,
      homeroomName: _selectedHomeroomName!,
      weekStart: DateTime(weekStart.year, weekStart.month, weekStart.day),
      weekEnd: DateTime(weekEnd.year, weekEnd.month, weekEnd.day, 23, 59, 59),
    );
    setState(() {
      _schedule = schedule;
      _loading = false;
    });
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<Map<String, dynamic>> items,
    required String valueKey,
    required String labelKey,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items.map<DropdownMenuItem<T>>((item) {
        return DropdownMenuItem<T>(
          value: item[valueKey],
          child: Text(item[labelKey] ?? ''),
        );
      }).toList(),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onChanged: onChanged,
    );
  }

  Map<String, int> _calculateAttendanceCounts() {
    final Map<String, int> counts = {
      for (final key in attendanceLabels.keys) key: 0,
      'Pendiente': 0,
    };
    for (final day in days) {
      for (int slot = 1; slot <= 8; slot++) {
        final info = _schedule[day]?[slot];
        if (info == null || info['label'] == null) {
          counts['Pendiente'] = (counts['Pendiente'] ?? 0) + 1;
        } else {
          final label = info['label'];
          if (attendanceLabels.containsKey(label)) {
            counts[label] = (counts[label] ?? 0) + 1;
          }
        }
      }
    }
    return counts;
  }

  Widget _buildScheduleTable() {
    if (_schedule.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Text('No hay horario o asistencias para mostrar.'),
      );
    }
    // Build table: Days as columns, slots as rows
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
                  final info = _schedule[day]?[slotNum];
                  if (info == null) {
                    // No attendance record at all for this slot/day
                    return DataCell(Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.13),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          Text('Pendiente', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ));
                  }
                  final label = info['label'];
                  final labelInfo = label != null ? attendanceLabels[label] : null;
                  final subject = info['subject'] ?? '';
                  if (labelInfo == null) {
                    // Subject known, but no attendance label for this student in this slot
                    return DataCell(Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.13),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(subject, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          const Text('Pendiente', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ));
                  }
                  // Attendance record for this student and slot exists
                  return DataCell(Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Color(labelInfo['color']).withOpacity(0.17),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          subject,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Text(
                            labelInfo['description'],
                            style: TextStyle(
                              color: Color(labelInfo['color']),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Wrap(
        spacing: 16,
        runSpacing: 6,
        children: [
          ...attendanceLabels.entries.map((e) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Color(e.value['color']),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(e.value['description'], style: const TextStyle(fontSize: 13)),
            ],
          )),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.13),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              const Text('Pendiente', style: TextStyle(fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartButton() {
    if (_schedule.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.pie_chart),
        label: const Text('Ver gráfico de asistencias'),
        onPressed: _showAttendanceChart,
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

  void _showAttendanceChart() {
    final counts = _calculateAttendanceCounts();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Distribución de asistencias',
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
                      ...attendanceLabels.entries.map((e) {
                        final count = counts[e.key] ?? 0;
                        final total = counts.values.fold(0, (p, v) => p + v);
                        final percent = total > 0 ? (count / total * 100).toStringAsFixed(1) : '0';
                        return PieChartSectionData(
                          color: Color(e.value['color']),
                          value: count.toDouble(),
                          title: count > 0 ? '$percent%' : '',
                          radius: 60,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }),
                      if ((counts['Pendiente'] ?? 0) > 0)
                        PieChartSectionData(
                          color: Colors.grey,
                          value: counts['Pendiente']!.toDouble(),
                          title: ((counts['Pendiente']! / counts.values.fold(0, (p, v) => p + v)) * 100).toStringAsFixed(1) + '%',
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
              _buildChartLegend(counts),
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

  Widget _buildChartLegend(Map<String, int> counts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...attendanceLabels.entries.map((e) => Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Color(e.value['color']),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text('${e.value['description']} (${counts[e.key] ?? 0})'),
          ],
        )),
        Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text('Pendiente (${counts['Pendiente'] ?? 0})'),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Horario y asistencias del estudiante'),
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
            _buildDropdown<String>(
              label: 'Campus',
              value: _selectedCampusId,
              items: _campuses,
              valueKey: 'id',
              labelKey: 'name',
              onChanged: (v) {
                setState(() {
                  _selectedCampusId = v;
                  _selectedHomeroomId = null;
                  _selectedStudentId = null;
                  _homerooms = [];
                  _students = [];
                  _schedule = {};
                });
                _loadHomerooms();
              },
            ),
            const SizedBox(height: 12),
            _buildDropdown<String>(
              label: 'Grupo',
              value: _selectedHomeroomId,
              items: _homerooms,
              valueKey: 'id',
              labelKey: 'name',
              onChanged: (v) {
                setState(() {
                  _selectedHomeroomId = v;
                  _selectedStudentId = null;
                  _students = [];
                  _schedule = {};
                });
                _loadStudents();
              },
            ),
            const SizedBox(height: 12),
            _buildDropdown<String>(
              label: 'Estudiante',
              value: _selectedStudentId,
              items: _students,
              valueKey: 'id',
              labelKey: 'name',
              onChanged: (v) {
                setState(() {
                  _selectedStudentId = v;
                  _schedule = {};
                });
                _loadSchedule();
              },
            ),
            _buildLegend(),
            const SizedBox(height: 8),
            Expanded(child: _buildScheduleTable()),
            _buildChartButton(),
          ],
        ),
      ),
    );
  }
}
