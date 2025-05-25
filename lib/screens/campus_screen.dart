import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class CampusScreen extends StatelessWidget {
  const CampusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userData = AuthService.currentUserData;
    print('userData from Campus Screen: $userData');
    final refId = userData?['refId'];

    // Imprimir refId en consola para depuración
    print('refId for usuario: $refId');

    return Scaffold(
      backgroundColor: const Color(0xFFF0F0E3),
      appBar: AppBar(
        title: const Text('Asistencias'),
        backgroundColor: const Color(0xFF53A09D),
      ),
      body: Center(
        child: Text(
          refId != null
              ? 'Tu código de referencia es: $refId'
              : 'No se encontró tu código de referencia.',
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
