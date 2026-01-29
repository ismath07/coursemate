import 'package:flutter/material.dart';
import 'student_home_screen.dart';
import '../../services/firestore_service.dart';

class StudentViewHallAllotmentScreen extends StatelessWidget {
  const StudentViewHallAllotmentScreen({super.key});

  static const String _examId = '2026_april';

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('View Hall Allotment', style: TextStyle(color: Colors.white)),
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
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: firestoreService.getHallAllotments(_examId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Failed to load hall allotments.'));
            }
            final rows = snapshot.data ?? [];
            if (rows.isEmpty) {
              return const Center(child: Text('No data available'));
            }
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('S.NO')),
                    DataColumn(label: Text('YEAR / DEPT')),
                    DataColumn(label: Text('REG. NO')),
                    DataColumn(label: Text('HALL')),
                  ],
                  rows: rows.map((row) {
                    final sno = row['sno']?.toString() ?? '';
                    final yearDept = (row['yearDept'] is List)
                        ? (row['yearDept'] as List).map((e) => e.toString()).join('\n')
                        : '';
                    final regNos = (row['regNos'] is List)
                        ? (row['regNos'] as List).map((e) => e.toString()).join('\n')
                        : '';
                    final hallNo = row['hallNo']?.toString() ?? '';
                    return DataRow(
                      cells: [
                        DataCell(Text(sno)),
                        DataCell(Text(yearDept)),
                        DataCell(Text(regNos)),
                        DataCell(Text(hallNo)),
                      ],
                    );
                  }).toList(),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        onTap: (index) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => StudentHomeScreen(initialIndex: index)),
          );
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), label: 'Syllabus'),
          BottomNavigationBarItem(icon: Icon(Icons.schedule_outlined), label: 'Timetable'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

