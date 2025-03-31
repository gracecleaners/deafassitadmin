import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
      
      // Initialize region data with explicit types
      final regions = ['Central', 'Eastern', 'Northern', 'Western'];
      final tempData = regions.map((region) => <String, dynamic>{
        'id': regions.indexOf(region).toString(),
        'region': region,
        'interpreters': 0, // Explicitly typed as int
        'deaf': 0,        // Explicitly typed as int
      }).toList();

      // Count users by region and role
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "User Locations",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            "Distribution of users around Uganda",
            style: TextStyle(color: Colors.grey.withOpacity(0.5)),
          ),
          SizedBox(
            width: double.infinity,
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : DataTable(
                    columnSpacing: defaultPadding,
                    columns: [
                      DataColumn(label: Text("ID")),
                      DataColumn(label: Text("Region")),
                      DataColumn(label: Text("Interpreters")),
                      DataColumn(label: Text("Deaf Users")),
                    ],
                    rows: _regionData.map((data) => DataRow(
                      cells: [
                        DataCell(Text(data['id'].toString())),
                        DataCell(Text(data['region'])),
                        DataCell(Text(data['interpreters'].toString())),
                        DataCell(Text(data['deaf'].toString())),
                      ],
                    )).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}