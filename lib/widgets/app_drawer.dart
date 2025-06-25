import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
// Add these imports for direct navigation
import '../screens/report_screen.dart';
import '../screens/campus_screen.dart';

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

              // Mis Horarios
              ListTile(
                leading: const Icon(Icons.schedule, color: Color(0xFF53a09d)),
                title: const Text('Mis Horarios'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/teacherSchedule');
                  print('[AppDrawer] Navigated to Mis Horarios');
                },
              ),

              // Mis Reportes
              ListTile(
                leading: const Icon(Icons.assignment, color: Color(0xFF53a09d)),
                title: const Text('Mis Reportes'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ReportScreen()),
                  );
                  print('[AppDrawer] Navigated to Mis Reportes');
                },
              ),

              // Registrar Asistencia
              ListTile(
                leading: const Icon(Icons.check_circle, color: Color(0xFF53a09d)),
                title: const Text('Registrar Asistencia'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CampusScreen()),
                  );
                  print('[AppDrawer] Navigated to Registrar Asistencia');
                },
              ),

              // Notificaciones
              ListTile(
                leading: const Icon(Icons.notifications, color: Color(0xFF53a09d)),
                title: const Text('Notificaciones'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/notifications');
                  print('[AppDrawer] Navigated to Notificaciones');
                },
              ),

              // Profile menu option
              ListTile(
                leading: const Icon(Icons.person, color: Color(0xFF53a09d)),
                title: const Text('Mi Perfil'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/profile');
                  print('[AppDrawer] Navigated to Mi Perfil');
                },
              ),

              // Credits menu option
              ListTile(
                leading: const Icon(Icons.info, color: Color(0xFF53a09d)),
                title: const Text('Créditos'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/credits');
                  print('[AppDrawer] Navigated to Créditos');
                },
              ),

              // License menu option
              ListTile(
                leading: const Icon(Icons.verified_user, color: Color(0xFF53a09d)),
                title: const Text('Licencia'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/license');
                  print('[AppDrawer] Navigated to Licencia');
                },
              ),

              // Logout menu option
              ListTile(
                leading: const Icon(Icons.logout, color: Color(0xFF53a09d)),
                title: const Text('Cerrar sesión'),
                onTap: () async {
                  Navigator.pop(context);
                  print('[AppDrawer] Logging out user...');
                  await AuthService.logout();
                  print('[AppDrawer] User logged out. Navigating to login screen.');
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
