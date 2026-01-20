import 'package:flutter/material.dart';
import 'student_home_screen.dart';
import 'view_syllabus_screen.dart';
import '../../services/firestore_service.dart';

class SelectSubjectScreen extends StatelessWidget {
  final String courseTitle;
  final int semester;
  final String? degreeLevel;

  const SelectSubjectScreen({
    super.key,
    required this.courseTitle,
    required this.semester,
    this.degreeLevel,
  });

  @override
  Widget build(BuildContext context) {
    final FirestoreService _firestoreService = FirestoreService();
    final String degreeLevelId = () {
      if (degreeLevel == 'Undergraduate') return 'UG';
      if (degreeLevel == 'Postgraduate') return 'PG';
      return 'DIP';
    }();
    final String semesterId = semester.toString();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Select Subject', style: TextStyle(color: Colors.white)),
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
        child: StreamBuilder<List<Map<String, String>>>(
          stream: _firestoreService.getCourses(degreeLevelId),
          builder: (context, courseSnapshot) {
            if (courseSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (courseSnapshot.hasError) {
              return const Center(child: Text('Failed to load data.'));
            }
            final courses = courseSnapshot.data ?? [];
            final course = courses.firstWhere(
              (c) => (c['displayName'] ?? '') == courseTitle,
              orElse: () => {},
            );
            final courseId = course['id'];
            if (courseId == null || courseId.isEmpty) {
              return const Center(child: Text('No data available'));
            }
            return StreamBuilder<List<Map<String, String>>>(
              stream: _firestoreService.getSubjects(degreeLevelId, courseId, semesterId),
              builder: (context, subjSnapshot) {
                if (subjSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (subjSnapshot.hasError) {
                  return const Center(child: Text('Failed to load subjects.'));
                }
                final subjects = subjSnapshot.data ?? [];
                if (subjects.isEmpty) {
                  return const Center(child: Text('No data available'));
                }
                return ListView.separated(
                  itemCount: subjects.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final subjectName = subjects[index]['displayName'] ?? '';
                    final subjectCode = subjects[index]['subjectCode'] ?? '';
                    return InkWell(
                      onTap: () async {
                        final data = await _firestoreService.getSyllabus(degreeLevelId, courseId, semesterId, subjectCode);
                        final titleFromFirestore = data?['subjectTitle']?.toString() ?? subjectName;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StudentViewSyllabusScreen(
                              subjectTitle: titleFromFirestore,
                              subjectCode: subjectCode,
                              degreeLevelId: degreeLevelId,
                              courseId: courseId,
                              semesterId: semesterId,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.menu_book_outlined, size: 28, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    subjectName,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    subjectCode,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).colorScheme.primary),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
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

