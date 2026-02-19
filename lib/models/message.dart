// lib/models/message.dart
import 'package:cloud_firestore/cloud_firestore.dart';

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
      'timestamp': Timestamp.fromDate(timestamp),
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
      timestamp: map['timestamp'] is Timestamp
          ? (map['timestamp'] as Timestamp).toDate()
          : (map['timestamp'] is String
              ? DateTime.tryParse(map['timestamp']) ?? DateTime.now()
              : (map['timestamp'] is DateTime
                  ? map['timestamp'] as DateTime
                  : DateTime.now())),
      type: _parseMessageType(map['type']),
      imageUrl: map['imageUrl'],
      meetingLink: map['meetingLink'],
      isRead: map['isRead'] ?? false,
    );
  }

  static MessageType _parseMessageType(dynamic type) {
    if (type == null) return MessageType.text;
    
    // Handle integer values (from mobile app)
    if (type is int) {
      switch (type) {
        case 0: return MessageType.text;
        case 1: return MessageType.image;
        case 2: return MessageType.meetingLink;
        case 3: return MessageType.file;
        case 4: return MessageType.audio;
        case 5: return MessageType.video;
        default: return MessageType.text;
      }
    }
    
    final typeString = type.toString().toLowerCase();
    switch (typeString) {
      case 'text':
      case 'system':
      case 'payment_details':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'meetinglink':
      case 'meeting_link':
      case 'videocall':
      case 'video_call':
        return MessageType.meetingLink;
      case 'file':
      case 'document':
        return MessageType.file;
      case 'audio':
      case 'voice':
      case 'voice_message':
        return MessageType.audio;
      case 'video':
        return MessageType.video;
      default:
        return MessageType.text;
    }
  }
}