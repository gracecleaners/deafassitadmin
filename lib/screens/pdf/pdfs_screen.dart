// screens/pdf/pdfs_screen.dart
import 'package:admin/constants.dart';
import 'package:admin/models/pdf.dart';
import 'package:admin/responsive.dart';
import 'package:admin/screens/dashboard/components/header.dart';
import 'package:admin/screens/main/components/side_menu.dart';
import 'package:admin/screens/pdf/add_pdf_dialog.dart';
import 'package:admin/screens/pdf/pdf_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PdfsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      drawer: Responsive.isDesktop(context)
          ? null
          : const Drawer(child: SideMenu()),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (Responsive.isDesktop(context))
              const SizedBox(width: 260, child: SideMenu()),
            Expanded(
              flex: 5,
              child: AddPdfScreen(),
            ),
          ],
        ),
      ),
    );
  }
}

class AddPdfScreen extends StatelessWidget {
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
              "PDF Documents",
              style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: darkTextColor),
            ),
            const SizedBox(height: 4),
            Text(
              "Upload and manage learning resources",
              style: GoogleFonts.inter(fontSize: 14, color: bodyTextColor),
            ),
            SizedBox(height: defaultPadding),
            PdfDocumentsGrid(),
          ],
        ),
      ),
    );
  }
}

class PdfDocumentsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Size _size = MediaQuery.of(context).size;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: cardDecoration,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.picture_as_pdf_outlined,
                    color: primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "All Documents",
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: darkTextColor),
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AddPdfDialog(),
                  );
                },
                icon: const Icon(Icons.upload_file_rounded, size: 18),
                label: Text("Upload PDF",
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        SizedBox(height: defaultPadding),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('pdfs').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(
                    color: primaryColor, strokeWidth: 2),
              ));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(40),
                decoration: cardDecoration,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.picture_as_pdf_outlined,
                          size: 40, color: primaryColor),
                    ),
                    const SizedBox(height: 16),
                    Text('No PDF documents yet',
                        style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: bodyTextColor)),
                  ],
                ),
              );
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _size.width > 1200 ? 3 : 2,
                crossAxisSpacing: defaultPadding,
                mainAxisSpacing: defaultPadding,
              ),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var pdfData = snapshot.data!.docs[index];
                return PdfCard(
                  pdf: PdfDocument.fromJson(
                    pdfData.data() as Map<String, dynamic>,
                    pdfData.id,
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
