class Event {
  final String? id;
  final String title;
  final String? description;
  final DateTime startDate;
  final DateTime endDate;
  final String? location;
  final String? imageUrl;
  final String? category;
  final List<String>? tags;
  final bool isFeatured;

  Event({
    this.id,
    required this.title,
    this.description,
    required this.startDate,
    required this.endDate,
    this.location,
    this.imageUrl,
    this.category,
    this.tags,
    this.isFeatured = false,
  });

  factory Event.fromJson(Map<String, dynamic> json, String documentId) {
    return Event(
      id: documentId,
      title: json['title'] ?? '',
      description: json['description'],
      startDate: json['startDate']?.toDate() ?? DateTime.now(),
      endDate: json['endDate']?.toDate() ?? DateTime.now(),
      location: json['location'],
      imageUrl: json['imageUrl'],
      category: json['category'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      isFeatured: json['isFeatured'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'startDate': startDate,
      'endDate': endDate,
      'location': location,
      'imageUrl': imageUrl,
      'category': category,
      'tags': tags,
      'isFeatured': isFeatured,
    };
  }
}