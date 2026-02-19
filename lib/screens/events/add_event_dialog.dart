import 'dart:html' as html;
import 'dart:typed_data';
import 'package:admin/constants.dart';
import 'package:admin/models/event.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

      final String fileName =
          'events/${DateTime.now().millisecondsSinceEpoch}_$_selectedImageName';
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

  // ... (keep all your existing imports and code until _saveEvent method)

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
        imagePath =
            'events/${DateTime.now().millisecondsSinceEpoch}_$_selectedImageName';
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
        'location':
            _locationController.text.isEmpty ? null : _locationController.text,
        'imageUrl': imageUrl,
        'category':
            _categoryController.text.isEmpty ? null : _categoryController.text,
        'tags': _tags.isEmpty ? null : _tags,
        'isFeatured': _isFeatured,
      };

      Event updatedEvent;
      if (widget.event == null) {
        final docRef = await _firestore.collection('events').add(eventData);
        updatedEvent = Event(
          id: docRef.id,
          title: _titleController.text,
          description: _descriptionController.text,
          startDate: _startDate,
          endDate: _endDate,
          location: _locationController.text,
          imageUrl: imageUrl,
          category: _categoryController.text,
          tags: _tags,
          isFeatured: _isFeatured,
        );
      } else {
        await _firestore
            .collection('events')
            .doc(widget.event!.id)
            .update(eventData);
        updatedEvent = Event(
          id: widget.event!.id,
          title: _titleController.text,
          description: _descriptionController.text,
          startDate: _startDate,
          endDate: _endDate,
          location: _locationController.text,
          imageUrl: imageUrl,
          category: _categoryController.text,
          tags: _tags,
          isFeatured: _isFeatured,
        );
      }

      Navigator.pop(context);
      Navigator.pop(context, updatedEvent);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(widget.event == null
                ? "Event created successfully"
                : "Event updated successfully")),
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
                widget.event == null ? Icons.event_rounded : Icons.edit_rounded,
                color: primaryColor,
                size: 20),
          ),
          const SizedBox(width: 12),
          Text(widget.event == null ? "Create Event" : "Edit Event",
              style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: darkTextColor)),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _eventField("Title", "Enter event title", _titleController,
                    Icons.title_rounded,
                    validator: (v) =>
                        v?.isEmpty ?? true ? "Title is required" : null),
                const SizedBox(height: 14),
                _eventField("Description (optional)", "Enter description",
                    _descriptionController, Icons.description_outlined,
                    maxLines: 3),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _datePickerField("Start Date", _startDate,
                          () => _selectDate(context, true)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _datePickerField("End Date", _endDate,
                          () => _selectDate(context, false)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _eventField("Location (optional)", "Enter location",
                    _locationController, Icons.location_on_rounded),
                const SizedBox(height: 14),
                Text('Event Image',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: darkTextColor)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 130,
                    decoration: BoxDecoration(
                      color: bgColor,
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: _selectedImageBytes != null ||
                            (widget.event != null &&
                                widget.event!.imageUrl != null)
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _selectedImageBytes != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.memory(
                                            _selectedImageBytes!,
                                            height: 80,
                                            fit: BoxFit.cover))
                                    : ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                            widget.event!.imageUrl!,
                                            height: 80,
                                            fit: BoxFit.cover)),
                                if (_selectedImageName != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(_selectedImageName!,
                                        style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: bodyTextColor)),
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
                                Text("Click to select image (optional)",
                                    style: GoogleFonts.inter(
                                        fontSize: 13, color: bodyTextColor)),
                              ],
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                _eventField("Category (optional)", "e.g., Workshop",
                    _categoryController, Icons.category_rounded),
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
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: SwitchListTile(
                    title: Text("Featured Event",
                        style: GoogleFonts.inter(
                            fontSize: 14, color: darkTextColor)),
                    value: _isFeatured,
                    activeColor: primaryColor,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) {
                      setState(() {
                        _isFeatured = value;
                      });
                    },
                  ),
                ),
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
          onPressed: _saveEvent,
          child: Text(widget.event == null ? "Create" : "Update",
              style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _eventField(String label, String hint,
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

Widget _datePickerField(String label, DateTime date, VoidCallback onTap) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label,
          style: GoogleFonts.inter(
              fontSize: 12, fontWeight: FontWeight.w500, color: darkTextColor)),
      const SizedBox(height: 6),
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 16, color: bodyTextColor),
              const SizedBox(width: 8),
              Text(DateFormat('MMM dd, yyyy').format(date),
                  style: GoogleFonts.inter(fontSize: 14, color: darkTextColor)),
            ],
          ),
        ),
      ),
    ],
  );
}
