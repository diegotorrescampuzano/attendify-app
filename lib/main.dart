// Importing Flutter's core UI package
import 'package:flutter/material.dart';

// Import Firebase core so we can initialize it
import 'package:firebase_core/firebase_core.dart';

// Import the generated Firebase options for our specific platform (Android/iOS)
import 'firebase_options.dart';

// Import the LoginScreen widget from our screens folder
import 'screens/login_screen.dart';

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
      title: 'Attendify', // Name of the app shown in Android/iOS task switcher
      theme: ThemeData(
        primarySwatch: Colors.blue, // Set a blue color theme
      ),
      home: const LoginScreen(), // This is the first screen the user sees
      routes: {
        // Define app routes for navigation
        '/home': (_) => const Placeholder(), // Replace this with your real HomeScreen widget
      },
    );
  }
}
