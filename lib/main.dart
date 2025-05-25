// Importing Flutter's core UI package
import 'package:flutter/material.dart';

// Import Firebase core so we can initialize it
import 'package:firebase_core/firebase_core.dart';

// Import the generated Firebase options for our specific platform (Android/iOS)
import 'firebase_options.dart';

// Import the LoginScreen widget from our screens folder
import 'screens/login_screen.dart';

import 'screens/home_screen.dart';

import 'screens/profile_screen.dart';

import 'screens/campus_screen.dart';

import 'screens/reports_screen.dart';

import 'screens/credits_screen.dart';

// The entry point of the application — must be `main()` in Dart
void main() async {
  // Ensures that Flutter is fully initialized before we use platform channels or Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with the configuration defined in firebase_options.dart
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Run the root of the app
  runApp(const MyApp());
}

// This widget represents the whole app (root-level widget)
class MyApp extends StatelessWidget {
  const MyApp({super.key}); // Constructor with optional key parameter

  // This method describes how to display the widget in the UI
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendify -',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/', // Start with LoginScreen
      routes: {
        '/': (_) => const LoginScreen(),       // Default route (Login)
        '/home': (_) => const HomeScreen(),    // Home after login
        '/profile': (_) => ProfileScreen(),
        '/campus': (_) => CampusScreen(),
        '/reports': (_) => ReportsScreen(),
        '/credits': (_) => CreditsScreen(),
      },
    );
  }
}
