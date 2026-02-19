import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:admin/constants.dart';
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
      final String fileName =
          'course_images/${DateTime.now().millisecondsSinceEpoch}_${_selectedImageName ?? "image.png"}';
      final Reference storageRef = _storage.ref().child(fileName);

      // Determine the MIME type based on the file extension
      final String mimeType = _selectedImageName?.endsWith('.png') ?? false
          ? 'image/png'
          : 'image/jpeg';

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
          child: CircularProgressIndicator(color: primaryColor, strokeWidth: 2),
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
        'courseLink': courseLink, // Add courseLink to the data
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
        SnackBar(
          backgroundColor: successColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text("Course added successfully",
                  style: GoogleFonts.inter(color: Colors.white)),
            ],
          ),
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: dangerColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                  child: Text("Error adding course: $e",
                      style: GoogleFonts.inter(color: Colors.white))),
            ],
          ),
        ),
      );
    }
  }

  Widget _courseField({
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextEditingController? controller,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: darkTextColor,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            readOnly: readOnly,
            onTap: onTap,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: GoogleFonts.inter(fontSize: 14, color: darkTextColor),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 20, color: bodyTextColor),
              filled: true,
              fillColor: bgColor,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryColor, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: dangerColor),
              ),
            ),
            validator: validator,
            onSaved: onSaved,
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: primaryColor),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: darkTextColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: secondaryColor,
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.05),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.school_rounded, color: primaryColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Add New Course",
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: darkTextColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Fill in the course details below",
                    style:
                        GoogleFonts.inter(fontSize: 12, color: bodyTextColor),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: bodyTextColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.close, size: 18, color: bodyTextColor),
              ),
            ),
          ],
        ),
      ),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                // Basic Information
                _sectionHeader("Basic Information", Icons.info_outline_rounded),
                _courseField(
                  label: "Course Name",
                  icon: Icons.book_rounded,
                  validator: (value) =>
                      value?.isEmpty ?? true ? "Course name is required" : null,
                  onSaved: (value) => name = value,
                ),
                _courseField(
                  label: "Description",
                  icon: Icons.description_rounded,
                  maxLines: 3,
                  validator: (value) =>
                      value?.isEmpty ?? true ? "Description is required" : null,
                  onSaved: (value) => description = value,
                ),

                // Course Image
                _sectionHeader("Course Image", Icons.image_rounded),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: bgColor,
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: _selectedImageBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.memory(
                              _selectedImageBytes!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.cloud_upload_rounded,
                                    size: 32, color: primaryColor),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "Click to upload course image",
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: bodyTextColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "PNG, JPG up to 5MB",
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: bodyTextColor.withOpacity(0.7)),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 14),

                // Instructor Information
                _sectionHeader("Instructor Information", Icons.person_rounded),
                _courseField(
                  label: "Instructor Name",
                  icon: Icons.person_rounded,
                  validator: (value) => value?.isEmpty ?? true
                      ? "Instructor name is required"
                      : null,
                  onSaved: (value) => instructor = value,
                ),
                _courseField(
                  label: "Instructor Bio",
                  icon: Icons.person_outline_rounded,
                  maxLines: 2,
                  onSaved: (value) => instructorBio = value,
                ),

                // Schedule
                _sectionHeader("Schedule", Icons.calendar_month_rounded),
                Row(
                  children: [
                    Expanded(
                      child: _courseField(
                        label: "Start Date",
                        icon: Icons.calendar_today_rounded,
                        controller: _startDateController,
                        readOnly: true,
                        onTap: () => _selectDate(context, true),
                        validator: (value) => value?.isEmpty ?? true
                            ? "Start date is required"
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _courseField(
                        label: "End Date",
                        icon: Icons.calendar_today_rounded,
                        controller: _endDateController,
                        readOnly: true,
                        onTap: () => _selectDate(context, false),
                        validator: (value) => value?.isEmpty ?? true
                            ? "End date is required"
                            : null,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: _courseField(
                        label: "Start Time",
                        icon: Icons.access_time_rounded,
                        controller: _startTimeController,
                        readOnly: true,
                        onTap: () => _selectTime(context, true),
                        validator: (value) => value?.isEmpty ?? true
                            ? "Start time is required"
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _courseField(
                        label: "End Time",
                        icon: Icons.access_time_rounded,
                        controller: _endTimeController,
                        readOnly: true,
                        onTap: () => _selectTime(context, false),
                        validator: (value) => value?.isEmpty ?? true
                            ? "End time is required"
                            : null,
                      ),
                    ),
                  ],
                ),

                // Course Details
                _sectionHeader("Course Details", Icons.tune_rounded),
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Mode",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: darkTextColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.laptop_mac_rounded,
                              size: 20, color: bodyTextColor),
                          filled: true,
                          fillColor: bgColor,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: primaryColor, width: 1.5),
                          ),
                        ),
                        style: GoogleFonts.inter(
                            fontSize: 14, color: darkTextColor),
                        dropdownColor: secondaryColor,
                        items: courseModes.map((String mode) {
                          return DropdownMenuItem<String>(
                            value: mode,
                            child: Text(mode),
                          );
                        }).toList(),
                        onChanged: (String? value) {
                          setState(() {
                            mode = value;
                            location = null;
                            courseLink = null;
                          });
                        },
                        validator: (value) =>
                            value == null ? "Mode is required" : null,
                      ),
                    ],
                  ),
                ),

                // Conditional fields based on mode
                if (mode == 'Physical')
                  _courseField(
                    label: "Location",
                    icon: Icons.location_on_rounded,
                    validator: (value) => value?.isEmpty ?? true
                        ? "Location is required for physical courses"
                        : null,
                    onSaved: (value) => location = value,
                  ),

                if (mode == 'Online')
                  _courseField(
                    label: "Course Link",
                    icon: Icons.link_rounded,
                    validator: (value) => value?.isEmpty ?? true
                        ? "Course link is required for online courses"
                        : null,
                    onSaved: (value) => courseLink = value,
                  ),

                _courseField(
                  label: "Price",
                  icon: Icons.attach_money_rounded,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return "Price is required";
                    if (double.tryParse(value!) == null) return "Invalid price";
                    return null;
                  },
                  onSaved: (value) => price = double.tryParse(value!),
                ),
                _courseField(
                  label: "Duration (weeks)",
                  icon: Icons.timer_rounded,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return "Duration is required";
                    if (int.tryParse(value!) == null) return "Invalid duration";
                    return null;
                  },
                  onSaved: (value) => duration = int.tryParse(value!),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Difficulty",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: darkTextColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.trending_up_rounded,
                              size: 20, color: bodyTextColor),
                          filled: true,
                          fillColor: bgColor,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: primaryColor, width: 1.5),
                          ),
                        ),
                        style: GoogleFonts.inter(
                            fontSize: 14, color: darkTextColor),
                        dropdownColor: secondaryColor,
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
                    ],
                  ),
                ),

                // Course Objectives
                _sectionHeader("Course Objectives", Icons.checklist_rounded),
                Row(
                  children: [
                    Expanded(
                      child: _courseField(
                        label: "Add Objective",
                        icon: Icons.flag_rounded,
                        controller: objectiveController,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon:
                            const Icon(Icons.add_rounded, color: Colors.white),
                        onPressed: _addObjective,
                      ),
                    ),
                  ],
                ),
                _courseField(
                  label: "Rating (0-5)",
                  icon: Icons.star_rounded,
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
                if (objectives.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Added Objectives",
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: darkTextColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...objectives.asMap().entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: secondaryColor,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: borderColor),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      "${entry.key + 1}",
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      entry.value,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: darkTextColor,
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => _removeObjective(entry.key),
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: dangerColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(Icons.close,
                                          size: 16, color: dangerColor),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ],
            ),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: borderColor),
                ),
                child: Text(
                  "Cancel",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    color: bodyTextColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _saveCourse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Save Course",
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
