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

    // Get educational level ID and start fetching grades
    final levelId = widget.educationalLevel['id'];
    _gradesFuture = GradeService.getGradesForLevel(levelId);
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
            // Display selected campus information for context
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

            // Display selected educational level information
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

            // Section title for grades
            const Text(
              'Grados Escolares:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),

            // Async grade list with loading/error states
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

                  // Display list of grade cards
                  return ListView.builder(
                    itemCount: grades.length,
                    itemBuilder: (context, index) {
                      final grade = grades[index];
                      return Card(
                        elevation: 2,
                        child: ListTile(
                          // Generic icon to represent groups of homerooms
                          leading: const Icon(Icons.groups, color: Color(0xFF53A09D)),
                          title: Text(
                            grade['name'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(grade['description'] ?? ''),
                          onTap: () {
                            // TODO: Navigate to the homerooms screen in the next phase
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
