import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/courses.dart';

class CourseService {
  final CollectionReference _courseCollection = FirebaseFirestore.instance.collection('courses');

  // Create
  Future<void> addCourse(Courses course, BuildContext context) async {
    try {
      await _courseCollection.add(course.toJson());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course added successfully!')),
      );
    } catch (e) {
      print("Error adding course: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding course: $e')),
      );
    }
  }

  // Read
  Stream<List<Courses>> getCourses() {
    return _courseCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Courses.fromJson(doc.data() as Map<String, dynamic>, documentId: doc.id);
      }).toList();
    });
  }

  // Read Single Course
  Future<Courses?> getCourse(String courseId) async {
    try {
      DocumentSnapshot doc = await _courseCollection.doc(courseId).get();
      if (doc.exists) {
        return Courses.fromJson(
          doc.data() as Map<String, dynamic>,
          documentId: doc.id,
        );
      }
      return null;
    } catch (e) {
      print("Error getting course: $e");
      return null;
    }
  }

  // Update
  Future<void> updateCourse(Courses course, BuildContext context) async {
    try {
      await _courseCollection.doc(course.id).update(course.toJson());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course updated successfully!')),
      );
    } catch (e) {
      print("Error updating course: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating course: $e')),
      );
    }
  }

  // Delete
  Future<void> deleteCourse(Courses course, BuildContext context) async {
    try {
      await _courseCollection.doc(course.id).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course deleted successfully!')),
      );
    } catch (e) {
      print("Error deleting course: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting course: $e')),
      );
    }
  }
}