import 'package:admin/constants.dart';
import 'package:admin/screens/courses/add_course_widget.dart';
import 'package:admin/screens/dashboard/components/header.dart';
import 'package:flutter/material.dart';


class AddCourseScreen extends StatelessWidget {
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
                      CourseGridWidget(),
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
