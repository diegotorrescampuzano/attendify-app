// campus_screen.dart
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/campus_service.dart';

class CampusScreen extends StatefulWidget {
  const CampusScreen({super.key});

  @override
  State<CampusScreen> createState() => _CampusScreenState();
}

class _CampusScreenState extends State<CampusScreen> {
  String? _refId;
  late Future<List<Map<String, dynamic>>> _campusesFuture;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserAndCampuses();
  }

  /// Loads user profile from Firestore to get refId,
  /// then loads campuses for that refId.
  Future<void> _loadUserAndCampuses() async {
    print('[CampusScreen] Loading user profile to get refId...');
    final userData = await FirestoreService.getUserProfile();
    setState(() {
      _refId = userData?['refId'];
      _isLoading = false;
    });
    if (_refId != null) {
      print('[CampusScreen] Found refId: $_refId. Loading campuses...');
      setState(() {
        _campusesFuture = CampusService.getCampusesAndLecturesForTeacher(_refId!);
      });
    } else {
      print('[CampusScreen] No refId found for user.');
      setState(() {
        _campusesFuture = Future.value([]);
      });
    }
  }

  void _onCampusSelected(Map<String, dynamic> campus) {
    Navigator.pushNamed(
      context,
      '/homeroom',
      arguments: campus,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0E3),
      appBar: AppBar(
        title: const Text('Selecciona tu campus'),
        backgroundColor: const Color(0xFF53A09D),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<Map<String, dynamic>>>(
        future: _campusesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print('[CampusScreen] Error loading campuses: ${snapshot.error}');
            return const Center(child: Text('Ocurrió un error cargando los campuses.'));
          }
          final campuses = snapshot.data ?? [];
          if (campuses.isEmpty) {
            print('[CampusScreen] No campuses found for refId $_refId.');
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
          return ListView(
            padding: const EdgeInsets.all(12),
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
              ...campuses.map((campus) => Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.location_city, color: Color(0xFF53A09D)),
                  title: Text(campus['name']),
                  subtitle: Text(campus['description']),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _onCampusSelected(campus),
                ),
              )),
            ],
          );
        },
      ),
    );
  }
}
