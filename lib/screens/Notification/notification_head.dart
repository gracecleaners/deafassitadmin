import 'package:admin/screens/Notification/notification_list.dart';
import 'package:admin/screens/dashboard/components/header.dart';
import 'package:admin/screens/deaf/list_deaf_widget.dart';
import 'package:flutter/material.dart';

import '../../constants.dart';

class NotificationHead extends StatelessWidget {
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
                      AdminNotificationsScreen(),
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
