import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/attendance_service.dart';
import '../services/auth_service.dart';
import '../services/homeroom_service.dart';

/// AttendanceScreen allows teachers to mark attendance for students in a specific class session.
/// It shows general info, student list with attendance dropdown, and saves attendance automatically on change.
class AttendanceScreen extends StatefulWidget {
  final Map<String, dynamic> campus;
  final Map<String, dynamic> educationalLevel;
  final Map<String, dynamic> grade;
  final Map<String, dynamic> homeroom; // Must include 'id' and 'ref'
  final Map<String, dynamic> subject;  // Must include 'id' and 'name'
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
  // Corporate colors for consistent theming
  static const Color backgroundColor = Color(0xFFF0F0E3);
  static const Color primaryColor = Color(0xFF53A09D);

  final AttendanceService _attendanceService = AttendanceService();

  late Future<List<Map<String, dynamic>>> _studentsFuture;

  // Map to hold attendance status per student: studentId -> attendance label code (e.g., 'A', 'I', etc.)
  Map<String, String> _attendanceMap = {};

  // Loading flag to show progress indicator during save operations
  bool _loadingSave = false;

  // Teacher info fetched from AuthService.currentUserData
  String? _teacherId;
  String? _teacherName;

  /// Generates a unique document ID for the attendance record based on homeroom, subject, date, and time
  String get _docId => _attendanceService.generateDocId(
    homeroomId: widget.homeroom['id'],
    subjectId: widget.subject['id'],
    date: widget.selectedDate,
    timeSlot: widget.selectedTime,
  );

  @override
  void initState() {
    super.initState();

    // Load students belonging to the homeroom
    _studentsFuture = HomeroomService.getStudentsFromHomeroom(widget.homeroom['ref']);

    // Get teacher data from AuthService
    final userData = AuthService.currentUserData;
    _teacherId = userData?['refId'];
    _teacherName = userData?['name'];

    if (_teacherId == null || _teacherName == null) {
      // Log warning if teacher info is missing
      print('Warning: Teacher info missing in AuthService.currentUserData');
    }

    // Load existing attendance data if available
    _loadExistingAttendance();
  }

  /// Loads existing attendance data from Firestore and updates local state
  Future<void> _loadExistingAttendance() async {
    final existingAttendance = await _attendanceService.loadAttendance(_docId);
    setState(() {
      _attendanceMap = existingAttendance;
    });
  }

  /// Saves attendance data to Firestore using AttendanceService
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

    // Prepare general info to save alongside attendance records
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

    try {
      await _attendanceService.saveAttendance(
        docId: _docId,
        generalInfo: generalInfo,
        attendanceMap: _attendanceMap,
        date: widget.selectedDate,
        timeSlot: widget.selectedTime,
        teacherId: _teacherId!,
        teacherName: _teacherName!,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Asistencia guardada correctamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingSave = false;
        });
      }
    }
  }

  /// Called when a student's attendance status changes.
  /// Updates local state and immediately saves attendance.
  void _onAttendanceChanged(String studentId, String newLabel) async {
    setState(() {
      _attendanceMap[studentId] = newLabel;
      _loadingSave = true;
    });

    if (_teacherId == null || _teacherName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontró información del docente.')),
      );
      setState(() {
        _loadingSave = false;
      });
      return;
    }

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

    try {
      await _attendanceService.saveAttendance(
        docId: _docId,
        generalInfo: generalInfo,
        attendanceMap: _attendanceMap,
        date: widget.selectedDate,
        timeSlot: widget.selectedTime,
        teacherId: _teacherId!,
        teacherName: _teacherName!,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Asistencia guardada')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingSave = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Registro de Asistencia'),
        backgroundColor: primaryColor,
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
            // Display general info about the class session
            Text('Campus: ${widget.campus['name']}', style: TextStyle(fontSize: 16, color: Colors.black87)),
            Text('Nivel Educativo: ${widget.educationalLevel['name']}', style: TextStyle(fontSize: 16, color: Colors.black87)),
            Text('Grado: ${widget.grade['name']}', style: TextStyle(fontSize: 16, color: Colors.black87)),
            Text('Salón: ${widget.homeroom['name']}', style: TextStyle(fontSize: 16, color: Colors.black87)),
            Text('Asignatura: ${widget.subject['name']}', style: TextStyle(fontSize: 16, color: Colors.black87)),
            Text('Fecha: ${DateFormat('dd/MM/yyyy').format(widget.selectedDate)}', style: TextStyle(fontSize: 16, color: Colors.black87)),
            Text('Hora: ${widget.selectedTime}', style: TextStyle(fontSize: 16, color: Colors.black87)),
            const SizedBox(height: 16),
            const Divider(),
            const Text(
              'Selecciona el estado de asistencia para cada estudiante:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // List of students with attendance dropdowns
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
                          // Student icon with corporate primary color
                          leading: Icon(Icons.person, color: primaryColor),
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
