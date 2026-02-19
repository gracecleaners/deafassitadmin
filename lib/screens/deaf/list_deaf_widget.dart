import 'package:admin/models/deaf.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
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
          .where('role', isEqualTo: 'Individual')
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return DeafUser(
          name: data['name'],
          email: data['email'],
          district: data['district'],
          currentEmployer: data['current_employer'],
          contact: data['contact'],
          yearsOfExperience: data['years_of_experience'],
          role: data['role'],
        );
      }).toList();
    } catch (e) {
      throw Exception("Error fetching deaf users: \$e");
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
                    child: const Icon(Icons.hearing_disabled_rounded,
                        color: primaryColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  FutureBuilder<List<DeafUser>>(
                    future: _futureDeafUsers,
                    builder: (context, snapshot) {
                      final count = snapshot.data?.length ?? 0;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("All Deaf Users",
                              style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: darkTextColor)),
                          Text("\$count total",
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: bodyTextColor)),
                        ],
                      );
                    },
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: const Icon(Icons.refresh_rounded,
                      color: bodyTextColor, size: 20),
                  onPressed: () => setState(() {
                    _futureDeafUsers = fetchDeafUsers();
                  }),
                  tooltip: 'Refresh',
                ),
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
                  child: FutureBuilder<List<DeafUser>>(
                    future: _futureDeafUsers,
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
                            child: Column(children: [
                              const Icon(Icons.error_outline,
                                  color: dangerColor, size: 40),
                              const SizedBox(height: 12),
                              Text('Error loading users',
                                  style: GoogleFonts.inter(
                                      color: darkTextColor,
                                      fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              Text('\${snapshot.error}',
                                  style: GoogleFonts.inter(
                                      color: bodyTextColor, fontSize: 12)),
                            ]),
                          ),
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(48),
                          child: Center(
                            child: Column(children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.people_outline,
                                    color: primaryColor, size: 36),
                              ),
                              const SizedBox(height: 16),
                              Text('No deaf users yet',
                                  style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: darkTextColor)),
                            ]),
                          ),
                        );
                      }

                      List<DeafUser> deafUsers = snapshot.data!;
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
                                label: Text("District",
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
                          ],
                          rows: deafUsers
                              .map((deafUser) => _buildDataRow(deafUser))
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

  DataRow _buildDataRow(DeafUser deafUser) {
    return DataRow(
      cells: [
        DataCell(
          Row(children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: primaryColor.withOpacity(0.1),
              child: Text(
                (deafUser.name ?? 'U')[0].toUpperCase(),
                style: GoogleFonts.inter(
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
            ),
            const SizedBox(width: 10),
            Text(deafUser.name ?? "N/A",
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500, color: darkTextColor)),
          ]),
        ),
        DataCell(Text(deafUser.email ?? "N/A",
            style: GoogleFonts.inter(color: darkTextColor, fontSize: 13))),
        DataCell(Text(deafUser.district ?? "N/A",
            style: GoogleFonts.inter(color: darkTextColor, fontSize: 13))),
        DataCell(Text(deafUser.contact ?? "N/A",
            style: GoogleFonts.inter(color: darkTextColor, fontSize: 13))),
      ],
    );
  }
}
