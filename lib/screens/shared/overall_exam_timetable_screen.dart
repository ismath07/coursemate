import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/pdf_service.dart';

/// Displays ALL exam timetable data for a given semester (ODD or EVEN)
/// grouped by Degree → Department → Year, in a single scrollable view.
/// Reads directly from the existing exam_timetables Firestore hierarchy.
class OverallExamTimetableScreen extends StatelessWidget {
  final String semesterType; // 'ODD' or 'EVEN'

  const OverallExamTimetableScreen({super.key, required this.semesterType});

  static const _gradient = BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFF0D1B6F), Color(0xFF880E4F)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
  );

  /// Fetches ALL data for the current semester and generates a single PDF.
  Future<void> _downloadPDF(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Collecting data…'), duration: Duration(seconds: 2)),
    );

    try {
      // Step 1 – all degrees
      final degreesSnap = await FirebaseFirestore.instance
          .collection('exam_timetables')
          .orderBy('displayName')
          .get();

      final List<Map<String, dynamic>> degreeGroups = [];

      for (final degreeDoc in degreesSnap.docs) {
        final degreeData = degreeDoc.data();
        final degreeName =
            (degreeData['displayName'] ?? degreeDoc.id).toString();

        // Step 2 – departments under this degree + semester
        final deptsSnap = await FirebaseFirestore.instance
            .collection('exam_timetables')
            .doc(degreeDoc.id)
            .collection('semesters')
            .doc(semesterType)
            .collection('departments')
            .orderBy('displayName')
            .get();

        if (deptsSnap.docs.isEmpty) continue;

        final List<Map<String, dynamic>> deptList = [];

        for (final deptDoc in deptsSnap.docs) {
          final deptData = deptDoc.data();
          final deptName =
              (deptData['displayName'] ?? deptDoc.id).toString();

          // Step 3 – years under this department
          final yearsSnap = await FirebaseFirestore.instance
              .collection('exam_timetables')
              .doc(degreeDoc.id)
              .collection('semesters')
              .doc(semesterType)
              .collection('departments')
              .doc(deptDoc.id)
              .collection('years')
              .orderBy('displayName')
              .get();

          if (yearsSnap.docs.isEmpty) continue;

          final List<Map<String, dynamic>> yearList = [];

          for (final yearDoc in yearsSnap.docs) {
            final yearData = yearDoc.data();
            final yearName =
                (yearData['displayName'] ?? yearDoc.id).toString();

            // Step 4 – exams
            final examsSnap = await FirebaseFirestore.instance
                .collection('exam_timetables')
                .doc(degreeDoc.id)
                .collection('semesters')
                .doc(semesterType)
                .collection('departments')
                .doc(deptDoc.id)
                .collection('years')
                .doc(yearDoc.id)
                .collection('exams')
                .orderBy('createdAt')
                .get();

            if (examsSnap.docs.isEmpty) continue;

            yearList.add({
              'yearName': yearName,
              'exams': examsSnap.docs.map((e) {
                final d = e.data();
                return {
                  'date': d['date'] ?? '',
                  'day': d['day'] ?? '',
                  'subject': d['subject'] ?? '',
                  'subjectCode': d['subjectCode'] ?? '',
                  'session': d['session'] ?? '',
                };
              }).toList(),
            });
          }

          if (yearList.isEmpty) continue;
          deptList.add({'deptName': deptName, 'years': yearList});
        }

        if (deptList.isEmpty) continue;
        degreeGroups.add({'degreeName': degreeName, 'departments': deptList});
      }

      if (degreeGroups.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No timetable data to download.')),
          );
        }
        return;
      }

      final filePath = await PdfService.generateOverallExamTimetablePDF(
        semesterType: semesterType,
        degreeGroups: degreeGroups,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          '$semesterType Semester — Overall',
          style: const TextStyle(color: Colors.white),
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
        // Step 1: load all degree documents
        stream: FirebaseFirestore.instance
            .collection('exam_timetables')
            .orderBy('displayName')
            .snapshots(),
        builder: (context, degreeSnap) {
          if (!degreeSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final degrees = degreeSnap.data!.docs;
          if (degrees.isEmpty) {
            return const Center(child: Text('No timetable data found.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: degrees.length,
            itemBuilder: (context, di) {
              final degreeDoc = degrees[di];
              final degreeData = degreeDoc.data() as Map<String, dynamic>;
              final degreeName =
                  (degreeData['displayName'] ?? degreeDoc.id).toString();

              return _DegreeSection(
                degreeId: degreeDoc.id,
                degreeName: degreeName,
                semesterType: semesterType,
              );
            },
          );
        },
      ),
    );
  }
}

// ─── Degree section ───────────────────────────────────────────────────────────

class _DegreeSection extends StatelessWidget {
  final String degreeId;
  final String degreeName;
  final String semesterType;

  const _DegreeSection({
    required this.degreeId,
    required this.degreeName,
    required this.semesterType,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('exam_timetables')
          .doc(degreeId)
          .collection('semesters')
          .doc(semesterType)
          .collection('departments')
          .orderBy('displayName')
          .snapshots(),
      builder: (context, deptSnap) {
        if (!deptSnap.hasData) return const SizedBox.shrink();
        final departments = deptSnap.data!.docs;
        if (departments.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Degree header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D1B6F), Color(0xFF880E4F)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.school, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      degreeName.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Departments ──
            ...departments.map((deptDoc) {
              final deptData = deptDoc.data() as Map<String, dynamic>;
              final deptName =
                  (deptData['displayName'] ?? deptDoc.id).toString();
              return _DepartmentSection(
                degreeId: degreeId,
                departmentId: deptDoc.id,
                departmentName: deptName,
                semesterType: semesterType,
              );
            }),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Divider(thickness: 1),
            ),
          ],
        );
      },
    );
  }
}

// ─── Department section ───────────────────────────────────────────────────────

class _DepartmentSection extends StatelessWidget {
  final String degreeId;
  final String departmentId;
  final String departmentName;
  final String semesterType;

  const _DepartmentSection({
    required this.degreeId,
    required this.departmentId,
    required this.departmentName,
    required this.semesterType,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('exam_timetables')
          .doc(degreeId)
          .collection('semesters')
          .doc(semesterType)
          .collection('departments')
          .doc(departmentId)
          .collection('years')
          .orderBy('displayName')
          .snapshots(),
      builder: (context, yearSnap) {
        if (!yearSnap.hasData) return const SizedBox.shrink();
        final years = yearSnap.data!.docs;
        if (years.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Department name ──
              Row(
                children: [
                  Icon(Icons.menu_book_outlined,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    departmentName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ── Years ──
              ...years.map((yearDoc) {
                final yearData = yearDoc.data() as Map<String, dynamic>;
                final yearName =
                    (yearData['displayName'] ?? yearDoc.id).toString();
                return _YearSection(
                  degreeId: degreeId,
                  departmentId: departmentId,
                  yearId: yearDoc.id,
                  yearName: yearName,
                  semesterType: semesterType,
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

// ─── Year section with timetable table ───────────────────────────────────────

class _YearSection extends StatelessWidget {
  final String degreeId;
  final String departmentId;
  final String yearId;
  final String yearName;
  final String semesterType;

  const _YearSection({
    required this.degreeId,
    required this.departmentId,
    required this.yearId,
    required this.yearName,
    required this.semesterType,
  });

  CollectionReference get _examsCollection =>
      FirebaseFirestore.instance
          .collection('exam_timetables')
          .doc(degreeId)
          .collection('semesters')
          .doc(semesterType)
          .collection('departments')
          .doc(departmentId)
          .collection('years')
          .doc(yearId)
          .collection('exams');

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _examsCollection.orderBy('createdAt').snapshots(),
      builder: (context, examSnap) {
        if (!examSnap.hasData) return const SizedBox.shrink();
        final exams = examSnap.data!.docs;
        if (exams.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Year label ──
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.event_note_outlined,
                        size: 14,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      yearName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Timetable table (horizontal scroll) ──
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 18,
                  headingRowColor: WidgetStateProperty.all(
                    Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.07),
                  ),
                  columns: const [
                    DataColumn(
                        label: Text('Date',
                            style:
                                TextStyle(fontWeight: FontWeight.w700))),
                    DataColumn(
                        label: Text('Day',
                            style:
                                TextStyle(fontWeight: FontWeight.w700))),
                    DataColumn(
                        label: Text('Subject',
                            style:
                                TextStyle(fontWeight: FontWeight.w700))),
                    DataColumn(
                        label: Text('Subject Code',
                            style:
                                TextStyle(fontWeight: FontWeight.w700))),
                    DataColumn(
                        label: Text('Session',
                            style:
                                TextStyle(fontWeight: FontWeight.w700))),
                  ],
                  rows: exams.map((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    return DataRow(cells: [
                      DataCell(Text(d['date'] ?? '')),
                      DataCell(Text(d['day'] ?? '')),
                      DataCell(Text(d['subject'] ?? '')),
                      DataCell(Text(d['subjectCode'] ?? '')),
                      DataCell(Text(d['session'] ?? '')),
                    ]);
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
