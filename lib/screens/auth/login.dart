import 'package:admin/screens/main/main_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../const/app_colors.dart';
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
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController forgotPasswordEmailController =
  TextEditingController();

  void _signIn(String email, String password) async {
    try {
      AuthService authService = AuthService();
      String? role = await authService.signInAndFetchRole(email, password);

      if (role != null) {
        if (role == 'admin') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MainScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("There is no such user"))
          );
        }
      } else {
        // Handle missing role scenario
        print("Role not found for user.");
      }
    } catch (e) {
      print("Error: $e");
      // Show error to the user
    }
  }

  @override
  Widget build(BuildContext context) {
    final ht = MediaQuery.of(context).size.height;
    final wd = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'ADMINISTRATOR',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 30.0, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  width: wd * 0.45, // Adjusted width to be 85% of screen width
                  constraints: BoxConstraints(maxHeight: ht * 0.5), // Limited height to 50% of screen
                  decoration: const BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.all(Radius.circular(25)),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: const Text(
                              "Welcome",
                              style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.normal,
                                  color: Colors.white
                              ),
                            ),
                          ),
                          const SizedBox(height: 20.0),
                          _buildEmailField(),
                          const SizedBox(height: 20.0),
                          _buildPasswordField(),
                          const SizedBox(height: 24.0),
                          _buildLoginButton(context),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: emailController,
      style: TextStyle(color: Colors.black),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.email),
        hintText: 'Email',
        filled: true,
        fillColor: AppColors.backgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      validator: FormValidator.validateEmail,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: passwordController,
      style: TextStyle(color: Colors.black),
      obscureText: _isObscure,
      decoration: InputDecoration(
        suffixIcon: IconButton(
          icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility),
          onPressed: () {
            setState(() {
              _isObscure = !_isObscure;
            });
          },
        ),
        prefixIcon: const Icon(Icons.lock),
        hintText: 'Password',
        filled: true,
        fillColor: AppColors.backgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      validator: FormValidator.validatePassword,
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonColor,
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
        onPressed: () {
          // _loginController.signIn(
          //   context,
          //   emailController.text,
          //   passwordController.text,
          //   _formKey,
          // );
          _signIn(emailController.text, passwordController.text);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: const Text(
            "LOGIN",
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
          ),
        ),
      ),
    );
  }

}
