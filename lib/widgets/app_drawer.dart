import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

/// Drawer widget with a profile and logout option.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: FutureBuilder<Map<String, dynamic>?>(
        future: FirestoreService.getUserProfile(),
        builder: (context, snapshot) {
          final user = snapshot.data;
          final name = user?['name'] ?? 'Usuario';
          final email = user?['email'] ?? '';

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  color: Color(0xFF53a09d),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      name,
                      style: const TextStyle(
                        color: Color(0xFFF0F0E3),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: const TextStyle(
                        color: Color(0xFFF0F0E3),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // Profile menu option
              ListTile(
                leading: const Icon(Icons.person, color: Color(0xFF53a09d)),
                title: const Text('Mi Perfil'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/profile');
                },
              ),

              // Credits menu option
              ListTile(
                leading: const Icon(Icons.info, color: Color(0xFF53a09d)),
                title: const Text('Créditos'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/credits');
                  },
              ),

              // Logout menu option
              ListTile(
                leading: const Icon(Icons.logout, color: Color(0xFF53a09d)),
                title: const Text('Cerrar sesión'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
