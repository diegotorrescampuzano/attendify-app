import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Schedule navigation after the first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
    });
  }

  // Checks if a user is already signed in
  void _checkAuth() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      print('[SplashScreen] User is signed in: ${user.uid}');
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      print('[SplashScreen] No user signed in, showing login.');
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
