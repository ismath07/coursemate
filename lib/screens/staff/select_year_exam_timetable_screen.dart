import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import 'view_exam_timetable_screen.dart';

class SelectYearExamTimetableScreen extends StatelessWidget {

  final String degreeId;
  final String degreeName;

  final String departmentId;
  final String departmentName;

  const SelectYearExamTimetableScreen({
    super.key,
    required this.degreeId,
    required this.degreeName,
    required this.departmentId,
    required this.departmentName,
  });

  @override
  Widget build(BuildContext context) {

    final firestoreService = FirestoreService();

    return Scaffold(

      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(

        title: Text(
          departmentName,
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
        padding: const EdgeInsets.all(20),

        child: StreamBuilder<List<Map<String, String>>>(

          stream: firestoreService.getExamYears(
             degreeId,
             departmentId,
          ),

          builder: (context, snapshot) {

            if (snapshot.connectionState ==
                ConnectionState.waiting) {

              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {

              return const Center(
                child: Text('Failed to load years'),
              );
            }

            final years = snapshot.data ?? [];

            if (years.isEmpty) {

              return const Center(
                child: Text('No years found'),
              );
            }

            return ListView.builder(

              itemCount: years.length,

              itemBuilder: (context, index) {

                final year = years[index];

                final id = year['id'] ?? '';
                final name =
                    year['displayName'] ?? id;

                return InkWell(

                  onTap: () {

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ViewExamTimetableScreen(

                          degreeId: degreeId,
                          degreeName: degreeName,

                          departmentId: departmentId,
                          departmentName: departmentName,

                          yearId: id,
                          yearName: name,

                        ),
                      ),
                    );
                  },

                  borderRadius:
                      BorderRadius.circular(16),

                  child: Container(

                    padding:
                        const EdgeInsets.all(18),

                    margin:
                        const EdgeInsets.only(
                            bottom: 16),

                    decoration: BoxDecoration(

                      color: Theme.of(context)
                          .cardColor,

                      borderRadius:
                          BorderRadius.circular(
                              16),

                      boxShadow: const [

                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),

                      ],
                    ),

                    child: Row(
                      children: [

                        Icon(
                          Icons.school_outlined,
                          size: 28,
                          color:
                              Theme.of(context)
                                  .colorScheme
                                  .primary,
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Text(
                            name,
                            style:
                                const TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ),

                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color:
                              Theme.of(context)
                                  .colorScheme
                                  .primary,
                        ),

                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}