import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../profile/profile_setup_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF141E30),
              Color(0xFF243B55),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    const Icon(
                      Icons.person_add_alt_1,
                      size: 60,
                      color: Colors.cyanAccent,
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      "Create Account",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // EMAIL FIELD
                    TextField(
                      controller: emailController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Email",
                        labelStyle:
                            const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor:
                            Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // PASSWORD FIELD
                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Password",
                        labelStyle:
                            const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor:
                            Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            setState(() {
                              obscurePassword =
                                  !obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // CREATE ACCOUNT BUTTON
                    isLoading
                        ? const CircularProgressIndicator()
                        : SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors.cyanAccent,
                                foregroundColor:
                                    Colors.black,
                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                          12),
                                ),
                              ),
                              onPressed: () async {
                                try {
                                  setState(() =>
                                      isLoading = true);

                                  await FirebaseAuth
                                      .instance
                                      .createUserWithEmailAndPassword(
                                    email:
                                        emailController.text
                                            .trim(),
                                    password:
                                        passwordController
                                            .text
                                            .trim(),
                                  );

                                  Navigator
                                      .pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ProfileSetupScreen(),
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(
                                          context)
                                      .showSnackBar(
                                    SnackBar(
                                      content:
                                          Text(e.toString()),
                                    ),
                                  );
                                } finally {
                                  setState(() =>
                                      isLoading = false);
                                }
                              },
                              child: const Text(
                                "Create Account",
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                        FontWeight.bold),
                              ),
                            ),
                          ),

                    const SizedBox(height: 15),

                    // BACK TO LOGIN
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Already have an account? Login",
                        style: TextStyle(
                            color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
