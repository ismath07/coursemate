import 'package:flutter/material.dart';
import 'select_degree_timetable_screen.dart';

class StaffTimetableHome extends StatelessWidget {
  const StaffTimetableHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),

          Text(
            'Select Timetable Type',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),

          const SizedBox(height: 20),

          _card(
            context,
            icon: Icons.description_outlined,
            title: 'Exam Timetable',
            subtitle: 'View UG / PG exam schedule',
            onTap: () {
              // TODO: Navigate to Exam Timetable
            },
          ),

          const SizedBox(height: 16),

          _card(
            context,
            icon: Icons.apartment_outlined,
            title: 'Hall Allotment',
            subtitle: 'Check exam hall details',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SelectDegreeTimetableStaffScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, {
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
            Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
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
