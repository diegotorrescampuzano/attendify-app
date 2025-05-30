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

import 'screens/educational_level_screen.dart';

import 'screens/grade_screen.dart';

import 'screens/homeroom_screen.dart';

import 'screens/subject_screen.dart';

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
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/home':
            return MaterialPageRoute(builder: (_) => const HomeScreen());
          case '/profile':
            return MaterialPageRoute(builder: (_) => ProfileScreen());
          case '/campus':
            return MaterialPageRoute(builder: (_) => CampusScreen());
          case '/reports':
            return MaterialPageRoute(builder: (_) => ReportsScreen());
          case '/credits':
            return MaterialPageRoute(builder: (_) => CreditsScreen());
          case '/educationalLevel':
          // Extract the arguments passed during navigation.
          // We expect a Map<String, dynamic> containing the campus data.
            final campus = settings.arguments as Map<String, dynamic>;

            // Return a MaterialPageRoute to display the EducationalLevelScreen.
            // The screen is built using the extracted 'campus' data.
            return MaterialPageRoute(
              builder: (_) => EducationalLevelScreen(campus: campus),
            );
          case '/grade':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => GradeScreen(
                campus: args['campus'],
                educationalLevel: args['educationalLevel'],
              ),
            );
          case '/homeroom':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => HomeroomScreen(
                campus: args['campus'],
                educationalLevel: args['educationalLevel'],
                grade: args['grade'],
              ),
            );
          case '/subject':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => SubjectScreen(
                campus: args['campus'],
                educationalLevel: args['educationalLevel'],
                grade: args['grade'],
                homeroom: args['homeroom'],
              ),
            );
          default:
            return null;
        }
      },
    );
  }
}
