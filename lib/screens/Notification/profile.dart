// Create a new file: notification/admin_profile_screen.dart
import 'package:admin/screens/auth/login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants.dart';
import '../../responsive.dart';
import '../dashboard/components/header.dart';
import '../main/components/side_menu.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({Key? key}) : super(key: key);

  @override
  _AdminProfileScreenState createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data()!;
          setState(() {
            _nameController.text = data['name'] ?? '';
            _emailController.text = user.email ?? '';
          });
        }
      }
    } catch (e) {
      // Handle error
      print('Error loading profile: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      drawer: Responsive.isDesktop(context)
          ? null
          : const Drawer(child: SideMenu()),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: primaryColor, strokeWidth: 2))
          : SafeArea(
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (Responsive.isDesktop(context))
                  const SizedBox(width: 260, child: SideMenu()),
                Expanded(
                  flex: 5,
                  child: SafeArea(
                    child: SingleChildScrollView(
                      primary: false,
                      padding: EdgeInsets.all(defaultPadding * 1.5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Header(title: ''),
                          SizedBox(height: defaultPadding),
                          Text(
                            "Admin Profile",
                            style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: darkTextColor),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "View and manage your account",
                            style: GoogleFonts.inter(
                                fontSize: 14, color: bodyTextColor),
                          ),
                          SizedBox(height: defaultPadding),
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 500),
                              child: Container(
                                padding: const EdgeInsets.all(32),
                                decoration: cardDecoration,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Center(
                                      child: CircleAvatar(
                                        radius: 50,
                                        backgroundColor:
                                            primaryColor.withOpacity(0.1),
                                        child: const Icon(Icons.person,
                                            size: 50, color: primaryColor),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      'Personal Information',
                                      style: GoogleFonts.inter(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: darkTextColor),
                                    ),
                                    const SizedBox(height: 16),
                                    Text('Name',
                                        style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: darkTextColor)),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: _nameController,
                                      readOnly: true,
                                      style: GoogleFonts.inter(
                                          color: darkTextColor),
                                      decoration: InputDecoration(
                                        prefixIcon: const Icon(
                                            Icons.person_outline,
                                            size: 18,
                                            color: bodyTextColor),
                                        fillColor: bgColor,
                                        filled: true,
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            borderSide: const BorderSide(
                                                color: borderColor)),
                                        enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            borderSide: const BorderSide(
                                                color: borderColor)),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text('Email',
                                        style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: darkTextColor)),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: _emailController,
                                      readOnly: true,
                                      style: GoogleFonts.inter(
                                          color: darkTextColor),
                                      decoration: InputDecoration(
                                        prefixIcon: const Icon(
                                            Icons.email_outlined,
                                            size: 18,
                                            color: bodyTextColor),
                                        fillColor: bgColor,
                                        filled: true,
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            borderSide: const BorderSide(
                                                color: borderColor)),
                                        enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            borderSide: const BorderSide(
                                                color: borderColor)),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: dangerColor,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 16),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                          elevation: 0,
                                        ),
                                        onPressed: () {
                                          FirebaseAuth.instance.signOut();
                                          Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      LoginPage()));
                                        },
                                        icon: const Icon(Icons.logout_rounded,
                                            size: 18),
                                        label: Text('Sign Out',
                                            style: GoogleFonts.inter(
                                                fontWeight: FontWeight.w600)),
                                      ),
                                    ),
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
              ]),
            ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
