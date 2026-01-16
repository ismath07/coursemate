import 'package:flutter/material.dart';

class AdminPanel extends StatelessWidget {
  const AdminPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Title (use AppBar gradient only; keep body non-gradient)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Admin Panel',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ),
          ),

          // Extra admin action bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: Theme.of(context).cardColor,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _adminAction(context, Icons.announcement, 'Announcements'),
                  const SizedBox(width: 8),
                  _adminAction(context, Icons.book_online, 'Manage Courses'),
                  const SizedBox(width: 8),
                  _adminAction(context, Icons.people, 'Users'),
                  const SizedBox(width: 8),
                  _adminAction(context, Icons.settings, 'Settings'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  _panelCard(context, 'System Logs', 'View recent system activity'),
                  const SizedBox(height: 12),
                  _panelCard(context, 'Course Approvals', 'Approve or reject course changes'),
                  const SizedBox(height: 12),
                  _panelCard(context, 'User Reports', 'Review flagged users or content'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _adminAction(BuildContext context, IconData icon, String label) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      onPressed: () {},
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }

  Widget _panelCard(BuildContext context, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyMedium?.color)),
                const SizedBox(height: 6),
                Text(subtitle, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
            onPressed: () {},
            child: const Text('Open'),
          )
        ],
      ),
    );
  }
}
