import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import '../../services/pdf_service.dart';

class ViewExamTimetableScreen extends StatefulWidget {
  final String degreeId;
  final String degreeName;
  final String departmentId;
  final String departmentName;
  final String yearId;
  final String yearName;
  final String semesterType; // 'ODD' or 'EVEN'

  const ViewExamTimetableScreen({
    super.key,
    required this.degreeId,
    required this.degreeName,
    required this.departmentId,
    required this.departmentName,
    required this.yearId,
    required this.yearName,
    this.semesterType = '',
  });

  @override
  State<ViewExamTimetableScreen> createState() => _ViewExamTimetableScreenState();
}

class _ViewExamTimetableScreenState extends State<ViewExamTimetableScreen> {
  // Semester-scoped Firestore base path:
  // exam_timetables/{degreeId}/semesters/{semesterType}/departments/{deptId}/years/{yearId}/exams
  CollectionReference get _examsCollection =>
      FirebaseFirestore.instance
          .collection('exam_timetables')
          .doc(widget.degreeId)
          .collection('semesters')
          .doc(widget.semesterType.isNotEmpty ? widget.semesterType : 'NONE')
          .collection('departments')
          .doc(widget.departmentId)
          .collection('years')
          .doc(widget.yearId)
          .collection('exams');

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
            title: Text(widget.yearName, style: const TextStyle(color: Colors.white)),
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
            actions: [
              IconButton(
                icon: const Icon(Icons.download, color: Colors.white),
                onPressed: () => _downloadPDF(context),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filter info bar
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 4,
                    children: [
                      _chip(context, Icons.school_outlined, widget.degreeName),
                      if (widget.semesterType.isNotEmpty)
                        _chip(context, Icons.calendar_today_outlined, '${widget.semesterType} SEM'),
                      _chip(context, Icons.menu_book_outlined, widget.departmentName),
                      _chip(context, Icons.event_note_outlined, widget.yearName),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _examsCollection.orderBy('createdAt').snapshots(),
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
                              const DataColumn(label: Text('Course Name')),
                              const DataColumn(label: Text('Course Code')),
                              const DataColumn(label: Text('Session')),
                              if (hasAccess)
                                const DataColumn(label: Text('Actions')),
                            ],
                            rows: docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return DataRow(cells: [
                                DataCell(Text(data['date'] ?? '')),
                                DataCell(Text(data['day'] ?? '')),
                                DataCell(Text(data['subject'] ?? '')),
                                DataCell(Text(data['subjectCode'] ?? '')),
                                DataCell(Text(data['session'] ?? '')),
                                if (hasAccess)
                                  DataCell(Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 18),
                                        onPressed: () => _editExam(context, doc),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            size: 18, color: Colors.red),
                                        onPressed: () =>
                                            _deleteExam(context, doc.id),
                                      ),
                                    ],
                                  )),
                              ]);
                            }).toList(),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
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

  Widget _chip(BuildContext context, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            )),
      ],
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) => _ExamTimetableForm(
        semesterType: widget.semesterType,
        examsCollection: _examsCollection,
      ),
    );
  }

  Future<void> _editExam(BuildContext context, DocumentSnapshot doc) async {
    await showDialog(
      context: context,
      builder: (ctx) => _ExamTimetableForm(
        semesterType: widget.semesterType,
        examsCollection: _examsCollection,
        existingDoc: doc,
      ),
    );
  }

  Future<void> _deleteExam(BuildContext context, String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Exam Timetable'),
        content: const Text('Are you sure you want to delete this exam entry?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _examsCollection.doc(docId).delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Exam timetable deleted successfully')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Future<void> _downloadPDF(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generating PDF...'), duration: Duration(seconds: 2)));
    try {
      final snapshot = await _examsCollection.orderBy('createdAt').get();
      if (snapshot.docs.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No data to download')));
        }
        return;
      }
      final timetableData = snapshot.docs.map((doc) {
        final d = doc.data() as Map<String, dynamic>;
        return {
          'date': d['date'] ?? '',
          'day': d['day'] ?? '',
          'subject': d['subject'] ?? '',
          'subjectCode': d['subjectCode'] ?? '',
          'session': d['session'] ?? '',
        };
      }).toList();

      final filePath = await PdfService.generateExamTimetablePDF(
        courseName: '${widget.degreeName} - ${widget.departmentName}',
        year: widget.yearName,
        semester: widget.semesterType,
        timetableData: timetableData,
      );

      if (context.mounted) {
        if (filePath != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('PDF saved\n$filePath'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(label: 'OK', onPressed: () {}),
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Failed to generate PDF'),
            backgroundColor: Colors.red,
          ));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }
}

// Separate stateful form widget for add/edit
class _ExamTimetableForm extends StatefulWidget {
  final String semesterType;
  final CollectionReference examsCollection;
  final DocumentSnapshot? existingDoc;

  const _ExamTimetableForm({
    required this.semesterType,
    required this.examsCollection,
    this.existingDoc,
  });

  @override
  State<_ExamTimetableForm> createState() => _ExamTimetableFormState();
}

class _ExamTimetableFormState extends State<_ExamTimetableForm> {
  DateTime? _selectedDate;
  String? _selectedDay;
  String? _selectedSession;
  final _subjectController = TextEditingController();
  final _codeController = TextEditingController();
  bool _isSaving = false;

  // Dropdown options
  static const List<String> _days = [
    'SUN',
    'MON',
    'TUE',
    'WED',
    'THUR',
    'FRI',
    'SAT',
  ];

  static const List<String> _sessions = ['FN', 'AN'];

  @override
  void initState() {
    super.initState();
    // Pre-populate if editing
    if (widget.existingDoc != null) {
      final data = widget.existingDoc!.data() as Map<String, dynamic>;
      _subjectController.text = data['subject'] ?? '';
      _codeController.text = data['subjectCode'] ?? '';
      _selectedDay = data['day'] ?? '';
      _selectedSession = data['session'] ?? '';
      // Parse existing date
      final dateStr = data['date'] ?? '';
      if (dateStr.isNotEmpty) {
        try {
          final parts = dateStr.split('-');
          if (parts.length == 3) {
            final day = int.tryParse(parts[0]);
            final month = int.tryParse(parts[1]);
            final year = int.tryParse(parts[2]);
            if (day != null && month != null && year != null) {
              _selectedDate = DateTime(year, month, day);
            }
          }
        } catch (e) {
          // ignore
        }
      }
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingDoc != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Exam Timetable' : 'Add Exam Timetable'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Picker
            const Text('Date', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _selectDate(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      _selectedDate != null
                          ? _formatDate(_selectedDate!)
                          : 'Select Date',
                      style: TextStyle(
                        color: _selectedDate != null
                            ? Colors.black87
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Day Dropdown
            const Text('Day', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedDay,
                  hint: const Text('Select Day'),
                  isExpanded: true,
                  items: _days.map((day) {
                    return DropdownMenuItem<String>(
                      value: day,
                      child: Text(day),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDay = value;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Course Name
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: 'Course Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Course Code
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Course Code',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Session Dropdown
            const Text('Session', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedSession,
                  hint: const Text('Select Session'),
                  isExpanded: true,
                  items: _sessions.map((session) {
                    return DropdownMenuItem<String>(
                      value: session,
                      child: Text(session),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSession = value;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        _isSaving
            ? const CircularProgressIndicator()
            : TextButton(
                onPressed: () async {
                  if (_selectedDate == null ||
                      _selectedDay == null ||
                      _selectedSession == null ||
                      _subjectController.text.trim().isEmpty ||
                      _codeController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill all fields')),
                    );
                    return;
                  }
                  setState(() => _isSaving = true);
                  try {
                    final dateStr = _formatDate(_selectedDate!);
                    if (isEdit) {
                      await widget.examsCollection.doc(widget.existingDoc!.id).update({
                        'date': dateStr,
                        'day': _selectedDay,
                        'subject': _subjectController.text.trim(),
                        'subjectCode': _codeController.text.trim(),
                        'session': _selectedSession,
                        'semesterType': widget.semesterType,
                      });
                    } else {
                      await widget.examsCollection.add({
                        'date': dateStr,
                        'day': _selectedDay,
                        'subject': _subjectController.text.trim(),
                        'subjectCode': _codeController.text.trim(),
                        'session': _selectedSession,
                        'semesterType': widget.semesterType,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                    }
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isEdit
                              ? 'Exam timetable updated successfully'
                              : 'Exam timetable added successfully'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      setState(() => _isSaving = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
                child: Text(isEdit ? 'Save' : 'Add'),
              ),
      ],
    );
  }
}
