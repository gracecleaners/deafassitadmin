import 'package:admin/models/interpreters.dart';
import 'package:admin/responsive.dart';
import 'package:admin/screens/chat/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// For generating unique codes
import '../../../constants.dart';

class AddInterpreterWidget extends StatefulWidget {
  const AddInterpreterWidget({Key? key}) : super(key: key);

  @override
  _AddInterpreterWidgetState createState() => _AddInterpreterWidgetState();
}

class _AddInterpreterWidgetState extends State<AddInterpreterWidget> {
  late Future<List<Interpreter>> _futureInterpreters;
  Future<void> signupUser(
    BuildContext context,
    String email,
    String password,
    String name,
    String district,
    String employer,
    String contact,
    String experience,
    String region, // New parameter
  ) async {
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // send password reset email
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

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
        'region': region, // New field
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign up successful!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _futureInterpreters = fetchInterpreters(); // Fetch interpreters data
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
          uid: doc.id, // Add this line
          name: data['name'],
          email: data['email'],
          district: data['district'],
          currentEmployer: data['currentEmployer'],
          contact: data['contact'],
          yearsOfExperience: data['yearsOfExperience'],
          role: data['role'],
          region: data['region']);
    }).toList();

    return interpreters;
  }

// Update the DataRow to properly display all fields
  DataRow recentFileDataRow(BuildContext context, Interpreter interpreterInfo) {
    return DataRow(
      cells: [
        DataCell(Text(interpreterInfo.name ?? '')),
        DataCell(Text(interpreterInfo.email ?? '')),
        DataCell(Text(interpreterInfo.region ?? '')),
        DataCell(Text(interpreterInfo.district ?? '')),
        DataCell(Text(interpreterInfo.currentEmployer ?? '')),
        DataCell(Text(interpreterInfo.contact ?? '')),
        DataCell(Text(interpreterInfo.yearsOfExperience ?? '')),
        DataCell(Text(interpreterInfo.role ?? '')),
        DataCell(
          IconButton(
            icon: Icon(Icons.chat),
            onPressed: () {
              _startChatWithInterpreter(context, interpreterInfo);
            },
          ),
        ),
      ],
    );
  }

 Future<void> _startChatWithInterpreter(BuildContext context, Interpreter interpreter) async {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  if (currentUserId == null || interpreter.uid == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Unable to start chat. Please try again.')),
    );
    return;
  }

  try {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(child: CircularProgressIndicator());
      },
    );

    // Check if a chat already exists between admin and this interpreter
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

    // If no existing chat, create one
    if (existingChatId == null) {
      final newChatRef = await chatsRef.add({
        'participants': [currentUserId, interpreter.uid],
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      existingChatId = newChatRef.id;
    }

    // Close loading dialog
    Navigator.of(context).pop();

    // Navigate to chat screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatId: existingChatId!, // Now we're sure this has a value
          recipientId: interpreter.uid!, 
          recipientName: interpreter.name ?? interpreter.email ?? 'Interpreter',
        ),
      ),
    );
  } catch (e) {
    // Close loading dialog if open
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error starting chat: ${e.toString()}')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    final Size _size = MediaQuery.of(context).size;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Interpreters",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            ElevatedButton.icon(
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: defaultPadding * 1.5,
                  vertical:
                      defaultPadding / (Responsive.isMobile(context) ? 2 : 1),
                ),
              ),
              onPressed: () {
                _showSignupDialog(context);
              },
              icon: Icon(Icons.add),
              label: Text("Add Interpreter"),
            ),
          ],
        ),
        SizedBox(height: defaultPadding),
        Container(
          padding: EdgeInsets.all(defaultPadding),
          decoration: BoxDecoration(
            color: secondaryColor,
            borderRadius: const BorderRadius.all(Radius.circular(10)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: FutureBuilder<List<Interpreter>>(
                  future: _futureInterpreters,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text('No Interpreters available.'));
                    }

                    // If we have data, build the DataTable
                    List<Interpreter> interpreters = snapshot.data!;
                    return DataTable(
                      columnSpacing: defaultPadding,
                      columns: [
                        DataColumn(label: Text("Name")),
                        DataColumn(label: Text("Email")),
                        DataColumn(label: Text("Region")),
                        DataColumn(label: Text("District")),
                        DataColumn(label: Text("Current Employer")),
                        DataColumn(label: Text("Contact")),
                        DataColumn(label: Text("Years of Experience")),
                        DataColumn(label: Text("Role")),
                        DataColumn(label: Text("Chat")), // Add this column
                      ],
                      rows: interpreters
                          .map((interpreter) => recentFileDataRow(
                              context, interpreter)) // Pass context here
                          .toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showSignupDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final nameController = TextEditingController();
    final districtController = TextEditingController();
    final employerController = TextEditingController();
    final contactController = TextEditingController();
    final experienceController = TextEditingController();
    String selectedRegion = 'Northern'; // Default value

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Sign Up'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: 'Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(labelText: 'Email'),
                    validator: (value) {
                      if (value == null ||
                          !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: passwordController,
                    decoration: InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  DropdownButtonFormField<String>(
                    value: selectedRegion,
                    decoration: InputDecoration(labelText: 'Region'),
                    items: ['Northern', 'Central', 'Western', 'Eastern']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      selectedRegion = newValue!;
                    },
                  ),
                  TextFormField(
                    controller: districtController,
                    decoration: InputDecoration(labelText: 'District'),
                  ),
                  TextFormField(
                    controller: employerController,
                    decoration: InputDecoration(labelText: 'Current Employer'),
                  ),
                  TextFormField(
                    controller: contactController,
                    decoration: InputDecoration(labelText: 'Contact'),
                    keyboardType: TextInputType.phone,
                  ),
                  TextFormField(
                    controller: experienceController,
                    decoration:
                        InputDecoration(labelText: 'Years of Experience'),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  await signupUser(
                    context,
                    emailController.text,
                    passwordController.text,
                    nameController.text,
                    districtController.text,
                    employerController.text,
                    contactController.text,
                    experienceController.text,
                    selectedRegion, // Pass the selected region
                  );
                  Navigator.of(context).pop();
                }
              },
              child: Text('Add Interpreter'),
            ),
          ],
        );
      },
    );
  }
}
