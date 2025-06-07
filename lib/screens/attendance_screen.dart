import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../services/attendance_service.dart';
import '../services/auth_service.dart';
import '../services/homeroom_service.dart';

class AttendanceScreen extends StatefulWidget {
  final Map<String, dynamic> campus;
  final Map<String, dynamic> educationalLevel;
  final Map<String, dynamic> grade;
  final Map<String, dynamic> homeroom; // Must include 'id' and 'ref'
  final Map<String, dynamic> subject; // Must include 'id' and 'name'
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
  // Corporate colors for consistent styling
  static const Color backgroundColor = Color(0xFFF0F0E3);
  static const Color primaryColor = Color(0xFF53A09D);

  final AttendanceService _attendanceService = AttendanceService();

  // Future to load students asynchronously
  late Future<List<Map<String, dynamic>>> _studentsFuture;

  // Maps to store attendance labels and notes keyed by student ID
  Map<String, String> _attendanceMap = {};
  Map<String, String> _attendanceNotes = {};

  // Loading state for save button
  bool _loadingSave = false;

  // Teacher info from authentication service
  String? _teacherId;
  String? _teacherName;

  // Generate document ID for attendance record
  String get _docId => _attendanceService.generateDocId(
    homeroomId: widget.homeroom['id'],
    subjectId: widget.subject['id'],
    date: widget.selectedDate,
    timeSlot: widget.selectedTime,
  );

  @override
  void initState() {
    super.initState();
    // Load students from homeroom reference
    //////////////////////////////////////////////////////_studentsFuture = HomeroomService.getStudentsFromHomeroom(widget.homeroom['ref']);
    // Get teacher data from authentication service
    final userData = AuthService.currentUserData;
    _teacherId = userData?['refId'];
    _teacherName = userData?['name'];
    if (_teacherId == null || _teacherName == null) {
      print('Warning: Teacher info missing in AuthService.currentUserData');
    }
    // Load existing attendance data if any
    _loadExistingAttendance();
  }

  /// Loads existing attendance and notes for the current attendance document
  Future<void> _loadExistingAttendance() async {
    final attendanceData = await _attendanceService.loadFullAttendance(_docId);
    setState(() {
      // Map student IDs to attendance labels and notes
      _attendanceMap = attendanceData.map((id, map) => MapEntry(id, map['label'] ?? ''));
      _attendanceNotes = attendanceData.map((id, map) => MapEntry(id, map['notes'] ?? ''));
    });
  }

  /// Saves the current attendance and notes to the backend
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

    // Prepare general info about the attendance record
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
      // Call service to save attendance data
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

  /// Handles change of attendance label for a student
  void _onAttendanceChanged(String studentId, String newLabel) async {
    setState(() {
      _attendanceMap[studentId] = newLabel;
      _loadingSave = true;
    });
    await _saveAttendance();
  }

  /// Shows a dialog to edit or add a note for a student
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
              onPressed: () => Navigator.pop(context, null), // Cancel editing
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()), // Save note
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

  /// Opens WhatsApp with a pre-filled message to the given phone number
  Future<void> _openWhatsApp(String phone, String message) async {
    final encodedMessage = Uri.encodeComponent(message);
    final cleanedPhone = phone.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    final whatsappUrl = Uri.parse('https://api.whatsapp.com/send?phone=$cleanedPhone&text=$encodedMessage');
    try {
      // Launch WhatsApp URL using platform default mode
      await launchUrl(whatsappUrl, mode: LaunchMode.platformDefault);
    } catch (e) {
      // Show error if WhatsApp cannot be opened
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir WhatsApp')),
      );
    }
  }

  /// Initiates a phone call to the given phone number
  Future<void> _makePhoneCall(String phone) async {
    final telUrl = Uri.parse('tel:$phone');
    try {
      // Launch phone dialer
      await launchUrl(telUrl, mode: LaunchMode.platformDefault);
    } catch (e) {
      // Show error if call cannot be initiated
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo iniciar la llamada')),
      );
    }
  }

  /// Shows confirmation dialog to finalize attendance registration
  void _confirmFinishAttendance() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar'),
          content: const Text('¿Estás seguro de finalizar el registro?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Close dialog on No
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog on Yes
                // Navigate to home screen and clear navigation stack
                Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
              },
              child: const Text('Sí'),
            ),
          ],
        );
      },
    );
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
            // Display general info about the attendance session
            Text('Campus: ${widget.campus['name']}', style: const TextStyle(fontSize: 16, color: Colors.black87)),
            Text('Nivel Educativo: ${widget.educationalLevel['name']}', style: const TextStyle(fontSize: 16, color: Colors.black87)),
            Text('Grado: ${widget.grade['name']}', style: const TextStyle(fontSize: 16, color: Colors.black87)),
            Text('Salón: ${widget.homeroom['name']}', style: const TextStyle(fontSize: 16, color: Colors.black87)),
            Text('Asignatura: ${widget.subject['name']}', style: const TextStyle(fontSize: 16, color: Colors.black87)),
            Text('Fecha: ${DateFormat('dd/MM/yyyy').format(widget.selectedDate)}', style: const TextStyle(fontSize: 16, color: Colors.black87)),
            Text('Hora: ${widget.selectedTime}', style: const TextStyle(fontSize: 16, color: Colors.black87)),
            const SizedBox(height: 16),
            const Divider(),
            const Text(
              'Selecciona el estado de asistencia para cada estudiante y agrega notas si es necesario:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Expanded list of students with attendance controls
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _studentsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    // Show loading spinner while fetching students
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    // Show error message if loading fails
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    // Show message if no students found
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
                      final phone = student['cellphoneContact'] ?? '';

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // First row: person icon, student name, note button, WhatsApp button
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
                                  IconButton(
                                    icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.green, size: 28),
                                    tooltip: 'Enviar mensaje WhatsApp',
                                    onPressed: phone.isEmpty
                                        ? null
                                        : () {
                                      final note = _attendanceNotes[studentId];
                                      final defaultMessage = (note?.isNotEmpty ?? false)
                                          ? note!
                                          : 'Mensaje para el acudiente del estudiante';
                                      _openWhatsApp(phone, defaultMessage);
                                    },
                                  ),
                                ],
                              ),

                              const SizedBox(height: 4),

                              // Second row: phone icon + tappable phone number to make call
                              GestureDetector(
                                onTap: phone.isEmpty
                                    ? null
                                    : () => _makePhoneCall(phone),
                                child: Row(
                                  children: [
                                    const Icon(Icons.phone, size: 18, color: Colors.grey),
                                    const SizedBox(width: 6),
                                    Text(
                                      phone.isEmpty ? 'Número no disponible' : phone,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: phone.isEmpty ? Colors.grey : primaryColor,
                                        decoration: phone.isEmpty ? null : TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Third row: attendance dropdown full width
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

            const SizedBox(height: 16),

            // Button to finalize attendance registration with corporate style
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor, // your corporate teal
                  foregroundColor: Colors.white, // text color explicitly white
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _confirmFinishAttendance,
                child: const Text('Finalizar registro de asistencia'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
