import 'dart:async';
import 'package:flutter/material.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;

  late Animation<Offset> _logoSlide;
  late Animation<Offset> _textSlide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // Logo: LEFT ➝ CENTER
    _logoSlide = Tween<Offset>(
      begin: const Offset(-1.5, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // Text: RIGHT ➝ CENTER
    _textSlide = Tween<Offset>(
      begin: const Offset(1.5, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // Fade (flash) effect
    _fade = Tween<double>(begin: 0, end: 1).animate(_controller);

    _controller.forward();

    // Navigate after splash
    Timer(const Duration(seconds: 8), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    });
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
                  Color(0xFF0D1B6F), // Dark Blue
                  Color(0xFF880E4F), // Dark Pink
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        ),
        child: FadeTransition(
          opacity: _fade,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              // LOGO ANIMATION (LEFT ➝ CENTER)
              SlideTransition(
                position: _logoSlide,
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 210,
                ),
              ),

              const SizedBox(height: 6),

              // TEXT ANIMATION (RIGHT ➝ CENTER)
              SlideTransition(
                position: _textSlide,
                child: const Text(
                  'COURSEMATE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}