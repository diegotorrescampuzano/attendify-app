import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/license_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAuthAndLicense());
  }

  Future<void> _checkAuthAndLicense() async {
    final user = FirebaseAuth.instance.currentUser;
    final licenseValid = await LicenseService.isLicenseValid();

    if (user != null && licenseValid) {
      // Check if license is about to expire and show warning if needed
      if (await LicenseService.isLicenseAboutToExpire()) {
        _showLicenseWarning(context);
      }
      print('[SplashScreen] User and license are valid. Navigating to home.');
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // If license is invalid, log out and show error
      if (user != null) {
        print('[SplashScreen] License is invalid. Logging out user.');
        await AuthService.logout();
      }
      _showLicenseError(context);
      print('[SplashScreen] No valid user or license. Navigating to login.');
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  void _showLicenseError(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Licencia no válida'),
        content: const Text('La licencia de uso ha expirado o está inactiva. Contacte al administrador.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  void _showLicenseWarning(BuildContext context) async {
    final license = await LicenseService.getLicense();
    final expiryDate = license?['expiryDate']?.toDate();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text('Aviso de licencia'),
        content: Text('La licencia expirará el ${expiryDate?.toString().split(' ')[0]}. Por favor, contacte al administrador.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
