// Importaciones
import 'dart:convert'; // Para decodificar base64
import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import '../screens/campus_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/profile_screen.dart';
import '../widgets/bottom_navbar.dart';
import '../services/home_service.dart'; // Importamos el nuevo servicio

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  late Future<Map<String, dynamic>> _schoolFuture;

  @override
  void initState() {
    super.initState();
    _schoolFuture = HomeService.getSchoolData(); // Inicializa la carga del logo
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Crea la página de bienvenida con logo y nombre del colegio
  Widget _buildWelcomePage() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _schoolFuture,
      builder: (context, snapshot) {
        final logoWidget = () {
          if (snapshot.hasData && snapshot.data!['logo'].isNotEmpty) {
            final bytes = base64Decode(snapshot.data!['logo']);
            return Image.memory(bytes, height: 80);
          }
          return const SizedBox.shrink();
        }();

        final nameWidget = () {
          if (snapshot.hasData) {
            return Text(
              snapshot.data!['name'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            );
          }
          return const SizedBox.shrink();
        }();

        return Container(
          color: const Color(0xFFF0F0E3),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/attendify_logo.png',
                height: 180,
              ),
              const SizedBox(height: 24),
              const Text(
                '¡Bienvenido a Attendify!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF53A09D),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Con esta aplicación podrás registrar y gestionar la asistencia de tus estudiantes de forma rápida, segura y eficiente.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Mostrar logo y nombre del colegio al final
              logoWidget,
              const SizedBox(height: 8),
              nameWidget,
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      _buildWelcomePage(),      // Página de bienvenida mejorada
      CampusScreen(),           // Pantalla de campus
      ReportsScreen(),          // Pantalla de reportes
      ProfileScreen(),          // Perfil
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendify'),
        backgroundColor: const Color(0xFF53A09D),
      ),
      drawer: const AppDrawer(),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
