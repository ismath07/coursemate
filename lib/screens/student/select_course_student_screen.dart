import 'package:flutter/material.dart';
import '../staff/select_semester_screen.dart';
import 'student_home_screen.dart';

class SelectCourseStudentScreen extends StatelessWidget {
  final String degreeLevel; // 'Undergraduate' | 'Postgraduate' | 'Diploma'
  const SelectCourseStudentScreen({super.key, required this.degreeLevel});

  static const Map<String, List<String>> _coursesByLevel = {
    'Undergraduate': [
      'BA TAM', 'BA ENG', 'BSC MAT', 'BSC BIO', 'BSC CS', 'BSC IT', 'BCA', 'BSC AIML', 'BSC DS', 'BCOM', 'BCOM CA', 'BCOM BM', 'BBA', 'BSC N&D'
    ],
    'Postgraduate': [
      'MA TAM', 'MA ENG', 'MSC MAT', 'MSC BIO', 'MSC CS', 'MSC IT', 'MCOM', 'MBA', 'BFSN'
    ],
    'Diploma': ['FT', 'DMLT'],
  };

  @override
  Widget build(BuildContext context) {
    final courses = _coursesByLevel[degreeLevel] ?? [];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Select Course', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 90,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0D1B6F), Color(0xFF880E4F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Courses',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: courses.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final title = courses[index];
                  return InkWell(
                    onTap: () {
                      if (degreeLevel == 'Diploma') {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Selected $title')));
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => SelectSemesterScreen(courseTitle: title, degreeLevel: degreeLevel)),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0,4))],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.book_outlined, size: 28, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 16),
                          Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))),
                          Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).colorScheme.primary),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        onTap: (index) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => StudentHomeScreen(initialIndex: index)),
          );
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), label: 'Syllabus'),
          BottomNavigationBarItem(icon: Icon(Icons.schedule_outlined), label: 'Timetable'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
