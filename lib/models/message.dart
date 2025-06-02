// lib/models/message.dart
enum MessageType {
  text,
  image,
  meetingLink, // Make sure this value exists
  file,
  audio,
  video,
}

class Message {
  final String senderId;
  final String senderName;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final MessageType type;
  final String? imageUrl;
  final String? meetingLink;
  final bool isRead;

  Message({
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    required this.type,
    this.imageUrl,
    this.meetingLink,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'type': type.toString().split('.').last, // Convert enum to string
      'imageUrl': imageUrl,
      'meetingLink': meetingLink,
      'isRead': isRead,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? 'Unknown',
      receiverId: map['receiverId'] ?? '',
      content: map['content'] ?? '',
      timestamp: map['timestamp'] is String 
          ? DateTime.parse(map['timestamp'])
          : DateTime.now(),
      type: _parseMessageType(map['type']),
      imageUrl: map['imageUrl'],
      meetingLink: map['meetingLink'],
      isRead: map['isRead'] ?? false,
    );
  }

  static MessageType _parseMessageType(dynamic type) {
    if (type == null) return MessageType.text;
    
    final typeString = type.toString().toLowerCase();
    switch (typeString) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'meetinglink':
      case 'meeting_link':
        return MessageType.meetingLink;
      case 'file':
        return MessageType.file;
      case 'audio':
        return MessageType.audio;
      case 'video':
        return MessageType.video;
      default:
        return MessageType.text;
    }
  }
}