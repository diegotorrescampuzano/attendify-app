// Importing Flutter's core UI package
import 'package:flutter/material.dart';

// Import Firebase core so we can initialize it
import 'package:firebase_core/firebase_core.dart';

// Import flutter_localizations for localization support
import 'package:flutter_localizations/flutter_localizations.dart';

// Import the generated Firebase options for our specific platform (Android/iOS)
import 'firebase_options.dart';

// Import screens
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/campus_screen.dart';
import 'screens/report_screen.dart';
import 'screens/credits_screen.dart';
import 'screens/educational_level_screen.dart';
import 'screens/grade_screen.dart';
import 'screens/homeroom_screen.dart';
import 'screens/subject_screen.dart';
import 'screens/attendance_screen.dart';

// Import the new teacher summary report screen
import 'screens/reports/teacher_summary_screen.dart';

// Import the new student summary report screen
import 'screens/reports/student_summary_screen.dart';

// Import the new homeroom summary report screen
import 'screens/reports/homeroom_summary_screen.dart';

// Import the new pattern summary report screen
import 'screens/reports/pattern_summary_screen.dart';

// Import the new outstanding register report screen
import 'screens/reports/outstanding_register_screen.dart';

// Import the new schedule summary report screen
import 'screens/reports/schedule_summary_screen.dart';

// Import the new outstanding current week report screen
import 'screens/reports/outstanding_currentweek_screen.dart';

// Import the splash screen
import 'screens/splash_screen.dart';

// Import the license screen
import 'screens/license_screen.dart';

// Import the new off the clock summary report screen
import 'screens/reports/offtheclock_summary_screen.dart';

// Import the new student schedule report screen
import 'screens/reports/student_schedule_screen.dart';

// Import the new teacher schedule report screen
import 'screens/reports/teacher_schedule_screen.dart';

// Import the outstanding attendance report screen
import 'screens/reports/outstanding_attendance_screen.dart';

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
      // Add localization delegates and supported locales here
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English
        Locale('es', ''), // Spanish
        // Add other locales here if needed
      ],
      initialRoute: '/splash',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/splash':
            return MaterialPageRoute(builder: (_) => const SplashScreen());
          case '/':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/home':
            return MaterialPageRoute(builder: (_) => const HomeScreen());
          case '/profile':
            return MaterialPageRoute(builder: (_) => ProfileScreen());
          case '/license':
            return MaterialPageRoute(builder: (_) => LicenseScreen());
          case '/campus':
            return MaterialPageRoute(builder: (_) => CampusScreen());
          case '/report':
            return MaterialPageRoute(builder: (_) => const ReportScreen());
          case '/teacherSummary':
            return MaterialPageRoute(builder: (_) => const TeacherSummaryScreen());
          case '/studentSummary':
            return MaterialPageRoute(builder: (_) => const StudentSummaryScreen());
          case '/homeroomSummary':
            return MaterialPageRoute(builder: (_) => const HomeroomSummaryScreen());
          case '/patternSummary':
            return MaterialPageRoute(builder: (_) => const PatternSummaryScreen());
          case '/outstandingRegister':
            return MaterialPageRoute(builder: (_) => OutstandingRegisterScreen());
          case '/outstandingCurrentWeek':
            return MaterialPageRoute(builder: (_) => const OutstandingCurrentWeekScreen());
          case '/scheduleSummary':
            return MaterialPageRoute(builder: (_) => ScheduleSummaryScreen());
          case '/offtheclockSummary':
            return MaterialPageRoute(builder: (_) => OffTheClockSummaryScreen());
          case '/studentSchedule':
            return MaterialPageRoute(builder: (_) => StudentScheduleScreen());
          case '/teacherSchedule':
            return MaterialPageRoute(builder: (_) => TeacherScheduleScreen());
          case '/outstandingAttendance':
            return MaterialPageRoute(builder: (_) => OutstandingAttendanceScreen());
          case '/credits':
            return MaterialPageRoute(builder: (_) => CreditsScreen());
          case '/educationalLevel':
            final campus = settings.arguments as Map<String, dynamic>;
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
            final campus = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => HomeroomScreen(campus: campus),
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
          case '/attendance':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => AttendanceScreen(
                campus: args['campus'],
                educationalLevel: args['educationalLevel'],
                grade: args['grade'],
                homeroom: args['homeroom'],
                subject: args['subject'],
                selectedDate: args['selectedDate'],
                selectedTime: args['selectedTime'],
                slot: args['slot'],
              ),
            );
          default:
            return null;
        }
      },
    );
  }
}
