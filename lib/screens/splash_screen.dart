import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'login_screen.dart';
import 'student_home_screen.dart';
import 'staff_home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<double> _scale;

  bool _navigated = false; // 🔐 prevent double navigation

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scale = Tween<double>(begin: 0.85, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    // ⏱️ Force auth check (never stuck)
    Timer(const Duration(seconds: 5), _checkAuth);
  }

  Future<void> _checkAuth() async {
    if (_navigated || !mounted) return;
    _navigated = true;

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        _goTo(const LoginScreen());
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 4));

      if (!doc.exists) {
        _goTo(const LoginScreen());
        return;
      }

      final role = doc.data()?['role'];

      if (role == "student") {
        _goTo(const StudentHomeScreen());
      } else if (role == "staff") {
        _goTo(const StaffHomeScreen());
      } else {
        _goTo(const LoginScreen());
      }
    } catch (e) {
      // ❌ Any Firebase / network error → go login
      _goTo(const LoginScreen());
    }
  }

  void _goTo(Widget page) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF3A0CA3),
              Color(0xFF7209B7),
              Color(0xFFF72585),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 180,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'COURSEMATE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
