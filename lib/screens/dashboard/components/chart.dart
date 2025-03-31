import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
      
      final counts = {
        'Central': 0,
        'Eastern': 0,
        'Northern': 0,
        'Western': 0,
      };

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
        radius: 25,
      ),
      PieChartSectionData(
        color: Color(0xFF26E5FF),
        value: _regionCounts['Eastern']?.toDouble() ?? 0,
        showTitle: false,
        radius: 22,
      ),
      PieChartSectionData(
        color: Color(0xFFFFCF26),
        value: _regionCounts['Northern']?.toDouble() ?? 0,
        showTitle: false,
        radius: 19,
      ),
      PieChartSectionData(
        color: Colors.red,
        value: _regionCounts['Western']?.toDouble() ?? 0,
        showTitle: false,
        radius: 15,
      ),
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
              sectionsSpace: 0,
              centerSpaceRadius: 70,
              startDegreeOffset: -90,
              sections: _isLoading ? _getEmptyChartData() : _getChartData(),
            ),
          ),
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: defaultPadding),
                Text(
                  _totalUsers.toString(),
                  style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        height: 0.5,
                      ),
                ),
                Text("Total Users")
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
        color: Colors.grey.withOpacity(0.3),
        value: 1,
        showTitle: false,
        radius: 25,
      ),
    ];
  }
}