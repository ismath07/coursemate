import 'package:flutter/material.dart';
import 'staff_home_screen.dart';
import 'select_subject_screen.dart';
import '../../services/firestore_service.dart';

class SelectSemesterScreen extends StatelessWidget {
  final String courseTitle;
  final String? degreeLevel; // optional: 'Undergraduate' | 'Postgraduate' | 'Diploma'
  final String? courseId; // Firestore document ID for course
  const SelectSemesterScreen({super.key, required this.courseTitle, this.degreeLevel, this.courseId});

  @override
  Widget build(BuildContext context) {
    final FirestoreService _firestoreService = FirestoreService();
    final String degreeLevelId = () {
      if (degreeLevel == 'Undergraduate') return 'UG';
      if (degreeLevel == 'Postgraduate') return 'PG';
      return 'DIP';
    }();
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Select Semester', style: TextStyle(color: Colors.white)),
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
              'Select semester for $courseTitle',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: (courseId != null && courseId!.isNotEmpty)
                  ? StreamBuilder<List<Map<String, String>>>(
                      stream: _firestoreService.getSemesters(degreeLevelId, courseId!),
                      builder: (context, semSnapshot) {
                        if (semSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (semSnapshot.hasError) {
                          return const Center(child: Text('Failed to load semesters.'));
                        }
                        final semesters = semSnapshot.data ?? [];
                        if (semesters.isEmpty) {
                          return const Center(child: Text('No data available'));
                        }
                        return ListView.separated(
                          itemCount: semesters.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final title = semesters[index]['displayName'] ?? '';
                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => StaffSelectSubjectScreen(
                                      courseTitle: courseTitle,
                                      courseId: courseId,
                                      semester: index + 1,
                                      degreeLevel: degreeLevel,
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
                                    BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.school_outlined, size: 28, color: Theme.of(context).colorScheme.primary),
                                    const SizedBox(width: 16),
                                    Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))),
                                    Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).colorScheme.primary),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    )
                  : StreamBuilder<List<Map<String, String>>>(
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
                        final resolvedCourseId = course['id'];
                        if (resolvedCourseId == null || resolvedCourseId.isEmpty) {
                          return const Center(child: Text('No data available'));
                        }
                        return StreamBuilder<List<Map<String, String>>>(
                          stream: _firestoreService.getSemesters(degreeLevelId, resolvedCourseId),
                          builder: (context, semSnapshot) {
                            if (semSnapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            if (semSnapshot.hasError) {
                              return const Center(child: Text('Failed to load semesters.'));
                            }
                            final semesters = semSnapshot.data ?? [];
                            if (semesters.isEmpty) {
                              return const Center(child: Text('No data available'));
                            }
                            return ListView.separated(
                              itemCount: semesters.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final title = semesters[index]['displayName'] ?? '';
                                return InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => StaffSelectSubjectScreen(
                                          courseTitle: courseTitle,
                                          courseId: resolvedCourseId,
                                          semester: index + 1,
                                          degreeLevel: degreeLevel,
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
                                        BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.school_outlined, size: 28, color: Theme.of(context).colorScheme.primary),
                                        const SizedBox(width: 16),
                                        Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))),
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
            MaterialPageRoute(builder: (_) => StaffHomeScreen(initialIndex: index)),
          );
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), label: 'Syllabus'),
          BottomNavigationBarItem(icon: Icon(Icons.schedule_outlined), label: 'Timetable'),
          BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings_outlined), label: 'Admin'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
