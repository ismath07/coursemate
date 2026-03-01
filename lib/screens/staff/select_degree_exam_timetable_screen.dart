import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import 'select_department_exam_timetable_screen.dart';

class SelectDegreeExamTimetableScreen extends StatelessWidget {
  const SelectDegreeExamTimetableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return StreamBuilder<bool>(
      stream: firestoreService.editAccessStream(),
      builder: (context, accessSnapshot) {
        final hasAccess = accessSnapshot.data ?? false;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,

          appBar: AppBar(
            title: const Text(
              'Exam Timetable',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
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
                  colors: [Color(0xFF0D1B6F), Color(0xFF880E4F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
              ),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
          ),

          body: Padding(
            padding: const EdgeInsets.all(20),

            child: StreamBuilder<List<Map<String, String>>>(
              stream: firestoreService.getExamDegrees(),

              builder: (context, snapshot) {

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final degrees = snapshot.data ?? [];

                if (degrees.isEmpty) {
                  return const Center(
                    child: Text('No degrees found'),
                  );
                }

                return ListView.builder(
                  itemCount: degrees.length,

                  itemBuilder: (context, index) {

                    final deg = degrees[index];
                    final id = deg['id'] ?? '';
                    final name = deg['displayName'] ?? id;

                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                SelectDepartmentExamTimetableScreen(
                              degreeId: id,
                              degreeName: name,
                            ),
                          ),
                        );
                      },

                      borderRadius: BorderRadius.circular(16),

                      child: Container(
                        padding: const EdgeInsets.all(18),
                        margin:
                            const EdgeInsets.only(bottom: 16),

                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).cardColor,

                          borderRadius:
                              BorderRadius.circular(16),

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

                            Icon(
                              Icons.school_outlined,
                              size: 28,
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary,
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Text(
                                name,
                                style:
                                    const TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                            ),

                            if (hasAccess)
                              PopupMenuButton<String>(
                                icon: Icon(
                                  Icons.more_vert,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                onSelected: (value) async {
                                  if (value == 'edit') {
                                    await _showEditDialog(context, id, name);
                                  } else if (value == 'delete') {
                                    await _showDeleteDialog(context, id, name);
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
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary,
                              ),

                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          floatingActionButton: hasAccess
              ? FloatingActionButton(
                  onPressed: () => _showAddDialog(context),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: const Icon(Icons.add, color: Colors.white),
                )
              : null,
        );
      },
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final nameController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Degree'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Degree Name (e.g., UG, PG)',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter degree name')),
                );
                return;
              }

              try {
                await FirebaseFirestore.instance
                    .collection('exam_timetables')
                    .add({
                  'displayName': name,
                  'createdAt': FieldValue.serverTimestamp(),
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Degree added successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context, String degreeId, String currentName) async {
    final nameController = TextEditingController(text: currentName);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Degree'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Degree Name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter degree name')),
                );
                return;
              }

              try {
                await FirebaseFirestore.instance
                    .collection('exam_timetables')
                    .doc(degreeId)
                    .update({
                  'displayName': name,
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Degree updated successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteDialog(BuildContext context, String degreeId, String degreeName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Degree'),
        content: Text('Are you sure you want to delete "$degreeName"? This will delete all departments, years, and exams under it.'),
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
      try {
        await FirebaseFirestore.instance
            .collection('exam_timetables')
            .doc(degreeId)
            .delete();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Degree deleted successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }
}