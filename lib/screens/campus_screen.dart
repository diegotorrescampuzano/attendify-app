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
        ? CampusService.getCampusesForTeacher(_refId!)
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
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: campuses.length,
            itemBuilder: (context, index) {
              final campus = campuses[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.location_city, color: Color(0xFF53A09D)), // Icon for campus
                  title: Text(campus['name']), // Campus name
                  subtitle: Text(campus['description']), // Campus description
                  trailing: const Icon(Icons.chevron_right), // Chevron icon to indicate navigation
                  onTap: () => _onCampusSelected(campus), // Navigate on tap
                ),
              );
            },
          );
        },
      ),
    );
  }
}
