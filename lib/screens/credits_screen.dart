import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  // Corporate colors
  static const Color backgroundColor = Color(0xFFF0F0E3);
  static const Color primaryColor = Color(0xFF53A09D);

  // Developer Info
  final String developerName = 'Diego Torres';
  final String email = 'diegotorres50@gmail.com';
  final String linkedInUrl = 'https://www.linkedin.com/in/diegotorrescampuzano/';
  final String description =
      'Soy ingeniero de software con experiencia en diseño, desarrollo backend y arquitectura de aplicaciones, apasionado por crear soluciones innovadoras como Attendify.';

  // Helper to open URLs
  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Créditos'),
        backgroundColor: primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 60,
                backgroundImage: AssetImage('assets/images/developer_photo.png'), // Agrega la imagen
              ),
              const SizedBox(height: 20),
              Text(
                developerName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                email,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _launchURL(linkedInUrl),
                child: Text(
                  'LinkedIn',
                  style: TextStyle(
                    fontSize: 16,
                    color: primaryColor,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
