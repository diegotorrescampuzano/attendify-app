import 'dart:convert';
import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import '../screens/campus_screen.dart';
import '../screens/report_screen.dart';
import '../screens/profile_screen.dart';
import '../widgets/bottom_navbar.dart';
import '../services/home_service.dart';

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
    _schoolFuture = HomeService.getSchoolData();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildWelcomePage() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _schoolFuture,
      builder: (context, snapshot) {
        // School logo logic
        final logoWidget = () {
          if (snapshot.hasData && snapshot.data!['logo'].isNotEmpty) {
            final bytes = base64Decode(snapshot.data!['logo']);
            return Image.memory(bytes, height: 80);
          }
          return const SizedBox.shrink();
        }();

        // School name logic
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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/edupilot360_logo.png',
                      height: 160,
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      '¡Bienvenido a EduPilot360!',
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
      _buildWelcomePage(),
      CampusScreen(),
      ReportScreen(),
      ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('EduPilot360'),
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
