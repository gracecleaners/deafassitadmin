import 'package:admin/screens/courses/addcoursewidget.dart';
import 'package:admin/screens/dashboard/components/header.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants.dart';

class AddCourseScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(defaultPadding * 1.5),
          child: Container(
            height: MediaQuery.of(context).size.height - 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Header(title: ''),
                SizedBox(height: defaultPadding),
                Text(
                  "Courses Management",
                  style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: darkTextColor),
                ),
                const SizedBox(height: 4),
                Text(
                  "Create and manage sign language courses",
                  style: GoogleFonts.inter(fontSize: 14, color: bodyTextColor),
                ),
                SizedBox(height: defaultPadding),
                Expanded(
                  child: AddCourse(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
