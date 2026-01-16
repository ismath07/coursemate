import 'package:flutter/material.dart';
import 'timetable_home_screen.dart';
import 'student_profile_screen.dart';
import 'select_course_student_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  final int initialIndex;
  const StudentHomeScreen({super.key, this.initialIndex = 0});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  late int _currentIndex;

  // 🔹 Pages for BottomNavigationBar
  final List<Widget> _pages = const [
    StudentSyllabusHome(),
    TimetableHomeScreen(),
    StudentProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      // 🔹 Gradient AppBar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _currentIndex == 0
              ? 'Select Degree Level'
              : _currentIndex == 1
                  ? 'Timetable'
                  : 'Profile',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        toolbarHeight: 90,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0D1B6F),
                Color(0xFF880E4F),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(30),
            ),
          ),
        ),
        // make back button and icons white on top gradient
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // 🔹 BODY SWITCHES BASED ON TAB
      body: _pages[_currentIndex],

      // 🔹 BOTTOM NAVIGATION
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            label: 'Syllabus',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule_outlined),
            label: 'Timetable',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

//
// 🔹 SYLLABUS HOME CONTENT (UG / PG / DIPLOMA)
//
class StudentSyllabusHome extends StatelessWidget {
  const StudentSyllabusHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, Student',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 30),

          _card(
            context,
            icon: Icons.school_outlined,
            title: 'Undergraduate',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SelectCourseStudentScreen(degreeLevel: 'Undergraduate')),
              );
            },
          ),

          const SizedBox(height: 16),

          _card(
            context,
            icon: Icons.workspace_premium_outlined,
            title: 'Postgraduate',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SelectCourseStudentScreen(degreeLevel: 'Postgraduate')),
              );
            },
          ),

          const SizedBox(height: 16),

          _card(
            context,
            icon: Icons.assignment_outlined,
            title: 'Diploma',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SelectCourseStudentScreen(degreeLevel: 'Diploma')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
        child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}
