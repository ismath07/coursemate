import 'package:flutter/material.dart';
import 'staff_master_screen.dart';
import 'hall_master_screen.dart';
import 'year_dept_master_screen.dart';

class MasterDataScreen extends StatelessWidget {
  const MasterDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gradient = const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF0D1B6F), Color(0xFF880E4F)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Data Management', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 90,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(30))),
        flexibleSpace: Container(decoration: gradient),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildCard(
              context,
              icon: Icons.person_outlined,
              title: 'faculty Management',
              subtitle: 'Manage faculty records',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StaffMasterScreen())),
            ),
            const SizedBox(height: 16),
            _buildCard(
              context,
              icon: Icons.apartment_outlined,
              title: 'Hall Management',
              subtitle: 'Manage examination halls',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HallMasterScreen())),
            ),
            const SizedBox(height: 16),
            _buildCard(
              context,
              icon: Icons.school_outlined,
              title: 'Department Management',
              subtitle: 'Manage year and department records',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const YearDeptMasterScreen())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
        ),
        child: Row(
          children: [
            Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}
