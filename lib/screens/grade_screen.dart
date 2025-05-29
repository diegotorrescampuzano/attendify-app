import 'package:flutter/material.dart';
import '../services/grade_service.dart';

class GradeScreen extends StatefulWidget {
  final Map<String, dynamic> campus;
  final Map<String, dynamic> educationalLevel;

  const GradeScreen({
    super.key,
    required this.campus,
    required this.educationalLevel,
  });

  @override
  State<GradeScreen> createState() => _GradeScreenState();
}

class _GradeScreenState extends State<GradeScreen> {
  late Future<List<Map<String, dynamic>>> _gradesFuture;

  @override
  void initState() {
    super.initState();
    final levelId = widget.educationalLevel['id'];
    _gradesFuture = GradeService.getGradesForLevel(levelId);
  }

  void _onGradeSelected(Map<String, dynamic> grade) {
    Navigator.pushNamed(context, '/homeroom', arguments: {
      'campus': widget.campus,
      'educationalLevel': widget.educationalLevel,
      'grade': grade,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0E3),
      appBar: AppBar(
        title: const Text('Selecciona el Grado Escolar'),
        backgroundColor: const Color(0xFF53A09D),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mensaje informativo para el usuario
            Card(
              color: const Color(0xFFE6F4F1),
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.info_outline, color: Color(0xFF53A09D), size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Selecciona el grado escolar correspondiente al nivel educativo de la sede elegida. '
                            'Esto te permitirá continuar con el proceso de registro de asistencia por salón.',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Información del campus
            Text(
              widget.campus['name'] ?? '',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              widget.campus['description'] ?? '',
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 12),

            // Información del nivel educativo
            Text(
              widget.educationalLevel['name'] ?? '',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              widget.educationalLevel['description'] ?? '',
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 16),

            const Text(
              'Grados Escolares:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),

            // Lista de grados escolares
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _gradesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No se encontraron grados.'));
                  }

                  final grades = snapshot.data!;

                  return ListView.builder(
                    itemCount: grades.length,
                    itemBuilder: (context, index) {
                      final grade = grades[index];
                      return Card(
                        elevation: 2,
                        child: ListTile(
                          leading: const Icon(Icons.groups, color: Color(0xFF53A09D)),
                          title: Text(
                            grade['name'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(grade['description'] ?? ''),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _onGradeSelected(grade),
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
