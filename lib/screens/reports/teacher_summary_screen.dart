// /lib/reports/teacher_summary_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../services/reports/teacher_summary_service.dart';
import '../../services/auth_service.dart';

const Map<String, Map<String, dynamic>> attendanceLabels = {
  'A': {'description': 'Asiste', 'color': 0xFF4CAF50},
  'T': {'description': 'Tarde', 'color': 0xFFFF9800},
  'E': {'description': 'Evasión', 'color': 0xFFF44336},
  'I': {'description': 'Inasistencia', 'color': 0xFF757575},
  'IJ': {'description': 'Inasistencia Justificada', 'color': 0xFF607D8B},
  'P': {'description': 'Retiro con acudiente', 'color': 0xFF9C27B0},
};

class TeacherSummaryScreen extends StatefulWidget {
  const TeacherSummaryScreen({super.key});

  @override
  State<TeacherSummaryScreen> createState() => _TeacherSummaryScreenState();
}

class _TeacherSummaryScreenState extends State<TeacherSummaryScreen> {
  static const Color backgroundColor = Color(0xFFF0F0E3);
  static const Color primaryColor = Color(0xFF53A09D);

  final TeacherSummaryService _service = TeacherSummaryService();

  List<Map<String, dynamic>> _teachers = [];
  String? _selectedTeacherRefId;

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  bool _loading = false;

  Map<String, Map<String, int>> _summaryData = {};

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  Future<void> _loadTeachers() async {
    setState(() => _loading = true);
    try {
      final teachers = await _service.fetchTeachers();
      final currentUserRefId = AuthService.currentUserData?['refId'];
      setState(() {
        _teachers = teachers;
        _selectedTeacherRefId = teachers.any((t) => t['refId'] == currentUserRefId)
            ? currentUserRefId
            : (teachers.isNotEmpty ? teachers.first['refId'] : null);
      });
      if (_selectedTeacherRefId != null) {
        await _fetchSummary();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando docentes: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchSummary() async {
    if (_selectedTeacherRefId == null) return;
    setState(() => _loading = true);
    try {
      final data = await _service.fetchAttendanceSummary(
        teacherRefId: _selectedTeacherRefId!,
        startDate: _startDate,
        endDate: _endDate,
      );
      setState(() {
        _summaryData = data;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando resumen: $e')),
        );
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
      await _fetchSummary();
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
      await _fetchSummary();
    }
  }

  /// Compute total counts per attendance label across all subjects
  Map<String, int> get _totalCounts {
    final totals = <String, int>{};
    for (var label in attendanceLabels.keys) {
      totals[label] = 0;
    }
    for (var subjectCounts in _summaryData.values) {
      for (var label in attendanceLabels.keys) {
        totals[label] = (totals[label] ?? 0) + (subjectCounts[label] ?? 0);
      }
    }
    return totals;
  }

  @override
  Widget build(BuildContext context) {
    final totals = _totalCounts;
    final totalSum = totals.values.fold<int>(0, (sum, val) => sum + val);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Resumen de Asistencias por Docente'),
        backgroundColor: primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Teacher selector dropdown
            Text('Docente:', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButton<String>(
              isExpanded: true,
              value: _selectedTeacherRefId,
              items: _teachers.map((teacher) {
                return DropdownMenuItem<String>(
                  value: teacher['refId'],
                  child: Text(teacher['name'] ?? 'Sin nombre'),
                );
              }).toList(),
              onChanged: (value) async {
                setState(() {
                  _selectedTeacherRefId = value;
                });
                await _fetchSummary();
              },
            ),
            const SizedBox(height: 16),

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

            // Legend with color circles and descriptions
            const SizedBox(height: 16),
            Wrap(
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
            ),

            const SizedBox(height: 24),

            // Pie Chart for attendance totals
            if (totalSum > 0)
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: attendanceLabels.entries.map((entry) {
                      final label = entry.key;
                      final count = totals[label] ?? 0;
                      if (count == 0) return null;
                      final percentage = (count / totalSum) * 100;
                      return PieChartSectionData(
                        color: Color(entry.value['color']),
                        value: count.toDouble(),
                        title: '${percentage.toStringAsFixed(1)}%',
                        radius: 50,
                        titleStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }).whereType<PieChartSectionData>().toList(),
                  ),
                ),
              )
            else
              const Center(child: Text('No hay datos para mostrar en el gráfico.')),

            const SizedBox(height: 24),

            // Summary report header
            Text(
              'Resumen de asistencias',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
            ),
            const SizedBox(height: 12),

            // Table header row with colored circles
            Container(
              color: primaryColor.withOpacity(0.1),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Row(
                children: [
                  const Expanded(
                    flex: 3,
                    child: Text('Asignatura', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  ...attendanceLabels.entries.map((entry) {
                    return Expanded(
                      flex: 2,
                      child: Tooltip(
                        message: entry.value['description'],
                        child: Container(
                          width: 24,
                          height: 24,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: Color(entry.value['color']),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),

            // Summary data list + totals row
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: _summaryData.isEmpty
                        ? const Center(child: Text('No hay datos para los filtros seleccionados.'))
                        : ListView.builder(
                      itemCount: _summaryData.length,
                      itemBuilder: (context, index) {
                        final subject = _summaryData.keys.elementAt(index);
                        final counts = _summaryData[subject]!;

                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(flex: 3, child: Text(subject)),
                              ...attendanceLabels.keys.map((labelKey) {
                                final count = counts[labelKey] ?? 0;
                                return Expanded(
                                  flex: 2,
                                  child: Text(
                                    '$count',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(attendanceLabels[labelKey]!['color']),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Totals row
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.15),
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade500),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          flex: 3,
                          child: Text(
                            'Totales',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        ...attendanceLabels.keys.map((labelKey) {
                          final count = totals[labelKey] ?? 0;
                          return Expanded(
                            flex: 2,
                            child: Text(
                              '$count',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(attendanceLabels[labelKey]!['color']),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
