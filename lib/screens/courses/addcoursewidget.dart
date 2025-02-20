import 'dart:io';

import 'package:admin/constants.dart';
import 'package:admin/models/courses.dart';
import 'package:admin/screens/courses/course_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddCourse extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Size _size = MediaQuery.of(context).size;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Courses",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AddCourseDialog(),
                );
              },
              icon: Icon(Icons.add),
              label: Text("Add Course"),
            ),
          ],
        ),
        SizedBox(height: defaultPadding),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance.collection('courses').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text("No courses available"));
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
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Course Image
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: course.imageUrl != null
                            ? Image.network(
                                course.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: Icon(Icons.image, size: 50),
                                  );
                                },
                              )
                            : Container(
                                color: Colors.grey[300],
                                child: Icon(Icons.image, size: 50),
                              ),
                      ),

                      // Content
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Course Title
                              Text(
                                course.name ?? 'Untitled Course',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),

                              const SizedBox(height: 8),

                              // Instructors
                              Text(
                                course.instructor ?? 'Unknown Instructor',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),

                              const SizedBox(height: 8),

                              // Rating
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 4,
                                children: [
                                  Text(
                                    '${course.rating?.toStringAsFixed(1) ?? "0.0"}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber[700],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: List.generate(5, (index) {
                                      final rating = course.rating ?? 0;
                                      final isHalf = rating - index > 0 &&
                                          rating - index < 1;
                                      final isFull = rating - index >= 1;

                                      return Icon(
                                        isFull
                                            ? Icons.star
                                            : isHalf
                                                ? Icons.star_half
                                                : Icons.star_border,
                                        size: 14,
                                        color: Colors.amber[700],
                                      );
                                    }),
                                  ),
                                  Text(
                                    '(${course.numberOfRatings?.toString() ?? "0"})',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                  ),
                                ],
                              ),

                              const Spacer(),

                              // Price and Bestseller
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                children: [
                                  // Price
                                  Wrap(
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 8,
                                    children: [
                                      Text(
                                        '\$${course.price?.toStringAsFixed(2) ?? "0.00"}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      if (course.originalPrice != null &&
                                          course.originalPrice! >
                                              (course.price ?? 0))
                                        Text(
                                          '\$${course.originalPrice?.toStringAsFixed(2)}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                decoration:
                                                    TextDecoration.lineThrough,
                                                color: Colors.grey[600],
                                              ),
                                        ),
                                    ],
                                  ),

                                  // Bestseller Badge
                                  if (course.isBestseller == true)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.yellow[100],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Bestseller',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                    ),
                                ],
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
