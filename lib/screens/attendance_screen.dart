import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/attendance_service.dart';
import '../services/auth_service.dart';
import '../services/homeroom_service.dart';

class AttendanceScreen extends StatefulWidget {
  final Map<String, dynamic> campus;
  final Map<String, dynamic> educationalLevel;
  final Map<String, dynamic> grade;
  final Map<String, dynamic> homeroom; // must include 'id' and 'ref'
  final Map<String, dynamic> subject;  // must include 'id' and 'name'
  final DateTime selectedDate;
  final String selectedTime; // e.g., "07:30 AM"

  const AttendanceScreen({
    super.key,
    required this.campus,
    required this.educationalLevel,
    required this.grade,
    required this.homeroom,
    required this.subject,
    required this.selectedDate,
    required this.selectedTime,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final AttendanceService _attendanceService = AttendanceService();

  late Future<List<Map<String, dynamic>>> _studentsFuture;

  Map<String, String> _attendanceMap = {};
  bool _loadingSave = false;

  String? _teacherId;
  String? _teacherName;

  String get _docId => _attendanceService.generateDocId(
    homeroomId: widget.homeroom['id'],
    subjectId: widget.subject['id'],
    date: widget.selectedDate,
    timeSlot: widget.selectedTime,
  );

  @override
  void initState() {
    super.initState();

    // Load students from homeroom
    _studentsFuture = HomeroomService.getStudentsFromHomeroom(widget.homeroom['ref']);

    // Get teacher info from AuthService
    final userData = AuthService.currentUserData;
    _teacherId = userData?['refId'];
    _teacherName = userData?['name'];

    if (_teacherId == null || _teacherName == null) {
      print('Warning: Teacher info missing in AuthService.currentUserData');
    }

    _loadExistingAttendance();
  }

  Future<void> _loadExistingAttendance() async {
    final existingAttendance = await _attendanceService.loadAttendance(_docId);
    setState(() {
      _attendanceMap = existingAttendance;
    });
  }

  Future<void> _saveAttendance() async {
    if (_teacherId == null || _teacherName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontró información del docente.')),
      );
      return;
    }

    setState(() {
      _loadingSave = true;
    });

    final generalInfo = {
      'campusId': widget.campus['id'],
      'campusName': widget.campus['name'],
      'educationalLevelId': widget.educationalLevel['id'],
      'educationalLevelName': widget.educationalLevel['name'],
      'gradeId': widget.grade['id'],
      'gradeName': widget.grade['name'],
      'homeroomId': widget.homeroom['id'],
      'homeroomName': widget.homeroom['name'],
      'subjectId': widget.subject['id'],
      'subjectName': widget.subject['name'],
    };

    await _attendanceService.saveAttendance(
      docId: _docId,
      generalInfo: generalInfo,
      attendanceMap: _attendanceMap,
      date: widget.selectedDate,
      timeSlot: widget.selectedTime,
      teacherId: _teacherId!,
      teacherName: _teacherName!,
    );

    setState(() {
      _loadingSave = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Asistencia guardada correctamente')),
    );
  }

  void _onAttendanceChanged(String studentId, String newLabel) {
    setState(() {
      _attendanceMap[studentId] = newLabel;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Asistencia'),
        backgroundColor: const Color(0xFF53A09D),
        actions: [
          IconButton(
            icon: _loadingSave
                ? const CircularProgressIndicator(color: Colors.white)
                : const Icon(Icons.save),
            onPressed: _loadingSave ? null : _saveAttendance,
            tooltip: 'Guardar asistencia',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Campus: ${widget.campus['name']}', style: const TextStyle(fontSize: 16)),
            Text('Nivel Educativo: ${widget.educationalLevel['name']}', style: const TextStyle(fontSize: 16)),
            Text('Grado: ${widget.grade['name']}', style: const TextStyle(fontSize: 16)),
            Text('Salón: ${widget.homeroom['name']}', style: const TextStyle(fontSize: 16)),
            Text('Asignatura: ${widget.subject['name']}', style: const TextStyle(fontSize: 16)),
            Text('Fecha: ${DateFormat('dd/MM/yyyy').format(widget.selectedDate)}', style: const TextStyle(fontSize: 16)),
            Text('Hora: ${widget.selectedTime}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            const Divider(),
            const Text(
              'Selecciona el estado de asistencia para cada estudiante:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _studentsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No se encontraron estudiantes.'));
                  }

                  final students = snapshot.data!;

                  return ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final student = students[index];
                      final studentId = student['id'] ?? student['ref']?.id ?? '';
                      final studentName = student['name'] ?? 'Sin nombre';
                      final currentLabel = _attendanceMap[studentId] ?? 'A';

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text(studentName),
                          subtitle: Text(student['cellphoneContact'] ?? ''),
                          trailing: DropdownButton<String>(
                            value: currentLabel,
                            items: attendanceLabels.entries.map((entry) {
                              final label = entry.key;
                              final desc = entry.value['description'] as String;
                              final color = entry.value['color'] as Color;
                              return DropdownMenuItem<String>(
                                value: label,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    Text(desc),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (newLabel) {
                              if (newLabel != null) {
                                _onAttendanceChanged(studentId, newLabel);
                              }
                            },
                          ),
                        ),
                      );
                    },
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
