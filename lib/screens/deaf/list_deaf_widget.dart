import 'package:admin/models/deaf.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../constants.dart';

class ListDeafWidget extends StatefulWidget {
  const ListDeafWidget({Key? key}) : super(key: key);

  @override
  _ListDeafWidgetState createState() => _ListDeafWidgetState();
}

class _ListDeafWidgetState extends State<ListDeafWidget> {
  late Future<List<DeafUser>> _futureDeafUsers;

  @override
  void initState() {
    super.initState();
    _futureDeafUsers = fetchDeafUsers();
  }

  Future<List<DeafUser>> fetchDeafUsers() async {
  try {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'deaf') // Filter by role
        .get();

    return snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return DeafUser(
        name: data['name'], // Only extract required fields
        email: data['email'],
        district: data['district'],
        currentEmployer: data['current_employer'],
        contact: data['contact'],
        yearsOfExperience: data['years_of_experience'],
        role: data['role'],
      );
    }).toList();
  } catch (e) {
    throw Exception("Error fetching deaf users: $e");
  }
}


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Deaf Users",
              style: Theme.of(context).textTheme.titleMedium,
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
                child: FutureBuilder<List<DeafUser>>(
                  future: _futureDeafUsers,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text('No Deaf Users available.'));
                    }

                    // If we have data, build the DataTable
                    List<DeafUser> deafUsers = snapshot.data!;
                    return DataTable(
                      columnSpacing: defaultPadding,
                      columns: [
                        DataColumn(label: Text("Name")),
                        DataColumn(label: Text("Email")),
                        DataColumn(label: Text("District")),
                        // DataColumn(label: Text("Current Employer")),
                        DataColumn(label: Text("Contact")),
                        // DataColumn(label: Text("Years of Experience")),
                        // DataColumn(label: Text("Role")),
                      ],
                      rows: deafUsers
                          .map((deafUser) => deafUserDataRow(deafUser))
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

  DataRow deafUserDataRow(DeafUser deafUser) {
    return DataRow(
      cells: [
        DataCell(Text(deafUser.name ?? "N/A")),
        DataCell(Text(deafUser.email ?? "N/A")),
        DataCell(Text(deafUser.district ?? "N/A")),
        // DataCell(Text(deafUser.currentEmployer ?? "N/A")),
        DataCell(Text(deafUser.contact ?? "N/A")),
        // DataCell(Text(deafUser.yearsOfExperience ?? "N/A")),
        // DataCell(Text(deafUser.role ?? "N/A")),
      ],
    );
  }
}
