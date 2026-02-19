import 'dart:io';

import 'package:admin/constants.dart';
import 'package:admin/models/courses.dart';
import 'package:admin/screens/courses/course_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddCourse extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Size _size = MediaQuery.of(context).size;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                    child: const Icon(Icons.school_rounded,
                        color: primaryColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text("All Courses",
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: darkTextColor)),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (context) => AddCourseDialog());
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text("Add Course",
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ],
          ),
        ),
        SizedBox(height: defaultPadding),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance.collection('courses').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: primaryColor, strokeWidth: 2));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.school_outlined,
                            color: primaryColor, size: 36),
                      ),
                      const SizedBox(height: 16),
                      Text("No courses available",
                          style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: darkTextColor)),
                    ],
                  ),
                );
              }
              return GridView.builder(
                shrinkWrap: true,
                physics: AlwaysScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _size.width > 1200 ? 3 : 2,
                  crossAxisSpacing: defaultPadding,
                  mainAxisSpacing: defaultPadding,
// Adjusted ratio
                ),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var courseData = snapshot.data!.docs[index];
                  return CourseCard(
                    course: Courses.fromJson(
                      courseData.data() as Map<String, dynamic>,
                      documentId: courseData.id,
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

class CourseCard extends StatelessWidget {
  final Courses course;
  final VoidCallback? onTap;

  const CourseCard({
    Key? key,
    required this.course,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: cardDecoration,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: course.imageUrl != null
                            ? Image.network(
                                course.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(color: bgColor, child: const Icon(Icons.image, size: 50, color: bodyTextColor));
                                },
                              )
                            : Container(color: bgColor, child: const Icon(Icons.image, size: 50, color: bodyTextColor)),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                course.name ?? 'Untitled Course',
                                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: darkTextColor),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                course.instructor ?? 'Unknown Instructor',
                                style: GoogleFonts.inter(fontSize: 13, color: bodyTextColor),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 4,
                                children: [
                                  Text(
                                    '${course.rating?.toStringAsFixed(1) ?? "0.0"}',
                                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.amber[700]),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: List.generate(5, (index) {
                                      final rating = course.rating ?? 0;
                                      final isHalf = rating - index > 0 && rating - index < 1;
                                      final isFull = rating - index >= 1;
                                      return Icon(
                                        isFull ? Icons.star : isHalf ? Icons.star_half : Icons.star_border,
                                        size: 14,
                                        color: Colors.amber[700],
                                      );
                                    }),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                '\$${course.price?.toStringAsFixed(2) ?? "0.00"}',
                                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: darkTextColor),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
