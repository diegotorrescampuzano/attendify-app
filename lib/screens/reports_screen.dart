import 'package:flutter/material.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0E3),
      appBar: AppBar(
        title: const Text('Reportes'),
        backgroundColor: const Color(0xFF53A09D),
      ),
      body: const Center(
        child: Text(
          'Aquí puedes buscar y ver reportes',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
