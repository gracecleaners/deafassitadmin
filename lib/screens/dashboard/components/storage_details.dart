import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
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
            newStats[region]!['interpreter'] =
                newStats[region]!['interpreter']! + 1;
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
      padding: const EdgeInsets.all(defaultPadding * 1.5),
      decoration: cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "User Analysis",
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: darkTextColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Regional breakdown",
            style: GoogleFonts.inter(fontSize: 13, color: bodyTextColor),
          ),
          const SizedBox(height: defaultPadding),
          const Chart(),
          const SizedBox(height: 8),
          StorageInfoCard(
            title: "Central Region",
            amountOfFiles:
                "${_regionStats['Central']?['interpreter']} interpreters",
            amountOfFile: "${_regionStats['Central']?['deaf']} Deaf Users",
            numOfFiles: _regionStats['Central']?['total'] ?? 0,
            color: primaryColor,
          ),
          StorageInfoCard(
            title: "Eastern Region",
            amountOfFiles:
                "${_regionStats['Eastern']?['interpreter']} interpreters",
            amountOfFile: "${_regionStats['Eastern']?['deaf']} Deaf Users",
            numOfFiles: _regionStats['Eastern']?['total'] ?? 0,
            color: successColor,
          ),
          StorageInfoCard(
            title: "Northern Region",
            amountOfFiles:
                "${_regionStats['Northern']?['interpreter']} interpreters",
            amountOfFile: "${_regionStats['Northern']?['deaf']} Deaf Users",
            numOfFiles: _regionStats['Northern']?['total'] ?? 0,
            color: warningColor,
          ),
          StorageInfoCard(
            title: "Western Region",
            amountOfFiles:
                "${_regionStats['Western']?['interpreter']} interpreters",
            amountOfFile: "${_regionStats['Western']?['deaf']} Deaf Users",
            numOfFiles: _regionStats['Western']?['total'] ?? 0,
            color: dangerColor,
          ),
        ],
      ),
    );
  }
}
