class Courses {
  final String? id;
  final String? name;
  final String? description;
  final String? instructor;
  final String? instructorBio;
  final String? instructorImage;
  final String? startDate;
  final String? endDate;
  final String? startTime;
  final String? endTime;
  final String? mode;
  final String? location;
  final String? courseLink;  
  final String? imageUrl;
  final List<String>? objectives;
  final double? price;
  final int? duration;
  final double? rating;

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
    this.location,
    this.courseLink, 
    this.imageUrl,
    this.objectives,
    this.price,
    this.duration,
    this.rating,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'instructor': instructor,
      'instructorBio': instructorBio,
      'instructorImage': instructorImage,
      'startDate': startDate,
      'endDate': endDate,
      'startTime': startTime,
      'endTime': endTime,
      'mode': mode,
      'location': location,
      'courseLink': courseLink,  
      'imageUrl': imageUrl,
      'objectives': objectives,
      'price': price,
      'duration': duration,
      'rating': rating,
    };
  }

  factory Courses.fromJson(Map<String, dynamic> json, {String? documentId}) {
    return Courses(
      id: documentId,
      name: json['name'],
      description: json['description'],
      instructor: json['instructor'],
      instructorBio: json['instructorBio'],
      instructorImage: json['instructorImage'],
      startDate: json['startDate'],
      endDate: json['endDate'],
      startTime: json['startTime'],
      endTime: json['endTime'],
      mode: json['mode'],
      location: json['location'],
      courseLink: json['courseLink'], 
      imageUrl: json['imageUrl'],
      objectives: List<String>.from(json['objectives'] ?? []),
      price: json['price']?.toDouble(),
      duration: json['duration'],
      rating: json['rating']?.toDouble(),
    );
  }
}