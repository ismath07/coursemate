import 'package:flutter/material.dart';
import 'select_department_exam_timetable_screen.dart';

class SelectSemesterExamTimetableScreen extends StatelessWidget {
  final String degreeId;
  final String degreeName;

  const SelectSemesterExamTimetableScreen({
    super.key,
    required this.degreeId,
    required this.degreeName,
  });

  static const _appBarGradient = BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFF0D1B6F), Color(0xFF880E4F)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(degreeName, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 90,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
        flexibleSpace: Container(decoration: _appBarGradient),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Text(
              'Select Semester',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            _semesterCard(
              context,
              label: 'ODD SEMESTER',
              subtitle: 'I, III, V Semester',
              icon: Icons.filter_1_outlined,
              semesterType: 'ODD',
            ),
            const SizedBox(height: 16),
            _semesterCard(
              context,
              label: 'EVEN SEMESTER',
              subtitle: 'II, IV, VI Semester',
              icon: Icons.filter_2_outlined,
              semesterType: 'EVEN',
            ),
          ],
        ),
      ),
    );
  }

  Widget _semesterCard(
    BuildContext context, {
    required String label,
    required String subtitle,
    required IconData icon,
    required String semesterType,
  }) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SelectDepartmentExamTimetableScreen(
            degreeId: degreeId,
            degreeName: degreeName,
            semesterType: semesterType,
          ),
        ),
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 16, color: Theme.of(context).colorScheme.primary),
          ],
        ),
      ),
    );
  }
}
