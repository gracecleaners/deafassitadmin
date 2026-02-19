import 'package:admin/screens/main/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants.dart';
import '../../utils/form_validator.dart';
import 'authService.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _auth = AuthService();
  bool _isObscure = true;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void _signIn(String email, String password) async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      AuthService authService = AuthService();
      String? role = await authService.signInAndFetchRole(email, password);

      if (role != null) {
        if (role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Access denied. Admin accounts only."),
              backgroundColor: dangerColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("User not found."),
            backgroundColor: dangerColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Login failed: ${e.toString().replaceAll('Exception: ', '')}"),
          backgroundColor: dangerColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo area
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: sidebarGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.sign_language, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 24),
              Text(
                'Deaf Assist',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: darkTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Admin Dashboard',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: bodyTextColor,
                ),
              ),
              const SizedBox(height: 40),
              // Login Card
              Container(
                width: 420,
                padding: const EdgeInsets.all(36),
                decoration: BoxDecoration(
                  color: secondaryColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Welcome back",
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: darkTextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Enter your credentials to access the admin panel",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: bodyTextColor,
                        ),
                      ),
                      const SizedBox(height: 28),
                      // Email
                      Text(
                        "Email",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: darkTextColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: emailController,
                        style: GoogleFonts.inter(fontSize: 14, color: darkTextColor),
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.email_outlined, color: bodyTextColor.withOpacity(0.5), size: 20),
                          hintText: 'admin@example.com',
                          hintStyle: GoogleFonts.inter(color: bodyTextColor.withOpacity(0.4)),
                          fillColor: bgColor,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: primaryColor, width: 2),
                          ),
                        ),
                        validator: FormValidator.validateEmail,
                      ),
                      const SizedBox(height: 20),
                      // Password
                      Text(
                        "Password",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: darkTextColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: passwordController,
                        style: GoogleFonts.inter(fontSize: 14, color: darkTextColor),
                        obscureText: _isObscure,
                        decoration: InputDecoration(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: bodyTextColor.withOpacity(0.5),
                              size: 20,
                            ),
                            onPressed: () => setState(() => _isObscure = !_isObscure),
                          ),
                          prefixIcon: Icon(Icons.lock_outline, color: bodyTextColor.withOpacity(0.5), size: 20),
                          hintText: 'Enter your password',
                          hintStyle: GoogleFonts.inter(color: bodyTextColor.withOpacity(0.4)),
                          fillColor: bgColor,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: primaryColor, width: 2),
                          ),
                        ),
                        validator: FormValidator.validatePassword,
                      ),
                      const SizedBox(height: 28),
                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isLoading ? null : () => _signIn(emailController.text, passwordController.text),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22, height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  "Sign In",
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "© 2026 Deaf Assist. All rights reserved.",
                style: GoogleFonts.inter(fontSize: 12, color: bodyTextColor.withOpacity(0.5)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
