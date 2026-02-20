import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'staff_home_screen.dart';

class StaffHallAllotmentScreen extends StatelessWidget {
  const StaffHallAllotmentScreen({super.key});

  int _calculateTotalStudents(List<dynamic> entries) {
    int total = 0;

    for (final entry in entries) {
      final text = entry.toString();

      final match = RegExp(r'(\d+)').firstMatch(text);

      if (match != null) {
        final value = int.tryParse(match.group(1) ?? '');

        if (value != null) {
          total += value;
        }
      }
    }

    return total;
  }

  @override
  Widget build(BuildContext context) {
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
              .orderBy('createdAt', descending: false)
              .snapshots(),

          builder: (context, snapshot) {

            /// loading
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            /// error
            if (snapshot.hasError) {
              return const Center(
                child: Text('Failed to load hall allotments.'),
              );
            }

            final docs = snapshot.data?.docs ?? [];

            /// empty
            if (docs.isEmpty) {
              return const Center(
                child: Text('No staff hall allotments found.'),
              );
            }

            /// table view
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,

              child: SingleChildScrollView(
                child: DataTable(

                  columns: const [
                    DataColumn(label: Text('S.No')),
                    DataColumn(label: Text('Staff Name')),
                    DataColumn(label: Text('Hall No')),
                    DataColumn(label: Text('No of Students')),
                    DataColumn(label: Text('Total Students')),
                  ],

                  rows: List.generate(
                    docs.length,
                    (index) {

                      final data =
                          docs[index].data() as Map<String, dynamic>;

                      final staffName =
                          (data['staffName'] ?? '').toString();

                      final hallNo =
                          (data['hallNo'] ?? '').toString();

                      final noOfStudentsRaw =
                          data['noOfStudents'];

                      final List<dynamic> entries =
                          noOfStudentsRaw is List
                              ? noOfStudentsRaw
                              : [];

                      final totalStudents =
                          _calculateTotalStudents(entries);

                      final noOfStudentsText =
                          entries.isEmpty
                              ? '-'
                              : entries.join('\n');

                      return DataRow(
                        cells: [

                          DataCell(
                            Text('${index + 1}'),
                          ),

                          DataCell(
                            Text(staffName),
                          ),

                          DataCell(
                            Text(hallNo),
                          ),

                          DataCell(
                            SizedBox(
                              width: 180,
                              child: Text(
                                noOfStudentsText,
                                softWrap: true,
                              ),
                            ),
                          ),

                          DataCell(
                            Text('$totalStudents'),
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

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        type: BottomNavigationBarType.fixed,

        selectedItemColor:
            Theme.of(context).colorScheme.primary,

        onTap: (index) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  StaffHomeScreen(initialIndex: index),
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
  }
}