import 'dart:typed_data';

import 'package:admin/constants.dart';
import 'package:admin/responsive.dart';
import 'package:admin/screens/dashboard/components/header.dart';
import 'package:admin/screens/main/components/side_menu.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class UpdatesScreen extends StatelessWidget {
  const UpdatesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Responsive.isDesktop(context)
          ? null
          : const Drawer(child: SideMenu()),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (Responsive.isDesktop(context))
              const SizedBox(width: 260, child: SideMenu()),
            const Expanded(flex: 5, child: UpdatesListScreen()),
          ],
        ),
      ),
    );
  }
}

class UpdatesListScreen extends StatefulWidget {
  const UpdatesListScreen({Key? key}) : super(key: key);

  @override
  State<UpdatesListScreen> createState() => _UpdatesListScreenState();
}

class _UpdatesListScreenState extends State<UpdatesListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _filterStatus = 'All';

  static const List<String> _statusOptions = [
    'Draft',
    'Published',
    'Scheduled',
    'Archived',
  ];

  static const List<String> _categoryOptions = [
    'General',
    'Event',
    'Course',
    'Service',
    'Announcement',
    'News',
    'Alert',
  ];

  static const List<String> _priorityOptions = ['Low', 'Normal', 'High'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(defaultPadding * 1.5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Header(title: "Latest Updates"),
              const SizedBox(height: defaultPadding),
              Text(
                "Latest Updates",
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: darkTextColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Manage updates displayed on the mobile app",
                style: GoogleFonts.inter(fontSize: 14, color: bodyTextColor),
              ),
              const SizedBox(height: defaultPadding),
              // Action Bar
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: cardDecoration,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.campaign_rounded,
                          color: primaryColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "All Updates",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: darkTextColor,
                      ),
                    ),
                    const Spacer(),
                    // Filter dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _filterStatus,
                          icon: const Icon(Icons.filter_list_rounded,
                              size: 18, color: bodyTextColor),
                          style: GoogleFonts.inter(
                              fontSize: 13, color: darkTextColor),
                          items: ['All', ..._statusOptions]
                              .map((s) =>
                                  DropdownMenuItem(value: s, child: Text(s)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _filterStatus = v ?? 'All'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _showAddUpdateDialog(context),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text("Add Update",
                          style:
                              GoogleFonts.inter(fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: defaultPadding),
              // Updates List
              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('latest_updates')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(
                            color: primaryColor, strokeWidth: 3),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            const Icon(Icons.error_outline,
                                color: dangerColor, size: 48),
                            const SizedBox(height: 12),
                            Text('Error loading updates: ${snapshot.error}',
                                style: GoogleFonts.inter(color: bodyTextColor)),
                          ],
                        ),
                      ),
                    );
                  }

                  var updates = snapshot.data?.docs ?? [];

                  // Client-side filter by status
                  if (_filterStatus != 'All') {
                    updates = updates.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return data['status'] == _filterStatus;
                    }).toList();
                  }

                  if (updates.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(60),
                        child: Column(
                          children: [
                            Icon(Icons.campaign_outlined,
                                color: bodyTextColor.withOpacity(0.3),
                                size: 64),
                            const SizedBox(height: 16),
                            Text(
                              _filterStatus == 'All'
                                  ? 'No updates yet'
                                  : 'No $_filterStatus updates',
                              style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: darkTextColor),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add your first update to display on the mobile app',
                              style: GoogleFonts.inter(
                                  fontSize: 14, color: bodyTextColor),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: updates.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: defaultPadding * 0.75),
                    itemBuilder: (context, index) {
                      final doc = updates[index];
                      final data = doc.data() as Map<String, dynamic>;
                      return _UpdateCard(
                        docId: doc.id,
                        data: data,
                        onEdit: () =>
                            _showEditUpdateDialog(context, doc.id, data),
                        onDelete: () =>
                            _showDeleteConfirmation(context, doc.id),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== HELPER WIDGETS ====================
  Widget _fieldLabel(String label) {
    return Text(label,
        style: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w600, color: darkTextColor));
  }

  Widget _buildTextField(TextEditingController controller, String hint,
      {int maxLines = 1, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      style: GoogleFonts.inter(fontSize: 14),
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: bodyTextColor),
        fillColor: bgColor,
        filled: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
      validator: validator,
    );
  }

  Widget _buildDropdown(
      String value, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      style: GoogleFonts.inter(fontSize: 14, color: darkTextColor),
      decoration: InputDecoration(
        fillColor: bgColor,
        filled: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: borderColor)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: borderColor)),
      ),
      items: items
          .map((c) => DropdownMenuItem(
              value: c, child: Text(c, style: GoogleFonts.inter(fontSize: 14))))
          .toList(),
      onChanged: onChanged,
    );
  }

  void _showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(message, style: GoogleFonts.inter()),
          ],
        ),
        backgroundColor: successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // ==================== IMAGE UPLOAD ====================
  Future<String?> _uploadImage(
      Uint8List bytes, String fileName, StateSetter setDialogState,
      ValueChanged<bool> setUploading, ValueChanged<String?> setUrl) async {
    try {
      setUploading(true);
      final ext = fileName.split('.').last;
      final ref = FirebaseStorage.instance
          .ref()
          .child('update_images')
          .child('${DateTime.now().millisecondsSinceEpoch}.$ext');
      final uploadTask = await ref.putData(
          bytes, SettableMetadata(contentType: 'image/$ext'));
      final url = await uploadTask.ref.getDownloadURL();
      setUrl(url);
      setUploading(false);
      return url;
    } catch (e) {
      setUploading(false);
      return null;
    }
  }

  Widget _buildImagePicker({
    required String? imageUrl,
    required Uint8List? pickedBytes,
    required bool isUploading,
    required StateSetter setDialogState,
    required ValueChanged<Uint8List?> onBytesPicked,
    required ValueChanged<String?> onUrlChanged,
    required ValueChanged<bool> onUploadingChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Image'),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              // Preview
              if (pickedBytes != null)
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(10)),
                  child: Image.memory(pickedBytes,
                      height: 140, width: double.infinity, fit: BoxFit.cover),
                )
              else if (imageUrl != null && imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(10)),
                  child: Image.network(imageUrl,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                            height: 80,
                            color: bgColor,
                            child: Center(
                              child: Text('Image failed to load',
                                  style: GoogleFonts.inter(
                                      fontSize: 12, color: bodyTextColor)),
                            ),
                          )),
                ),
              // Buttons
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    if (isUploading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: primaryColor),
                      ),
                    if (isUploading)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text('Uploading...',
                            style: GoogleFonts.inter(
                                fontSize: 12, color: bodyTextColor)),
                      ),
                    if (!isUploading)
                      OutlinedButton.icon(
                        onPressed: () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.image,
                            withData: true,
                          );
                          if (result != null &&
                              result.files.single.bytes != null) {
                            final bytes = result.files.single.bytes!;
                            final name = result.files.single.name;
                            onBytesPicked(bytes);
                            await _uploadImage(
                                bytes, name, setDialogState,
                                onUploadingChanged, onUrlChanged);
                          }
                        },
                        icon: const Icon(Icons.upload_rounded, size: 16),
                        label: Text(
                          imageUrl != null && imageUrl.isNotEmpty
                              ? 'Change Image'
                              : 'Upload Image',
                          style: GoogleFonts.inter(fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryColor,
                          side: const BorderSide(color: primaryColor),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                        ),
                      ),
                    const Spacer(),
                    if ((imageUrl != null && imageUrl.isNotEmpty) ||
                        pickedBytes != null)
                      IconButton(
                        onPressed: () {
                          onBytesPicked(null);
                          onUrlChanged(null);
                        },
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: dangerColor, size: 20),
                        tooltip: 'Remove image',
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== ADD UPDATE DIALOG ====================
  void _showAddUpdateDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final targetAudienceController = TextEditingController();
    final authorController = TextEditingController();
    final linkController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String selectedCategory = 'General';
    String selectedStatus = 'Published';
    String selectedPriority = 'Normal';
    DateTime? scheduledDate;
    String? uploadedImageUrl;
    Uint8List? pickedImageBytes;
    bool isUploadingImage = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add_rounded,
                    color: primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Add New Update',
                  style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: darkTextColor)),
            ],
          ),
          content: SizedBox(
            width: 600,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title (required)
                    _fieldLabel('Title *'),
                    const SizedBox(height: 6),
                    _buildTextField(titleController, 'Enter update title',
                        validator: (v) =>
                            v?.isEmpty ?? true ? 'Title is required' : null),
                    const SizedBox(height: 16),

                    // Description (required)
                    _fieldLabel('Description *'),
                    const SizedBox(height: 6),
                    _buildTextField(
                        descriptionController, 'Enter update description',
                        maxLines: 4,
                        validator: (v) => v?.isEmpty ?? true
                            ? 'Description is required'
                            : null),
                    const SizedBox(height: 16),

                    // Image upload
                    _buildImagePicker(
                      imageUrl: uploadedImageUrl,
                      pickedBytes: pickedImageBytes,
                      isUploading: isUploadingImage,
                      setDialogState: setDialogState,
                      onBytesPicked: (bytes) =>
                          setDialogState(() => pickedImageBytes = bytes),
                      onUrlChanged: (url) =>
                          setDialogState(() => uploadedImageUrl = url),
                      onUploadingChanged: (v) =>
                          setDialogState(() => isUploadingImage = v),
                    ),
                    const SizedBox(height: 16),

                    // Row: Category + Status
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('Category'),
                              const SizedBox(height: 6),
                              _buildDropdown(selectedCategory, _categoryOptions,
                                  (v) {
                                setDialogState(() => selectedCategory = v!);
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('Status'),
                              const SizedBox(height: 6),
                              _buildDropdown(selectedStatus, _statusOptions,
                                  (v) {
                                setDialogState(() => selectedStatus = v!);
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Row: Priority + Publish Date
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('Priority'),
                              const SizedBox(height: 6),
                              _buildDropdown(selectedPriority, _priorityOptions,
                                  (v) {
                                setDialogState(() => selectedPriority = v!);
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('Publish Date'),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate:
                                        scheduledDate ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                  );
                                  if (picked != null) {
                                    setDialogState(
                                        () => scheduledDate = picked);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 13),
                                  decoration: BoxDecoration(
                                    color: bgColor,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: borderColor),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          scheduledDate != null
                                              ? DateFormat('MMM d, yyyy')
                                                  .format(scheduledDate!)
                                              : 'Select date',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: scheduledDate != null
                                                ? darkTextColor
                                                : bodyTextColor,
                                          ),
                                        ),
                                      ),
                                      const Icon(Icons.calendar_today_rounded,
                                          size: 16, color: bodyTextColor),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Target Audience
                    _fieldLabel('Target Audience'),
                    const SizedBox(height: 6),
                    _buildTextField(
                        targetAudienceController, 'e.g. Deaf Community, All'),
                    const SizedBox(height: 16),

                    // Row: Author + Link
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('Author'),
                              const SizedBox(height: 6),
                              _buildTextField(authorController, 'Author name'),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('Link / URL'),
                              const SizedBox(height: 6),
                              _buildTextField(linkController, 'https://...'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: GoogleFonts.inter(color: bodyTextColor)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    final data = <String, dynamic>{
                      'title': titleController.text.trim(),
                      'description': descriptionController.text.trim(),
                      'category': selectedCategory,
                      'status': selectedStatus,
                      'priority': selectedPriority,
                      'createdAt': FieldValue.serverTimestamp(),
                      'isActive': selectedStatus == 'Published',
                    };

                    // Optional fields
                    if (uploadedImageUrl != null &&
                        uploadedImageUrl!.isNotEmpty) {
                      data['imageUrl'] = uploadedImageUrl;
                    }

                    final targetAudience = targetAudienceController.text.trim();
                    if (targetAudience.isNotEmpty) {
                      data['targetAudience'] = targetAudience;
                    }

                    final author = authorController.text.trim();
                    if (author.isNotEmpty) data['author'] = author;

                    final link = linkController.text.trim();
                    if (link.isNotEmpty) data['link'] = link;

                    if (scheduledDate != null) {
                      data['publishDate'] = Timestamp.fromDate(scheduledDate!);
                    }

                    await _firestore.collection('latest_updates').add(data);
                    Navigator.pop(context);
                    _showSuccessSnackbar(context, 'Update added successfully');
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: dangerColor),
                    );
                  }
                }
              },
              child: Text('Add Update',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== EDIT UPDATE DIALOG ====================
  void _showEditUpdateDialog(
      BuildContext context, String docId, Map<String, dynamic> data) {
    final titleController = TextEditingController(text: data['title'] ?? '');
    final descriptionController =
        TextEditingController(text: data['description'] ?? '');
    final targetAudienceController =
        TextEditingController(text: data['targetAudience'] ?? '');
    final authorController = TextEditingController(text: data['author'] ?? '');
    final linkController = TextEditingController(text: data['link'] ?? '');
    final formKey = GlobalKey<FormState>();
    String selectedCategory = data['category'] ?? 'General';
    String selectedStatus = data['status'] ?? 'Published';
    String selectedPriority = data['priority'] ?? 'Normal';
    DateTime? scheduledDate;
    if (data['publishDate'] is Timestamp) {
      scheduledDate = (data['publishDate'] as Timestamp).toDate();
    }
    String? uploadedImageUrl = data['imageUrl'] as String?;
    Uint8List? pickedImageBytes;
    bool isUploadingImage = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.edit_rounded,
                    color: primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Edit Update',
                  style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: darkTextColor)),
            ],
          ),
          content: SizedBox(
            width: 600,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('Title *'),
                    const SizedBox(height: 6),
                    _buildTextField(titleController, 'Enter update title',
                        validator: (v) =>
                            v?.isEmpty ?? true ? 'Title is required' : null),
                    const SizedBox(height: 16),
                    _fieldLabel('Description *'),
                    const SizedBox(height: 6),
                    _buildTextField(
                        descriptionController, 'Enter update description',
                        maxLines: 4,
                        validator: (v) => v?.isEmpty ?? true
                            ? 'Description is required'
                            : null),
                    const SizedBox(height: 16),
                    _buildImagePicker(
                      imageUrl: uploadedImageUrl,
                      pickedBytes: pickedImageBytes,
                      isUploading: isUploadingImage,
                      setDialogState: setDialogState,
                      onBytesPicked: (bytes) =>
                          setDialogState(() => pickedImageBytes = bytes),
                      onUrlChanged: (url) =>
                          setDialogState(() => uploadedImageUrl = url),
                      onUploadingChanged: (v) =>
                          setDialogState(() => isUploadingImage = v),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('Category'),
                              const SizedBox(height: 6),
                              _buildDropdown(selectedCategory, _categoryOptions,
                                  (v) {
                                setDialogState(() => selectedCategory = v!);
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('Status'),
                              const SizedBox(height: 6),
                              _buildDropdown(selectedStatus, _statusOptions,
                                  (v) {
                                setDialogState(() => selectedStatus = v!);
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('Priority'),
                              const SizedBox(height: 6),
                              _buildDropdown(selectedPriority, _priorityOptions,
                                  (v) {
                                setDialogState(() => selectedPriority = v!);
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('Publish Date'),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate:
                                        scheduledDate ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                  );
                                  if (picked != null) {
                                    setDialogState(
                                        () => scheduledDate = picked);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 13),
                                  decoration: BoxDecoration(
                                    color: bgColor,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: borderColor),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          scheduledDate != null
                                              ? DateFormat('MMM d, yyyy')
                                                  .format(scheduledDate!)
                                              : 'Select date',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: scheduledDate != null
                                                ? darkTextColor
                                                : bodyTextColor,
                                          ),
                                        ),
                                      ),
                                      const Icon(Icons.calendar_today_rounded,
                                          size: 16, color: bodyTextColor),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _fieldLabel('Target Audience'),
                    const SizedBox(height: 6),
                    _buildTextField(
                        targetAudienceController, 'e.g. Deaf Community, All'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('Author'),
                              const SizedBox(height: 6),
                              _buildTextField(authorController, 'Author name'),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('Link / URL'),
                              const SizedBox(height: 6),
                              _buildTextField(linkController, 'https://...'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: GoogleFonts.inter(color: bodyTextColor)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    final updateData = <String, dynamic>{
                      'title': titleController.text.trim(),
                      'description': descriptionController.text.trim(),
                      'category': selectedCategory,
                      'status': selectedStatus,
                      'priority': selectedPriority,
                      'isActive': selectedStatus == 'Published',
                    };

                    updateData['imageUrl'] =
                        (uploadedImageUrl != null &&
                                uploadedImageUrl!.isNotEmpty)
                            ? uploadedImageUrl
                            : null;

                    final targetAudience = targetAudienceController.text.trim();
                    updateData['targetAudience'] =
                        targetAudience.isNotEmpty ? targetAudience : null;

                    final author = authorController.text.trim();
                    updateData['author'] = author.isNotEmpty ? author : null;

                    final link = linkController.text.trim();
                    updateData['link'] = link.isNotEmpty ? link : null;

                    if (scheduledDate != null) {
                      updateData['publishDate'] =
                          Timestamp.fromDate(scheduledDate!);
                    }

                    await _firestore
                        .collection('latest_updates')
                        .doc(docId)
                        .update(updateData);
                    Navigator.pop(context);
                    _showSuccessSnackbar(context, 'Update edited successfully');
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: dangerColor),
                    );
                  }
                }
              },
              child: Text('Save Changes',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: dangerColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: dangerColor, size: 20),
            ),
            const SizedBox(width: 12),
            Text('Delete Update',
                style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: darkTextColor)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete this update? This action cannot be undone.',
          style: GoogleFonts.inter(fontSize: 14, color: bodyTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('Cancel', style: GoogleFonts.inter(color: bodyTextColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: dangerColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            onPressed: () async {
              try {
                await _firestore
                    .collection('latest_updates')
                    .doc(docId)
                    .delete();
                Navigator.pop(context);
                _showSuccessSnackbar(context, 'Update deleted');
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Error: $e'), backgroundColor: dangerColor),
                );
              }
            },
            child: Text('Delete',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ==================== UPDATE CARD ====================
class _UpdateCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UpdateCard({
    required this.docId,
    required this.data,
    required this.onEdit,
    required this.onDelete,
  });

  IconData _getCategoryIcon(String? category) {
    switch (category) {
      case 'Event':
        return Icons.event_rounded;
      case 'Course':
        return Icons.school_rounded;
      case 'Service':
        return Icons.miscellaneous_services_rounded;
      case 'Announcement':
        return Icons.campaign_rounded;
      case 'News':
        return Icons.newspaper_rounded;
      case 'Alert':
        return Icons.warning_amber_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  Color _getCategoryColor(String? category) {
    switch (category) {
      case 'Event':
        return warningColor;
      case 'Course':
        return successColor;
      case 'Service':
        return infoColor;
      case 'Announcement':
        return dangerColor;
      case 'News':
        return const Color(0xFF9B59B6);
      case 'Alert':
        return const Color(0xFFE74C3C);
      default:
        return primaryColor;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Published':
        return successColor;
      case 'Draft':
        return warningColor;
      case 'Scheduled':
        return infoColor;
      case 'Archived':
        return bodyTextColor;
      default:
        return bodyTextColor;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'Published':
        return Icons.public_rounded;
      case 'Draft':
        return Icons.edit_note_rounded;
      case 'Scheduled':
        return Icons.schedule_rounded;
      case 'Archived':
        return Icons.archive_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Color _getPriorityColor(String? priority) {
    switch (priority) {
      case 'High':
        return dangerColor;
      case 'Normal':
        return primaryColor;
      case 'Low':
        return bodyTextColor;
      default:
        return primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = data['category'] ?? 'General';
    final catColor = _getCategoryColor(category);
    final createdAt = data['createdAt'] as Timestamp?;
    final dateStr = createdAt != null
        ? DateFormat('MMM d, yyyy • h:mm a').format(createdAt.toDate())
        : 'Just now';
    final status = data['status'] ?? 'Published';
    final statusColor = _getStatusColor(status);
    final priority = data['priority'] ?? 'Normal';
    final imageUrl = data['imageUrl'] as String?;
    final author = data['author'] as String?;
    final targetAudience = data['targetAudience'] as String?;

    return Container(
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: cardShadow,
        border: Border(left: BorderSide(color: catColor, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image preview
          if (imageUrl != null && imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius:
                  const BorderRadius.only(topRight: Radius.circular(14)),
              child: Image.network(
                imageUrl,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 60,
                  color: bgColor,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.broken_image_rounded,
                            color: bodyTextColor.withOpacity(0.4), size: 18),
                        const SizedBox(width: 6),
                        Text('Image failed to load',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: bodyTextColor.withOpacity(0.4))),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tags row
                Row(
                  children: [
                    // Category badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: catColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_getCategoryIcon(category),
                              size: 14, color: catColor),
                          const SizedBox(width: 4),
                          Text(
                            category,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: catColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_getStatusIcon(status),
                              size: 12, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            status,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Priority badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(priority).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        priority,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _getPriorityColor(priority),
                        ),
                      ),
                    ),
                    const Spacer(),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded,
                          color: bodyTextColor, size: 20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      onSelected: (value) {
                        if (value == 'edit') onEdit();
                        if (value == 'delete') onDelete();
                        if (value == 'publish') {
                          FirebaseFirestore.instance
                              .collection('latest_updates')
                              .doc(docId)
                              .update({
                            'status': 'Published',
                            'isActive': true,
                          });
                        }
                        if (value == 'archive') {
                          FirebaseFirestore.instance
                              .collection('latest_updates')
                              .doc(docId)
                              .update({
                            'status': 'Archived',
                            'isActive': false,
                          });
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(Icons.edit_rounded,
                                  size: 18, color: primaryColor),
                              const SizedBox(width: 8),
                              Text('Edit',
                                  style: GoogleFonts.inter(fontSize: 14)),
                            ],
                          ),
                        ),
                        if (status != 'Published')
                          PopupMenuItem(
                            value: 'publish',
                            child: Row(
                              children: [
                                const Icon(Icons.public_rounded,
                                    size: 18, color: successColor),
                                const SizedBox(width: 8),
                                Text('Publish',
                                    style: GoogleFonts.inter(fontSize: 14)),
                              ],
                            ),
                          ),
                        if (status != 'Archived')
                          PopupMenuItem(
                            value: 'archive',
                            child: Row(
                              children: [
                                const Icon(Icons.archive_rounded,
                                    size: 18, color: warningColor),
                                const SizedBox(width: 8),
                                Text('Archive',
                                    style: GoogleFonts.inter(fontSize: 14)),
                              ],
                            ),
                          ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete_outline_rounded,
                                  size: 18, color: dangerColor),
                              const SizedBox(width: 8),
                              Text('Delete',
                                  style: GoogleFonts.inter(
                                      fontSize: 14, color: dangerColor)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Title
                Text(
                  data['title'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: darkTextColor,
                  ),
                ),
                const SizedBox(height: 6),
                // Description
                Text(
                  data['description'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: bodyTextColor,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
                // Meta row
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _metaItem(Icons.access_time_rounded, dateStr),
                    if (author != null && author.isNotEmpty)
                      _metaItem(Icons.person_rounded, author),
                    if (targetAudience != null && targetAudience.isNotEmpty)
                      _metaItem(Icons.groups_rounded, targetAudience),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: bodyTextColor.withOpacity(0.6)),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: bodyTextColor.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}
