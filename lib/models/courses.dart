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
  final String? imageUrl;
  final List<String>? objectives;
  final double? price;
  final double? originalPrice; // Added for showing discounted price
  final int? duration;
  final String? difficulty;
  final double? rating; // Added for course rating
  final int? numberOfRatings; // Added for number of ratings
  final bool? isBestseller; // Added for bestseller badge

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
    this.imageUrl,
    this.objectives,
    this.price,
    this.originalPrice,
    this.duration,
    this.difficulty,
    this.rating,
    this.numberOfRatings,
    this.isBestseller,
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
      'imageUrl': imageUrl,
      'objectives': objectives,
      'price': price,
      'originalPrice': originalPrice,
      'duration': duration,
      'difficulty': difficulty,
      'rating': rating,
      'numberOfRatings': numberOfRatings,
      'isBestseller': isBestseller,
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
      imageUrl: json['imageUrl'],
      objectives: List<String>.from(json['objectives'] ?? []),
      price: json['price']?.toDouble(),
      originalPrice: json['originalPrice']?.toDouble(),
      duration: json['duration'],
      difficulty: json['difficulty'],
      rating: json['rating']?.toDouble(),
      numberOfRatings: json['numberOfRatings'],
      isBestseller: json['isBestseller'],
    );
  }
}
