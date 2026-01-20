import 'package:flutter/material.dart';
import 'timetable_home_screen.dart';
import 'select_course_screen.dart';
import 'select_course_postgrad_screen.dart';
import 'select_course_diploma_screen.dart';
import '../../services/firestore_service.dart';
import 'staff_profile_screen.dart';
import 'admin_panel.dart';

class StaffHomeScreen extends StatefulWidget {
  final int initialIndex;
  const StaffHomeScreen({super.key, this.initialIndex = 0});

  @override
  State<StaffHomeScreen> createState() => _StaffHomeScreenState();
}

class _StaffHomeScreenState extends State<StaffHomeScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  List<Widget> get _pages => [
        StreamBuilder<List<Map<String, String>>>(
          stream: FirestoreService().getDegreeLevels(),
          builder: (context, snapshot) {
            final levels = snapshot.data ?? const [];
            String ugName = 'Undergraduate';
            String pgName = 'Postgraduate';
            String dipName = 'Diploma';
            for (final lvl in levels) {
              if (lvl['id'] == 'UG') ugName = lvl['displayName'] ?? ugName;
              if (lvl['id'] == 'PG') pgName = lvl['displayName'] ?? pgName;
              if (lvl['id'] == 'DIP') dipName = lvl['displayName'] ?? dipName;
            }
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Welcome, Staff',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      _card(
                        context,
                        icon: Icons.school_outlined,
                        title: ugName,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const SelectCourseScreen()));
                        },
                      ),
                      const SizedBox(height: 16),
                      _card(
                        context,
                        icon: Icons.workspace_premium_outlined,
                        title: pgName,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const SelectCoursePostgradScreen()));
                        },
                      ),
                      const SizedBox(height: 16),
                      _card(
                        context,
                        icon: Icons.assignment_outlined,
                        title: dipName,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const SelectCourseDiplomaScreen()));
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        const StaffTimetableHome(),
        const AdminPanel(),
        const StaffProfileScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      // 🔹 APP BAR HEADER
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _currentIndex == 0
              ? 'Select Degree Level'
              : _currentIndex == 1
                  ? 'Timetable'
                  : _currentIndex == 2
                      ? 'Admin'
                      : 'Profile',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
        toolbarHeight: 90,
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

      // body switches based on tab
      body: IndexedStack(index: _currentIndex, children: _pages),

      // bottom navigation
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), label: 'Syllabus'),
          BottomNavigationBarItem(icon: Icon(Icons.schedule_outlined), label: 'Timetable'),
          BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings_outlined), label: 'Admin'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, {required IconData icon, required String title, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
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
            Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).colorScheme.primary),
          ],
        ),
      ),
    );
  }
}
