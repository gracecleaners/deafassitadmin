// models/pdf.dart
class PdfDocument {
  final String? id;
  final String title;
  final String? description;
  final String downloadUrl;
  final String filePath;
  final String fileName;
  final int fileSize;
  final DateTime uploadDate;
  final String? category;
  final List<String>? tags;

  PdfDocument({
    this.id,
    required this.title,
    this.description,
    required this.downloadUrl,
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.uploadDate,
    this.category,
    this.tags,
  });

  factory PdfDocument.fromJson(Map<String, dynamic> json, String documentId) {
    return PdfDocument(
      id: documentId,
      title: json['title'] ?? '',
      description: json['description'],
      downloadUrl: json['downloadUrl'] ?? '',
      filePath: json['filePath'] ?? '',
      fileName: json['fileName'] ?? '',
      fileSize: json['fileSize'] ?? 0,
      uploadDate: json['uploadDate']?.toDate() ?? DateTime.now(),
      category: json['category'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'downloadUrl': downloadUrl,
      'filePath': filePath,
      'fileName': fileName,
      'fileSize': fileSize,
      'uploadDate': uploadDate,
      'category': category,
      'tags': tags,
    };
  }
}