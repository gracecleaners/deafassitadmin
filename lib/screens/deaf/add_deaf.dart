import 'package:admin/screens/dashboard/components/header.dart';
import 'package:admin/screens/deaf/list_deaf_widget.dart';
import 'package:admin/screens/interpreter/add_interpreter_widget.dart';
import 'package:flutter/material.dart';

import '../../constants.dart';

class DeafListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        primary: false,
        padding: EdgeInsets.all(defaultPadding),
        child: Column(
          children: [
            Header(),
            SizedBox(height: defaultPadding),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      ListDeafWidget(),
                      SizedBox(height: defaultPadding),
                      // RecentFiles(),
                    ],
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
