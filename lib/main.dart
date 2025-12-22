import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const CourseMateApp());
}

class CourseMateApp extends StatelessWidget {
  const CourseMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}
