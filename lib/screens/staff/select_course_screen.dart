import 'package:flutter/material.dart';
import 'staff_home_screen.dart';
import 'select_semester_screen.dart';
import '../../services/firestore_service.dart';

class SelectCourseScreen extends StatelessWidget {
  const SelectCourseScreen({super.key});

  static const String _degreeLevelId = 'UG';

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();
    
    return StreamBuilder<bool>(
      stream: firestoreService.editAccessStream(),
      builder: (context, accessSnapshot) {
        final hasAccess = accessSnapshot.data ?? false;

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
              child: StreamBuilder<List<Map<String, String>>>(
                stream: firestoreService.getCourses(_degreeLevelId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('Failed to load courses.'));
                  }
                  final courses = snapshot.data ?? [];
                  if (courses.isEmpty) {
                    return const Center(child: Text('No data available'));
                  }
                  return ListView.separated(
                    itemCount: courses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final title = courses[index]['displayName'] ?? '';
                      final courseId = courses[index]['id'] ?? '';
                      
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SelectSemesterScreen(
                                courseTitle: title,
                                courseId: courseId,
                                degreeLevel: 'Undergraduate',
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
                              Icon(Icons.book_outlined, size: 28, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                              ),
                              if (hasAccess)
                                PopupMenuButton<String>(
                                  icon: Icon(Icons.more_vert, color: Theme.of(context).colorScheme.primary),
                                  onSelected: (value) async {
                                    if (value == 'edit') {
                                      await _showEditCourseDialog(context, firestoreService, courseId, title);
                                    } else if (value == 'delete') {
                                      await _showDeleteCourseDialog(context, firestoreService, courseId, title);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, size: 20),
                                          SizedBox(width: 8),
                                          Text('Edit'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, size: 20, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Delete', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).colorScheme.primary),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: hasAccess
          ? FloatingActionButton(
              onPressed: () => _showAddCourseDialog(context, firestoreService),
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
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
      },
    );
  }

  Future<void> _showAddCourseDialog(BuildContext context, FirestoreService firestoreService) async {
    final nameController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Course'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Course Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter course name')),
                );
                return;
              }

              await firestoreService.addCourse(
                degreeLevelId: _degreeLevelId,
                displayName: nameController.text,
              );

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Course added successfully')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditCourseDialog(
    BuildContext context,
    FirestoreService firestoreService,
    String courseId,
    String currentName,
  ) async {
    final nameController = TextEditingController(text: currentName);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Course'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Course Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter course name')),
                );
                return;
              }

              await firestoreService.updateCourse(
                degreeLevelId: _degreeLevelId,
                courseId: courseId,
                displayName: nameController.text,
              );

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Course updated successfully')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteCourseDialog(
    BuildContext context,
    FirestoreService firestoreService,
    String courseId,
    String courseName,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Course'),
        content: Text('Are you sure you want to delete "$courseName"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await firestoreService.deleteCourse(
        degreeLevelId: _degreeLevelId,
        courseId: courseId,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Course deleted successfully')),
        );
      }
    }
  }
}
