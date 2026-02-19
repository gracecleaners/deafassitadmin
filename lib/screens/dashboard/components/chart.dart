import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants.dart';

class Chart extends StatefulWidget {
  const Chart({Key? key}) : super(key: key);

  @override
  _ChartState createState() => _ChartState();
}

class _ChartState extends State<Chart> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, int> _regionCounts = {
    'Central': 0,
    'Eastern': 0,
    'Northern': 0,
    'Western': 0,
  };
  int _totalUsers = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      final counts = {'Central': 0, 'Eastern': 0, 'Northern': 0, 'Western': 0};
      for (final doc in usersSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final region = data['region']?.toString() ?? 'Unknown';
        if (counts.containsKey(region)) {
          counts[region] = counts[region]! + 1;
        }
      }
      setState(() {
        _regionCounts = counts;
        _totalUsers = usersSnapshot.size;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() => _isLoading = false);
    }
  }

  List<PieChartSectionData> _getChartData() {
    return [
      PieChartSectionData(
          color: primaryColor,
          value: _regionCounts['Central']?.toDouble() ?? 0,
          showTitle: false,
          radius: 28),
      PieChartSectionData(
          color: successColor,
          value: _regionCounts['Eastern']?.toDouble() ?? 0,
          showTitle: false,
          radius: 24),
      PieChartSectionData(
          color: warningColor,
          value: _regionCounts['Northern']?.toDouble() ?? 0,
          showTitle: false,
          radius: 22),
      PieChartSectionData(
          color: dangerColor,
          value: _regionCounts['Western']?.toDouble() ?? 0,
          showTitle: false,
          radius: 20),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Stack(
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 60,
              startDegreeOffset: -90,
              sections: _isLoading ? _getEmptyChartData() : _getChartData(),
            ),
          ),
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _totalUsers.toString(),
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: darkTextColor,
                  ),
                ),
                Text(
                  "Total Users",
                  style: GoogleFonts.inter(fontSize: 12, color: bodyTextColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _getEmptyChartData() {
    return [
      PieChartSectionData(
        color: borderColor,
        value: 1,
        showTitle: false,
        radius: 25,
      ),
    ];
  }
}
