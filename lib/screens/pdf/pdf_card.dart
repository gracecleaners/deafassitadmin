// screens/pdf/pdf_card.dart
import 'package:admin/constants.dart';
import 'package:admin/models/pdf.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class PdfCard extends StatelessWidget {
  final PdfDocument pdf;
  final VoidCallback? onTap;

  const PdfCard({
    Key? key,
    required this.pdf,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: cardDecoration,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: dangerColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded,
                        size: 28, color: dangerColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pdf.title,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: darkTextColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          pdf.fileName,
                          style: GoogleFonts.inter(
                              fontSize: 12, color: bodyTextColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (pdf.description != null)
                Text(
                  pdf.description!,
                  style: GoogleFonts.inter(fontSize: 13, color: bodyTextColor),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const Spacer(),
              Wrap(
                spacing: 8,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: borderColor),
                    ),
                    child: Text(
                      '${(pdf.fileSize / (1024 * 1024)).toStringAsFixed(2)} MB',
                      style:
                          GoogleFonts.inter(fontSize: 11, color: bodyTextColor),
                    ),
                  ),
                  if (pdf.category != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        pdf.category!,
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: primaryColor),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 13, color: bodyTextColor),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM dd, yyyy').format(pdf.uploadDate),
                        style: GoogleFonts.inter(
                            fontSize: 12, color: bodyTextColor),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.download_rounded,
                        size: 18, color: primaryColor),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
