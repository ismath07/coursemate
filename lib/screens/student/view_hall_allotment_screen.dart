import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'student_home_screen.dart';

class StudentViewHallAllotmentScreen extends StatelessWidget {
  const StudentViewHallAllotmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
              .collection('staff_hall_allotments')
              .orderBy('sno')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return const Center(child: Text('Failed to load hall allotments.'));
            }
            
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No data available'));
            }
            
            final docs = snapshot.data!.docs;
            
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  columnSpacing: 20,
                  columns: const [
                    DataColumn(label: Text('S.No')),
                    DataColumn(label: Text('Staff Name')),
                    DataColumn(label: Text('Hall No')),
                    DataColumn(label: Text('Students')),
                    DataColumn(label: Text('Total Students')),
                  ],
                  rows: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    
                    final sno = data['sno'] ?? 0;
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
                        DataCell(Text(sno.toString())),
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
