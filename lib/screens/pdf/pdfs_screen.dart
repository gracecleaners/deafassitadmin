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

class PdfsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: SideMenu(),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (Responsive.isDesktop(context))
              Expanded(
                child: SideMenu(),
              ),
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
    final Size _size = MediaQuery.of(context).size;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(defaultPadding),
          child: Container(
            height: MediaQuery.of(context).size.height - 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Header(title: "PDF Documents"),
                SizedBox(height: defaultPadding),
                Expanded(
                  child: PdfDocumentsGrid(),
                ),
              ],
            ),
          ),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "PDF Documents",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AddPdfDialog(),
                );
              },
              icon: Icon(Icons.upload_file),
              label: Text("Upload PDF"),
            ),
          ],
        ),
        SizedBox(height: defaultPadding),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('pdfs').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text("No PDF documents available"));
              }
              return GridView.builder(
                shrinkWrap: true,
                physics: AlwaysScrollableScrollPhysics(),
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
        ),
      ],
    );
  }
}