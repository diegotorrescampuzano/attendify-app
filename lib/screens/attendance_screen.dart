import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/student_service.dart';
import '../services/attendance_service.dart';

class AttendanceScreen extends StatefulWidget {
  final Map<String, dynamic> campus;
  final Map<String, dynamic> educationalLevel;
  final Map<String, dynamic> grade;
  final Map<String, dynamic> homeroom;

  const AttendanceScreen({
    super.key,
    required this.campus,
    required this.educationalLevel,
    required this.grade,
    required this.homeroom,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final Map<String, String> attendance = {}; // tipo de asistencia por estudiante

  final Map<String, String> attendanceLabels = {
    'A': 'Asiste',
    'T': 'Tarde',
    'E': 'Evasión',
    'I': 'Inasistencia',
    'IJ': 'Inasistencia Justificada',
    'P': 'Retiro con acudiente',
  };

  final Map<String, Color> attendanceColors = {
    'A': Colors.green,
    'T': Colors.orange,
    'E': Colors.red,
    'I': Colors.black54,
    'IJ': Colors.blueGrey,
    'P': Colors.purple,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0E3),
      appBar: AppBar(
        title: const Text('Registro de Asistencia'),
        backgroundColor: const Color(0xFF53A09D),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Guardar asistencia',
            onPressed: _saveAttendance,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.campus['name'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(widget.educationalLevel['name'] ?? '', style: const TextStyle(fontSize: 18)),
            Text(widget.grade['name'] ?? '', style: const TextStyle(fontSize: 16)),
            Text(widget.homeroom['name'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            const Text('Estudiantes del salón:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: StudentService.getStudentsByHomeroom(widget.homeroom['ref']),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No se encontraron estudiantes.'));
                  }

                  final students = snapshot.data!;
                  return ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final student = students[index];
                      final studentId = student['id'];

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text(student['name'] ?? 'Sin nombre'),
                          subtitle: Text(
                            attendance[studentId] != null
                                ? 'Estado: ${attendanceLabels[attendance[studentId]!]}'
                                : 'Selecciona un estado',
                            style: TextStyle(
                              color: attendance[studentId] != null
                                  ? attendanceColors[attendance[studentId]!]
                                  : Colors.grey,
                            ),
                          ),
                          trailing: DropdownButton<String>(
                            hint: const Text('Estado'),
                            value: attendance[studentId],
                            items: attendanceLabels.entries.map((entry) {
                              return DropdownMenuItem<String>(
                                value: entry.key,
                                child: Row(
                                  children: [
                                    Icon(Icons.circle, color: attendanceColors[entry.key], size: 12),
                                    const SizedBox(width: 8),
                                    Text(entry.value),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                if (value != null) {
                                  attendance[studentId] = value;
                                }
                              });
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

  void _saveAttendance() async {
    if (attendance.length < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes registrar al menos una asistencia.')),
      );
      return;
    }

    try {
      await AttendanceService.saveAttendance(
        attendanceMap: attendance, // Aquí se guarda el tipo de asistencia por estudiante
        homeroomRef: widget.homeroom['ref'],
        gradeRef: widget.grade['ref'],
        educationalLevelRef: widget.educationalLevel['ref'],
        campusRef: widget.campus['ref'],
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Asistencia guardada exitosamente')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar asistencia')),
      );
    }
  }
}
