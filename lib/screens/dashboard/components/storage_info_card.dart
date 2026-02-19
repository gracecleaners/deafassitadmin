import 'package:admin/constants.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StorageInfoCard extends StatelessWidget {
  const StorageInfoCard({
    Key? key,
    required this.title,
    required this.amountOfFiles,
    required this.amountOfFile,
    required this.numOfFiles,
    required this.color,
  }) : super(key: key);

  final String title, amountOfFiles, amountOfFile;
  final int numOfFiles;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        border: Border.all(width: 1, color: color.withOpacity(0.15)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.people_alt_rounded, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600, color: darkTextColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "$amountOfFiles  ·  $amountOfFile",
                  style: GoogleFonts.inter(fontSize: 11, color: bodyTextColor),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "$numOfFiles",
              style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w700, color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}