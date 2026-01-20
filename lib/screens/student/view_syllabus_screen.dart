import 'package:flutter/material.dart';
import 'student_home_screen.dart';
import '../../services/firestore_service.dart';

class StudentViewSyllabusScreen extends StatelessWidget {
  final String subjectTitle;
  final String subjectCode;

  const StudentViewSyllabusScreen({
    super.key,
    required this.subjectTitle,
    required this.subjectCode,
  });

  @override
  Widget build(BuildContext context) {
    final FirestoreService _firestoreService = FirestoreService();
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
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _firestoreService.getSyllabusBySubjectCode(subjectCode),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Failed to load syllabus.'));
            }
            final data = snapshot.data;
            if (data == null) {
              return const Center(child: Text('No data available'));
            }
            final units = (data['units'] as Map<String, String>? ?? {});
            return SingleChildScrollView(
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
                  if (units.isEmpty)
                    const Center(child: Text('No data available'))
                  else
                    for (final entry in units.entries) ...[
                      Text(
                        entry.key,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        entry.value,
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 14),
                    ],
                ],
              ),
            );
          },
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

