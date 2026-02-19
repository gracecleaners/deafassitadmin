import 'package:admin/screens/dashboard/components/header.dart';
import 'package:admin/screens/interpreter/add_interpreter_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants.dart';

class AddInterpreterScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        primary: false,
        padding: const EdgeInsets.all(defaultPadding * 1.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Header(title: 'Interpreters'),
            const SizedBox(height: defaultPadding * 1.5),
            Text(
              "Interpreter Management",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: darkTextColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "View, add, and manage sign language interpreters",
              style: GoogleFonts.inter(fontSize: 14, color: bodyTextColor),
            ),
            const SizedBox(height: defaultPadding),
            const AddInterpreterWidget(),
          ],
        ),
      ),
    );
  }
}
