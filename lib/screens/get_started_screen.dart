import 'package:flutter/material.dart';
import 'student_home_screen.dart';
import 'staff_home_screen.dart';

class GetStartedScreen extends StatelessWidget {
  final String role;

  const GetStartedScreen({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [

          // 🔷 TOP GRADIENT (SAME AS LOGIN & SIGNUP)
          Container(
            height: height * 0.55,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0D1B6F),
                  Color(0xFF880E4F),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          SingleChildScrollView(
            child: SizedBox(
              height: height,
              child: Column(
                children: [

                  const SizedBox(height: 90),

                  // 🖼️ IMAGE ICON (REPLACE PATH IF NEEDED)
                  Image.asset(
                    'assets/images/logo.png',
                    height: 180,
                  ),

                  const SizedBox(height: 4),

                  // 👋 WELCOME TEXT
                  const Text(
                    'Welcome to COURSEMATE!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontFamily: 'Lexend Deca',
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Plan. Learn. Succeed',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 50),

                  // ⚪ WHITE CURVED CONTAINER (LIKE LOGIN)
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(28, 40, 28, 30),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(45),
                          topRight: Radius.circular(45),
                        ),
                      ),
                      child: Column(
                        children: [

                          const Text(
                            'Stay organised with easy access to exam schdules and course content. Your academic hub starts here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 20),

                          Text(
                            role == 'Student'
                                ? 'Access your syllabus, timetable and profile easily.'
                                : 'Manage syllabus, timetable and admin tools efficiently.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                            ),
                          ),

                          const SizedBox(height: 40),

                          // 🔵 GET STARTED BUTTON (SMOOTH NAVIGATION)
                          Material(
                            color: const Color(0xFF0D1B6F),
                            borderRadius: BorderRadius.circular(18),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              splashColor: Colors.white24,
                              onTap: () {
                                if (role == 'Student') {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const StudentHomeScreen(),
                                    ),
                                  );
                                } else {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const StaffHomeScreen(),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  'Get Started',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),

                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}