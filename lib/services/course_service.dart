                  import 'package:cloud_firestore/cloud_firestore.dart';
                  import 'package:flutter/material.dart';
                  import 'package:admin/models/courses.dart';
                  import 'package:firebase_storage/firebase_storage.dart';

                  class CourseService {
                    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
                    final FirebaseStorage _storage = FirebaseStorage.instance;

                    // Add a new course
                    Future<void> addCourse(Courses course, BuildContext context) async {
                      try {
                        await _firestore.collection('courses').add(course.toJson());
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Course added successfully!')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to add course: $e')),
                        );
                      }
                    }

                    // Update an existing course
                    Future<void> updateCourse(Courses course, BuildContext context) async {
                      try {
                        if (course.id == null) {
                          throw Exception('Course ID is required for update');
                        }
                        await _firestore.collection('courses').doc(course.id).update(course.toJson());
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Course updated successfully!')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to update course: $e')),
                        );
                      }
                    }

                    // Delete a course
                    Future<void> deleteCourse(Courses course, BuildContext context) async {
                      try {
                        // First, delete associated images from Firebase Storage
                        if (course.imageUrl != null) {
                          await _storage.refFromURL(course.imageUrl!).delete();
                        }
                        if (course.instructorImage != null) {
                          await _storage.refFromURL(course.instructorImage!).delete();
                        }

                        // Delete the course from Firestore
                        await _firestore.collection('courses').doc(course.id).delete();
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Course deleted successfully!')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to delete course: $e')),
                        );
                      }
                    }

                    // Get all courses
                    Stream<List<Courses>> getCourses() {
                      return _firestore.collection('courses').snapshots().map((snapshot) {
                        return snapshot.docs.map((doc) {
                          return Courses.fromJson(doc.data(), documentId: doc.id);
                        }).toList();
                      });
                    }
                  }