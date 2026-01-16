import 'package:flutter/material.dart';
import 'student_home_screen.dart';

class StudentViewSyllabusScreen extends StatelessWidget {
  final String subjectTitle;
  final String subjectCode;

  const StudentViewSyllabusScreen({
    super.key,
    required this.subjectTitle,
    required this.subjectCode,
  });

  List<Map<String, String>> get _units => const [
        {
          'title': 'Unit 1: Foundations',
          'content': 'Introduction, core concepts, and fundamental principles.',
        },
        {
          'title': 'Unit 2: Applications',
          'content': 'Applying concepts to practical scenarios and case studies.',
        },
        {
          'title': 'Unit 3: Analysis',
          'content': 'Deep dive, comparative study, and analytical methods.',
        },
        {
          'title': 'Unit 4: Advanced Topics',
          'content': 'Emerging trends, advanced techniques, and integrations.',
        },
        {
          'title': 'Unit 5: Review & Assessment',
          'content': 'Revision, problem solving, and assessment preparation.',
        },
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('View Your Syllabus', style: TextStyle(color: Colors.white)),
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subjectTitle,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              if (subjectCode.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  subjectCode,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              for (final unit in _units) ...[
                Text(
                  unit['title'] ?? '',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  unit['content'] ?? '',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 14),
              ],
            ],
          ),
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

