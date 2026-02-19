import 'package:admin/models/interpreters.dart';
import 'package:admin/responsive.dart';
import 'package:admin/screens/chat/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import '../../../constants.dart';

class AddInterpreterWidget extends StatefulWidget {
  const AddInterpreterWidget({Key? key}) : super(key: key);

  @override
  _AddInterpreterWidgetState createState() => _AddInterpreterWidgetState();
}

class _AddInterpreterWidgetState extends State<AddInterpreterWidget> {
  late Future<List<Interpreter>> _futureInterpreters;

  /// Signs up an interpreter with a random temporary password and sends
  /// a password-reset email so they can set their own password.
  Future<void> signupUser(
    BuildContext context,
    String email,
    String name,
    String district,
    String employer,
    String contact,
    String experience,
    String region,
  ) async {
    try {
      // Generate a random temporary password (the user will never use it)
      final tempPassword = _generateTempPassword();

      // Keep the current admin user so we can restore the session
      final adminUser = FirebaseAuth.instance.currentUser;

      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: tempPassword,
      );

      // Store interpreter data in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'name': name,
        'email': email,
        'district': district,
        'currentEmployer': employer,
        'contact': contact,
        'yearsOfExperience': experience,
        'role': 'interpreter',
        'region': region,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Send password reset email so the interpreter can set their own password
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      // Sign out the newly-created user (Firebase auto-signs-in new accounts)
      // and re-authenticate as admin if needed
      if (adminUser != null &&
          FirebaseAuth.instance.currentUser?.uid != adminUser.uid) {
        // The admin session may have been replaced – sign out the new user
        await FirebaseAuth.instance.signOut();
        // Note: admin needs to sign in again or use admin SDK in production
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Interpreter added! A password reset link has been sent to $email',
                    style: GoogleFonts.inter(fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: successColor,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 4),
          ),
        );
        // Refresh the interpreters list
        setState(() {
          _futureInterpreters = fetchInterpreters();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                    child: Text('Error: ${e.toString()}',
                        style: GoogleFonts.inter(fontSize: 13))),
              ],
            ),
            backgroundColor: dangerColor,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  String _generateTempPassword() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%';
    final rng = Random.secure();
    return List.generate(16, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  @override
  void initState() {
    super.initState();
    _futureInterpreters = fetchInterpreters();
  }

  Future<List<Interpreter>> fetchInterpreters() async {
    CollectionReference interpretersCollection =
        FirebaseFirestore.instance.collection('users');

    QuerySnapshot querySnapshot = await interpretersCollection
        .where('role', isEqualTo: 'interpreter')
        .get();

    List<Interpreter> interpreters = querySnapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return Interpreter(
        uid: doc.id,
        name: data['name'],
        email: data['email'],
        district: data['district'],
        currentEmployer: data['currentEmployer'],
        contact: data['contact'],
        yearsOfExperience: data['yearsOfExperience'],
        role: data['role'],
        region: data['region'],
      );
    }).toList();

    return interpreters;
  }

  Future<void> _startChatWithInterpreter(
      BuildContext context, Interpreter interpreter) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null || interpreter.uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Unable to start chat.'),
            backgroundColor: dangerColor),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: cardShadow,
              ),
              child: const CircularProgressIndicator(
                  color: primaryColor, strokeWidth: 3),
            ),
          );
        },
      );

      final chatsRef = FirebaseFirestore.instance.collection('chats');
      final query = await chatsRef
          .where('participants', arrayContains: currentUserId)
          .get();

      String? existingChatId;
      for (var doc in query.docs) {
        final participants = List<String>.from(doc['participants'] ?? []);
        if (participants.contains(interpreter.uid)) {
          existingChatId = doc.id;
          break;
        }
      }

      if (existingChatId == null) {
        final newChatRef = await chatsRef.add({
          'participants': [currentUserId, interpreter.uid],
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        existingChatId = newChatRef.id;
      }

      Navigator.of(context).pop();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatId: existingChatId!,
            recipientId: interpreter.uid!,
            recipientName:
                interpreter.name ?? interpreter.email ?? 'Interpreter',
          ),
        ),
      );
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error starting chat: ${e.toString()}'),
            backgroundColor: dangerColor),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Action bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: cardDecoration,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.interpreter_mode_rounded,
                        color: primaryColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  FutureBuilder<List<Interpreter>>(
                    future: _futureInterpreters,
                    builder: (context, snapshot) {
                      final count = snapshot.data?.length ?? 0;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "All Interpreters",
                            style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: darkTextColor),
                          ),
                          Text(
                            "$count total",
                            style: GoogleFonts.inter(
                                fontSize: 12, color: bodyTextColor),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  // Refresh button
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.refresh_rounded,
                          color: bodyTextColor, size: 20),
                      onPressed: () {
                        setState(() {
                          _futureInterpreters = fetchInterpreters();
                        });
                      },
                      tooltip: 'Refresh',
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(
                        horizontal: defaultPadding * 1.5,
                        vertical: defaultPadding /
                            (Responsive.isMobile(context) ? 2 : 1),
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _showSignupDialog(context),
                    icon: const Icon(Icons.person_add_rounded, size: 18),
                    label: Text("Add Interpreter",
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: defaultPadding),
        // Table
        Container(
          decoration: cardDecoration,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FutureBuilder<List<Interpreter>>(
                    future: _futureInterpreters,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(48),
                          child: Center(
                              child: CircularProgressIndicator(
                                  color: primaryColor, strokeWidth: 2)),
                        );
                      } else if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(48),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.error_outline,
                                    color: dangerColor, size: 40),
                                const SizedBox(height: 12),
                                Text('Error loading interpreters',
                                    style: GoogleFonts.inter(
                                        color: darkTextColor,
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(height: 4),
                                Text('${snapshot.error}',
                                    style: GoogleFonts.inter(
                                        color: bodyTextColor, fontSize: 12)),
                              ],
                            ),
                          ),
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(48),
                          child: Center(
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.people_outline,
                                      color: primaryColor, size: 36),
                                ),
                                const SizedBox(height: 16),
                                Text('No interpreters yet',
                                    style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: darkTextColor)),
                                const SizedBox(height: 4),
                                Text(
                                    'Add your first interpreter to get started',
                                    style: GoogleFonts.inter(
                                        fontSize: 13, color: bodyTextColor)),
                              ],
                            ),
                          ),
                        );
                      }

                      List<Interpreter> interpreters = snapshot.data!;
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: defaultPadding * 1.5,
                          headingRowHeight: 52,
                          dataRowMinHeight: 56,
                          dataRowMaxHeight: 56,
                          columns: [
                            DataColumn(
                                label: Text("Name",
                                    style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        color: bodyTextColor,
                                        fontSize: 13))),
                            DataColumn(
                                label: Text("Email",
                                    style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        color: bodyTextColor,
                                        fontSize: 13))),
                            DataColumn(
                                label: Text("Region",
                                    style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        color: bodyTextColor,
                                        fontSize: 13))),
                            DataColumn(
                                label: Text("District",
                                    style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        color: bodyTextColor,
                                        fontSize: 13))),
                            DataColumn(
                                label: Text("Employer",
                                    style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        color: bodyTextColor,
                                        fontSize: 13))),
                            DataColumn(
                                label: Text("Contact",
                                    style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        color: bodyTextColor,
                                        fontSize: 13))),
                            DataColumn(
                                label: Text("Experience",
                                    style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        color: bodyTextColor,
                                        fontSize: 13))),
                            DataColumn(
                                label: Text("Actions",
                                    style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        color: bodyTextColor,
                                        fontSize: 13))),
                          ],
                          rows: interpreters
                              .map((interpreter) =>
                                  _buildDataRow(context, interpreter))
                              .toList(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  DataRow _buildDataRow(BuildContext context, Interpreter interpreterInfo) {
    return DataRow(
      cells: [
        DataCell(
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: primaryColor.withOpacity(0.1),
                child: Text(
                  (interpreterInfo.name ?? 'U')[0].toUpperCase(),
                  style: GoogleFonts.inter(
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
              ),
              const SizedBox(width: 10),
              Text(interpreterInfo.name ?? '',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500, color: darkTextColor)),
            ],
          ),
        ),
        DataCell(Text(interpreterInfo.email ?? '',
            style: GoogleFonts.inter(color: darkTextColor, fontSize: 13))),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(interpreterInfo.region ?? '',
                style: GoogleFonts.inter(
                    color: primaryColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 12)),
          ),
        ),
        DataCell(Text(interpreterInfo.district ?? '',
            style: GoogleFonts.inter(color: darkTextColor, fontSize: 13))),
        DataCell(Text(interpreterInfo.currentEmployer ?? '',
            style: GoogleFonts.inter(color: darkTextColor, fontSize: 13))),
        DataCell(Text(interpreterInfo.contact ?? '',
            style: GoogleFonts.inter(color: darkTextColor, fontSize: 13))),
        DataCell(Text(interpreterInfo.yearsOfExperience ?? '',
            style: GoogleFonts.inter(color: darkTextColor, fontSize: 13))),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Tooltip(
                message: 'Chat with interpreter',
                child: Container(
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.chat_bubble_outline_rounded,
                        color: primaryColor, size: 18),
                    onPressed: () =>
                        _startChatWithInterpreter(context, interpreterInfo),
                    constraints:
                        const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: const EdgeInsets.all(6),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Tooltip(
                message: 'Send password reset link',
                child: Container(
                  decoration: BoxDecoration(
                    color: warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.lock_reset_rounded,
                        color: warningColor, size: 18),
                    onPressed: () => _sendPasswordResetEmail(
                        context, interpreterInfo.email ?? ''),
                    constraints:
                        const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: const EdgeInsets.all(6),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Tooltip(
                message: 'Delete interpreter',
                child: Container(
                  decoration: BoxDecoration(
                    color: dangerColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: dangerColor, size: 18),
                    onPressed: () =>
                        _showDeleteInterpreterDialog(context, interpreterInfo),
                    constraints:
                        const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: const EdgeInsets.all(6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _sendPasswordResetEmail(
      BuildContext context, String email) async {
    if (email.isEmpty) return;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.email_outlined, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                    child: Text('Password reset link sent to $email',
                        style: GoogleFonts.inter(fontSize: 13))),
              ],
            ),
            backgroundColor: successColor,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending reset link: ${e.toString()}'),
            backgroundColor: dangerColor,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _showDeleteInterpreterDialog(
      BuildContext context, Interpreter interpreter) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: dangerColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: dangerColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Delete Interpreter',
                  style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: darkTextColor)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete "${interpreter.name}"?',
              style: GoogleFonts.inter(fontSize: 14, color: bodyTextColor),
            ),
            const SizedBox(height: 8),
            Text(
              'This will remove the interpreter from the system. This action cannot be undone.',
              style: GoogleFonts.inter(fontSize: 12, color: bodyTextColor),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child:
                Text('Cancel', style: GoogleFonts.inter(color: bodyTextColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: dangerColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              _deleteInterpreter(interpreter);
            },
            child: Text('Delete',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteInterpreter(Interpreter interpreter) async {
    if (interpreter.uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: Interpreter ID not found',
              style: GoogleFonts.inter()),
          backgroundColor: dangerColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    try {
      // Delete interpreter document from Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(interpreter.uid)
          .delete();

      // Clean up related notifications
      final notifs = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: interpreter.uid)
          .get();
      for (var doc in notifs.docs) {
        await doc.reference.delete();
      }

      // Refresh the list
      setState(() {
        _futureInterpreters = fetchInterpreters();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('${interpreter.name} has been deleted',
                    style: GoogleFonts.inter()),
              ],
            ),
            backgroundColor: successColor,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting interpreter: $e',
                style: GoogleFonts.inter()),
            backgroundColor: dangerColor,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _showSignupDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final emailController = TextEditingController();
    final nameController = TextEditingController();
    final districtController = TextEditingController();
    final employerController = TextEditingController();
    final contactController = TextEditingController();
    final experienceController = TextEditingController();
    String selectedRegion = 'Northern';
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              backgroundColor: secondaryColor,
              child: Container(
                width: 500,
                padding: const EdgeInsets.all(32),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.person_add_rounded,
                                  color: primaryColor, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Add Interpreter',
                                      style: GoogleFonts.inter(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: darkTextColor)),
                                  const SizedBox(height: 2),
                                  Text(
                                    'A password reset link will be sent to their email',
                                    style: GoogleFonts.inter(
                                        fontSize: 12, color: bodyTextColor),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close,
                                  color: bodyTextColor, size: 20),
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Info banner about password reset
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: infoColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border:
                                Border.all(color: infoColor.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline,
                                  color: infoColor, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'The interpreter will receive an email with a link to set their password and access the platform.',
                                  style: GoogleFonts.inter(
                                      fontSize: 12, color: darkTextColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Form fields
                        _buildDialogField(
                            'Full Name', nameController, Icons.person_outline,
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null),
                        _buildDialogField('Email Address', emailController,
                            Icons.email_outlined,
                            validator: (v) => v == null ||
                                    !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)
                                ? 'Valid email required'
                                : null),
                        _buildDialogDropdown('Region', selectedRegion,
                            ['Northern', 'Central', 'Western', 'Eastern'],
                            onChanged: (v) =>
                                setDialogState(() => selectedRegion = v!)),
                        _buildDialogField('District', districtController,
                            Icons.location_on_outlined),
                        _buildDialogField('Current Employer',
                            employerController, Icons.business_outlined),
                        _buildDialogField('Phone Contact', contactController,
                            Icons.phone_outlined,
                            keyboardType: TextInputType.phone),
                        _buildDialogField('Years of Experience',
                            experienceController, Icons.timeline_outlined,
                            keyboardType: TextInputType.number),
                        const SizedBox(height: 24),
                        // Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: bodyTextColor,
                                  side: const BorderSide(color: borderColor),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                                child: Text('Cancel',
                                    style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w500)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: isSubmitting
                                    ? null
                                    : () async {
                                        if (formKey.currentState!.validate()) {
                                          setDialogState(
                                              () => isSubmitting = true);
                                          await signupUser(
                                            context,
                                            emailController.text.trim(),
                                            nameController.text.trim(),
                                            districtController.text.trim(),
                                            employerController.text.trim(),
                                            contactController.text.trim(),
                                            experienceController.text.trim(),
                                            selectedRegion,
                                          );
                                          Navigator.of(dialogContext).pop();
                                        }
                                      },
                                icon: isSubmitting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white))
                                    : const Icon(Icons.send_rounded, size: 18),
                                label: Text(
                                  isSubmitting
                                      ? 'Adding...'
                                      : 'Add & Send Link',
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDialogField(
    String label,
    TextEditingController controller,
    IconData icon, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: darkTextColor)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            style: GoogleFonts.inter(fontSize: 14, color: darkTextColor),
            decoration: InputDecoration(
              prefixIcon:
                  Icon(icon, size: 18, color: bodyTextColor.withOpacity(0.5)),
              hintText: 'Enter $label',
              hintStyle: GoogleFonts.inter(
                  fontSize: 13, color: bodyTextColor.withOpacity(0.4)),
              fillColor: bgColor,
              filled: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: borderColor)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: borderColor)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: primaryColor, width: 2)),
              errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: dangerColor)),
            ),
            validator: validator,
          ),
        ],
      ),
    );
  }

  Widget _buildDialogDropdown(String label, String value, List<String> items,
      {required ValueChanged<String?> onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: darkTextColor)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: value,
            style: GoogleFonts.inter(fontSize: 14, color: darkTextColor),
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.map_outlined,
                  size: 18, color: bodyTextColor.withOpacity(0.5)),
              fillColor: bgColor,
              filled: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: borderColor)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: borderColor)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: primaryColor, width: 2)),
            ),
            items: items
                .map((String v) =>
                    DropdownMenuItem<String>(value: v, child: Text(v)))
                .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
