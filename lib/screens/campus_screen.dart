import 'package:flutter/material.dart';

class CampusScreen extends StatelessWidget {
  const CampusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0E3),
      appBar: AppBar(
        title: const Text('Asistencias'),
        backgroundColor: const Color(0xFF53A09D),
      ),
      body: const Center(
        child: Text(
          'Aquí puedes gestionar las asistencias',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
