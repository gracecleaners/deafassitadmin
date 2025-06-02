import 'dart:io';

import 'package:admin/models/message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Send message with proper MessageType handling
  Future<void> sendMessage({
    required String receiverId, 
    required String content, 
    MessageType type = MessageType.text,
    String? meetingLink,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final message = Message(
      senderId: currentUser.uid,
      senderName: currentUser.displayName ?? 'Admin',
      receiverId: receiverId,
      content: content,
      timestamp: DateTime.now(),
      type: type,
      meetingLink: meetingLink,
    );

    // Create a unique chat room ID
    final chatRoomId = _generateChatRoomId(currentUser.uid, receiverId);

    // Add message to Firestore
    final messageData = message.toMap();
    
    // Add additional fields for meeting link messages (with null safety)
    if (type == MessageType.meetingLink) {
      if (meetingLink != null) {
        messageData['meetingLink'] = meetingLink;
      }
    }

    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add(messageData);

    // Update last message in chat room
    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .set({
          'participants': [currentUser.uid, receiverId],
          'lastMessage': content,
          'lastMessageTime': DateTime.now().toIso8601String(),
          'lastMessageTimestamp': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    // Also update the legacy 'chats' collection if it exists
    await _updateLegacyChatCollection(currentUser.uid, receiverId, content, type, meetingLink);
  }

  // Helper method to maintain compatibility with legacy chat structure
  Future<void> _updateLegacyChatCollection(
    String senderId,
    String receiverId, 
    String content,
    MessageType type,
    String? meetingLink,
  ) async {
    try {
      // Check if there's an existing chat document
      final chatQuery = await _firestore
          .collection('chats')
          .where('participants', arrayContains: senderId)
          .get();

      String? chatId;
      
      for (var doc in chatQuery.docs) {
        final participants = List<String>.from(doc.data()['participants'] ?? []);
        if (participants.contains(receiverId)) {
          chatId = doc.id;
          break;
        }
      }

      // If no existing chat, create a new one
      if (chatId == null) {
        final newChatDoc = await _firestore.collection('chats').add({
          'participants': [senderId, receiverId],
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessage': content,
          'lastMessageTime': FieldValue.serverTimestamp(),
        });
        chatId = newChatDoc.id;
      }

      // Add message to the chat's messages subcollection
      final messageData = <String, dynamic>{
        'senderId': senderId,
        'receiverId': receiverId,
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
        'type': type.toString().split('.').last, // Convert enum to string
        'isRead': false,
      };

      // Add meeting link fields with null safety
      if (type == MessageType.meetingLink) {
        if (meetingLink != null) {
          messageData['meetingLink'] = meetingLink;
        }
      }

      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(messageData);

      // Update chat document with last message info
      await _firestore
          .collection('chats')
          .doc(chatId)
          .update({
            'lastMessage': content,
            'lastMessageTime': FieldValue.serverTimestamp(),
          });

    } catch (e) {
      print('Error updating legacy chat collection: $e');
      // Don't throw error as this is for compatibility only
    }
  }

  // Send meeting link message (convenience method)
  Future<void> sendMeetingLink({
    required String receiverId,
    required String meetingLink,
    String? customMessage,
  }) async {
    final content = customMessage ?? 'Meeting link for your booking: $meetingLink';
    
    await sendMessage(
      receiverId: receiverId,
      content: content,
      type: MessageType.meetingLink,
      meetingLink: meetingLink,
    );
  }

  // Get messages for a specific chat room
  Stream<List<Message>> getMessages(String otherUserId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const Stream.empty();
    }

    final chatRoomId = _generateChatRoomId(currentUser.uid, otherUserId);

    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) => 
          snapshot.docs.map((doc) {
            try {
              return Message.fromMap(doc.data());
            } catch (e) {
              print('Error parsing message: $e');
              // Return a default message if parsing fails
              return Message(
                senderId: doc.data()['senderId'] ?? '',
                senderName: doc.data()['senderName'] ?? 'Unknown',
                receiverId: doc.data()['receiverId'] ?? '',
                content: doc.data()['content'] ?? 'Message could not be loaded',
                timestamp: DateTime.now(),
                type: MessageType.text,
              );
            }
          }).toList()
        );
  }

  // Get chat rooms for current user
  Stream<List<Map<String, dynamic>>> getChatRooms() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: currentUser.uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList());
  }

  // Generate a unique chat room ID for two users
  String _generateChatRoomId(String userId1, String userId2) {
    return userId1.compareTo(userId2) < 0 
      ? '$userId1-$userId2' 
      : '$userId2-$userId1';
  }

  // Upload image for chat
  Future<String> uploadChatImage(File imageFile) async {
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('chat_images')
        .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

    final uploadTask = await storageRef.putFile(imageFile);
    return await uploadTask.ref.getDownloadURL();
  }

  // Send image message
  Future<void> sendImageMessage({
    required String receiverId,
    required File imageFile,
    String? caption,
  }) async {
    try {
      // Upload image first
      final imageUrl = await uploadChatImage(imageFile);
      
      // Send image message
      await sendMessage(
        receiverId: receiverId,
        content: caption ?? 'Image',
        type: MessageType.image,
      );
      
      // Store image URL in a separate field or modify the message content
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final chatRoomId = _generateChatRoomId(currentUser.uid, receiverId);
        
        // Update the last message with image URL
        final messagesRef = _firestore
            .collection('chat_rooms')
            .doc(chatRoomId)
            .collection('messages');
            
        final lastMessage = await messagesRef
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();
            
        if (lastMessage.docs.isNotEmpty) {
          await lastMessage.docs.first.reference.update({
            'imageUrl': imageUrl,
            'content': caption ?? 'Image',
          });
        }
      }
    } catch (e) {
      throw Exception('Failed to send image message: $e');
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String otherUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final chatRoomId = _generateChatRoomId(currentUser.uid, otherUserId);

    try {
      final unreadMessages = await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .where('receiverId', isEqualTo: currentUser.uid)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  // Get unread message count
  Future<int> getUnreadMessageCount(String otherUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return 0;

    final chatRoomId = _generateChatRoomId(currentUser.uid, otherUserId);

    try {
      final unreadMessages = await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .where('receiverId', isEqualTo: currentUser.uid)
          .where('isRead', isEqualTo: false)
          .get();

      return unreadMessages.size;
    } catch (e) {
      print('Error getting unread message count: $e');
      return 0;
    }
  }

  // Delete a message
  Future<void> deleteMessage(String otherUserId, String messageId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final chatRoomId = _generateChatRoomId(currentUser.uid, otherUserId);

    try {
      await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }
}