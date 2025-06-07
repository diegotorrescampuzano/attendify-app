import 'package:flutter/material.dart';
import '../services/homeroom_service.dart';

/// Screen that displays the list of homerooms for the selected campus
/// showing lecture details for today's schedule.
class HomeroomScreen extends StatefulWidget {
  final Map<String, dynamic> campus;

  const HomeroomScreen({
    super.key,
    required this.campus,
  });

  @override
  State<HomeroomScreen> createState() => _HomeroomScreenState();
}

class _HomeroomScreenState extends State<HomeroomScreen> {
  late Future<List<Map<String, dynamic>>> _homeroomsFuture;

  @override
  void initState() {
    super.initState();
    // Fetch homerooms enriched with today's lecture details from the campus data
    _homeroomsFuture = HomeroomService.getHomeroomsWithLectureDetails(
      widget.campus['lecturesForToday'] ?? {},
    );
  }

  /// Navigates to the attendance screen with the selected homeroom and all required arguments
  void _onHomeroomSelected(Map<String, dynamic> homeroom) {
    // Prepare arguments for attendance screen
    Navigator.pushNamed(
      context,
      '/attendance',
      arguments: {
        'campus': {
          'id': homeroom['campusId'],
          'name': homeroom['campusName'],
        },
        'educationalLevel': {
          'id': homeroom['educationalLevelId'],
          'name': homeroom['educationalLevelName'],
        },
        'grade': {
          'id': homeroom['gradeId'],
          'name': homeroom['gradeName'],
        },
        'homeroom': homeroom,
        'subject': {
          'id': homeroom['subjectId'],  // Now correctly included
          'name': homeroom['subjectName'],
        },
        // Pass slot, time, and current date for attendance
        'selectedTime': homeroom['time'],
        'selectedDate': DateTime.now(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0E3),
      appBar: AppBar(
        title: Text(widget.campus['name']),
        backgroundColor: const Color(0xFF53A09D),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                        'Selecciona el salón de clase donde deseas registrar la asistencia.',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _homeroomsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return const Center(child: Text('Error cargando salones'));
                  }
                  final homerooms = snapshot.data!;
                  if (homerooms.isEmpty) {
                    return const Center(child: Text('No hay salones disponibles para hoy.'));
                  }
                  return ListView.builder(
                    itemCount: homerooms.length,
                    itemBuilder: (context, index) {
                      final homeroom = homerooms[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: const Icon(Icons.meeting_room, color: Color(0xFF53A09D)),
                          title: Text(homeroom['name']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if ((homeroom['subjectName'] ?? '').isNotEmpty)
                                Text('Asignatura: ${homeroom['subjectName']}'),
                              if ((homeroom['slot'] ?? '').toString().isNotEmpty)
                                Text('Slot: ${homeroom['slot']}'),
                              if ((homeroom['time'] ?? '').toString().isNotEmpty)
                                Text('Horario: ${homeroom['time']}'),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _onHomeroomSelected(homeroom),
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
