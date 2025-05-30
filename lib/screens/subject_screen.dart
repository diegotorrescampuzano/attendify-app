import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For weekday formatting
import '../services/subject_service.dart';

class SubjectScreen extends StatefulWidget {
  final Map<String, dynamic> campus;
  final Map<String, dynamic> educationalLevel;
  final Map<String, dynamic> grade;
  final Map<String, dynamic> homeroom; // Includes 'id' and 'ref' (DocumentReference)

  const SubjectScreen({
    super.key,
    required this.campus,
    required this.educationalLevel,
    required this.grade,
    required this.homeroom,
  });

  @override
  State<SubjectScreen> createState() => _SubjectScreenState();
}

class _SubjectScreenState extends State<SubjectScreen> {
  late Future<List<Map<String, dynamic>>> _subjectsFuture;
  late String _weekdayKey;

  // Map English weekday names to Spanish as static const
  static const Map<String, String> englishToSpanishWeekdays = {
    'monday': 'Lunes',
    'tuesday': 'Martes',
    'wednesday': 'Miércoles',
    'thursday': 'Jueves',
    'friday': 'Viernes',
    'saturday': 'Sábado',
    'sunday': 'Domingo',
  };

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _weekdayKey = DateFormat('EEEE').format(now).toLowerCase();

    final homeroomRef = widget.homeroom['ref'];
    _subjectsFuture = SubjectService.getSubjectsForHomeroomByDay(homeroomRef, _weekdayKey);
  }

  @override
  Widget build(BuildContext context) {
    final spanishWeekday = englishToSpanishWeekdays[_weekdayKey] ?? _weekdayKey;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F0E3),
      appBar: AppBar(
        title: const Text('Selecciona la Asignatura'),
        backgroundColor: const Color(0xFF53A09D),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Card(
              color: const Color(0xFFE6F4F1),
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFF53A09D), size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Selecciona la asignatura correspondiente al salón y día actual para continuar con el registro de asistencia.',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Display hierarchy info
            Text(
              widget.campus['name'] ?? '',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              widget.educationalLevel['name'] ?? '',
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              widget.grade['name'] ?? '',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              widget.homeroom['name'] ?? '',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),

            // Current weekday display in Spanish
            Text(
              'Asignaturas para el día: $spanishWeekday',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 10),

            // Subjects list
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _subjectsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No se encontraron asignaturas para hoy.'));
                  }

                  final subjects = snapshot.data!;

                  return ListView.builder(
                    itemCount: subjects.length,
                    itemBuilder: (context, index) {
                      final subject = subjects[index];
                      return Card(
                        elevation: 2,
                        child: ListTile(
                          leading: const Icon(Icons.menu_book, color: Color(0xFF53A09D)),
                          title: Text(
                            subject['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(subject['description']),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            // TODO: Navigate to attendance screen or next step
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
}
