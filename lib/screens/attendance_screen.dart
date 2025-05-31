import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/attendance_service.dart';
import '../services/auth_service.dart';
import '../services/homeroom_service.dart';

/// AttendanceScreen allows teachers to mark attendance and add notes per student.
/// Notes are saved immediately along with attendance status.
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

  // Maps to hold attendance status and notes per student
  Map<String, String> _attendanceMap = {};
  Map<String, String> _attendanceNotes = {};

  // Loading flag to show progress indicator during save operations
  bool _loadingSave = false;

  // Teacher info fetched from AuthService.currentUserData
  String? _teacherId;
  String? _teacherName;

  /// Generates a unique document ID for the attendance record
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
      print('Warning: Teacher info missing in AuthService.currentUserData');
    }

    // Load existing attendance data if available
    _loadExistingAttendance();
  }

  /// Loads existing attendance data and notes from Firestore and updates local state
  Future<void> _loadExistingAttendance() async {
    final attendanceData = await _attendanceService.loadFullAttendance(_docId);
    setState(() {
      _attendanceMap = attendanceData.map((id, map) => MapEntry(id, map['label'] ?? 'A'));
      _attendanceNotes = attendanceData.map((id, map) => MapEntry(id, map['notes'] ?? ''));
    });
  }

  /// Saves attendance and notes to Firestore using AttendanceService
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
      await _attendanceService.saveFullAttendance(
        docId: _docId,
        generalInfo: generalInfo,
        attendanceMap: _attendanceMap,
        notesMap: _attendanceNotes,
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
  /// Updates local state and immediately saves attendance and notes.
  void _onAttendanceChanged(String studentId, String newLabel) async {
    setState(() {
      _attendanceMap[studentId] = newLabel;
      _loadingSave = true;
    });

    await _saveAttendance();
  }

  /// Opens a dialog to add/edit a note for a student.
  /// Saves the note immediately after editing.
  Future<void> _editNoteDialog(String studentId, String studentName) async {
    String tempNote = _attendanceNotes[studentId] ?? '';
    final controller = TextEditingController(text: tempNote);

    final newNote = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Nota para $studentName'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 4,
            decoration: const InputDecoration(hintText: 'Escribe una nota...'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (newNote != null) {
      setState(() {
        _attendanceNotes[studentId] = newNote;
        _loadingSave = true;
      });
      await _saveAttendance();
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
            // General info display
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
              'Selecciona el estado de asistencia para cada estudiante y agrega notas si es necesario:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Student list with attendance dropdown and note icon
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
                      final currentLabel = _attendanceMap[studentId] ?? '';
                      final hasNote = (_attendanceNotes[studentId]?.isNotEmpty ?? false);

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // First row: icon + name + note button aligned horizontally
                              Row(
                                children: [
                                  Icon(Icons.person, color: primaryColor, size: 28),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      studentName,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      hasNote ? Icons.note : Icons.note_outlined,
                                      color: hasNote ? Colors.amber : Colors.grey,
                                      size: 28,
                                    ),
                                    tooltip: hasNote ? 'Editar nota' : 'Agregar nota',
                                    onPressed: () => _editNoteDialog(studentId, studentName),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Second row: attendance dropdown full width
                              DropdownButton<String>(
                                value: (currentLabel != null && currentLabel.isNotEmpty) ? currentLabel : null,
                                hint: const Text('Seleccione el estado'),
                                isExpanded: true,
                                items: attendanceLabels.entries.map((entry) {
                                  final label = entry.key;
                                  final desc = entry.value['description'] as String;
                                  final color = entry.value['color'] as Color;
                                  return DropdownMenuItem<String>(
                                    value: label,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 14,
                                          height: 14,
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
                            ],
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
