import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeroomScreen extends StatefulWidget {
  final Map<String, dynamic> campus;
  final Map<String, dynamic> educationalLevel;
  final Map<String, dynamic> grade;

  const HomeroomScreen({
    super.key,
    required this.campus,
    required this.educationalLevel,
    required this.grade,
  });

  @override
  State<HomeroomScreen> createState() => _HomeroomScreenState();
}

class _HomeroomScreenState extends State<HomeroomScreen> {
  List<DocumentReference> homeroomRefs = [];

  @override
  void initState() {
    super.initState();
    homeroomRefs = (widget.grade['homerooms'] as List).cast<DocumentReference>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0E3),
      appBar: AppBar(
        title: const Text('Selecciona el salón'),
        backgroundColor: const Color(0xFF53A09D),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.campus['name'] ?? '',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.educationalLevel['name'] ?? '',
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              widget.grade['name'] ?? '',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Text(
              'Salones disponibles:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: homeroomRefs.length,
                itemBuilder: (context, index) {
                  final ref = homeroomRefs[index];
                  return FutureBuilder<DocumentSnapshot>(
                    future: ref.get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const ListTile(title: Text('Cargando...'));
                      } else if (snapshot.hasError) {
                        return ListTile(title: Text('Error al cargar salón'));
                      } else if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const ListTile(title: Text('Salón no disponible'));
                      }

                      final data = snapshot.data!.data() as Map<String, dynamic>;
                      return Card(
                        child: ListTile(
                          title: Text(data['name'] ?? 'Sin nombre'),
                          subtitle: Text(data['description'] ?? ''),
                          leading: const Icon(Icons.meeting_room, color: Color(0xFF53A09D)),
                          onTap: () {
                            // Aquí podrías navegar a una pantalla de asistencia, por ejemplo.
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
