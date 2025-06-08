import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/reports/student_summary_service.dart';

const Map<String, Map<String, dynamic>> attendanceLabels = {
  'A': {'description': 'Asiste', 'color': 0xFF4CAF50},
  'T': {'description': 'Tarde', 'color': 0xFFFF9800},
  'E': {'description': 'Evasión', 'color': 0xFFF44336},
  'I': {'description': 'Inasistencia', 'color': 0xFF757575},
  'IJ': {'description': 'Inasistencia Justificada', 'color': 0xFF607D8B},
  'P': {'description': 'Retiro con acudiente', 'color': 0xFF9C27B0},
};

class StudentSummaryScreen extends StatefulWidget {
  const StudentSummaryScreen({Key? key}) : super(key: key);

  @override
  State<StudentSummaryScreen> createState() => _StudentSummaryScreenState();
}

class _StudentSummaryScreenState extends State<StudentSummaryScreen> {
  static const Color backgroundColor = Color(0xFFF0F0E3);
  static const Color primaryColor = Color(0xFF53A09D);

  final StudentSummaryService _service = StudentSummaryService();

  List<Map<String, dynamic>> _campuses = [];
  String? _selectedCampusId;

  List<Map<String, dynamic>> _homerooms = [];
  String? _selectedHomeroomId;

  List<Map<String, dynamic>> _students = [];
  String? _selectedStudentId;

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();

  List<Map<String, dynamic>> _attendanceSummary = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadCampuses();
  }

  Future<void> _loadCampuses() async {
    setState(() => _loading = true);
    _campuses = await _service.fetchCampuses();
    setState(() => _loading = false);
  }

  Future<void> _loadHomerooms() async {
    if (_selectedCampusId == null) return;
    setState(() {
      _loading = true;
      _homerooms = [];
      _selectedHomeroomId = null;
      _students = [];
      _selectedStudentId = null;
      _attendanceSummary = [];
    });
    _homerooms = await _service.fetchHomerooms(campusId: _selectedCampusId!);
    setState(() => _loading = false);
  }

  Future<void> _loadStudents() async {
    if (_selectedHomeroomId == null) return;
    setState(() {
      _loading = true;
      _students = [];
      _selectedStudentId = null;
      _attendanceSummary = [];
    });
    _students = await _service.fetchStudents(
      campusId: _selectedCampusId!,
      homeroomId: _selectedHomeroomId,
      criteriaType: null,
      criteriaValue: null,
    );
    setState(() => _loading = false);
  }

  Future<void> _loadAttendanceSummary() async {
    if (_selectedStudentId == null) return;
    setState(() => _loading = true);
    _attendanceSummary = await _service.fetchStudentAttendanceRecords(
      studentId: _selectedStudentId!,
      startDate: _startDate,
      endDate: _endDate,
    );
    setState(() => _loading = false);
  }

  Future<void> _pickStartDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: _endDate,
      locale: const Locale('es', 'ES'),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  void _showAttendancePieChartDialog() {
    final Map<String, int> typeCounts = {};
    for (final rec in _attendanceSummary) {
      final label = rec['label'] ?? '';
      if (label.isEmpty) continue;
      typeCounts[label] = (typeCounts[label] ?? 0) + 1;
    }
    final total = typeCounts.values.fold(0, (a, b) => a + b);

    if (total == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No hay datos para graficar")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Porcentaje por tipo de asistencia'),
          content: SizedBox(
            width: 320,
            height: 320,
            child: PieChart(
              PieChartData(
                sections: typeCounts.entries.map((entry) {
                  final label = entry.key;
                  final count = entry.value;
                  final color = Color(attendanceLabels[label]?['color'] ?? 0xFF757575);
                  final percent = (count / total * 100).toStringAsFixed(1);
                  return PieChartSectionData(
                    color: color,
                    value: count.toDouble(),
                    title: '${attendanceLabels[label]?['description'] ?? label}\n$percent% ($count)',
                    titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
                    radius: 70,
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 32,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTable() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_attendanceSummary.isEmpty) return const Text('No hay datos para mostrar.');

    final columns = [
      DataColumn(label: Text('Fecha', style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor))),
      DataColumn(label: Text('Materia', style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor))),
      DataColumn(label: Text('Slot', style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor))),
      DataColumn(label: Text('Docente', style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor))),
      DataColumn(label: Text('Tipo', style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor))),
      DataColumn(label: Text('Notas', style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor))),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: columns,
        rows: _attendanceSummary.map((rec) {
          String formattedDate = '';
          DateTime? dt;
          if (rec['date'] is DateTime) {
            dt = rec['date'];
          } else if (rec['date'] is String) {
            try {
              dt = DateTime.parse(rec['date']);
            } catch (_) {}
          } else if (rec['date'] != null && rec['date'].toString().contains('Timestamp')) {
            dt = (rec['date'] as dynamic).toDate();
          }
          if (dt != null) {
            formattedDate = DateFormat('yyyy-MM-dd').format(dt);
          }
          final subject = rec['subjectName'] ?? '';
          final slot = rec['slot']?.toString() ?? '';
          final teacher = rec['teacherName'] ?? '';
          final type = rec['label'] ?? '';
          final typeDesc = attendanceLabels[type]?['description'] ?? type;
          final typeColor = Color(attendanceLabels[type]?['color'] ?? 0xFF757575);
          final notes = rec['details'] ?? '';

          return DataRow(cells: [
            DataCell(Text(formattedDate)),
            DataCell(Text(subject)),
            DataCell(Text(slot)),
            DataCell(Text(teacher)),
            DataCell(Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: typeColor,
                    shape: BoxShape.circle,
                  ),
                ),
                Text(typeDesc),
              ],
            )),
            DataCell(
              notes.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.notes),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Notas'),
                      content: Text(notes),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cerrar'),
                        ),
                      ],
                    ),
                  );
                },
              )
                  : const SizedBox.shrink(),
            ),
          ]);
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text('Resumen por Estudiante'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Date range pickers
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fecha inicio:', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: _pickStartDate,
                        child: Text(DateFormat('dd/MM/yyyy').format(_startDate)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fecha fin:', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: _pickEndDate,
                        child: Text(DateFormat('dd/MM/yyyy').format(_endDate)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Campus dropdown
            DropdownButtonFormField<String>(
              value: _selectedCampusId,
              decoration: InputDecoration(
                labelText: 'Campus',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: _campuses
                  .map((c) => DropdownMenuItem<String>(
                value: c['id'],
                child: Text(c['name']),
              ))
                  .toList(),
              onChanged: (campusId) async {
                setState(() {
                  _selectedCampusId = campusId;
                  _homerooms = [];
                  _selectedHomeroomId = null;
                  _students = [];
                  _selectedStudentId = null;
                  _attendanceSummary = [];
                });
                await _loadHomerooms();
              },
            ),
            const SizedBox(height: 12),

            // Homeroom dropdown
            DropdownButtonFormField<String>(
              value: _selectedHomeroomId,
              decoration: InputDecoration(
                labelText: 'Homeroom',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: _homerooms
                  .map((h) => DropdownMenuItem<String>(
                value: h['id'],
                child: Text(h['name'] ?? h['id']),
              ))
                  .toList(),
              onChanged: (homeroomId) async {
                setState(() {
                  _selectedHomeroomId = homeroomId;
                  _students = [];
                  _selectedStudentId = null;
                  _attendanceSummary = [];
                });
                await _loadStudents();
              },
            ),
            const SizedBox(height: 12),

            // Student dropdown
            DropdownButtonFormField<String>(
              value: _selectedStudentId,
              decoration: InputDecoration(
                labelText: 'Estudiante',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: _students
                  .map((s) => DropdownMenuItem<String>(
                value: s['id'],
                child: Text(s['name'] ?? s['id']),
              ))
                  .toList(),
              onChanged: (studentId) {
                setState(() {
                  _selectedStudentId = studentId;
                  _attendanceSummary = [];
                });
              },
            ),

            const SizedBox(height: 12),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: (_selectedCampusId != null &&
                  _selectedHomeroomId != null &&
                  _selectedStudentId != null)
                  ? _loadAttendanceSummary
                  : null,
              child: const Text('Buscar información'),
            ),

            const SizedBox(height: 24),
            Expanded(child: _buildTable()),
          ],
        ),
      ),
      bottomNavigationBar: (_attendanceSummary.isNotEmpty)
          ? Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.pie_chart),
          label: const Text('Generar gráfico'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
          ),
          onPressed: _showAttendancePieChartDialog,
        ),
      )
          : null,
    );
  }
}
