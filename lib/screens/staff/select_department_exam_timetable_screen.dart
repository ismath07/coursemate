import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import 'select_year_exam_timetable_screen.dart';

class SelectDepartmentExamTimetableScreen extends StatelessWidget {

  final String degreeId;
  final String degreeName;

  const SelectDepartmentExamTimetableScreen({
    super.key,
    required this.degreeId,
    required this.degreeName,
  });

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
            title: Text(
              degreeName,
              style: const TextStyle(color: Colors.white),
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

            iconTheme:
                const IconThemeData(color: Colors.white),
          ),

          body: Padding(
            padding: const EdgeInsets.all(20),

            child: StreamBuilder<List<Map<String, String>>>(

              stream: firestoreService
                  .getExamDepartments(degreeId),

              builder: (context, snapshot) {

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {

                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {

                  return const Center(
                    child: Text(
                      'Failed to load departments',
                    ),
                  );
                }

                final departments =
                    snapshot.data ?? [];

                if (departments.isEmpty) {

                  return const Center(
                    child: Text('No departments found'),
                  );
                }

                return ListView.builder(

                  itemCount: departments.length,

                  itemBuilder: (context, index) {

                    final dept =
                        departments[index];

                    final id = dept['id'] ?? '';
                    final name =
                        dept['displayName'] ?? id;

                    return InkWell(

                      onTap: () {

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                SelectYearExamTimetableScreen(
                              degreeId: degreeId,
                              degreeName: degreeName,
                              departmentId: id,
                              departmentName: name,
                            ),
                          ),
                        );
                      },

                      borderRadius:
                          BorderRadius.circular(16),

                      child: Container(

                        padding:
                            const EdgeInsets.all(18),

                        margin:
                            const EdgeInsets.only(
                                bottom: 16),

                        decoration: BoxDecoration(

                          color: Theme.of(context)
                              .cardColor,

                          borderRadius:
                              BorderRadius.circular(
                                  16),

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
                              Icons.menu_book_outlined,
                              size: 28,
                              color:
                                  Theme.of(context)
                                      .colorScheme
                                      .primary,
                            ),

                            const SizedBox(
                                width: 12),

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
                                color:
                                    Theme.of(context)
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
        title: const Text('Add Department'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Department Name',
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
                  const SnackBar(content: Text('Please enter department name')),
                );
                return;
              }

              try {
                await FirebaseFirestore.instance
                    .collection('exam_timetables')
                    .doc(degreeId)
                    .collection('departments')
                    .add({
                  'displayName': name,
                  'createdAt': FieldValue.serverTimestamp(),
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Department added successfully')),
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

  Future<void> _showEditDialog(BuildContext context, String departmentId, String currentName) async {
    final nameController = TextEditingController(text: currentName);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Department'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Department Name',
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
                  const SnackBar(content: Text('Please enter department name')),
                );
                return;
              }

              try {
                await FirebaseFirestore.instance
                    .collection('exam_timetables')
                    .doc(degreeId)
                    .collection('departments')
                    .doc(departmentId)
                    .update({
                  'displayName': name,
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Department updated successfully')),
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

  Future<void> _showDeleteDialog(BuildContext context, String departmentId, String departmentName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Department'),
        content: Text('Are you sure you want to delete "$departmentName"? This will delete all years and exams under it.'),
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
            .collection('departments')
            .doc(departmentId)
            .delete();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Department deleted successfully')),
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