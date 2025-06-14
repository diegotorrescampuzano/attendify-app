import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../services/reports/teacher_summary_service.dart';

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

class TeacherSummaryScreen extends StatefulWidget {
  const TeacherSummaryScreen({Key? key}) : super(key: key);

  @override
  State<TeacherSummaryScreen> createState() => _TeacherSummaryScreenState();
}

class _TeacherSummaryScreenState extends State<TeacherSummaryScreen> {
  final TeacherSummaryService _service = TeacherSummaryService();
  List<Map<String, dynamic>> _campuses = [];
  List<Map<String, dynamic>> _teachers = [];
  String? _selectedCampusId;
  String? _selectedTeacherId;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  List<Map<String, dynamic>> _summary = [];
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
      _loading = false;
    });
  }

  Future<void> _loadTeachers() async {
    if (_selectedCampusId == null) return;
    setState(() => _loading = true);
    final teachers = await _service.fetchTeachers(campusId: _selectedCampusId!);
    setState(() {
      _teachers = teachers;
      _selectedTeacherId = null;
      _loading = false;
    });
  }

  Future<void> _loadSummary() async {
    if (_selectedTeacherId == null) return;
    setState(() => _loading = true);
    final summary = await _service.fetchTeacherAttendanceSummary(
      teacherId: _selectedTeacherId!,
      startDate: _startDate,
      endDate: _endDate,
    );
    setState(() {
      _summary = summary;
      _loading = false;
    });
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) => Theme(
        data: ThemeData(
          colorScheme: ColorScheme.light(primary: primaryColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Widget _buildCampusDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCampusId,
      items: _campuses.map<DropdownMenuItem<String>>((campus) {
        return DropdownMenuItem<String>(
          value: campus['id'],
          child: Text(campus['name'] ?? ''),
        );
      }).toList(),
      decoration: InputDecoration(
        labelText: 'Selecciona un campus',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onChanged: (String? value) {
        setState(() {
          _selectedCampusId = value;
          _summary = [];
        });
        _loadTeachers();
      },
    );
  }

  Widget _buildTeacherDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedTeacherId,
      items: _teachers.map<DropdownMenuItem<String>>((teacher) {
        return DropdownMenuItem<String>(
          value: teacher['id'],
          child: Text(teacher['name'] ?? ''),
        );
      }).toList(),
      decoration: InputDecoration(
        labelText: 'Selecciona un docente',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onChanged: (String? value) {
        setState(() {
          _selectedTeacherId = value;
          _summary = [];
        });
      },
    );
  }

  Widget _buildSummaryTable() {
    if (_summary.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Text('No hay registros de asistencia para este docente en el rango seleccionado.'),
      );
    }

    // Compute totals by attendance type
    final Map<String, int> totalCounts = {};
    for (final row in _summary) {
      final counts = row['counts'] as Map<String, int>;
      for (final label in attendanceLabels.keys) {
        totalCounts[label] = (totalCounts[label] ?? 0) + (counts[label] ?? 0);
      }
    }

    return Expanded(
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(primaryColor.withOpacity(0.1)),
              columns: [
                const DataColumn(label: Text('Grupo')),
                const DataColumn(label: Text('Materia')),
                ...attendanceLabels.entries.map((e) => DataColumn(label: Text(e.value['description']))),
              ],
              rows: [
                ..._summary.map((row) {
                  final counts = row['counts'] as Map<String, int>;
                  return DataRow(cells: [
                    DataCell(Text(row['homeroomName'] ?? '', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold))),
                    DataCell(Text(row['subjectName'] ?? '')),
                    ...attendanceLabels.entries.map((e) => DataCell(
                      counts.containsKey(e.key)
                          ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(e.value['color']).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          counts[e.key].toString(),
                          style: TextStyle(
                            color: Color(e.value['color']),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                          : const SizedBox.shrink(),
                    )),
                  ]);
                }),
                // Totals row
                DataRow(
                  color: MaterialStateProperty.all(primaryColor.withOpacity(0.08)),
                  cells: [
                    const DataCell(Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                    const DataCell(Text('')),
                    ...attendanceLabels.entries.map((e) => DataCell(
                      Text(
                        (totalCounts[e.key] ?? 0).toString(),
                        style: TextStyle(
                          color: Color(e.value['color']),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChartLegend(Map<String, int> totalCounts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: attendanceLabels.entries.map((e) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Row(
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
            Text(
              e.value['description'],
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(width: 8),
            Text(
              '(${totalCounts[e.key] ?? 0})',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ))
          .toList(),
    );
  }

  Widget _buildChartButton(Map<String, int> totalCounts) {
    if (_summary.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.pie_chart),
        label: const Text('Ver gráfico de resumen'),
        onPressed: () => _showSummaryChart(totalCounts),
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

  void _showSummaryChart(Map<String, int> totalCounts) {
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
                    sections: attendanceLabels.entries.map((e) {
                      final count = totalCounts[e.key] ?? 0;
                      final total = totalCounts.values.fold(0, (p, v) => p + v);
                      final percent = total > 0 ? (count / total * 100).toStringAsFixed(1) : '0';
                      return PieChartSectionData(
                        color: Color(e.value['color']),
                        value: count.toDouble(),
                        title: '$percent%',
                        radius: 60,
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList(),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildChartLegend(totalCounts),
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
    final dateRangeLabel =
        '${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}';

    // Compute totals for chart
    final Map<String, int> totalCounts = {};
    for (final row in _summary) {
      final counts = row['counts'] as Map<String, int>;
      for (final label in attendanceLabels.keys) {
        totalCounts[label] = (totalCounts[label] ?? 0) + (counts[label] ?? 0);
      }
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Resumen de asistencias por docente'),
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
            Text(
              'Rango de fechas: $dateRangeLabel',
              style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.date_range),
                  label: const Text('Cambiar rango'),
                  onPressed: _pickDateRange,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCampusDropdown(),
            const SizedBox(height: 16),
            _buildTeacherDropdown(),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.search),
              label: const Text('Buscar resumen'),
              onPressed: _selectedTeacherId == null ? null : _loadSummary,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildSummaryTable(),
            _buildChartButton(totalCounts),
          ],
        ),
      ),
    );
  }
}
