import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';

// Screens
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
import 'screens/reports/teacher_summary_screen.dart';
import 'screens/reports/student_summary_screen.dart';
import 'screens/reports/homeroom_summary_screen.dart';
import 'screens/reports/pattern_summary_screen.dart';
import 'screens/reports/outstanding_register_screen.dart';
import 'screens/reports/schedule_summary_screen.dart';
import 'screens/reports/outstanding_currentweek_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/license_screen.dart';
import 'screens/reports/offtheclock_summary_screen.dart';
import 'screens/reports/student_schedule_screen.dart';
import 'screens/reports/teacher_schedule_screen.dart';
import 'screens/reports/outstanding_attendance_screen.dart';
import 'screens/notification_screen.dart';
import 'services/notification_service.dart';

// Import the new report category screens
import 'screens/reports/teacher_report_screen.dart';
import 'screens/reports/student_report_screen.dart';
import 'screens/reports/homeroom_report_screen.dart';
import 'screens/reports/general_report_screen.dart';

// Background message handler (must be top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling a background message: ${message.messageId}');
  debugPrint('Message data: ${message.data}');
  debugPrint('Message notification: ${message.notification?.title}');
  // Show the notification using NotificationService
  final notificationService = NotificationService();
  if (message.notification != null) {
    await notificationService.showLocalNotification(
      title: message.notification?.title ?? 'Recordatorio',
      body: message.notification?.body ?? 'Mensaje de recordatorio',
    );
  }
}

void main() async {
  // Initialize Flutter bindings and Firebase
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('Initializing Firebase...');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Firebase initialized successfully.');

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  debugPrint('Background message handler registered.');

  // Start the app
  debugPrint('Starting Attendify app...');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('Building MyApp widget...');
    return MaterialApp(
      title: 'Attendify -',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // Localization setup
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('es', ''),
      ],
      initialRoute: '/splash',
      // Route generator
      onGenerateRoute: (settings) {
        debugPrint('Navigating to route: ${settings.name}');
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
        // Add new report category routes
          case '/teacher-reports':
            debugPrint('Loading Teacher Reports screen...');
            return MaterialPageRoute(builder: (_) => const TeacherReportScreen());
          case '/student-reports':
            debugPrint('Loading Student Reports screen...');
            return MaterialPageRoute(builder: (_) => const StudentReportScreen());
          case '/homeroom-reports':
            debugPrint('Loading Homeroom Reports screen...');
            return MaterialPageRoute(builder: (_) => const HomeroomReportScreen());
          case '/general-reports':
            debugPrint('Loading General Reports screen...');
            return MaterialPageRoute(builder: (_) => const GeneralReportScreen());
        // Keep all existing report detail routes
          case '/teacherSummary':
            debugPrint('Loading Teacher Summary screen...');
            return MaterialPageRoute(builder: (_) => const TeacherSummaryScreen());
          case '/studentSummary':
            debugPrint('Loading Student Summary screen...');
            return MaterialPageRoute(builder: (_) => const StudentSummaryScreen());
          case '/homeroomSummary':
            debugPrint('Loading Homeroom Summary screen...');
            return MaterialPageRoute(builder: (_) => const HomeroomSummaryScreen());
          case '/patternSummary':
            debugPrint('Loading Pattern Summary screen...');
            return MaterialPageRoute(builder: (_) => const PatternSummaryScreen());
          case '/outstandingRegister':
            debugPrint('Loading Outstanding Register screen...');
            return MaterialPageRoute(builder: (_) => OutstandingRegisterScreen());
          case '/outstandingCurrentWeek':
            debugPrint('Loading Outstanding Current Week screen...');
            return MaterialPageRoute(builder: (_) => const OutstandingCurrentWeekScreen());
          case '/scheduleSummary':
            debugPrint('Loading Schedule Summary screen...');
            return MaterialPageRoute(builder: (_) => ScheduleSummaryScreen());
          case '/offtheclockSummary':
            debugPrint('Loading Off The Clock Summary screen...');
            return MaterialPageRoute(builder: (_) => OffTheClockSummaryScreen());
          case '/studentSchedule':
            debugPrint('Loading Student Schedule screen...');
            return MaterialPageRoute(builder: (_) => StudentScheduleScreen());
          case '/teacherSchedule':
            debugPrint('Loading Teacher Schedule screen...');
            return MaterialPageRoute(builder: (_) => TeacherScheduleScreen());
          case '/outstandingAttendance':
            debugPrint('Loading Outstanding Attendance screen...');
            return MaterialPageRoute(builder: (_) => OutstandingAttendanceScreen());
          case '/credits':
            debugPrint('Loading Credits screen...');
            return MaterialPageRoute(builder: (_) => CreditsScreen());
          case '/notifications':
            debugPrint('Loading Notifications screen...');
            return MaterialPageRoute(builder: (_) => const NotificationScreen());
          case '/educationalLevel':
            final campus = settings.arguments as Map<String, dynamic>;
            debugPrint('Loading Educational Level screen for campus: ${campus['name']}');
            return MaterialPageRoute(
              builder: (_) => EducationalLevelScreen(campus: campus),
            );
          case '/grade':
            final args = settings.arguments as Map<String, dynamic>;
            debugPrint('Loading Grade screen for educational level: ${args['educationalLevel']}');
            return MaterialPageRoute(
              builder: (_) => GradeScreen(
                campus: args['campus'],
                educationalLevel: args['educationalLevel'],
              ),
            );
          case '/homeroom':
            final campus = settings.arguments as Map<String, dynamic>;
            debugPrint('Loading Homeroom screen for campus: ${campus['name']}');
            return MaterialPageRoute(
              builder: (_) => HomeroomScreen(campus: campus),
            );
          case '/subject':
            final args = settings.arguments as Map<String, dynamic>;
            debugPrint('Loading Subject screen for homeroom: ${args['homeroom']}');
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
            debugPrint('Loading Attendance screen for subject: ${args['subject']} at ${args['selectedDate']}');
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
            debugPrint('Route not found: ${settings.name}');
            return null;
        }
      },
    );
  }
}
