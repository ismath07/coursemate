import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import '../../services/pdf_service.dart';
import 'absent_details_form_screen.dart';

class AbsentDetailsScreen extends StatelessWidget {
  const AbsentDetailsScreen({super.key});

  static const _collection = 'absent_details';

  static const _gradient = BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFF0D1B6F), Color(0xFF880E4F)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
  );

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: FirestoreService().editAccessStream(),
      builder: (context, accessSnap) {
        final hasAccess = accessSnap.data ?? false;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text(
              'Absent Details',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            toolbarHeight: 90,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            flexibleSpace: Container(decoration: _gradient),
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.download, color: Colors.white),
                tooltip: 'Download PDF',
                onPressed: () => _downloadPDF(context),
              ),
            ],
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(_collection)
                .orderBy('sno')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Failed to load absent details.'));
              }

              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.assignment_outlined,
                          size: 64,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      const Text('No absent details found.',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: _AbsentTable(
                    docs: docs,
                    hasAccess: hasAccess,
                    onEdit: (doc) => _showEditDialog(context, doc),
                    onDelete: (id) => _confirmDelete(context, id),
                  ),
                ),
              );
            },
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

  // ── Download PDF ─────────────────────────────────────────────────────────

  Future<void> _downloadPDF(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Generating PDF…'), duration: Duration(seconds: 2)),
    );
    try {
      final snap = await FirebaseFirestore.instance
          .collection(_collection)
          .orderBy('sno')
          .get();

      if (snap.docs.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No data to download.')),
          );
        }
        return;
      }

      final records = snap.docs.map((d) => d.data()).toList();

      final filePath =
          await PdfService.generateAbsentDetailsPDF(records: records);

      if (context.mounted) {
        if (filePath != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('PDF saved\n$filePath'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(label: 'OK', onPressed: () {}),
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Failed to generate PDF.'),
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

  // ── Add ──────────────────────────────────────────────────────────────────

  Future<void> _showAddDialog(BuildContext context) async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AbsentDetailsFormScreen()));
    if (result == true) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Record added successfully.')));
    }
  }

  // ── Edit ─────────────────────────────────────────────────────────────────

  Future<void> _showEditDialog(BuildContext context, DocumentSnapshot doc) async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => AbsentDetailsFormScreen(existing: doc)));
    if (result == true) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Record updated successfully.')));
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> _confirmDelete(BuildContext context, String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Record'),
        content:
            const Text('Are you sure you want to delete this absent record?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection(_collection)
            .doc(docId)
            .delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Record deleted successfully.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
}

// ─── Table widget ─────────────────────────────────────────────────────────────

class _AbsentTable extends StatelessWidget {
  final List<QueryDocumentSnapshot> docs;
  final bool hasAccess;
  final void Function(DocumentSnapshot) onEdit;
  final void Function(String) onDelete;

  const _AbsentTable({
    required this.docs,
    required this.hasAccess,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final headerStyle = TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 13,
      color: primary,
    );
    const cellPad = EdgeInsets.symmetric(horizontal: 12, vertical: 10);
    final borderSide = BorderSide(color: Colors.grey.shade300);

    return Table(
      defaultColumnWidth: const IntrinsicColumnWidth(),
      border: TableBorder.all(color: Colors.grey.shade300, width: 0.8),
      children: [
        // Header
        TableRow(
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.07),
          ),
          children: [
            _headerCell('S.No', headerStyle, cellPad),
            _headerCell('Hall No', headerStyle, cellPad),
            _headerCell('No. of Students\nAbsent', headerStyle, cellPad),
            _headerCell('Student Name', headerStyle, cellPad),
            _headerCell('Register Number', headerStyle, cellPad),
            _headerCell('Staff Name', headerStyle, cellPad),
            if (hasAccess) _headerCell('Actions', headerStyle, cellPad),
          ],
        ),
        // Data rows
        ...docs.map((doc) {
          final d = doc.data() as Map<String, dynamic>;
          final sno = (d['sno'] ?? 0).toString();
          final hallNo = d['hallNo']?.toString() ?? '';
          final staffName = d['staffName']?.toString() ?? '';

          final rawStudents = d['students'];
          final List<Map<String, String>> students = [];
          if (rawStudents is List) {
            for (final s in rawStudents) {
              if (s is Map) {
                students.add({
                  'name': s['name']?.toString() ?? '',
                  'regNo': s['regNo']?.toString() ?? '',
                });
              }
            }
          }
          final absentCount = students.length.toString();

          return TableRow(
            decoration: BoxDecoration(
              border: Border(bottom: borderSide),
            ),
            children: [
              // S.No
              Padding(
                padding: cellPad,
                child: Text(sno,
                    style: const TextStyle(fontSize: 13)),
              ),
              // Hall No
              Padding(
                padding: cellPad,
                child: Text(hallNo,
                    style: const TextStyle(fontSize: 13)),
              ),
              // Absent count
              Padding(
                padding: cellPad,
                child: Text(absentCount,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13)),
              ),
              // Student Names (one per line)
              Padding(
                padding: cellPad,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: students
                      .map((s) => Text(s['name']!,
                          style: const TextStyle(fontSize: 13)))
                      .toList(),
                ),
              ),
              // Register Numbers (one per line, aligned with names)
              Padding(
                padding: cellPad,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: students
                      .map((s) => Text(s['regNo']!,
                          style: const TextStyle(fontSize: 13)))
                      .toList(),
                ),
              ),
              // Staff Name
              Padding(
                padding: cellPad,
                child: Text(staffName,
                    style: const TextStyle(fontSize: 13)),
              ),
              // Actions
              if (hasAccess)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () => onEdit(doc),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete,
                            size: 18, color: Colors.red),
                        onPressed: () => onDelete(doc.id),
                      ),
                    ],
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }

  Widget _headerCell(
      String text, TextStyle style, EdgeInsets pad) {
    return Padding(
      padding: pad,
      child: Text(text, style: style),
    );
  }
}

