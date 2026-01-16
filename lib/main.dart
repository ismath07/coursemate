import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/auth/splash_screen.dart';
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
          home: const SplashScreen(),
      
        );
      },
    );
  }
}
