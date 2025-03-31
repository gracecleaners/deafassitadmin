// screens/pdf/add_pdf_dialog.dart
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:admin/models/pdf.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
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
      
      final String fileName = 'pdfs/${DateTime.now().millisecondsSinceEpoch}_$_selectedPdfName';
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
        filePath = 'pdfs/${DateTime.now().millisecondsSinceEpoch}_$_selectedPdfName';
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
        'category': _categoryController.text.isEmpty 
            ? null 
            : _categoryController.text,
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
        SnackBar(content: Text(
          widget.pdf == null 
            ? "PDF uploaded successfully" 
            : "PDF updated successfully"
        )),
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
      title: Text(widget.pdf == null ? "Upload PDF" : "Edit PDF"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: "Title",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? "Title is required" : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: "Description (optional)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16),
              GestureDetector(
                onTap: _pickPdf,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _selectedPdfBytes != null || widget.pdf != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.picture_as_pdf, size: 40, color: Colors.red),
                              Text(
                                _selectedPdfName ?? widget.pdf?.fileName ?? '',
                                textAlign: TextAlign.center,
                              ),
                              if (_selectedPdfSize != null)
                                Text(
                                  '${(_selectedPdfSize! / (1024 * 1024)).toStringAsFixed(2)} MB',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.upload_file, size: 40),
                              Text("Click to select PDF file"),
                            ],
                          ),
                        ),
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                decoration: InputDecoration(
                  labelText: "Category (optional)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _tagsController,
                      decoration: InputDecoration(
                        labelText: "Add Tag",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.tag),
                      ),
                      onFieldSubmitted: (value) => _addTag(),
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.add_circle),
                    onPressed: _addTag,
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ),
              SizedBox(height: 8),
              if (_tags.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  children: _tags.asMap().entries.map((entry) {
                    return Chip(
                      label: Text(entry.value),
                      deleteIcon: Icon(Icons.close, size: 16),
                      onDeleted: () => _removeTag(entry.key),
                    );
                  }).toList(),
                ),
                SizedBox(height: 16),
              ],
              if (_isUploading) LinearProgressIndicator(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _savePdf,
          child: Text(widget.pdf == null ? "Upload" : "Update"),
        ),
      ],
    );
  }
}