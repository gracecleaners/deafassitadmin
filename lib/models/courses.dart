import 'package:cloud_firestore/cloud_firestore.dart';

class Courses {
  String? id; // Document ID field
  String? name;
  String? description;
  String? instructor;
  String? instructorBio;
  String? instructorImage;
  String? startDate;
  String? endDate;
  String? startTime;
  String? endTime;
  String? mode; // Physical or Online
  String? location; // Location for physical mode
  String? imageUrl;
  List<String>? objectives;

  Courses({
    this.id,
    this.name,
    this.description,
    this.instructor,
    this.instructorBio,
    this.instructorImage,
    this.startDate,
    this.endDate,
    this.startTime,
    this.endTime,
    this.mode,
    this.location, // Location field
    this.imageUrl,
    this.objectives,
  });

  Courses.fromJson(Map<String, dynamic> json, {String? documentId}) {
    id = documentId; // Capture document ID
    name = json['name'];
    description = json['description'];
    instructor = json['instructor'];
    instructorBio = json['instructorBio'];
    instructorImage = json['instructorImage'];
    startDate = json['startDate'];
    endDate = json['endDate'];
    startTime = json['startTime'];
    endTime = json['endTime'];
    mode = json['mode'];
    location = json['location']; // Parse location from JSON
    imageUrl = json['imageUrl'];
    objectives = json['objectives'] != null 
        ? List<String>.from(json['objectives'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['description'] = description;
    data['instructor'] = instructor;
    data['instructorBio'] = instructorBio;
    data['instructorImage'] = instructorImage;
    data['startDate'] = startDate;
    data['endDate'] = endDate;
    data['startTime'] = startTime;
    data['endTime'] = endTime;
    data['mode'] = mode;
    data['location'] = location; // Add location to JSON
    data['imageUrl'] = imageUrl;
    data['objectives'] = objectives;
    return data;
  }
}
