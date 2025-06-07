import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/campus_service.dart'; // Service to fetch campuses for the teacher


/// Screen to display a list of campuses assigned to the logged-in teacher
class CampusScreen extends StatefulWidget {
  const CampusScreen({super.key});

  @override
  State<CampusScreen> createState() => _CampusScreenState();
}

class _CampusScreenState extends State<CampusScreen> {
  // Future that will hold the list of campuses retrieved asynchronously
  late Future<List<Map<String, dynamic>>> _campusesFuture;

  // Reference ID used to identify the teacher in Firestore
  String? _refId;

  @override
  void initState() {
    super.initState();

    // Get current logged-in user's data from the auth service
    final userData = AuthService.currentUserData;

    // Extract 'refId' that links the user to their Firestore teacher document
    _refId = userData?['refId'];

    // If the refId exists, fetch campuses; otherwise return an empty list
    _campusesFuture = _refId != null
        ? CampusService.getCampusesAndLecturesForTeacher(_refId!)
        : Future.value([]);
  }

  /// Navigate to the homeroom screen when a campus is selected
  void _onCampusSelected(Map<String, dynamic> campus) {
    Navigator.pushNamed(context, '/educationalLevel', arguments: campus);
  }

  @override
  Widget build(BuildContext context) {
    final userData = AuthService.currentUserData;
    print('userData from Campus Screen: $userData');
    final refId = userData?['refId'];

    // Imprimir refId en consola para depuración
    print('refId for usuario: $refId');

    return Scaffold(
      backgroundColor: const Color(0xFFF0F0E3),
      appBar: AppBar(
        title: const Text('Selecciona tu campus'),
        backgroundColor: const Color(0xFF53A09D),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        // Pass the campuses future to the FutureBuilder
        future: _campusesFuture,
        builder: (context, snapshot) {
          // Show a loading indicator while data is being fetched
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Show an error message if the future completes with an error
          if (snapshot.hasError) {
            return const Center(child: Text('Ocurrió un error cargando los campuses.'));
          }

          // Retrieve data or use an empty list if data is null
          final campuses = snapshot.data ?? [];

          // Show a message if no campuses are assigned
          if (campuses.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No tienes ningún campus asignado.\nPor favor contacta al administrador.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
              ),
            );
          }

          // Build the list of campus cards
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // Informative message for the teacher
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
                          'En esta pantalla puedes seleccionar la sede (campus) a la cual perteneces. '
                              'Esto te permitirá acceder al proceso de registro de asistencia para tus estudiantes. '
                              'Haz clic sobre una de las sedes para continuar.',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // List of campus cards
              ...campuses.map((campus) {
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.location_city, color: Color(0xFF53A09D)),
                    title: Text(campus['name']),
                    subtitle: Text(campus['description']),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _onCampusSelected(campus),
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }
}
