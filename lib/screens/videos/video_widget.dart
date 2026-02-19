import 'package:admin/screens/dashboard/components/header.dart';
import 'package:admin/screens/videos/add_video_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants.dart';

class AddVideoScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(defaultPadding * 1.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Header(title: ''),
            SizedBox(height: defaultPadding),
            Text(
              "Video Management",
              style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: darkTextColor),
            ),
            const SizedBox(height: 4),
            Text(
              "Upload and manage sign language videos",
              style: GoogleFonts.inter(fontSize: 14, color: bodyTextColor),
            ),
            SizedBox(height: defaultPadding),
            AddVideoWidget(),
          ],
        ),
      ),
    );
  }
}
