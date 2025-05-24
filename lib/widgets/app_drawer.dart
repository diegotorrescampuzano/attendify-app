import 'package:flutter/material.dart';

/// Drawer widget with a profile and logout option.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Drawer header con imagen del logo y fondo en el color principal corporativo
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF53a09d), // Color principal corporativo
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Puedes cambiar este AssetImage por tu logo
                /*CircleAvatar(
                  radius: 32,
                  backgroundImage: AssetImage('assets/images/logo.png'), // Reemplaza por tu imagen
                  backgroundColor: Colors.transparent,
                ),*/
                const SizedBox(height: 12),
                const Text(
                  'Attendify',
                  style: TextStyle(
                    color: Color(0xFFF0F0E3), // Color secundario corporativo claro
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Sistema de asistencia para profesores',
                  style: TextStyle(
                    color: Color(0xFFF0F0E3), // Mismo color claro para subtitulo
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Profile menu option
          ListTile(
            leading: const Icon(Icons.person, color: Color(0xFF53a09d)), // Color principal corporativo para iconos
            title: const Text('Mi Perfil'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              // Navigate to ProfileScreen route
              Navigator.pushNamed(context, '/profile');
            },
          ),

          // Logout menu option
          ListTile(
            leading: const Icon(Icons.logout, color: Color(0xFF53a09d)), // Color principal corporativo para iconos
            title: const Text('Cerrar sesión'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              // Clear navigation stack and go to home or login screen
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
          ),
        ],
      ),
    );
  }
}
