import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';

class ViewExamTimetableScreen extends StatelessWidget {
  final String degreeId;
  final String degreeName;
  final String departmentId;
  final String departmentName;
  final String yearId;
  final String yearName;

  const ViewExamTimetableScreen({
    super.key,
    required this.degreeId,
    required this.degreeName,
    required this.departmentId,
    required this.departmentName,
    required this.yearId,
    required this.yearName,
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
              yearName,
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
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('exam_timetables')
                  .orderBy('createdAt')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(child: Text('No timetable found'));
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      columnSpacing: 20,
                      columns: [
                        const DataColumn(label: Text('Date')),
                        const DataColumn(label: Text('Day')),
                        const DataColumn(label: Text('Subject')),
                        const DataColumn(label: Text('Subject Code')),
                        const DataColumn(label: Text('Session')),
                        if (hasAccess)
                          const DataColumn(label: Text('Actions')),
                      ],
                      rows: docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return DataRow(
                          cells: [
                            DataCell(Text(data['date'] ?? '')),
                            DataCell(Text(data['day'] ?? '')),
                            DataCell(Text(data['subject'] ?? '')),
                            DataCell(Text(data['subjectCode'] ?? '')),
                            DataCell(Text(data['session'] ?? '')),
                            if (hasAccess)
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 18),
                                      onPressed: () => _editExam(context, doc),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                      onPressed: () => _deleteExam(context, doc.id),
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
        );
      },
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final dateController = TextEditingController();
    final dayController = TextEditingController();
    final subjectController = TextEditingController();
    final subjectCodeController = TextEditingController();
    final sessionController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Exam Timetable'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: dateController,
                decoration: const InputDecoration(labelText: 'Date (e.g., 01-12-2024)'),
              ),
              TextField(
                controller: dayController,
                decoration: const InputDecoration(labelText: 'Day (e.g., Monday)'),
              ),
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(labelText: 'Subject'),
              ),
              TextField(
                controller: subjectCodeController,
                decoration: const InputDecoration(labelText: 'Subject Code'),
              ),
              TextField(
                controller: sessionController,
                decoration: const InputDecoration(labelText: 'Session (e.g., FN/AN)'),
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
              if (dateController.text.isEmpty ||
                  dayController.text.isEmpty ||
                  subjectController.text.isEmpty ||
                  subjectCodeController.text.isEmpty ||
                  sessionController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              try {
                await FirebaseFirestore.instance
                    .collection('exam_timetables')
                    .add({
                  'date': dateController.text.trim(),
                  'day': dayController.text.trim(),
                  'subject': subjectController.text.trim(),
                  'subjectCode': subjectCodeController.text.trim(),
                  'session': sessionController.text.trim(),
                  'createdAt': FieldValue.serverTimestamp(),
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Exam timetable added successfully')),
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

  Future<void> _editExam(BuildContext context, DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final dateController = TextEditingController(text: data['date'] ?? '');
    final dayController = TextEditingController(text: data['day'] ?? '');
    final subjectController = TextEditingController(text: data['subject'] ?? '');
    final subjectCodeController = TextEditingController(text: data['subjectCode'] ?? '');
    final sessionController = TextEditingController(text: data['session'] ?? '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Exam Timetable'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: dateController,
                decoration: const InputDecoration(labelText: 'Date'),
              ),
              TextField(
                controller: dayController,
                decoration: const InputDecoration(labelText: 'Day'),
              ),
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(labelText: 'Subject'),
              ),
              TextField(
                controller: subjectCodeController,
                decoration: const InputDecoration(labelText: 'Subject Code'),
              ),
              TextField(
                controller: sessionController,
                decoration: const InputDecoration(labelText: 'Session'),
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
              if (dateController.text.isEmpty ||
                  dayController.text.isEmpty ||
                  subjectController.text.isEmpty ||
                  subjectCodeController.text.isEmpty ||
                  sessionController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              try {
                await FirebaseFirestore.instance
                    .collection('exam_timetables')
                    .doc(doc.id)
                    .update({
                  'date': dateController.text.trim(),
                  'day': dayController.text.trim(),
                  'subject': subjectController.text.trim(),
                  'subjectCode': subjectCodeController.text.trim(),
                  'session': sessionController.text.trim(),
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Exam timetable updated successfully')),
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

  Future<void> _deleteExam(BuildContext context, String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Exam Timetable'),
        content: const Text('Are you sure you want to delete this exam entry?'),
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
            .doc(docId)
            .delete();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Exam timetable deleted successfully')),
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
