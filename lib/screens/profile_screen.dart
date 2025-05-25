import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../widgets/app_drawer.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // Fetch user profile data from Firestore
  Future<void> _loadUserProfile() async {
    final data = await FirestoreService.getUserProfile();
    setState(() {
      _userData = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFF0F0E3);
    const primaryColor = Color(0xFF53A09D);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        backgroundColor: primaryColor,
      ),
      body: Container(
        color: backgroundColor,
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _userData == null
            ? const Center(child: Text('No se pudieron cargar los datos del usuario.'))
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Profile Icon Placeholder
            const CircleAvatar(
              radius: 60,
              backgroundColor: primaryColor,
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 24),

            // User's Name
            Text(
              _userData!['name'] ?? 'Nombre no disponible',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // User's Email
            Text(
              _userData!['email'] ?? 'Correo no disponible',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // User's Role (if available)
            if (_userData!['role'] != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryColor),
                ),
                child: Text(
                  _userData!['role'],
                  style: const TextStyle(color: primaryColor),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
