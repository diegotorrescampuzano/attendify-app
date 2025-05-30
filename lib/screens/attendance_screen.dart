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
  final Map<String, bool> attendance = {};

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

            const Text(
              'Estudiantes del salón:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: StudentService.getStudentsByHomeroom(widget.homeroom['ref']),
                builder: (context, snapshot) {
                  print("Snapshot data for attendance screen: ${snapshot.data}");
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
                        child: CheckboxListTile(
                          title: Text(student['name'] ?? 'Sin nombre'),
                          value: attendance[studentId] ?? true,
                          onChanged: (value) {
                            setState(() {
                              attendance[studentId] = value ?? true;
                            });
                          },
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
    try {
      await AttendanceService.saveAttendance(
        attendanceMap: attendance,
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
