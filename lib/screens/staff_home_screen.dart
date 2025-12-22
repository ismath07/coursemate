import 'package:flutter/material.dart';

class StaffHomeScreen extends StatelessWidget {
  const StaffHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // 🔹 APP BAR HEADER
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Transparent to show gradient
        elevation: 0,
        title: const Text(
          'Select Degree Level',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white, // White title text
          ),
        ),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
        toolbarHeight: 90,

        // 🔹 Gradient Background
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0D1B6F), // Dark Blue
                Color(0xFF880E4F), // Dark Pink
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(30),
            ),
          ),
        ),

        // 🔹 Back button color
        iconTheme: const IconThemeData(
          color: Colors.white, // White back button
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              'Welcome, Staff',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0D1B6F),
              ),
            ),

            const SizedBox(height: 30),

            _card(
              icon: Icons.school_outlined,
              title: 'Undergraduate',
            ),

            const SizedBox(height: 16),

            _card(
              icon: Icons.workspace_premium_outlined,
              title: 'Postgraduate',
            ),

            const SizedBox(height: 16),

            // 🔹 Extra Diploma Card with Certificate Icon
            _card(
              icon: Icons.assignment_outlined, // Certificate-style icon
              title: 'Diploma',
            ),
          ],
        ),
      ),

      // 🔻 BOTTOM DASHBOARD
      bottomNavigationBar: _staffBottomBar(),
    );
  }

  Widget _card({required IconData icon, required String title}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Icon(icon, size: 28, color: const Color(0xFF0D1B6F)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    );
  }

  Widget _staffBottomBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF0D1B6F),
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
    );
  }
}