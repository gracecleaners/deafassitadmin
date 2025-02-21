import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:html' as html;

class AddCourseDialog extends StatefulWidget {
  const AddCourseDialog({Key? key}) : super(key: key);

  @override
  _AddCourseDialogState createState() => _AddCourseDialogState();
}

class _AddCourseDialogState extends State<AddCourseDialog> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  String? courseLink;
  final List<String> courseModes = ['Physical', 'Online'];
  double? rating;
  int? numberOfRatings;
  double? originalPrice;
  bool isBestseller = false;
  String? name;
  String? description;
  String? instructor;
  String? instructorBio;
  String? instructorImage;
  DateTime? startDate;
  DateTime? endDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  String? mode;
  String? location;
  File? _imageFile;
  String? imageUrl;
  List<String> objectives = [];
  double? price;
  int? duration;
  String? difficulty;
  TextEditingController objectiveController = TextEditingController();

  // Controllers for date and time fields
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();

  final List<String> difficultyLevels = [
    'Beginner',
    'Intermediate',
    'Advanced'
  ];

  @override
  void dispose() {
    objectiveController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  Uint8List? _selectedImageBytes;
  String? _selectedImageName;

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
    final String fileName = 'course_images/${DateTime.now().millisecondsSinceEpoch}_${_selectedImageName ?? "image.png"}';
    final Reference storageRef = _storage.ref().child(fileName);

    // Determine the MIME type based on the file extension
    final String mimeType = _selectedImageName?.endsWith('.png') ?? false ? 'image/png' : 'image/jpeg';

    final UploadTask uploadTask = storageRef.putData(
      _selectedImageBytes!,
      SettableMetadata(contentType: mimeType),
    );

    final TaskSnapshot snapshot = await uploadTask;
    final String downloadUrl = await snapshot.ref.getDownloadURL();
    print('Image uploaded. Download URL: $downloadUrl');
    return downloadUrl;
  } catch (e) {
    print('Error uploading image: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error uploading image: $e")),
    );
    return null;
  }
}

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          startDate = picked;
          _startDateController.text = DateFormat('yyyy-MM-dd').format(picked);
        } else {
          endDate = picked;
          _endDateController.text = DateFormat('yyyy-MM-dd').format(picked);
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          startTime = picked;
          _startTimeController.text = picked.format(context);
        } else {
          endTime = picked;
          _endTimeController.text = picked.format(context);
        }
      });
    }
  }

  void _addObjective() {
    if (objectiveController.text.isNotEmpty) {
      setState(() {
        objectives.add(objectiveController.text);
        objectiveController.clear();
      });
    }
  }

  void _removeObjective(int index) {
    setState(() {
      objectives.removeAt(index);
    });
  }

  Future<void> _saveCourse() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(),
        ),
      );

      _formKey.currentState!.save();

      final String? uploadedImageUrl = await _uploadImage();

      final Map<String, dynamic> courseData = {
        'name': name,
        'description': description,
        'instructor': instructor,
        'instructorBio': instructorBio,
        'instructorImage': instructorImage,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'startTime': startTime?.format(context),
        'endTime': endTime?.format(context),
        'mode': mode,
        'location': location,
        'courseLink': courseLink,  // Add courseLink to the data
        'imageUrl': uploadedImageUrl,
        'objectives': objectives,
        'price': price,
        'duration': duration,
        'createdAt': FieldValue.serverTimestamp(),
        'rating': rating ?? 0.0,
      };

      await _firestore.collection('courses').add(courseData);

      Navigator.pop(context);
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Course added successfully")),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error adding course: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Add New Course"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course Basic Information
              Text("Basic Information",
                  style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: "Course Name",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.book),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? "Course name is required" : null,
                onSaved: (value) => name = value,
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (value) =>
                    value?.isEmpty ?? true ? "Description is required" : null,
                onSaved: (value) => description = value,
              ),
              SizedBox(height: 16),

              // Course Image
              Text("Course Image",
                  style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _selectedImageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            _selectedImageBytes!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate, size: 50),
                              Text("Click to add course image"),
                            ],
                          ),
                        ),
                ),
              ),
              SizedBox(height: 16),

              // Instructor Information
              Text("Instructor Information",
                  style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: "Instructor Name",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) => value?.isEmpty ?? true
                    ? "Instructor name is required"
                    : null,
                onSaved: (value) => instructor = value,
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: "Instructor Bio",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                maxLines: 2,
                onSaved: (value) => instructorBio = value,
              ),
              SizedBox(height: 16),

              // Schedule Information
              Text("Schedule", style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _startDateController,
                      decoration: InputDecoration(
                        labelText: "Start Date",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () => _selectDate(context, true),
                      validator: (value) => value?.isEmpty ?? true
                          ? "Start date is required"
                          : null,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _endDateController,
                      decoration: InputDecoration(
                        labelText: "End Date",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () => _selectDate(context, false),
                      validator: (value) => value?.isEmpty ?? true
                          ? "End date is required"
                          : null,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _startTimeController,
                      decoration: InputDecoration(
                        labelText: "Start Time",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.access_time),
                      ),
                      readOnly: true,
                      onTap: () => _selectTime(context, true),
                      validator: (value) => value?.isEmpty ?? true
                          ? "Start time is required"
                          : null,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _endTimeController,
                      decoration: InputDecoration(
                        labelText: "End Time",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.access_time),
                      ),
                      readOnly: true,
                      onTap: () => _selectTime(context, false),
                      validator: (value) => value?.isEmpty ?? true
                          ? "End time is required"
                          : null,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Course Details
              Text("Course Details",
                  style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: 16),
             DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: "Mode",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.mode),
                ),
                items: courseModes.map((String mode) {
                  return DropdownMenuItem<String>(
                    value: mode,
                    child: Text(mode),
                  );
                }).toList(),
                onChanged: (String? value) {
                  setState(() {
                    mode = value;
                    // Clear location and courseLink when mode changes
                    location = null;
                    courseLink = null;
                  });
                },
                validator: (value) => value == null ? "Mode is required" : null,
              ),
              SizedBox(height: 16),
              
              // Conditional form fields based on mode
              if (mode == 'Physical') 
                TextFormField(
                  decoration: InputDecoration(
                    labelText: "Location",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  validator: (value) => 
                    value?.isEmpty ?? true ? "Location is required for physical courses" : null,
                  onSaved: (value) => location = value,
                ),
                
              if (mode == 'Online')
                TextFormField(
                  decoration: InputDecoration(
                    labelText: "Course Link",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.link),
                  ),
                  validator: (value) => 
                    value?.isEmpty ?? true ? "Course link is required for online courses" : null,
                  onSaved: (value) => courseLink = value,
                ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: "Price",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return "Price is required";
                  if (double.tryParse(value!) == null) return "Invalid price";
                  return null;
                },
                onSaved: (value) => price = double.tryParse(value!),
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: "Duration (weeks)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.timer),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return "Duration is required";
                  if (int.tryParse(value!) == null) return "Invalid duration";
                  return null;
                },
                onSaved: (value) => duration = int.tryParse(value!),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: "Difficulty",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.trending_up),
                ),
                items: difficultyLevels.map((String level) {
                  return DropdownMenuItem<String>(
                    value: level,
                    child: Text(level),
                  );
                }).toList(),
                onChanged: (String? value) {
                  setState(() {
                    difficulty = value;
                  });
                },
                validator: (value) =>
                    value == null ? "Difficulty is required" : null,
              ),
              SizedBox(height: 16),

              // Course Objectives
              Text("Course Objectives",
                  style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: objectiveController,
                      decoration: InputDecoration(
                        labelText: "Add Objective",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.list),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.add_circle),
                    onPressed: _addObjective,
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ),
              SizedBox(height: 8),
              TextFormField(
                decoration: InputDecoration(
                  labelText: "Rating (0-5)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.star),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return null;
                  final rating = double.tryParse(value!);
                  if (rating == null || rating < 0 || rating > 5) {
                    return "Rating must be between 0 and 5";
                  }
                  return null;
                },
                onSaved: (value) => rating = double.tryParse(value ?? "0"),
              ),
              SizedBox(height: 16),
              if (objectives.isNotEmpty) ...[
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Added Objectives:",
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        SizedBox(height: 8),
                        ...objectives.asMap().entries.map((entry) {
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text("${entry.key + 1}"),
                            ),
                            title: Text(entry.value),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeObjective(entry.key),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
              ],
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
          onPressed: _saveCourse,
          child: Text("Save Course"),
        ),
      ],
    );
  }
}
