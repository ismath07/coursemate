import 'package:flutter/material.dart';
import 'get_started_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool _obscurePassword = true;
  String? role; // Student / Staff

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [

          // 🔷 TOP GRADIENT (SAME AS LOGIN)
          Container(
            height: height * 0.35,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0D1B6F),
                  Color(0xFF880E4F),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          SingleChildScrollView(
            child: SizedBox(
              height: height,
              child: Column(
                children: [

                  const SizedBox(height: 30),

                  // 🔙 BACK BUTTON
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 🔤 TITLE
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontFamily: 'Lexend Deca',
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Sign up to get started',
                    style: TextStyle(color: Colors.white70),
                  ),

                  const SizedBox(height: 35),

                  // ⚪ WHITE CONTAINER
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(28, 40, 28, 30),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(45),
                          topRight: Radius.circular(45),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          _field('Name', 'Enter your name'),
                          _field('Email Address', 'Enter your email'),

                          // 🔐 PASSWORD FIELD
                          const Text(
                            'Password',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            obscureText: _obscurePassword,
                            decoration: _input(
                              hint: '••••••••',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // 🔽 ROLE SELECTION
                          const Text(
                            'Staff / Student',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: role,
                            items: const [
                              DropdownMenuItem(
                                value: 'Student',
                                child: Text('Student'),
                              ),
                              DropdownMenuItem(
                                value: 'Staff',
                                child: Text('Staff'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                role = value;
                              });
                            },
                            decoration: _input(hint: 'Select role'),
                          ),

                          const SizedBox(height: 30),

                          // 🔵 SIGN UP BUTTON (ROLE PASSED HERE)
                          Material(
                            color: const Color(0xFF0D1B6F),
                            borderRadius: BorderRadius.circular(18),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              splashColor: Colors.white24,
                              onTap: () {
                                if (role == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Please select Student or Staff'),
                                    ),
                                  );
                                  return;
                                }

                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        GetStartedScreen(role: role!),
                                  ),
                                );
                              },
                              child: Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                alignment: Alignment.center,
                                child: const Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Already have an account? "),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    color: Colors.indigo,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 COMMON TEXT FIELD
  Widget _field(String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        TextField(
          decoration: _input(hint: hint),
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  // 🔹 INPUT DECORATION
  static InputDecoration _input({String? hint, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      suffixIcon: suffixIcon,
    );
  }
}