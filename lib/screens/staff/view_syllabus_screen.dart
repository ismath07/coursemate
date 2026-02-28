import 'package:flutter/material.dart';
import 'staff_home_screen.dart';
import '../../services/firestore_service.dart';

class StaffViewSyllabusScreen extends StatelessWidget {
  final String subjectTitle;
  final String subjectCode;
  final String degreeLevelId;
  final String courseId;
  final String semesterId;

  const StaffViewSyllabusScreen({
    super.key,
    required this.subjectTitle,
    required this.subjectCode,
    required this.degreeLevelId,
    required this.courseId,
    required this.semesterId,
  });

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
                actions: hasAccess
                    ? [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white),
                          onPressed: () => _showEditDialog(context, firestoreService),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.white),
                          onPressed: () => _showDeleteDialog(context, firestoreService),
                        ),
                      ]
                    : null,
              ),
              body: Padding(
                padding: const EdgeInsets.all(20),
                child: StreamBuilder<Map<String, dynamic>?>(
                  stream: _getSyllabusStream(firestoreService),
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
                    final units = Map<String, dynamic>.from(data['units'] ?? {});
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
                              Container(
                                padding: const EdgeInsets.all(16),
                                margin: const EdgeInsets.only(bottom: 14),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            entry.key,
                                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                        if (hasAccess)
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: Icon(Icons.edit, size: 20, color: Theme.of(context).colorScheme.primary),
                                                onPressed: () => _showEditUnitDialog(
                                                  context,
                                                  firestoreService,
                                                  entry.key,
                                                  entry.value.toString(),
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                                onPressed: () => _showDeleteUnitDialog(
                                                  context,
                                                  firestoreService,
                                                  entry.key,
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      entry.value.toString(),
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                        ],
                      ),
                    );
                  },
                ),
              ),
              floatingActionButton: hasAccess
                  ? FloatingActionButton(
                      onPressed: () => _showAddUnitDialog(context, firestoreService),
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

  Stream<Map<String, dynamic>?> _getSyllabusStream(FirestoreService firestoreService) {
    return Stream.fromFuture(
      firestoreService.getSyllabus(degreeLevelId, courseId, semesterId, subjectCode),
    ).asyncExpand((data) {
      // Convert to a stream that updates periodically
      return Stream.periodic(const Duration(seconds: 1), (_) => data).asyncMap((_) async {
        return await firestoreService.getSyllabus(degreeLevelId, courseId, semesterId, subjectCode);
      });
    });
  }

  Future<void> _showEditDialog(BuildContext context, FirestoreService firestoreService) async {
    final data = await firestoreService.getSyllabus(degreeLevelId, courseId, semesterId, subjectCode);
    if (data == null) return;

    final units = Map<String, dynamic>.from(data['units'] ?? {});
    final titleController = TextEditingController(text: subjectTitle);
    final unitControllers = <String, TextEditingController>{};

    for (final entry in units.entries) {
      unitControllers[entry.key] = TextEditingController(text: entry.value.toString());
    }

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Syllabus'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Subject Title'),
              ),
              const SizedBox(height: 16),
              ...unitControllers.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: entry.value,
                    decoration: InputDecoration(labelText: entry.key),
                    maxLines: 3,
                  ),
                );
              }).toList(),
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
              final updatedUnits = <String, dynamic>{};
              for (final entry in unitControllers.entries) {
                updatedUnits[entry.key] = entry.value.text;
              }

              await firestoreService.updateSubject(
                degreeLevelId: degreeLevelId,
                courseId: courseId,
                semesterId: semesterId,
                subjectCode: subjectCode,
                subjectTitle: titleController.text,
                units: updatedUnits,
              );

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Syllabus updated successfully')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditUnitDialog(
    BuildContext context,
    FirestoreService firestoreService,
    String unitKey,
    String currentContent,
  ) async {
    final unitTitleController = TextEditingController(text: unitKey);
    final unitContentController = TextEditingController(text: currentContent);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Unit'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: unitTitleController,
                decoration: const InputDecoration(labelText: 'Unit Title'),
                enabled: false, // Don't allow changing unit key for now
              ),
              const SizedBox(height: 12),
              TextField(
                controller: unitContentController,
                decoration: const InputDecoration(labelText: 'Unit Content'),
                maxLines: 5,
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
              await firestoreService.updateUnit(
                degreeLevelId: degreeLevelId,
                courseId: courseId,
                semesterId: semesterId,
                subjectCode: subjectCode,
                unitKey: unitKey,
                unitContent: unitContentController.text,
              );

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Unit updated successfully')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddUnitDialog(BuildContext context, FirestoreService firestoreService) async {
    final unitTitleController = TextEditingController();
    final unitContentController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Unit'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: unitTitleController,
                decoration: const InputDecoration(labelText: 'Unit Title (e.g., Unit 1)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: unitContentController,
                decoration: const InputDecoration(labelText: 'Unit Content'),
                maxLines: 5,
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
              if (unitTitleController.text.isEmpty || unitContentController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              await firestoreService.addUnit(
                degreeLevelId: degreeLevelId,
                courseId: courseId,
                semesterId: semesterId,
                subjectCode: subjectCode,
                unitTitle: unitTitleController.text,
                unitContent: unitContentController.text,
              );

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Unit added successfully')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteUnitDialog(
    BuildContext context,
    FirestoreService firestoreService,
    String unitKey,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Unit'),
        content: Text('Are you sure you want to delete "$unitKey"? This action cannot be undone.'),
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
      await firestoreService.deleteUnit(
        degreeLevelId: degreeLevelId,
        courseId: courseId,
        semesterId: semesterId,
        subjectCode: subjectCode,
        unitKey: unitKey,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unit deleted successfully')),
        );
      }
    }
  }

  Future<void> _showDeleteDialog(BuildContext context, FirestoreService firestoreService) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subject'),
        content: const Text('Are you sure you want to delete this subject?'),
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
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subject deleted successfully')),
        );
      }
    }
  }
}
