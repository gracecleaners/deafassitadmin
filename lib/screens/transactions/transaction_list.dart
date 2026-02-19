import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants.dart';

class TransactionList extends StatelessWidget {
  const TransactionList({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: cardDecoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long_outlined,
                size: 48, color: primaryColor),
          ),
          const SizedBox(height: 20),
          Text(
            'No transactions yet',
            style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: darkTextColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Transactions will appear here once payments are processed.',
            style: GoogleFonts.inter(fontSize: 14, color: bodyTextColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
