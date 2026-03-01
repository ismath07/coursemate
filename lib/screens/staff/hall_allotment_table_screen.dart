import 'package:flutter/material.dart';
import 'view_hall_allotment_screen.dart';

class HallAllotmentTableScreen extends StatelessWidget {
  const HallAllotmentTableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Directly navigate to ViewHallAllotmentScreen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const StaffViewHallAllotmentScreen(),
        ),
      );
    });

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
