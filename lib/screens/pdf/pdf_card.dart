// screens/pdf/pdf_card.dart
import 'package:admin/models/pdf.dart';
import 'package:flutter/material.dart';
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
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.picture_as_pdf, size: 40, color: Colors.red),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pdf.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          pdf.fileName,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              if (pdf.description != null)
                Text(
                  pdf.description!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  Chip(
                    label: Text(
                      '${(pdf.fileSize / (1024 * 1024)).toStringAsFixed(2)} MB'),
                    backgroundColor: Colors.grey[200],
                  ),
                  if (pdf.category != null)
                    Chip(
                      label: Text(pdf.category!),
                      backgroundColor: Colors.blue[100],
                    ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('MMM dd, yyyy').format(pdf.uploadDate),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  IconButton(
                    icon: Icon(Icons.download),
                    onPressed: () {
                      // Implement download functionality
                    },
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