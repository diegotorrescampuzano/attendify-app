import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  String _studentQuery = '';

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  bool _loading = false;

  Map<String, Map<String, String>> _attendanceDetail = {};

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _loading = true);
    try {
      final students = await _service.fetchStudents(query: _studentQuery);
      print('Loaded students count: ${students.length}');
      print('Student IDs: ${students.map((s) => s['refId']).toList()}');
      setState(() {
        _selectedStudentRefId = null; // Reset before updating
        _students = students;
        if (_students.isNotEmpty) {
          if (_selectedStudentRefId == null || !_students.any((s) => s['refId'] == _selectedStudentRefId)) {
            _selectedStudentRefId = _students.first['refId'];
            print('Selected student set to: $_selectedStudentRefId');
          }
        } else {
          _selectedStudentRefId = null;
          print('No students available, selected student set to null');
        }
      });
      if (_selectedStudentRefId != null) {
        await _fetchAttendanceDetail();
      } else {
        setState(() {
          _attendanceDetail = {};
        });
      }
    } catch (e) {
      print('Error loading students: $e');
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

  Widget _buildStudentFilter() {
    print('Building dropdown with selectedStudentRefId: $_selectedStudentRefId');
    print('Dropdown items: ${_students.map((s) => s['refId']).toList()}');
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, grupo o celular',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            ),
            onChanged: (value) {
              setState(() {
                _studentQuery = value;
              });
              _loadStudents();
            },
          ),
        ),
        const SizedBox(width: 12),
        DropdownButton<String>(
          value: _selectedStudentRefId,
          hint: const Text('Seleccionar estudiante'),
          items: _students.map((student) {
            return DropdownMenuItem<String>(
              value: student['refId'],
              child: Text(
                '${student['name']} (${student['homeroom']})',
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (value) async {
            setState(() {
              _selectedStudentRefId = value;
            });
            await _fetchAttendanceDetail();
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final Set<String> allDates = {};
    for (final subject in _attendanceDetail.values) {
      allDates.addAll(subject.keys);
    }
    final sortedDates = allDates.toList()..sort((a, b) => a.compareTo(b));

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Resumen de Asistencia por Estudiante'),
        backgroundColor: primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Estudiante:', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildStudentFilter(),
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
              'Detalle de asistencias',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
            ),
            const SizedBox(height: 12),
            Container(
              color: primaryColor.withOpacity(0.1),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Row(
                children: [
                  const Expanded(
                    flex: 3,
                    child: Text('Asignatura', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  ...sortedDates.map((date) => Expanded(
                    flex: 2,
                    child: Text(
                      DateFormat('dd/MM').format(DateTime.parse(date)),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  )),
                ],
              ),
            ),
            Expanded(
              child: _attendanceDetail.isEmpty
                  ? const Center(child: Text('No hay datos para los filtros seleccionados.'))
                  : ListView.builder(
                itemCount: _attendanceDetail.length,
                itemBuilder: (context, index) {
                  final subject = _attendanceDetail.keys.elementAt(index);
                  final dateMap = _attendanceDetail[subject]!;
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
                        ...sortedDates.map((date) {
                          final label = dateMap[date] ?? '';
                          return Expanded(
                            flex: 2,
                            child: label.isNotEmpty
                                ? Tooltip(
                              message: attendanceLabels[label]?['description'] ?? label,
                              child: Container(
                                width: 24,
                                height: 24,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Color(attendanceLabels[label]?['color'] ?? 0xFFBDBDBD),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  label,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            )
                                : const SizedBox.shrink(),
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
