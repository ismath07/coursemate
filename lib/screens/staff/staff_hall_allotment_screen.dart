import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import 'staff_home_screen.dart';

class StaffHallAllotmentScreen extends StatelessWidget {
  const StaffHallAllotmentScreen({super.key});

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
              'Staff Hall Allotment',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            toolbarHeight: 80,
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
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('staff_hall_allotments')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Failed to load hall allotments.'),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Center(
                    child: Text('No staff hall allotments found.'),
                  );
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      columnSpacing: 20,
                      columns: [
                        const DataColumn(label: Text('S.No')),
                        const DataColumn(label: Text('Staff Name')),
                        const DataColumn(label: Text('Hall No')),
                        const DataColumn(label: Text('Students')),
                        const DataColumn(label: Text('Total Students')),
                        if (hasAccess)
                          const DataColumn(label: Text('Actions')),
                      ],
                      rows: List.generate(
                        docs.length,
                        (index) {
                          final doc = docs[index];
                          final data = doc.data() as Map<String, dynamic>;

                          final staffName = data['staffName']?.toString() ?? '';
                          final hallNo = data['hallNo']?.toString() ?? '';
                          final totalStudents = data['totalStudents'] ?? 0;

                          // Safe conversion for noOfStudents
                          final noOfStudentsData = data['noOfStudents'];
                          List<String> studentsList = [];
                          if (noOfStudentsData is List) {
                            studentsList = noOfStudentsData.map((e) => e.toString()).toList();
                          }

                          final studentsText = studentsList.isEmpty ? '-' : studentsList.join(', ');

                          return DataRow(
                            cells: [
                              DataCell(Text('${index + 1}')),
                              DataCell(Text(staffName)),
                              DataCell(Text(hallNo)),
                              DataCell(
                                SizedBox(
                                  width: 200,
                                  child: Text(
                                    studentsText,
                                    softWrap: true,
                                  ),
                                ),
                              ),
                              DataCell(Text(totalStudents.toString())),
                              if (hasAccess)
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 18),
                                        onPressed: () => _showEditDialog(context, doc),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                        onPressed: () => _showDeleteDialog(context, doc.id),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
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
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: 2,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            onTap: (index) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => StaffHomeScreen(initialIndex: index),
                ),
              );
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.menu_book_outlined),
                label: 'Syllabus',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.schedule_outlined),
                label: 'Timetable',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.admin_panel_settings_outlined),
                label: 'Admin',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final staffNameController = TextEditingController();
    final hallNoController = TextEditingController();
    final studentsController = TextEditingController();
    final totalStudentsController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Staff Hall Allotment'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: staffNameController,
                decoration: const InputDecoration(
                  labelText: 'Staff Name',
                  hintText: 'Enter staff name',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: hallNoController,
                decoration: const InputDecoration(
                  labelText: 'Hall No',
                  hintText: 'e.g., A1',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: studentsController,
                decoration: const InputDecoration(
                  labelText: 'Students List (comma separated)',
                  hintText: 'Msc IT - 12, Msc CS - 6',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: totalStudentsController,
                decoration: const InputDecoration(
                  labelText: 'Total Students',
                  hintText: 'e.g., 18',
                ),
                keyboardType: TextInputType.number,
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
              if (staffNameController.text.isEmpty ||
                  hallNoController.text.isEmpty ||
                  studentsController.text.isEmpty ||
                  totalStudentsController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              try {
                final studentsList = studentsController.text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();

                final totalStudents = int.tryParse(totalStudentsController.text.trim()) ?? 0;

                await FirebaseFirestore.instance
                    .collection('staff_hall_allotments')
                    .add({
                  'staffName': staffNameController.text.trim(),
                  'hallNo': hallNoController.text.trim(),
                  'noOfStudents': studentsList,
                  'totalStudents': totalStudents,
                  'createdAt': FieldValue.serverTimestamp(),
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Staff hall allotment added successfully')),
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

  Future<void> _showEditDialog(BuildContext context, DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;

    final staffNameController = TextEditingController(text: data['staffName']?.toString() ?? '');
    final hallNoController = TextEditingController(text: data['hallNo']?.toString() ?? '');
    final totalStudentsController = TextEditingController(text: data['totalStudents']?.toString() ?? '');

    // Safe conversion for noOfStudents
    final noOfStudentsData = data['noOfStudents'];
    List<String> studentsList = [];
    if (noOfStudentsData is List) {
      studentsList = noOfStudentsData.map((e) => e.toString()).toList();
    }
    final studentsController = TextEditingController(text: studentsList.join(', '));

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Staff Hall Allotment'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: staffNameController,
                decoration: const InputDecoration(
                  labelText: 'Staff Name',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: hallNoController,
                decoration: const InputDecoration(
                  labelText: 'Hall No',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: studentsController,
                decoration: const InputDecoration(
                  labelText: 'Students List (comma separated)',
                  hintText: 'Msc IT - 12, Msc CS - 6',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: totalStudentsController,
                decoration: const InputDecoration(
                  labelText: 'Total Students',
                ),
                keyboardType: TextInputType.number,
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
              if (staffNameController.text.isEmpty ||
                  hallNoController.text.isEmpty ||
                  studentsController.text.isEmpty ||
                  totalStudentsController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              try {
                final studentsList = studentsController.text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();

                final totalStudents = int.tryParse(totalStudentsController.text.trim()) ?? 0;

                await FirebaseFirestore.instance
                    .collection('staff_hall_allotments')
                    .doc(doc.id)
                    .update({
                  'staffName': staffNameController.text.trim(),
                  'hallNo': hallNoController.text.trim(),
                  'noOfStudents': studentsList,
                  'totalStudents': totalStudents,
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Staff hall allotment updated successfully')),
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

  Future<void> _showDeleteDialog(BuildContext context, String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Staff Hall Allotment'),
        content: const Text('Are you sure you want to delete this staff hall allotment?'),
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
            .collection('staff_hall_allotments')
            .doc(docId)
            .delete();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Staff hall allotment deleted successfully')),
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
