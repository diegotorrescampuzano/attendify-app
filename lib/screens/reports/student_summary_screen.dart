import 'dart:async';

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

enum StudentFilterType { name, cellphoneContact, homeroom }

extension StudentFilterTypeExtension on StudentFilterType {
  String get label {
    switch (this) {
      case StudentFilterType.name:
        return 'Nombre';
      case StudentFilterType.cellphoneContact:
        return 'Celular';
      case StudentFilterType.homeroom:
        return 'Grupo (Homeroom)';
    }
  }
}

class StudentSummaryScreen extends StatefulWidget {
  const StudentSummaryScreen({super.key});

  @override
  State<StudentSummaryScreen> createState() => _StudentSummaryScreenState();
}

class _StudentSummaryScreenState extends State<StudentSummaryScreen> {
  static const Color backgroundColor = Color(0xFFF0F0E3);
  static const Color primaryColor = Color(0xFF53A09D);

  final StudentSummaryService _service = StudentSummaryService();

  List<Map<String, dynamic>> _students = [];
  String? _selectedStudentRefId;

  StudentFilterType _selectedFilterType = StudentFilterType.name;
  String _filterValue = '';

  final TextEditingController _criteriaController = TextEditingController();
  Timer? _debounce;
  String _lastFilterValue = '';

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  bool _loading = false;

  Map<String, Map<String, String>> _attendanceDetail = {};

  @override
  void initState() {
    super.initState();
    _criteriaController.addListener(_onCriteriaChanged);
    _loadStudents();
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
    _debounce = Timer(const Duration(milliseconds: 2000), () {
      final currentText = _criteriaController.text.trim();
      if (currentText == _lastFilterValue) return; // No change, skip
      _lastFilterValue = currentText;

      setState(() {
        _filterValue = currentText;
      });
      _loadStudents();
    });
  }

  Future<void> _loadStudents() async {
    setState(() => _loading = true);
    try {
      final allStudents = await _service.fetchStudents();
      final filtered = allStudents.where((student) {
        final filterText = _filterValue.toLowerCase();
        if (filterText.isEmpty) return true;

        switch (_selectedFilterType) {
          case StudentFilterType.name:
            return (student['name'] ?? '').toLowerCase().contains(filterText);
          case StudentFilterType.cellphoneContact:
            return (student['cellphoneContact'] ?? '').toLowerCase().contains(filterText);
          case StudentFilterType.homeroom:
            final homeroomRef = student['homeroom'];
            if (homeroomRef == null) return false;
            final homeroomStr = homeroomRef.toString().toLowerCase();
            return homeroomStr.contains(filterText);
        }
      }).toList();

      setState(() {
        _students = filtered;
        // Do NOT auto-select a student here; teacher must choose explicitly
      });

      if (_selectedStudentRefId == null) {
        setState(() {
          _attendanceDetail = {};
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando estudiantes: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchAttendanceDetail() async {
    if (_selectedStudentRefId == null) {
      setState(() {
        _attendanceDetail = {};
      });
      return;
    }
    setState(() => _loading = true);
    try {
      final detail = await _service.fetchStudentAttendanceDetail(
        studentRefId: _selectedStudentRefId!,
        startDate: _startDate,
        endDate: _endDate,
      );
      setState(() {
        _attendanceDetail = detail;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando detalle: $e')),
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
      await _fetchAttendanceDetail();
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
      await _fetchAttendanceDetail();
    }
  }

  Widget _buildFilterControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<StudentFilterType>(
          decoration: InputDecoration(
            labelText: 'Filtrar por',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          value: _selectedFilterType,
          items: StudentFilterType.values.map((filterType) {
            return DropdownMenuItem<StudentFilterType>(
              value: filterType,
              child: Text(filterType.label),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedFilterType = value;
              });
              _loadStudents();
            }
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _criteriaController,
          decoration: InputDecoration(
            labelText: 'Criterio de búsqueda',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Seleccionar estudiante',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      value: _selectedStudentRefId,
      hint: const Text('Seleccione un estudiante'),
      items: _students.map((student) {
        return DropdownMenuItem<String>(
          value: student['refId'],
          child: Text('${student['name']} (${_extractHomeroomName(student['homeroom'])})'),
        );
      }).toList(),
      onChanged: (value) async {
        setState(() {
          _selectedStudentRefId = value;
        });
        if (value != null) {
          await _fetchAttendanceDetail();
        } else {
          setState(() {
            _attendanceDetail = {};
          });
        }
      },
    );
  }

  String _extractHomeroomName(dynamic homeroomRef) {
    if (homeroomRef == null) return 'Sin grupo';
    final path = homeroomRef.toString();
    final segments = path.split('/');
    return segments.isNotEmpty ? segments.last : 'Sin grupo';
  }

  Widget _buildAttendanceTotalsTable() {
    final Map<String, Map<String, int>> totals = {};

    for (final subject in _attendanceDetail.keys) {
      final labelMap = _attendanceDetail[subject]!;
      final Map<String, int> counts = {};
      for (final label in labelMap.values) {
        if (label.isEmpty) continue;
        counts[label] = (counts[label] ?? 0) + 1;
      }
      totals[subject] = counts;
    }

    final labels = attendanceLabels.keys.toList();

    final Map<String, int> grandTotals = {};
    for (final counts in totals.values) {
      for (final label in labels) {
        grandTotals[label] = (grandTotals[label] ?? 0) + (counts[label] ?? 0);
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(primaryColor.withOpacity(0.1)),
        columnSpacing: 8,
        columns: [
          DataColumn(
            label: SizedBox(
              width: 150,
              child: const Text(
                'Asignatura',
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
        rows: [
          ...totals.entries.map((entry) {
            final subject = entry.key;
            final counts = entry.value;

            return DataRow(
              cells: [
                DataCell(
                  SizedBox(
                    width: 150,
                    child: Text(
                      subject,
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
          }),
          DataRow(
            color: MaterialStateProperty.all(primaryColor.withOpacity(0.15)),
            cells: [
              const DataCell(
                Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ...labels.map((label) {
                final total = grandTotals[label] ?? 0;
                return DataCell(
                  SizedBox(
                    width: 24,
                    child: Text(
                      total.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );
  }

  Map<String, int> _calculateAttendanceCounts(Map<String, Map<String, String>> attendanceDetail) {
    final counts = <String, int>{};
    for (final subjectMap in attendanceDetail.values) {
      for (final label in subjectMap.values) {
        if (label.isEmpty) continue;
        counts[label] = (counts[label] ?? 0) + 1;
      }
    }
    return counts;
  }

  Widget _buildAttendancePieChart() {
    final attendanceCounts = _calculateAttendanceCounts(_attendanceDetail);
    final total = attendanceCounts.values.fold<int>(0, (sum, count) => sum + count);

    if (total == 0) {
      return const Center(child: Text('No hay datos de asistencia para mostrar.'));
    }

    final sections = attendanceCounts.entries.map((entry) {
      final label = entry.key;
      final count = entry.value;
      final percentage = (count / total) * 100;
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
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: attendanceCounts.entries.map((entry) {
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
        title: const Text('Resumen de Asistencia por Estudiante'),
        backgroundColor: primaryColor,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFilterControls(),
                const SizedBox(height: 16),
                _buildStudentDropdown(),
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
                Text(
                  'Totales de asistencia por asignatura',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: _attendanceDetail.isEmpty
                      ? const Center(child: Text('No hay datos para los filtros seleccionados.'))
                      : _buildAttendanceTotalsTable(),
                ),
                const SizedBox(height: 24),
                Text(
                  'Gráfico de asistencia',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
                ),
                const SizedBox(height: 12),
                _buildAttendancePieChart(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
