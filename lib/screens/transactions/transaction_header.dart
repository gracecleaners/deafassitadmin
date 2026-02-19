import 'package:admin/screens/dashboard/components/header.dart';
import 'package:admin/screens/transactions/transaction_list.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants.dart';

class TransactionHeader extends StatelessWidget {
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
              "Transactions",
              style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: darkTextColor),
            ),
            const SizedBox(height: 4),
            Text(
              "Track all payment transactions",
              style: GoogleFonts.inter(fontSize: 14, color: bodyTextColor),
            ),
            SizedBox(height: defaultPadding),
            TransactionList(),
          ],
        ),
      ),
    );
  }
}
