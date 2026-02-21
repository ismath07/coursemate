import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

    return Scaffold(

      backgroundColor:
          Theme.of(context).scaffoldBackgroundColor,

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

        iconTheme:
            const IconThemeData(color: Colors.white),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: StreamBuilder<QuerySnapshot>(

          stream: FirebaseFirestore.instance

              .collection('exam_timetables')
              .doc(degreeId)

              .collection('departments')
              .doc(departmentId)

              .collection('years')
              .doc(yearId)

              .collection('exams')

              .orderBy('date')

              .snapshots(),

          builder: (context, snapshot) {

            if (snapshot.connectionState ==
                ConnectionState.waiting) {

              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {

              return const Center(
                child: Text('Failed to load timetable'),
              );
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {

              return const Center(
                child: Text('No timetable found'),
              );
            }

            return SingleChildScrollView(

              scrollDirection: Axis.horizontal,

              child: SingleChildScrollView(

                child: DataTable(

                  columnSpacing: 20,

                  columns: const [

                    DataColumn(
                      label: Text('Date'),
                    ),

                    DataColumn(
                      label: Text('Day'),
                    ),

                    DataColumn(
                      label: Text('Subject'),
                    ),

                    DataColumn(
                      label: Text('Code'),
                    ),

                    DataColumn(
                      label: Text('Session'),
                    ),

                  ],

                  rows: docs.map((doc) {

                    final data =
                        doc.data()
                            as Map<String, dynamic>;

                    return DataRow(

                      cells: [

                        DataCell(
                          Text(
                            data['date'] ?? '',
                          ),
                        ),

                        DataCell(
                          Text(
                            data['day'] ?? '',
                          ),
                        ),

                        DataCell(
                          Text(
                            data['title'] ?? '',
                          ),
                        ),

                        DataCell(
                          Text(
                            data['subjectCode'] ?? '',
                          ),
                        ),

                        DataCell(
                          Text(
                            data['session'] ?? '',
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
    );
  }
}