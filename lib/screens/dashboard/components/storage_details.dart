import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../constants.dart';
import 'chart.dart';
import 'storage_info_card.dart';

class StorageDetails extends StatefulWidget {
  const StorageDetails({Key? key}) : super(key: key);

  @override
  _StorageDetailsState createState() => _StorageDetailsState();
}

class _StorageDetailsState extends State<StorageDetails> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, Map<String, int>> _regionStats = {
    'Central': {'interpreter': 0, 'deaf': 0, 'total': 0},
    'Eastern': {'interpreter': 0, 'deaf': 0, 'total': 0},
    'Northern': {'interpreter': 0, 'deaf': 0, 'total': 0},
    'Western': {'interpreter': 0, 'deaf': 0, 'total': 0},
  };

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      
      // Reset counts
      final newStats = {
        'Central': {'interpreter': 0, 'deaf': 0, 'total': 0},
        'Eastern': {'interpreter': 0, 'deaf': 0, 'total': 0},
        'Northern': {'interpreter': 0, 'deaf': 0, 'total': 0},
        'Western': {'interpreter': 0, 'deaf': 0, 'total': 0},
      };

      for (final doc in usersSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final region = data['region']?.toString() ?? 'Unknown';
        final role = data['role']?.toString() ?? 'unknown';

        if (newStats.containsKey(region)) {
          if (role.toLowerCase() == 'interpreter') {
            newStats[region]!['interpreter'] = newStats[region]!['interpreter']! + 1;
          } else if (role.toLowerCase() == 'deaf') {
            newStats[region]!['deaf'] = newStats[region]!['deaf']! + 1;
          }
          newStats[region]!['total'] = newStats[region]!['total']! + 1;
        }
      }

      setState(() {
        _regionStats = newStats;
      });
    } catch (e) {
      print('Error fetching user data: $e');
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
            "User Analysis",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: defaultPadding),
          Chart(),
          StorageInfoCard(
            svgSrc: "assets/icons/users.svg",
            title: "Central Region",
            amountOfFiles: "${_regionStats['Central']?['interpreter']} interpreters",
            amountOfFile: "${_regionStats['Central']?['deaf']} Deaf Users",
            numOfFiles: _regionStats['Central']?['total'] ?? 0,
            colors: primaryColor.withOpacity(0.3),
            color1: primaryColor,
            // subtitle: "${_regionStats['Central']?['deaf']} deaf users",
          ),
          StorageInfoCard(
            svgSrc: "assets/icons/users.svg",
            title: "Eastern Region",
            amountOfFiles: "${_regionStats['Eastern']?['interpreter']} interpreters",
            amountOfFile: "${_regionStats['Eastern']?['deaf']} Deaf Users",
            numOfFiles: _regionStats['Eastern']?['total'] ?? 0,
            colors: Color(0xFF26E5FF).withOpacity(0.3),
            color1: Color(0xFF26E5FF),
            // subtitle: "${_regionStats['Eastern']?['deaf']} deaf users",
          ),
          StorageInfoCard(
            svgSrc: "assets/icons/users.svg",
            title: "Northern Region",
            amountOfFiles: "${_regionStats['Northern']?['interpreter']} interpreters",
            amountOfFile: "${_regionStats['Northern']?['deaf']} Deaf Users",
            numOfFiles: _regionStats['Northern']?['total'] ?? 0,
            colors: Color(0xFFFFCF26).withOpacity(0.3),
            color1: Color(0xFFFFCF26),
            // subtitle: "${_regionStats['Northern']?['deaf']} deaf users",
          ),
          StorageInfoCard(
            svgSrc: "assets/icons/users.svg",
            title: "Western Region",
            amountOfFiles: "${_regionStats['Western']?['interpreter']} interpreters",
            amountOfFile: "${_regionStats['Western']?['deaf']} Deaf Users",
            numOfFiles: _regionStats['Western']?['total'] ?? 0,
            colors: Colors.red.withOpacity(0.3),
            color1: Colors.red,
            // subtitle: "${_regionStats['Western']?['deaf']} deaf users",
          ),
        ],
      ),
    );
  }
}