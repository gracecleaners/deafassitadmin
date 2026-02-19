// screens/pdf/add_pdf_dialog.dart
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:admin/constants.dart';
import 'package:admin/models/pdf.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AddPdfDialog extends StatefulWidget {
  final PdfDocument? pdf;

  const AddPdfDialog({Key? key, this.pdf}) : super(key: key);

  @override
  _AddPdfDialogState createState() => _AddPdfDialogState();
}

class _AddPdfDialogState extends State<AddPdfDialog> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Uint8List? _selectedPdfBytes;
  String? _selectedPdfName;
  int? _selectedPdfSize;
  bool _isUploading = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    if (widget.pdf != null) {
      _titleController.text = widget.pdf!.title;
      _descriptionController.text = widget.pdf?.description ?? '';
      _categoryController.text = widget.pdf?.category ?? '';
      _tags = widget.pdf?.tags ?? [];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickPdf() async {
    try {
      final html.FileUploadInputElement input = html.FileUploadInputElement()
        ..accept = 'application/pdf';
      input.click();

      await input.onChange.first;
      if (input.files?.isEmpty ?? true) return;

      final html.File file = input.files![0];
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);

      await reader.onLoad.first;
      setState(() {
        _selectedPdfBytes = Uint8List.fromList(reader.result as List<int>);
        _selectedPdfName = file.name;
        _selectedPdfSize = file.size;
      });
    } catch (e) {
      print('Error picking PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking PDF: $e")),
      );
    }
  }

  Future<String?> _uploadPdf() async {
    if (_selectedPdfBytes == null) return null;

    try {
      setState(() => _isUploading = true);

      final String fileName =
          'pdfs/${DateTime.now().millisecondsSinceEpoch}_$_selectedPdfName';
      final Reference storageRef = _storage.ref().child(fileName);

      final UploadTask uploadTask = storageRef.putData(
        _selectedPdfBytes!,
        SettableMetadata(contentType: 'application/pdf'),
      );

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error uploading PDF: $e")),
      );
      return null;
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _addTag() {
    if (_tagsController.text.isNotEmpty) {
      setState(() {
        _tags.add(_tagsController.text);
        _tagsController.clear();
      });
    }
  }

  void _removeTag(int index) {
    setState(() {
      _tags.removeAt(index);
    });
  }

  Future<void> _savePdf() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(),
        ),
      );

      String? downloadUrl;
      String filePath = '';

      if (_selectedPdfBytes != null) {
        downloadUrl = await _uploadPdf();
        filePath =
            'pdfs/${DateTime.now().millisecondsSinceEpoch}_$_selectedPdfName';
      } else if (widget.pdf == null) {
        throw Exception('Please select a PDF file');
      } else {
        downloadUrl = widget.pdf!.downloadUrl;
        filePath = widget.pdf!.filePath;
      }

      final Map<String, dynamic> pdfData = {
        'title': _titleController.text,
        'description': _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        'downloadUrl': downloadUrl,
        'filePath': filePath,
        'fileName': _selectedPdfName ?? widget.pdf?.fileName ?? '',
        'fileSize': _selectedPdfSize ?? widget.pdf?.fileSize ?? 0,
        'uploadDate': FieldValue.serverTimestamp(),
        'category':
            _categoryController.text.isEmpty ? null : _categoryController.text,
        'tags': _tags.isEmpty ? null : _tags,
      };

      if (widget.pdf == null) {
        await _firestore.collection('pdfs').add(pdfData);
      } else {
        await _firestore.collection('pdfs').doc(widget.pdf!.id).update(pdfData);
      }

      Navigator.pop(context); // Close progress dialog
      Navigator.pop(context); // Close form dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(widget.pdf == null
                ? "PDF uploaded successfully"
                : "PDF updated successfully")),
      );
    } catch (e) {
      Navigator.pop(context); // Close progress dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
                widget.pdf == null
                    ? Icons.upload_file_rounded
                    : Icons.edit_rounded,
                color: primaryColor,
                size: 20),
          ),
          const SizedBox(width: 12),
          Text(widget.pdf == null ? "Upload PDF" : "Edit PDF",
              style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: darkTextColor)),
        ],
      ),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dialogField("Title", "Enter document title", _titleController,
                    Icons.title_rounded,
                    validator: (value) =>
                        value?.isEmpty ?? true ? "Title is required" : null),
                const SizedBox(height: 14),
                _dialogField("Description (optional)", "Enter description",
                    _descriptionController, Icons.description_outlined,
                    maxLines: 3),
                const SizedBox(height: 14),
                Text('PDF File',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: darkTextColor)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _pickPdf,
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: bgColor,
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: _selectedPdfBytes != null || widget.pdf != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.picture_as_pdf_rounded,
                                    size: 32, color: dangerColor),
                                const SizedBox(height: 6),
                                Text(
                                  _selectedPdfName ??
                                      widget.pdf?.fileName ??
                                      '',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                      fontSize: 13, color: darkTextColor),
                                ),
                                if (_selectedPdfSize != null)
                                  Text(
                                    '${(_selectedPdfSize! / (1024 * 1024)).toStringAsFixed(2)} MB',
                                    style: GoogleFonts.inter(
                                        fontSize: 11, color: bodyTextColor),
                                  ),
                              ],
                            ),
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.cloud_upload_outlined,
                                    size: 32, color: bodyTextColor),
                                const SizedBox(height: 6),
                                Text("Click to select PDF file",
                                    style: GoogleFonts.inter(
                                        fontSize: 13, color: bodyTextColor)),
                              ],
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                _dialogField("Category (optional)", "e.g., Learning Materials",
                    _categoryController, Icons.category_outlined),
                const SizedBox(height: 14),
                Text('Tags',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: darkTextColor)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _tagsController,
                        style: GoogleFonts.inter(
                            fontSize: 14, color: darkTextColor),
                        decoration: InputDecoration(
                          hintText: "Add a tag",
                          hintStyle: GoogleFonts.inter(
                              fontSize: 13, color: bodyTextColor),
                          prefixIcon: const Icon(Icons.tag_rounded,
                              size: 18, color: bodyTextColor),
                          fillColor: bgColor,
                          filled: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: borderColor)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: borderColor)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: primaryColor)),
                        ),
                        onSubmitted: (value) => _addTag(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add_circle_rounded,
                          color: primaryColor),
                      onPressed: _addTag,
                    ),
                  ],
                ),
                if (_tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _tags.asMap().entries.map((entry) {
                      return Chip(
                        label: Text(entry.value,
                            style: GoogleFonts.inter(
                                fontSize: 12, color: primaryColor)),
                        deleteIcon: const Icon(Icons.close,
                            size: 14, color: primaryColor),
                        onDeleted: () => _removeTag(entry.key),
                        backgroundColor: primaryColor.withOpacity(0.1),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      );
                    }).toList(),
                  ),
                ],
                if (_isUploading) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: const LinearProgressIndicator(
                        color: primaryColor,
                        backgroundColor: bgColor,
                        minHeight: 3),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel", style: GoogleFonts.inter(color: bodyTextColor)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
          onPressed: _savePdf,
          child: Text(widget.pdf == null ? "Upload" : "Update",
              style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _dialogField(String label, String hint,
      TextEditingController controller, IconData icon,
      {String? Function(String?)? validator, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: darkTextColor)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          style: GoogleFonts.inter(fontSize: 14, color: darkTextColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(fontSize: 13, color: bodyTextColor),
            prefixIcon: Icon(icon, size: 18, color: bodyTextColor),
            fillColor: bgColor,
            filled: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: primaryColor)),
          ),
        ),
      ],
    );
  }
}
