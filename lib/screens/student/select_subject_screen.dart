import 'package:flutter/material.dart';
import 'student_home_screen.dart';
import 'view_syllabus_screen.dart';

class SelectSubjectScreen extends StatelessWidget {
  final String courseTitle;
  final int semester;
  final String? degreeLevel;

  const SelectSubjectScreen({
    super.key,
    required this.courseTitle,
    required this.semester,
    this.degreeLevel,
  });

  List<Map<String, String>> _subjectsFor(String course, int sem) {
    // Example: BA TAM subjects by semester
    if (course == 'BA TAM') {
      switch (sem) {
        case 1:
          return [
            {'name': 'Tamil Ilakkiya Varalaru – I', 'code': '23LGT1'},
            {'name': 'General English', 'code': '23ELGE1'},
            {'name': 'Ikkala Ilakkiyam – Kavithaiyum Urai Nadaiyum', 'code': '22ACCTA1'},
            {'name': 'Nannul – Ezhuthathikaram', 'code': '22ACCTA2'},
            {'name': 'Tamil Ilakkiya Varalaru', 'code': '22AFACTA1'},
            {'name': 'Value Education', 'code': '22UGVED'},
          ];
        case 2:
          return [
            {'name': 'Tamil Ilakkiya Varalaru – II', 'code': '23LGT2'},
            {'name': 'General English', 'code': '23ELGE2'},
            {'name': 'Chittrilakkiyam', 'code': '22ACCTA3'},
            {'name': 'Nannul – Sollathikaram', 'code': '22ACCTA4'},
            {'name': 'Tamilaka Varalar, um Makkal Panpadum', 'code': '22AFACTA2'},
            {'name': 'Environmental Studies', 'code': '22UGCES'},
            {'name': 'Professional English – I', 'code': '22PELPS1'},
          ];
        case 3:
          return [
            {'name': 'Tamilaga Varalarum Panpadum', 'code': '23LGT3'},
            {'name': 'General English', 'code': '23ELGE3'},
            {'name': 'Samaya Ilakkiyam', 'code': '22ACCTA5'},
            {'name': 'Nambiyakapporul & Purapporul Venba Maalai', 'code': '22ACCTA6'},
            {'name': 'Tourism', 'code': '22ASACTA1'},
            {'name': 'Nutrition for Health and Fitness', 'code': '22SNMEND1'},
            {'name': 'Professional English – II', 'code': '22PELPS2'},
          ];
        case 4:
          return [
            {'name': 'Tamilum Ariviyalum', 'code': '23LGT4'},
            {'name': 'General English', 'code': '23ELGE4'},
            {'name': 'Kappiyam', 'code': '22ACCTA7'},
            {'name': 'Ikkala Tamil Ilakkanam', 'code': '22ACCTA8'},
            {'name': 'Tamilaka Koyil Kalaiyum Nirvakamum', 'code': '22ASACTA2'},
            {'name': 'Nutrition for Women', 'code': '22SNMEND2'},
          ];
        case 5:
          return [
            {'name': 'Neethi Ilakkiyam', 'code': '22ACCTA9'},
            {'name': 'Oppilakkiyam', 'code': '22ACCTA10'},
            {'name': 'Yapperunkalakariakai & Thandiyalangaram', 'code': '22ACCDTA11'},
            {'name': 'Mozhiyiyal', 'code': '22ACCTA12'},
            {'name': 'Chitharilakkiyam', 'code': '22AMBETA2'},
            {'name': 'Padippilakkiyam', 'code': '22ASBETA1'},
            {'name': 'Soft Skills Development', 'code': '22UGSDC'},
          ];
        case 6:
          return [
            {'name': 'Sanga Ilakkiyam', 'code': '22ACCTA13'},
            {'name': 'Molipeyarppiyal', 'code': '22ACCTA14'},
            {'name': 'Tamilin Semmozhi Panpukal', 'code': '22ACCTA15'},
            {'name': 'Kalvett iyal', 'code': '22AMBETA3'},
            {'name': 'Project', 'code': '22ATAPW'},
            {'name': 'Ithazhiyal', 'code': '22ASBETA2'},
            {'name': 'Gender Studies', 'code': '22UGGS'},
          ];
      }
    }

    // Generic sample subjects for other courses
    return [
      {'name': 'Core Theory', 'code': 'SUBJ101'},
      {'name': 'Practical / Lab', 'code': 'SUBJ102'},
      {'name': 'Elective - I', 'code': 'SUBJ103'},
      {'name': 'Value Education', 'code': 'SUBJ104'},
      {'name': 'Skill Development', 'code': 'SUBJ105'},
    ];
  }

  @override
  Widget build(BuildContext context) {
    final subjects = _subjectsFor(courseTitle, semester);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Select Subject', style: TextStyle(color: Colors.white)),
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
        child: ListView.separated(
          itemCount: subjects.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final subject = subjects[index];
            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StudentViewSyllabusScreen(
                      subjectTitle: subject['name'] ?? '',
                      subjectCode: subject['code'] ?? '',
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.menu_book_outlined, size: 28, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject['name'] ?? '',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subject['code'] ?? '',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).colorScheme.primary),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
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

