// Importaciones
import 'dart:convert'; // Para decodificar base64
import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import '../screens/campus_screen.dart';
import '../screens/report_screen.dart';
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
                fontSize: 20,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            );
          }
          return const SizedBox.shrink();
        }();

        return Container(
          color: const Color(0xFFF0F0E3),
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(  // <-- Wrap with scroll view
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/attendify_logo.png',
                      height: 160,
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      '¡Bienvenido a Attendify!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF53A09D),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Con esta aplicación podrás registrar y gestionar la asistencia de tus estudiantes de forma rápida, segura y eficiente.',
                      style: TextStyle(fontSize: 18, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        child: Column(
                          children: [
                            logoWidget,
                            const SizedBox(height: 12),
                            nameWidget,
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: 220,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF53A09D),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 6,
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, '/attendance');
                        },
                        child: const Text(
                          'Tomar Asistencia',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
      ReportScreen(),          // Pantalla de reportes
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
