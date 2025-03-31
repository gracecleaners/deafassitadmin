import 'dart:html' as html;
import 'dart:typed_data';
import 'package:admin/models/event.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddEventDialog extends StatefulWidget {
  final Event? event;

  const AddEventDialog({Key? key, this.event}) : super(key: key);

  @override
  _AddEventDialogState createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<AddEventDialog> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  bool _isUploading = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  bool _isFeatured = false;
  List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      _titleController.text = widget.event!.title;
      _descriptionController.text = widget.event?.description ?? '';
      _locationController.text = widget.event?.location ?? '';
      _categoryController.text = widget.event?.category ?? '';
      _startDate = widget.event!.startDate;
      _endDate = widget.event!.endDate;
      _isFeatured = widget.event?.isFeatured ?? false;
      _tags = widget.event?.tags ?? [];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _categoryController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final html.FileUploadInputElement input = html.FileUploadInputElement()
        ..accept = 'image/*';
      input.click();

      await input.onChange.first;
      if (input.files?.isEmpty ?? true) return;

      final html.File file = input.files![0];
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);

      await reader.onLoad.first;
      setState(() {
        _selectedImageBytes = Uint8List.fromList(reader.result as List<int>);
        _selectedImageName = file.name;
      });
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking image: $e")),
      );
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImageBytes == null) return null;

    try {
      setState(() => _isUploading = true);
      
      final String fileName = 'events/${DateTime.now().millisecondsSinceEpoch}_$_selectedImageName';
      final Reference storageRef = _storage.ref().child(fileName);

      final UploadTask uploadTask = storageRef.putData(
        _selectedImageBytes!,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error uploading image: $e")),
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

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(),
        ),
      );

      String? imageUrl;
      String imagePath = '';

      if (_selectedImageBytes != null) {
        imageUrl = await _uploadImage();
        imagePath = 'events/${DateTime.now().millisecondsSinceEpoch}_$_selectedImageName';
      } else if (widget.event == null && _selectedImageBytes == null) {
        // Allow events without images
      } else if (widget.event != null) {
        imageUrl = widget.event!.imageUrl;
        imagePath = widget.event!.imageUrl ?? '';
      }

      final Map<String, dynamic> eventData = {
        'title': _titleController.text,
        'description': _descriptionController.text.isEmpty 
            ? null 
            : _descriptionController.text,
        'startDate': _startDate,
        'endDate': _endDate,
        'location': _locationController.text.isEmpty 
            ? null 
            : _locationController.text,
        'imageUrl': imageUrl,
        'category': _categoryController.text.isEmpty 
            ? null 
            : _categoryController.text,
        'tags': _tags.isEmpty ? null : _tags,
        'isFeatured': _isFeatured,
      };

      if (widget.event == null) {
        await _firestore.collection('events').add(eventData);
      } else {
        await _firestore.collection('events').doc(widget.event!.id).update(eventData);
      }

      Navigator.pop(context); // Close progress dialog
      Navigator.pop(context); // Close form dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
          widget.event == null 
            ? "Event created successfully" 
            : "Event updated successfully"
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
      title: Text(widget.event == null ? "Create Event" : "Edit Event"),
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
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, true),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: "Start Date",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(DateFormat('MMM dd, yyyy').format(_startDate)),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, false),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: "End Date",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(DateFormat('MMM dd, yyyy').format(_endDate)),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: "Location (optional)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              SizedBox(height: 16),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _selectedImageBytes != null || (widget.event != null && widget.event!.imageUrl != null)
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _selectedImageBytes != null
                                  ? Image.memory(_selectedImageBytes!, height: 100)
                                  : Image.network(widget.event!.imageUrl!, height: 100),
                              if (_selectedImageName != null)
                                Text(
                                  _selectedImageName!,
                                  textAlign: TextAlign.center,
                                ),
                            ],
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image, size: 40),
                              Text("Click to select event image (optional)"),
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
              SwitchListTile(
                title: Text("Featured Event"),
                value: _isFeatured,
                onChanged: (value) {
                  setState(() {
                    _isFeatured = value;
                  });
                },
              ),
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
          onPressed: _saveEvent,
          child: Text(widget.event == null ? "Create" : "Update"),
        ),
      ],
    );
  }
}