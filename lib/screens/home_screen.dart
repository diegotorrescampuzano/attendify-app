import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart'; // Import the drawer widget
import '../screens/campus_screen.dart'; // Import CampusScreen
import '../screens/reports_screen.dart'; // Import ReportsScreen
import '../screens/profile_screen.dart'; // Import ProfileScreen
import '../widgets/bottom_navbar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    // Página de bienvenida estilizada
    Container(
      color: const Color(0xFFF0F0E3), // Fondo claro y suave
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/attendify_logo.png',
            height: 180,
          ),
          const SizedBox(height: 24),
          Text(
            '¡Bienvenido a Attendify!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF53A09D),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Con esta aplicación podrás registrar y gestionar la asistencia de tus estudiantes de forma rápida, segura y eficiente.',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),

    // Reemplazamos por el CampusScreen
    CampusScreen(),

    // Reemplazamos por el ReportsScreen
    ReportsScreen(),

    // Reemplazamos por el ProfileScreen
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendify'),
        backgroundColor: const Color(0xFF53A09D),
      ),
      drawer: const AppDrawer(), // <-- Include the drawer here
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
