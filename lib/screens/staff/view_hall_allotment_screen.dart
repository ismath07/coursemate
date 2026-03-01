import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import 'staff_home_screen.dart';

class StaffViewHallAllotmentScreen extends StatelessWidget {
  const StaffViewHallAllotmentScreen({super.key});

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
            title: const Text('Hall Allotment', style: TextStyle(color: Colors.white)),
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
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('exam_hall_allotments')
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(child: Text('No hall allotments found'));
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      columnSpacing: 20,
                      columns: [
                        const DataColumn(label: Text('Sno')),
                        const DataColumn(label: Text('Year/Dept')),
                        const DataColumn(label: Text('Register No')),
                        const DataColumn(label: Text('Hall No')),
                        const DataColumn(label: Text('No.of Students')),
                        if (hasAccess)
                          const DataColumn(label: Text('Actions')),
                      ],
                      rows: docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        
                        // Safe conversion for numeric fields
                        final int sno = data['sno'] ?? 0;
                        final int noOfStudents = data['noOfStudents'] ?? 0;
                        final String hallNo = data['hallNo']?.toString() ?? '';
                        
                        // Safe conversion for yearDept
                        final yearDeptData = data['yearDept'];
                        String yearDeptText = '';
                        if (yearDeptData is List) {
                          yearDeptText = yearDeptData.join('\n');
                        } else if (yearDeptData is String) {
                          yearDeptText = yearDeptData;
                        }
                        
                        // Safe conversion for registerNumbers
                        final registerNoData = data['registerNumbers'];
                        String registerNoText = '';
                        if (registerNoData is List) {
                          registerNoText = registerNoData.join('\n');
                        } else if (registerNoData is String) {
                          registerNoText = registerNoData;
                        }
                        
                        return DataRow(
                          cells: [
                            DataCell(Text(sno.toString())),
                            DataCell(Text(yearDeptText)),
                            DataCell(Text(registerNoText)),
                            DataCell(Text(hallNo)),
                            DataCell(Text(noOfStudents.toString())),
                            if (hasAccess)
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 18),
                                      onPressed: () => _editHall(context, doc),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                      onPressed: () => _deleteHall(context, doc.id),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        );
                      }).toList(),
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
            currentIndex: 1,
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

  Future<void> _showAddDialog(BuildContext context) async {
    final snoController = TextEditingController();
    final yearDeptController = TextEditingController();
    final registerNoController = TextEditingController();
    final hallNoController = TextEditingController();
    final noStudentsController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Hall Allotment'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: snoController,
                decoration: const InputDecoration(labelText: 'Sno'),
              ),
              TextField(
                controller: yearDeptController,
                decoration: const InputDecoration(
                  labelText: 'Year/Dept (comma separated)',
                  hintText: 'BCA IT,2nd IT',
                ),
                maxLines: 2,
              ),
              TextField(
                controller: registerNoController,
                decoration: const InputDecoration(
                  labelText: 'Register No (comma separated)',
                  hintText: '12345,67890',
                ),
                maxLines: 2,
              ),
              TextField(
                controller: hallNoController,
                decoration: const InputDecoration(labelText: 'Hall No'),
              ),
              TextField(
                controller: noStudentsController,
                decoration: const InputDecoration(labelText: 'No.of Students'),
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
              if (snoController.text.isEmpty ||
                  yearDeptController.text.isEmpty ||
                  registerNoController.text.isEmpty ||
                  hallNoController.text.isEmpty ||
                  noStudentsController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              try {
                final yearDeptList = yearDeptController.text.split(',').map((e) => e.trim()).toList();
                final registerNumbersList = registerNoController.text.split(',').map((e) => e.trim()).toList();

                await FirebaseFirestore.instance
                    .collection('exam_hall_allotments')
                    .add({
                  'sno': int.tryParse(snoController.text.trim()) ?? 0,
                  'yearDept': yearDeptList,
                  'registerNumbers': registerNumbersList,
                  'hallNo': hallNoController.text.trim(),
                  'noOfStudents': int.tryParse(noStudentsController.text.trim()) ?? 0,
                  'createdAt': FieldValue.serverTimestamp(),
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Hall allotment added successfully')),
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

  Future<void> _editHall(BuildContext context, DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    
    // Safe conversion for numeric fields
    final int sno = data['sno'] ?? 0;
    final int noOfStudents = data['noOfStudents'] ?? 0;
    final String hallNo = data['hallNo']?.toString() ?? '';
    
    final snoController = TextEditingController(text: sno.toString());
    final hallNoController = TextEditingController(text: hallNo);
    final noStudentsController = TextEditingController(text: noOfStudents.toString());
    
    // Safe conversion for yearDept
    final yearDeptData = data['yearDept'];
    String yearDeptText = '';
    if (yearDeptData is List) {
      yearDeptText = yearDeptData.join(',');
    } else if (yearDeptData is String) {
      yearDeptText = yearDeptData;
    }
    final yearDeptController = TextEditingController(text: yearDeptText);
    
    // Safe conversion for registerNumbers
    final registerNoData = data['registerNumbers'] ?? data['registerNo'];
    String registerNoText = '';
    if (registerNoData is List) {
      registerNoText = registerNoData.join(',');
    } else if (registerNoData is String) {
      registerNoText = registerNoData;
    }
    final registerNoController = TextEditingController(text: registerNoText);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Hall Allotment'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: snoController,
                decoration: const InputDecoration(labelText: 'Sno'),
              ),
              TextField(
                controller: yearDeptController,
                decoration: const InputDecoration(
                  labelText: 'Year/Dept (comma separated)',
                  hintText: 'BCA IT,2nd IT',
                ),
                maxLines: 2,
              ),
              TextField(
                controller: registerNoController,
                decoration: const InputDecoration(
                  labelText: 'Register No (comma separated)',
                  hintText: '12345,67890',
                ),
                maxLines: 2,
              ),
              TextField(
                controller: hallNoController,
                decoration: const InputDecoration(labelText: 'Hall No'),
              ),
              TextField(
                controller: noStudentsController,
                decoration: const InputDecoration(labelText: 'No.of Students'),
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
              if (snoController.text.isEmpty ||
                  yearDeptController.text.isEmpty ||
                  registerNoController.text.isEmpty ||
                  hallNoController.text.isEmpty ||
                  noStudentsController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              try {
                await FirebaseFirestore.instance
                    .collection('exam_hall_allotments')
                    .doc(doc.id)
                    .update({
                  'sno': int.tryParse(snoController.text.trim()) ?? 0,
                  'yearDept': yearDeptController.text.split(',').map((e) => e.trim()).toList(),
                  'registerNumbers': registerNoController.text.split(',').map((e) => e.trim()).toList(),
                  'hallNo': hallNoController.text.trim(),
                  'noOfStudents': int.tryParse(noStudentsController.text.trim()) ?? 0,
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Hall allotment updated successfully')),
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

  Future<void> _deleteHall(BuildContext context, String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Hall Allotment'),
        content: const Text('Are you sure you want to delete this hall allotment?'),
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
            .collection('exam_hall_allotments')
            .doc(docId)
            .delete();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Hall allotment deleted successfully')),
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
