import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../services/attendance_service.dart';
import '../services/auth_service.dart';
import '../services/homeroom_service.dart';

const Map<String, Map<String, dynamic>> attendanceLabels = {
  'A': {'description': 'Asiste', 'color': Color(0xFF4CAF50)},
  'T': {'description': 'Tarde', 'color': Color(0xFFFF9800)},
  'E': {'description': 'Evasión', 'color': Color(0xFFF44336)},
  'I': {'description': 'Inasistencia', 'color': Colors.black54},
  'IJ': {'description': 'Inasistencia Justificada', 'color': Color(0xFF607D8B)},
  'P': {'description': 'Retiro con acudiente', 'color': Color(0xFF9C27B0)},
};

class AttendanceScreen extends StatefulWidget {
  final Map<String, dynamic> campus;
  final Map<String, dynamic> educationalLevel;
  final Map<String, dynamic> grade;
  final Map<String, dynamic> homeroom;
  final Map<String, dynamic> subject;
  final DateTime selectedDate;
  final String selectedTime;

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
  static const Color backgroundColor = Color(0xFFF0F0E3);
  static const Color primaryColor = Color(0xFF53A09D);

  final AttendanceService _attendanceService = AttendanceService();

  late Future<List<Map<String, dynamic>>> _studentsFuture;

  Map<String, String> _attendanceMap = {};
  Map<String, String> _attendanceNotes = {};

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
    _studentsFuture = HomeroomService.getStudentsFromHomeroom(widget.homeroom['ref']);
    final userData = AuthService.currentUserData;
    _teacherId = userData?['refId'];
    _teacherName = userData?['name'];
    if (_teacherId == null || _teacherName == null) {
      print('Warning: Teacher info missing in AuthService.currentUserData');
    }
    _loadExistingAttendance();
  }

  Future<void> _loadExistingAttendance() async {
    final attendanceData = await _attendanceService.loadFullAttendance(_docId);
    setState(() {
      _attendanceMap = attendanceData.map((id, map) => MapEntry(id, map['label'] ?? ''));
      _attendanceNotes = attendanceData.map((id, map) => MapEntry(id, map['notes'] ?? ''));
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

  void _onAttendanceChanged(String studentId, String newLabel) async {
    setState(() {
      _attendanceMap[studentId] = newLabel;
      _loadingSave = true;
    });
    await _saveAttendance();
  }

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

  Future<void> _openWhatsApp(String phone, String message) async {
    final encodedMessage = Uri.encodeComponent(message);
    final cleanedPhone = phone.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    final whatsappUrl = Uri.parse('https://api.whatsapp.com/send?phone=$cleanedPhone&text=$encodedMessage');
    try {
      await launchUrl(whatsappUrl, mode: LaunchMode.platformDefault);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir WhatsApp')),
      );
    }
  }

  Future<void> _makePhoneCall(String phone) async {
    final telUrl = Uri.parse('tel:$phone');
    try {
      await launchUrl(telUrl, mode: LaunchMode.platformDefault);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo iniciar la llamada')),
      );
    }
  }

  void _confirmFinishAttendance() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar'),
          content: const Text('¿Estás seguro de finalizar el registro?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
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
                      final phone = student['cellphoneContact'] ?? '';

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                              Row(
                                children: [
                                  const Text('Asistencia: ', style: TextStyle(fontSize: 16)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: DropdownButton<String>(
                                      isExpanded: true,
                                      value: currentLabel.isNotEmpty ? currentLabel : null,
                                      hint: const Text('Selecciona'),
                                      items: attendanceLabels.entries.map((entry) {
                                        final label = entry.key;
                                        final labelInfo = entry.value;
                                        return DropdownMenuItem<String>(
                                          value: label,
                                          child: Row(
                                            children: [
                                              Icon(Icons.circle, color: labelInfo['color'], size: 16),
                                              const SizedBox(width: 8),
                                              Text('${labelInfo['description']} ($label)'),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        if (newValue != null) {
                                          _onAttendanceChanged(studentId, newValue);
                                        }
                                      },
                                    ),
                                  ),
                                ],
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
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('Finalizar Registro'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                onPressed: _confirmFinishAttendance,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
