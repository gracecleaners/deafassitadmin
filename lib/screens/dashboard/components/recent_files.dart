import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants.dart';

class RecentFiles extends StatefulWidget {
  const RecentFiles({Key? key}) : super(key: key);

  @override
  _RecentFilesState createState() => _RecentFilesState();
}

class _RecentFilesState extends State<RecentFiles> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _regionData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      final regions = ['Central', 'Eastern', 'Northern', 'Western'];
      final tempData = regions
          .map((region) => <String, dynamic>{
                'id': regions.indexOf(region).toString(),
                'region': region,
                'interpreters': 0,
                'deaf': 0,
              })
          .toList();

      for (final doc in usersSnapshot.docs) {
        final data = doc.data();
        final region = data['region']?.toString() ?? 'Unknown';
        final role = data['role']?.toString().toLowerCase() ?? 'unknown';
        final regionIndex = regions.indexOf(region);
        if (regionIndex != -1) {
          if (role == 'interpreter') {
            tempData[regionIndex]['interpreters'] =
                (tempData[regionIndex]['interpreters'] as int) + 1;
          } else if (role == 'deaf') {
            tempData[regionIndex]['deaf'] =
                (tempData[regionIndex]['deaf'] as int) + 1;
          }
        }
      }

      setState(() {
        _regionData = tempData;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() => _isLoading = false);
    }
  }

  final List<Color> _regionColors = [
    primaryColor,
    successColor,
    warningColor,
    dangerColor
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(defaultPadding * 1.5),
      decoration: cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "User Distribution",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: darkTextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Users across regions of Uganda",
                    style:
                        GoogleFonts.inter(fontSize: 13, color: bodyTextColor),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "All Regions",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: defaultPadding),
          SizedBox(
            width: double.infinity,
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(
                          color: primaryColor, strokeWidth: 2),
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: DataTable(
                      columnSpacing: defaultPadding,
                      headingRowHeight: 48,
                      dataRowMinHeight: 52,
                      dataRowMaxHeight: 52,
                      columns: [
                        DataColumn(
                            label: Text("Region",
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    color: bodyTextColor,
                                    fontSize: 13))),
                        DataColumn(
                            label: Text("Interpreters",
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    color: bodyTextColor,
                                    fontSize: 13))),
                        DataColumn(
                            label: Text("Deaf Users",
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    color: bodyTextColor,
                                    fontSize: 13))),
                        DataColumn(
                            label: Text("Total",
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    color: bodyTextColor,
                                    fontSize: 13))),
                      ],
                      rows: _regionData.asMap().entries.map((entry) {
                        final i = entry.key;
                        final data = entry.value;
                        final total = (data['interpreters'] as int) +
                            (data['deaf'] as int);
                        return DataRow(
                          cells: [
                            DataCell(Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _regionColors[i],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(data['region'],
                                    style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w500,
                                        color: darkTextColor)),
                              ],
                            )),
                            DataCell(Text(data['interpreters'].toString(),
                                style:
                                    GoogleFonts.inter(color: darkTextColor))),
                            DataCell(Text(data['deaf'].toString(),
                                style:
                                    GoogleFonts.inter(color: darkTextColor))),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _regionColors[i].withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  total.toString(),
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      color: _regionColors[i]),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
