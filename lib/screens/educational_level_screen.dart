import 'package:flutter/material.dart';
import '../services/educational_level_service.dart';

// This screen displays the list of educational levels available for a selected campus.
class EducationalLevelScreen extends StatefulWidget {
  final Map<String, dynamic> campus;

  const EducationalLevelScreen({super.key, required this.campus});

  @override
  State<EducationalLevelScreen> createState() => _EducationalLevelScreenState();
}

class _EducationalLevelScreenState extends State<EducationalLevelScreen> {
  late Future<List<Map<String, dynamic>>> _levelsFuture;

  @override
  void initState() {
    super.initState();
    // Get the campus ID and fetch the corresponding educational levels.
    final campusId = widget.campus['id'];
    _levelsFuture = EducationalLevelService.getEducationalLevelsForCampus(campusId);
  }

  // Handle the selection of an educational level and navigate to the grade screen.
  void _onLevelSelected(Map<String, dynamic> level) {
    Navigator.pushNamed(context, '/grade', arguments: {
      'campus': widget.campus,
      'educationalLevel': level,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0E3),
      appBar: AppBar(
        title: const Text('Selecciona el Nivel Escolar'),
        backgroundColor: const Color(0xFF53A09D),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display campus name
            Text(
              widget.campus['name'] ?? '',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            // Display campus description
            Text(
              widget.campus['description'] ?? '',
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            // Section title
            const Text(
              'Niveles de Escolaridad:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            // Asynchronous loading of educational levels
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _levelsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    // Show loading indicator
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    // Show error message
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    // Show message if no data is available
                    return const Center(child: Text('No se encontraron niveles escolares.'));
                  }

                  final levels = snapshot.data!;

                  // Display each educational level in a list
                  return ListView.builder(
                    itemCount: levels.length,
                    itemBuilder: (context, index) {
                      final level = levels[index];
                      return Card(
                        elevation: 2,
                        child: ListTile(
                          leading: const Icon(Icons.school, color: Color(0xFF53A09D)), // Educational icon
                          title: Text(level['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(level['description'] ?? ''),
                          onTap: () => _onLevelSelected(level), // Navigate on tap
                        ),
                      );
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
