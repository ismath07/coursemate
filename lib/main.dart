import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/auth/login_screen.dart';
import 'screens/staff/staff_home_screen.dart';
import 'screens/student/student_home_screen.dart';
import 'services/firestore_service.dart';
import 'theme_notifier.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Initialize Firebase
  await Firebase.initializeApp();

  // 🎨 Load saved theme
  await ThemeManager.loadTheme();

  runApp(const CourseMateApp());
}

class CourseMateApp extends StatelessWidget {
  const CourseMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: const Color(0xFF0D1B6F),
            colorScheme: const ColorScheme.light(primary: Color(0xFF0D1B6F)),
            scaffoldBackgroundColor: Colors.white,
            cardColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            iconTheme: const IconThemeData(color: Color(0xFF0D1B6F)),
            textTheme:
                const TextTheme(bodyMedium: TextStyle(color: Colors.black87)),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color(0xFF90CAF9),
            colorScheme: const ColorScheme.dark(primary: Color(0xFF90CAF9)),
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardColor: const Color(0xFF1E1E1E),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            iconTheme: const IconThemeData(color: Color(0xFF90CAF9)),
            textTheme:
                const TextTheme(bodyMedium: TextStyle(color: Colors.white70)),
          ),
          home: const AuthWrapper(),
      
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // User is NOT logged in → show LoginScreen
        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginScreen();
        }

        // User IS logged in → check role and navigate accordingly
        return FutureBuilder<String?>(
          future: FirestoreService().getUserRole(),
          builder: (context, roleSnapshot) {
            // Show loading while fetching role
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final role = roleSnapshot.data;

            // Navigate based on role
            if (role == 'staff') {
              return const StaffHomeScreen();
            } else if (role == 'student') {
              return const StudentHomeScreen();
            } else {
              // Role not found → show LoginScreen
              return const LoginScreen();
            }
          },
        );
      },
    );
  }
}
