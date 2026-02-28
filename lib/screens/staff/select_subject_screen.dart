import 'package:flutter/material.dart';
import 'staff_home_screen.dart';
import 'view_syllabus_screen.dart';
import '../../services/firestore_service.dart';

class StaffSelectSubjectScreen extends StatelessWidget {
  final String courseTitle;
  final int semester;
  final String? degreeLevel;
  final String? courseId;

  const StaffSelectSubjectScreen({
    super.key,
    required this.courseTitle,
    required this.semester,
    this.degreeLevel,
    this.courseId,
  });

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();
    final String degreeLevelId = () {
      if (degreeLevel == 'Undergraduate') return 'UG';
      if (degreeLevel == 'Postgraduate') return 'PG';
      return 'DIP';
    }();
    final String semesterId = semester.toString();

    return StreamBuilder<bool>(
      stream: firestoreService.editAccessStream(),
      builder: (context, accessSnapshot) {
        final hasAccess = accessSnapshot.data ?? false;

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
                  stream: firestoreService.getCourses(degreeLevelId),
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
                    final effectiveCourseIdFuture = courseId.isNotEmpty
                        ? Future.value(courseId)
                        : Future<String?>(() async {
                            final courses = await firestoreService.getCourses(degreeLevelId).first;
                            final course = courses.firstWhere(
                              (c) => (c['displayName'] ?? '') == courseTitle,
                              orElse: () => {},
                            );
                            return course['id'];
                          });
                    return FutureBuilder<String?>(
                      future: effectiveCourseIdFuture,
                      builder: (context, idSnap) {
                        if (idSnap.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final effectiveCourseId = idSnap.data;
                        if (effectiveCourseId == null || effectiveCourseId.isEmpty) {
                          return const Center(child: Text('No data available'));
                        }
                        return StreamBuilder<List<Map<String, String>>>(
                          stream: firestoreService.getSubjects(degreeLevelId, effectiveCourseId, semesterId),
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
                                    final data = await firestoreService.getSyllabus(degreeLevelId, effectiveCourseId, semesterId, subjectCode);
                                    final titleFromFirestore = data?['subjectTitle']?.toString() ?? subjectName;
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => StaffViewSyllabusScreen(
                                          subjectTitle: titleFromFirestore,
                                          subjectCode: subjectCode,
                                          degreeLevelId: degreeLevelId,
                                          courseId: effectiveCourseId,
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
                                        if (hasAccess)
                                          PopupMenuButton<String>(
                                            icon: Icon(Icons.more_vert, color: Theme.of(context).colorScheme.primary),
                                            onSelected: (value) async {
                                              if (value == 'edit') {
                                                await _showEditSubjectDialog(
                                                  context,
                                                  firestoreService,
                                                  degreeLevelId,
                                                  effectiveCourseId,
                                                  semesterId,
                                                  subjectCode,
                                                  subjectName,
                                                );
                                              } else if (value == 'delete') {
                                                await _showDeleteSubjectDialog(
                                                  context,
                                                  firestoreService,
                                                  degreeLevelId,
                                                  effectiveCourseId,
                                                  semesterId,
                                                  subjectCode,
                                                );
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
                        );
                      },
                    );
                  },
                ),
              ),
              floatingActionButton: hasAccess
                  ? FloatingActionButton(
                      onPressed: () => _showAddSubjectDialog(context, firestoreService, degreeLevelId, courseId ?? '', semesterId),
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

  Future<void> _showAddSubjectDialog(
    BuildContext context,
    FirestoreService firestoreService,
    String degreeLevelId,
    String courseId,
    String semesterId,
  ) async {
    final subjectCodeController = TextEditingController();
    final displayNameController = TextEditingController();
    final subjectTitleController = TextEditingController();
    final unit1Controller = TextEditingController();
    final unit2Controller = TextEditingController();
    final unit3Controller = TextEditingController();
    final unit4Controller = TextEditingController();
    final unit5Controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Subject'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: subjectCodeController,
                decoration: const InputDecoration(labelText: 'Subject Code'),
              ),
              TextField(
                controller: displayNameController,
                decoration: const InputDecoration(labelText: 'Display Name'),
              ),
              TextField(
                controller: subjectTitleController,
                decoration: const InputDecoration(labelText: 'Subject Title'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: unit1Controller,
                decoration: const InputDecoration(labelText: 'Unit 1'),
                maxLines: 2,
              ),
              TextField(
                controller: unit2Controller,
                decoration: const InputDecoration(labelText: 'Unit 2'),
                maxLines: 2,
              ),
              TextField(
                controller: unit3Controller,
                decoration: const InputDecoration(labelText: 'Unit 3'),
                maxLines: 2,
              ),
              TextField(
                controller: unit4Controller,
                decoration: const InputDecoration(labelText: 'Unit 4'),
                maxLines: 2,
              ),
              TextField(
                controller: unit5Controller,
                decoration: const InputDecoration(labelText: 'Unit 5'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (subjectCodeController.text.isEmpty || displayNameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill required fields')),
                );
                return;
              }

              final units = <String, dynamic>{};
              if (unit1Controller.text.isNotEmpty) units['Unit 1'] = unit1Controller.text;
              if (unit2Controller.text.isNotEmpty) units['Unit 2'] = unit2Controller.text;
              if (unit3Controller.text.isNotEmpty) units['Unit 3'] = unit3Controller.text;
              if (unit4Controller.text.isNotEmpty) units['Unit 4'] = unit4Controller.text;
              if (unit5Controller.text.isNotEmpty) units['Unit 5'] = unit5Controller.text;

              await firestoreService.addSubject(
                degreeLevelId: degreeLevelId,
                courseId: courseId,
                semesterId: semesterId,
                subjectCode: subjectCodeController.text,
                displayName: displayNameController.text,
                subjectTitle: subjectTitleController.text,
                units: units,
              );

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Subject added successfully')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditSubjectDialog(
    BuildContext context,
    FirestoreService firestoreService,
    String degreeLevelId,
    String courseId,
    String semesterId,
    String oldSubjectCode,
    String currentDisplayName,
  ) async {
    // Fetch current subject data
    final data = await firestoreService.getSyllabus(degreeLevelId, courseId, semesterId, oldSubjectCode);
    
    final subjectCodeController = TextEditingController(text: oldSubjectCode);
    final displayNameController = TextEditingController(text: currentDisplayName);
    final subjectTitleController = TextEditingController(text: data?['subjectTitle']?.toString() ?? '');

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Subject'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: displayNameController,
                decoration: const InputDecoration(labelText: 'Subject Name'),
              ),
              TextField(
                controller: subjectCodeController,
                decoration: const InputDecoration(labelText: 'Subject Code'),
              ),
              TextField(
                controller: subjectTitleController,
                decoration: const InputDecoration(labelText: 'Subject Title'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (displayNameController.text.isEmpty || subjectCodeController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              await firestoreService.updateSubjectInfo(
                degreeLevelId: degreeLevelId,
                courseId: courseId,
                semesterId: semesterId,
                oldSubjectCode: oldSubjectCode,
                newSubjectCode: subjectCodeController.text,
                displayName: displayNameController.text,
                subjectTitle: subjectTitleController.text,
              );

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Subject updated successfully')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteSubjectDialog(
    BuildContext context,
    FirestoreService firestoreService,
    String degreeLevelId,
    String courseId,
    String semesterId,
    String subjectCode,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subject'),
        content: const Text('Are you sure you want to delete this subject? This action cannot be undone.'),
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
      await firestoreService.deleteSubject(
        degreeLevelId: degreeLevelId,
        courseId: courseId,
        semesterId: semesterId,
        subjectCode: subjectCode,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subject deleted successfully')),
        );
      }
    }
  }
}

