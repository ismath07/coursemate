import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../services/pdf_service.dart';

// Helper function to get the priority of a unit key
int _getUnitPriority(String key) {
  final lowerKey = key.toLowerCase();
  
  // Course Objective: priority 0
  if (lowerKey.contains('course') && lowerKey.contains('objective')) {
    return 0;
  }
  
  // Unit X: priority X
  final unitMatch = RegExp(r'unit[^\d]*(\d+)').firstMatch(lowerKey);
  if (unitMatch != null) {
    final unitNumber = int.tryParse(unitMatch.group(1)!);
    if (unitNumber != null) {
      return unitNumber;
    }
  }
  
  // Reference/References: priority 999
  if (lowerKey.contains('reference')) {
    return 999;
  }
  
  // Unknown: priority 998
  return 998;
}

// Helper function to get the display label for a unit key
String _getUnitLabel(String key) {
  final lowerKey = key.toLowerCase();
  
  // Course Objective
  if (lowerKey.contains('course') && lowerKey.contains('objective')) {
    return 'Course Objectives';
  }
  
  // Unit X
  final unitMatch = RegExp(r'unit[^\d]*(\d+)').firstMatch(lowerKey);
  if (unitMatch != null) {
    final unitNumber = int.tryParse(unitMatch.group(1)!);
    if (unitNumber != null) {
      return 'UNIT $unitNumber';
    }
  }
  
  // Reference/References
  if (lowerKey.contains('reference')) {
    return 'Reference';
  }
  
  // Keep as is
  return key;
}

// Helper function to sort units and return ordered entries
List<MapEntry<String, dynamic>> _sortSyllabusUnits(Map<String, dynamic> units) {
  final entries = units.entries.toList();
  entries.sort((a, b) => _getUnitPriority(a.key).compareTo(_getUnitPriority(b.key)));
  return entries.map((e) => MapEntry(_getUnitLabel(e.key), e.value)).toList();
}

class StudentViewSyllabusScreen extends StatelessWidget {
  final String subjectTitle;
  final String subjectCode;
  final String degreeLevelId;
  final String courseId;
  final String courseName; // display name, never the document ID
  final String semesterId;

  const StudentViewSyllabusScreen({
    super.key,
    required this.subjectTitle,
    required this.subjectCode,
    required this.degreeLevelId,
    required this.courseId,
    required this.courseName,
    required this.semesterId,
  });

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();
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
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: () => _downloadPDF(context, firestoreService),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: FutureBuilder<Map<String, dynamic>?>(
          future: firestoreService.getSyllabus(degreeLevelId, courseId, semesterId, subjectCode),
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
            
            // Display in canonical syllabus order using custom sorting
            final orderedEntries = _sortSyllabusUnits(units);
            
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
                    for (final entry in orderedEntries) ...[
                      Text(
                        entry.key,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        entry.value.toString(),
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 14),
                    ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _downloadPDF(BuildContext context, FirestoreService firestoreService) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generating PDF...'),
          duration: Duration(seconds: 2),
        ),
      );

      // Fetch syllabus data
      final data = await firestoreService.getSyllabus(
        degreeLevelId,
        courseId,
        semesterId,
        subjectCode,
      );

      if (data == null || data['units'] == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No data to download')),
          );
        }
        return;
      }

      final units = Map<String, dynamic>.from(data['units']);

      // Generate PDF
      final filePath = await PdfService.generateSyllabusPDF(
        subjectName: subjectTitle,
        subjectCode: subjectCode,
        course: courseName,
        semester: semesterId,
        syllabusData: units,
      );

      if (context.mounted) {
        if (filePath != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF saved in Download folder\n$filePath'),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'OK',
                onPressed: () {},
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to download PDF. Check console for details.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      print('Download error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
