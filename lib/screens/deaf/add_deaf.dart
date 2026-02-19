import 'package:admin/screens/dashboard/components/header.dart';
import 'package:admin/screens/deaf/list_deaf_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants.dart';

class DeafListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        primary: false,
        padding: EdgeInsets.all(defaultPadding * 1.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Header(title: ''),
            SizedBox(height: defaultPadding),
            // Title section
            Text(
              "Deaf Users Management",
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: darkTextColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "View and manage registered deaf users",
              style: GoogleFonts.inter(fontSize: 14, color: bodyTextColor),
            ),
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
