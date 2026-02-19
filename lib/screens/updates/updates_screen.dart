import 'package:admin/constants.dart';
import 'package:admin/responsive.dart';
import 'package:admin/screens/dashboard/components/header.dart';
import 'package:admin/screens/main/components/side_menu.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
                "Manage updates that are displayed on the mobile app",
                style: GoogleFonts.inter(fontSize: 14, color: bodyTextColor),
              ),
              const SizedBox(height: defaultPadding),
              // Add Update Button
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: cardDecoration,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
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
                      ],
                    ),
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
                            Text('Error loading updates',
                                style: GoogleFonts.inter(color: bodyTextColor)),
                          ],
                        ),
                      ),
                    );
                  }

                  final updates = snapshot.data?.docs ?? [];

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
                              'No updates yet',
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

  void _showAddUpdateDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String selectedCategory = 'General';

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
            width: 500,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Title',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: darkTextColor)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: titleController,
                    style: GoogleFonts.inter(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Enter update title',
                      hintStyle: GoogleFonts.inter(color: bodyTextColor),
                      fillColor: bgColor,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
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
                    validator: (v) =>
                        v?.isEmpty ?? true ? 'Title is required' : null,
                  ),
                  const SizedBox(height: 16),
                  Text('Description',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: darkTextColor)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: descriptionController,
                    style: GoogleFonts.inter(fontSize: 14),
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Enter update description',
                      hintStyle: GoogleFonts.inter(color: bodyTextColor),
                      fillColor: bgColor,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
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
                    validator: (v) =>
                        v?.isEmpty ?? true ? 'Description is required' : null,
                  ),
                  const SizedBox(height: 16),
                  Text('Category',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: darkTextColor)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    style:
                        GoogleFonts.inter(fontSize: 14, color: darkTextColor),
                    decoration: InputDecoration(
                      fillColor: bgColor,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: borderColor)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: borderColor)),
                    ),
                    items: [
                      'General',
                      'Event',
                      'Course',
                      'Service',
                      'Announcement'
                    ]
                        .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c,
                                style: GoogleFonts.inter(fontSize: 14))))
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => selectedCategory = v!),
                  ),
                ],
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
                    await _firestore.collection('latest_updates').add({
                      'title': titleController.text.trim(),
                      'description': descriptionController.text.trim(),
                      'category': selectedCategory,
                      'createdAt': FieldValue.serverTimestamp(),
                      'isActive': true,
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text('Update added successfully',
                                style: GoogleFonts.inter()),
                          ],
                        ),
                        backgroundColor: successColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: dangerColor,
                      ),
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

  void _showEditUpdateDialog(
      BuildContext context, String docId, Map<String, dynamic> data) {
    final titleController = TextEditingController(text: data['title']);
    final descriptionController =
        TextEditingController(text: data['description']);
    final formKey = GlobalKey<FormState>();
    String selectedCategory = data['category'] ?? 'General';

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
            width: 500,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Title',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: darkTextColor)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: titleController,
                    style: GoogleFonts.inter(fontSize: 14),
                    decoration: InputDecoration(
                      fillColor: bgColor,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
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
                    validator: (v) =>
                        v?.isEmpty ?? true ? 'Title is required' : null,
                  ),
                  const SizedBox(height: 16),
                  Text('Description',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: darkTextColor)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: descriptionController,
                    style: GoogleFonts.inter(fontSize: 14),
                    maxLines: 4,
                    decoration: InputDecoration(
                      fillColor: bgColor,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
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
                    validator: (v) =>
                        v?.isEmpty ?? true ? 'Description is required' : null,
                  ),
                  const SizedBox(height: 16),
                  Text('Category',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: darkTextColor)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    style:
                        GoogleFonts.inter(fontSize: 14, color: darkTextColor),
                    decoration: InputDecoration(
                      fillColor: bgColor,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: borderColor)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: borderColor)),
                    ),
                    items: [
                      'General',
                      'Event',
                      'Course',
                      'Service',
                      'Announcement'
                    ]
                        .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c,
                                style: GoogleFonts.inter(fontSize: 14))))
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => selectedCategory = v!),
                  ),
                ],
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
                    await _firestore
                        .collection('latest_updates')
                        .doc(docId)
                        .update({
                      'title': titleController.text.trim(),
                      'description': descriptionController.text.trim(),
                      'category': selectedCategory,
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text('Update edited successfully',
                                style: GoogleFonts.inter()),
                          ],
                        ),
                        backgroundColor: successColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: dangerColor,
                      ),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text('Update deleted', style: GoogleFonts.inter()),
                      ],
                    ),
                    backgroundColor: successColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: dangerColor,
                  ),
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
    final isActive = data['isActive'] ?? true;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: cardShadow,
        border: Border(
          left: BorderSide(color: catColor, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: catColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getCategoryIcon(category), size: 14, color: catColor),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive
                      ? successColor.withOpacity(0.1)
                      : bodyTextColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isActive ? 'Active' : 'Inactive',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isActive ? successColor : bodyTextColor,
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
                  if (value == 'toggle') {
                    FirebaseFirestore.instance
                        .collection('latest_updates')
                        .doc(docId)
                        .update({'isActive': !isActive});
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
                        Text('Edit', style: GoogleFonts.inter(fontSize: 14)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(
                            isActive
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: 18,
                            color: warningColor),
                        const SizedBox(width: 8),
                        Text(isActive ? 'Deactivate' : 'Activate',
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
          Text(
            data['title'] ?? '',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: darkTextColor,
            ),
          ),
          const SizedBox(height: 6),
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
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time_rounded,
                  size: 14, color: bodyTextColor.withOpacity(0.6)),
              const SizedBox(width: 4),
              Text(
                dateStr,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: bodyTextColor.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
