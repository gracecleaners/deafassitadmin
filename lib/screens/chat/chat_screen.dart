import 'package:admin/controllers/chat.dart';
import 'package:admin/responsive.dart';
import 'package:admin/screens/main/components/side_menu.dart';
import 'package:admin/models/message.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../constants.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String recipientId;
  final String recipientName;

  const ChatScreen({
    Key? key,
    required this.chatId,
    required this.recipientId,
    required this.recipientName,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  late Stream<List<Message>> _messagesStream;
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  void _setup() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Set up messages stream using ChatService
      _messagesStream = _chatService.getMessages(widget.recipientId);
      
      // Mark messages as read when entering the chat
      await _chatService.markMessagesAsRead(widget.recipientId);
          
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error setting up chat: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    
    final String messageText = _messageController.text.trim();
    _messageController.clear();
    
    try {
      // Send message using ChatService
      await _chatService.sendMessage(
        receiverId: widget.recipientId,
        content: messageText,
        type: MessageType.text,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: ${e.toString()}')),
      );
    }
  }

  // Format timestamp according to when the message was sent
  String _formatMessageTime(DateTime? timestamp) {
    if (timestamp == null) return "";
    
    final DateTime messageTime = timestamp;
    final DateTime now = DateTime.now();
    
    // If within the last minute, show "now"
    if (now.difference(messageTime).inMinutes < 1) {
      return "now";
    }
    
    // Check if it's today
    final bool isToday = messageTime.year == now.year && 
                         messageTime.month == now.month && 
                         messageTime.day == now.day;
    
    if (isToday) {
      return "today at ${DateFormat('h:mm a').format(messageTime)}";
    }
    
    // Check if it's yesterday
    final DateTime yesterday = now.subtract(Duration(days: 1));
    final bool isYesterday = messageTime.year == yesterday.year && 
                             messageTime.month == yesterday.month && 
                             messageTime.day == yesterday.day;
                             
    if (isYesterday) {
      return "yesterday at ${DateFormat('h:mm a').format(messageTime)}";
    }
    
    // Otherwise, show the full date
    return "${DateFormat('MMM d, yyyy').format(messageTime)} at ${DateFormat('h:mm a').format(messageTime)}";
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
  String timeText = _formatMessageTime(message.timestamp);
  
  return Align(
    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? primaryColor : Colors.grey[800],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Handle different message types
          if (message.type == MessageType.meetingLink)
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.video_call, color: Colors.blue, size: 20),
                  SizedBox(height: 4),
                  Text(
                    message.content,
                    style: TextStyle(color: Colors.white),
                  ),
                  if (message.meetingLink != null)
                    GestureDetector(
                      onTap: () {
                        // Handle meeting link tap - you can implement URL launcher here
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Meeting link: ${message.meetingLink}')),
                        );
                      },
                      child: Container(
                        margin: EdgeInsets.only(top: 4),
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Join Meeting',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            )
          else if (message.type == MessageType.image)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display the actual image using the imageUrl
                if (message.imageUrl != null && message.imageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      message.imageUrl!,
                      height: 200,
                      width: 200,
                      fit: BoxFit.cover,
                      loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 200,
                          width: 200,
                          color: Colors.grey[700],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          width: 200,
                          color: Colors.grey[700],
                          child: Center(
                            child: Icon(Icons.error, color: Colors.red),
                          ),
                        );
                      },
                    ),
                  )
                else
                  Container(
                    height: 200,
                    width: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[700],
                    ),
                    child: Center(
                      child: Icon(Icons.image, size: 50, color: Colors.grey),
                    ),
                  ),
                if (message.content.isNotEmpty && message.content != 'Image')
                  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      message.content,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
              ],
            )
          else
            Text(
              message.content,
              style: TextStyle(color: Colors.white),
            ),
          SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                timeText,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
              if (isMe) SizedBox(width: 4),
              if (isMe)
                Icon(
                  message.isRead ? Icons.done_all : Icons.done,
                  size: 12,
                  color: Colors.white70,
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipientName),
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(Icons.video_call),
            onPressed: () {
              // Send a meeting link - you can implement this functionality
              _sendMeetingLink();
            },
          ),
        ],
      ),
      drawer: Responsive.isDesktop(context) ? null : const Drawer(child: SideMenu()),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Side menu for desktop
            if (Responsive.isDesktop(context))
              const SizedBox(
                width: 260,
                child: SideMenu(),
              ),
              ),
            // Main chat area
            Expanded(
              flex: 5, // Takes 5/6 part of the screen
              child: Container(
                color: secondaryColor,
                child: Column(
                  children: [
                    // Messages area
                    Expanded(
                      child: _isLoading
                          ? Center(child: CircularProgressIndicator())
                          : StreamBuilder<List<Message>>(
                              stream: _messagesStream,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                                  return Center(child: CircularProgressIndicator());
                                }
                                
                                if (snapshot.hasError) {
                                  return Center(child: Text("Error: ${snapshot.error}"));
                                }
                                
                                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                  return Center(child: Text("No messages yet. Start the conversation!"));
                                }
                                
                                var messages = snapshot.data!.reversed.toList(); // Reverse to show latest at bottom
                                
                                return ListView.builder(
                                  reverse: true,
                                  padding: EdgeInsets.all(defaultPadding),
                                  itemCount: messages.length,
                                  itemBuilder: (context, index) {
                                    Message message = messages[index];
                                    bool isMe = message.senderId == currentUserId;
                                    
                                    return _buildMessageBubble(message, isMe);
                                  },
                                );
                              },
                            ),
                    ),
                    
                    // Message input area
                    Container(
                      padding: EdgeInsets.all(defaultPadding),
                      decoration: BoxDecoration(
                        color: bgColor,
                        boxShadow: [
                          BoxShadow(
                            offset: Offset(0, -10),
                            blurRadius: 20,
                            color: Colors.black.withOpacity(0.05),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: defaultPadding * 0.75),
                                decoration: BoxDecoration(
                                  color: secondaryColor,
                                  borderRadius: BorderRadius.circular(40),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.sentiment_satisfied_alt, color: Colors.white70),
                                    SizedBox(width: defaultPadding / 4),
                                    Expanded(
                                      child: TextField(
                                        controller: _messageController,
                                        decoration: InputDecoration(
                                          hintText: "Type a message",
                                          border: InputBorder.none,
                                        ),
                                        onSubmitted: (_) => _sendMessage(),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.attach_file, color: Colors.white70),
                                      onPressed: () {
                                        // Handle file attachment
                                        _showAttachmentOptions();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: defaultPadding),
                            MaterialButton(
                              onPressed: _sendMessage,
                              color: primaryColor,
                              padding: EdgeInsets.all(12),
                              shape: CircleBorder(),
                              child: Icon(
                                Icons.send,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMeetingLink() async {
    // Generate or get meeting link - replace with your actual meeting link logic
    String meetingLink = "https://meet.example.com/room-${DateTime.now().millisecondsSinceEpoch}";
    
    try {
      await _chatService.sendMeetingLink(
        receiverId: widget.recipientId,
        meetingLink: meetingLink,
        customMessage: "Meeting scheduled for your booking",
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending meeting link: ${e.toString()}')),
      );
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      builder: (context) => Container(
        padding: EdgeInsets.all(defaultPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo, color: primaryColor),
              title: Text('Photo'),
              onTap: () {
                Navigator.pop(context);
                // Implement photo selection
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Photo selection not implemented yet')),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.videocam, color: primaryColor),
              title: Text('Video Call'),
              onTap: () {
                Navigator.pop(context);
                _sendMeetingLink();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}