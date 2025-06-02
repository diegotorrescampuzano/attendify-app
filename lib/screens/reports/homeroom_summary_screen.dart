import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../services/reports/homeroom_summary_service.dart';

const Map<String, Map<String, dynamic>> attendanceLabels = {
  'A': {'description': 'Asiste', 'color': 0xFF4CAF50},
  'T': {'description': 'Tarde', 'color': 0xFFFF9800},
  'E': {'description': 'Evasión', 'color': 0xFFF44336},
  'I': {'description': 'Inasistencia', 'color': 0xFF757575},
  'IJ': {'description': 'Inasistencia Justificada', 'color': 0xFF607D8B},
  'P': {'description': 'Retiro con acudiente', 'color': 0xFF9C27B0},
};

class HomeroomSummaryScreen extends StatefulWidget {
  const HomeroomSummaryScreen({super.key});

  @override
  State<HomeroomSummaryScreen> createState() => _HomeroomSummaryScreenState();
}

class _HomeroomSummaryScreenState extends State<HomeroomSummaryScreen> {
  final HomeroomSummaryService _service = HomeroomSummaryService();

  String _filterValue = '';
  final TextEditingController _criteriaController = TextEditingController();
  Timer? _debounce;

  List<Map<String, dynamic>> _homerooms = [];
  String? _selectedHomeroomRefId;

  Map<String, Map<String, int>> _attendanceTotals = {};
  Map<String, Map<String, dynamic>> _studentsMap = {}; // studentRefId -> student data

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  bool _loading = false;
  double _classAttendancePercent = 0.0;

  static const Color backgroundColor = Color(0xFFF0F0E3);
  static const Color primaryColor = Color(0xFF53A09D);
  static const Color secondaryColor = Color(0xFF607D8B);

  @override
  void initState() {
    super.initState();
    _criteriaController.addListener(_onCriteriaChanged);
  }

  @override
  void dispose() {
    _criteriaController.removeListener(_onCriteriaChanged);
    _criteriaController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onCriteriaChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final currentText = _criteriaController.text.trim();
      if (currentText == _filterValue) return;
      setState(() {
        _filterValue = currentText;
        _selectedHomeroomRefId = null;
        _attendanceTotals.clear();
        _studentsMap.clear();
        _classAttendancePercent = 0.0;
      });
      _loadHomerooms();
    });
  }

  Future<void> _loadHomerooms() async {
    if (_filterValue.isEmpty) {
      setState(() {
        _homerooms = [];
      });
      return;
    }
    setState(() => _loading = true);
    try {
      final homerooms = await _service.fetchHomerooms(criteria: _filterValue);
      setState(() {
        _homerooms = homerooms;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error cargando grupos: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onHomeroomSelected(String? homeroomRefId) async {
    setState(() {
      _selectedHomeroomRefId = homeroomRefId;
      _attendanceTotals.clear();
      _studentsMap.clear();
      _classAttendancePercent = 0.0;
    });
    if (homeroomRefId == null) return;

    setState(() => _loading = true);
    try {
      final students = await _service.fetchStudentsOfHomeroom(homeroomRefId);
      final studentMap = {for (var s in students) s['refId'] as String: s};
      final attendanceTotals = await _service.fetchAttendanceTotalsPerStudent(
        homeroomRefId: homeroomRefId,
        startDate: _startDate,
        endDate: _endDate,
      );
      final classPercent = _service.calculateClassAttendancePercentage(attendanceTotals);

      setState(() {
        _studentsMap = studentMap;
        _attendanceTotals = attendanceTotals;
        _classAttendancePercent = classPercent;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error cargando asistencias: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: _endDate,
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
      if (_selectedHomeroomRefId != null) {
        await _onHomeroomSelected(_selectedHomeroomRefId);
      }
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
      if (_selectedHomeroomRefId != null) {
        await _onHomeroomSelected(_selectedHomeroomRefId);
      }
    }
  }

  Widget _buildAttendanceLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: attendanceLabels.entries.map((entry) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Color(entry.value['color']),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(entry.value['description']),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildAttendanceTable() {
    final labels = attendanceLabels.keys.toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(secondaryColor.withOpacity(0.1)),
        columnSpacing: 8,
        columns: [
          DataColumn(
            label: SizedBox(
              width: 150,
              child: const Text(
                'Estudiante',
                style: TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          ...labels.map((label) {
            return DataColumn(
              numeric: true,
              label: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Color(attendanceLabels[label]?['color'] ?? 0xFFBDBDBD),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }).toList(),
        ],
        rows: _studentsMap.entries.map((entry) {
          final studentId = entry.key;
          final student = entry.value;
          final counts = _attendanceTotals[studentId] ?? {};
          return DataRow(
            cells: [
              DataCell(
                SizedBox(
                  width: 150,
                  child: Text(
                    student['name'] ?? '',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              ...labels.map((label) {
                final count = counts[label] ?? 0;
                return DataCell(
                  SizedBox(
                    width: 24,
                    child: Text(
                      count.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                );
              }).toList(),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAttendancePieChart() {
    final Map<String, int> totalCounts = {};
    _attendanceTotals.values.forEach((counts) {
      counts.forEach((label, count) {
        totalCounts[label] = (totalCounts[label] ?? 0) + count;
      });
    });

    final totalSum = totalCounts.values.fold<int>(0, (sum, val) => sum + val);
    if (totalSum == 0) {
      return const Center(child: Text('No hay datos de asistencia para mostrar.'));
    }

    final sections = totalCounts.entries.map((entry) {
      final label = entry.key;
      final count = entry.value;
      final percentage = (count / totalSum) * 100;
      final color = Color(attendanceLabels[label]?['color'] ?? 0xFFBDBDBD);

      return PieChartSectionData(
        color: color,
        value: count.toDouble(),
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: totalCounts.entries.map((entry) {
            final label = entry.key;
            final description = attendanceLabels[label]?['description'] ?? label;
            final color = Color(attendanceLabels[label]?['color'] ?? 0xFFBDBDBD);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 16, height: 16, color: color),
                const SizedBox(width: 6),
                Text(description),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Resumen de Asistencia por Grupo'),
        backgroundColor: primaryColor,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _criteriaController,
                  decoration: InputDecoration(
                    labelText: 'Buscar grupo (homeroom)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    suffixIcon: _filterValue.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _criteriaController.clear();
                      },
                    )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Seleccionar grupo',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  value: _selectedHomeroomRefId,
                  items: _homerooms.map((homeroom) {
                    return DropdownMenuItem<String>(
                      value: homeroom['refId'],
                      child: Text(homeroom['name'] ?? ''),
                    );
                  }).toList(),
                  onChanged: (value) => _onHomeroomSelected(value),
                ),
                const SizedBox(height: 16),
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

                // Attendance legend
                Text(
                  'Leyenda de asistencia',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                _buildAttendanceLegend(),

                const SizedBox(height: 24),

                if (_studentsMap.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildAttendanceTable(),
                  const SizedBox(height: 24),
                  Text(
                    'Distribución porcentual de tipos de asistencia',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  _buildAttendancePieChart(),
                ] else if (_selectedHomeroomRefId != null) ...[
                  const Text('No hay datos de asistencia para el grupo y rango de fechas seleccionados.'),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
