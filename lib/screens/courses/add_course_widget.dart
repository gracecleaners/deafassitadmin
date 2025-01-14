import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:admin/models/courses.dart';
import 'package:admin/services/course_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';

class CourseGridWidget extends StatefulWidget {
  const CourseGridWidget({Key? key}) : super(key: key);

  @override
  _CourseGridWidgetState createState() => _CourseGridWidgetState();
}

class _CourseGridWidgetState extends State<CourseGridWidget> {
  final CourseService _courseService = CourseService();

  Future<String> _uploadImage(File image) async {
    try {
      FirebaseStorage storage = FirebaseStorage.instance;
      String fileName = 'courses/${DateTime.now().millisecondsSinceEpoch}.png';
      Reference ref = storage.ref().child(fileName);

      // Log the file name to ensure it's correct
      print("Uploading image to: $fileName");

      await ref.putFile(image);

      // Log to confirm upload success
      String imageUrl = await ref.getDownloadURL();
      print("Image uploaded successfully, URL: $imageUrl");
      return imageUrl;
    } catch (e) {
      print("Error uploading image: $e");
      throw Exception('Failed to upload image');
    }
  }

  void _showAddCourseDialog() {
    final _formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final instructorController = TextEditingController();
    final instructorBioController = TextEditingController();
    final objectivesController = TextEditingController();
    final locationController = TextEditingController();
    final startDateController = TextEditingController();
    final endDateController = TextEditingController();
    final startTimeController = TextEditingController();
    final endTimeController = TextEditingController();

    DateTime? _selectedStartDate;
    DateTime? _selectedEndDate;
    TimeOfDay? _selectedStartTime;
    TimeOfDay? _selectedEndTime;
    File? _courseImage;
    String? _selectedMode;
    DateFormat dateFormat = DateFormat("yyyy-MM-dd");

    String formatTime(TimeOfDay time) {
      final hour = time.hour < 10 ? '0${time.hour}' : '${time.hour}';
      final minute = time.minute < 10 ? '0${time.minute}' : '${time.minute}';
      return '$hour:$minute';
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Course'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Course Name'),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please enter a course name'
                            : null,
                      ),
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(labelText: 'Description'),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please enter a description'
                            : null,
                      ),
                      TextFormField(
                        controller: instructorController,
                        decoration: const InputDecoration(labelText: 'Instructor Name'),
                      ),
                      TextFormField(
                        controller: instructorBioController,
                        decoration: const InputDecoration(labelText: 'Instructor Bio'),
                      ),
                      TextFormField(
                        controller: objectivesController,
                        decoration: const InputDecoration(labelText: 'Objectives'),
                      ),
                      DropdownButtonFormField<String>(
                        value: _selectedMode,
                        decoration: const InputDecoration(labelText: 'Mode'),
                        items: ['Physical', 'Online']
                            .map((mode) => DropdownMenuItem(
                                  value: mode,
                                  child: Text(mode),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedMode = value;
                          });
                        },
                        validator: (value) =>
                            value == null ? 'Please select the course mode' : null,
                      ),
                      if (_selectedMode == 'Physical')
                        TextFormField(
                          controller: locationController,
                          decoration: const InputDecoration(labelText: 'Location'),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Please enter the location for the course'
                              : null,
                        ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_courseImage == null
                              ? 'No course image selected'
                              : 'Course image selected!'),
                          IconButton(
                            icon: const Icon(Icons.photo),
                            onPressed: () async {
                              // Use ImagePicker to pick an image
                              final ImagePicker _picker = ImagePicker();
                              final XFile? pickedFile = await _picker.pickImage(
                                source: ImageSource.gallery, // You can use ImageSource.camera for camera
                              );
                              if (pickedFile != null) {
                                setState(() {
                                  _courseImage = File(pickedFile.path);
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      TextFormField(
                        controller: startDateController,
                        decoration: const InputDecoration(labelText: 'Start Date'),
                        onTap: () async {
                          FocusScope.of(context).requestFocus(FocusNode());
                          _selectedStartDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          setState(() {
                            startDateController.text = _selectedStartDate != null
                                ? '${_selectedStartDate!.day}-${_selectedStartDate!.month}-${_selectedStartDate!.year}'
                                : '';
                          });
                        },
                      ),
                      TextFormField(
                        controller: endDateController,
                        decoration: const InputDecoration(labelText: 'End Date'),
                        onTap: () async {
                          FocusScope.of(context).requestFocus(FocusNode());
                          _selectedEndDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          setState(() {
                            endDateController.text = _selectedEndDate != null
                                ? '${_selectedEndDate!.day}-${_selectedEndDate!.month}-${_selectedEndDate!.year}'
                                : '';
                          });
                        },
                      ),
                      TextFormField(
                        controller: startTimeController,
                        decoration: const InputDecoration(labelText: 'Start Time'),
                        onTap: () async {
                          FocusScope.of(context).requestFocus(FocusNode());
                          _selectedStartTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          setState(() {
                            startTimeController.text = _selectedStartTime != null
                                ? _selectedStartTime!.format(context)
                                : '';
                          });
                        },
                      ),
                      TextFormField(
                        controller: endTimeController,
                        decoration: const InputDecoration(labelText: 'End Time'),
                        onTap: () async {
                          FocusScope.of(context).requestFocus(FocusNode());
                          _selectedEndTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          setState(() {
                            endTimeController.text = _selectedEndTime != null
                                ? _selectedEndTime!.format(context)
                                : '';
                          });
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  String? imageUrl;
                  if (_courseImage != null) {
                    imageUrl = await _uploadImage(_courseImage!);
                  }

                  Courses newCourse = Courses(
                    name: nameController.text,
                    description: descriptionController.text,
                    instructor: instructorController.text,
                    instructorBio: instructorBioController.text,
                    objectives: objectivesController.text.split(','),
                    startDate: dateFormat.format(_selectedStartDate!),
                    endDate: dateFormat.format(_selectedEndDate!),
                    startTime: formatTime(_selectedStartTime!),
                    endTime: formatTime(_selectedEndTime!),
                    mode: _selectedMode!,
                    location: _selectedMode == 'Physical'
                        ? locationController.text
                        : null,
                    imageUrl: imageUrl,
                  );

                  await _courseService.addCourse(newCourse, context);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Add'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Courses>>(
      stream: _courseService.getCourses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final courses = snapshot.data ?? [];

        return Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _showAddCourseDialog,
                child: const Text("Add Course"),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                return Card(
                  child: Column(
                    children: [
                      Text(course.name ?? 'no name'),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          await _courseService.deleteCourse(course, context);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
