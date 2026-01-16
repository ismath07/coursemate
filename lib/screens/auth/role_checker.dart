import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../staff/staff_home_screen.dart';
import '../student/student_home_screen.dart';
import 'login_screen.dart';

class RoleChecker extends StatelessWidget {
  const RoleChecker({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // 🔴 If user not logged in → go to Login
    if (user == null) {
      return const LoginScreen();
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get(),
      builder: (context, snapshot) {
        // 🔄 Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ❌ If document not found or error
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const LoginScreen();
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;

        // ✅ DEFENSIVE FIX: normalize role
        final String role =
            (data['role'] ?? '').toString().toLowerCase();

        // 🧪 DEBUG LOG (keep while testing)
        debugPrint('LOGGED IN ROLE => $role');

        // 🔐 ROLE BASED ROUTING
        if (role == 'staff') {
          return const StaffHomeScreen();
        } else {
          return const StudentHomeScreen();
        }
      },
    );
  }
}
