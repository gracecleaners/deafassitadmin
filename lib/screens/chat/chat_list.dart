import 'package:admin/controllers/chat.dart';
import 'package:admin/screens/chat/chat_screen.dart';
import 'package:admin/screens/dashboard/components/header.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../constants.dart';
import '../../responsive.dart';
import '../main/components/side_menu.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatMessageTime(DateTime? timestamp) {
    if (timestamp == null) return "Recently";

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate =
        DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (now.difference(timestamp).inMinutes < 1) {
      return "now";
    } else if (messageDate == today) {
      return "Today, ${DateFormat('h:mm a').format(timestamp)}";
    } else if (messageDate == yesterday) {
      return "Yesterday, ${DateFormat('h:mm a').format(timestamp)}";
    } else if (now.difference(timestamp).inDays < 7) {
      return "${DateFormat('EEEE').format(timestamp)}, ${DateFormat('h:mm a').format(timestamp)}";
    } else {
      return DateFormat('MMM d, yyyy').format(timestamp);
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
      }
    });
  }

  // Generate chat room ID (moved from ChatService since it's private there)
  String _generateChatRoomId(String userId1, String userId2) {
    return userId1.compareTo(userId2) < 0
        ? '$userId1-$userId2'
        : '$userId2-$userId1';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: !Responsive.isDesktop(context)
          ? AppBar(
              title: _isSearching
                  ? TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: "Search conversations...",
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.white70),
                      ),
                      style: const TextStyle(color: Colors.white),
                    )
                  : const Text("Chats"),
              actions: [
                IconButton(
                  icon: Icon(_isSearching ? Icons.close : Icons.search),
                  onPressed: _toggleSearch,
                ),
              ],
            )
          : null,
      drawer: Responsive.isDesktop(context)
          ? null
          : const Drawer(child: SideMenu()),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (Responsive.isDesktop(context))
              const SizedBox(
                width: 260,
                child: SideMenu(),
              ),
            Expanded(
              flex: 5,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(defaultPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (Responsive.isDesktop(context))
                        const Header(title: 'Chats'),
                      const SizedBox(height: defaultPadding),
                      if (Responsive.isDesktop(context))
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: defaultPadding),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: borderColor),
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: "Search conversations...",
                              border: InputBorder.none,
                              icon: Icon(Icons.search, color: bodyTextColor),
                            ),
                          ),
                        ),
                      const SizedBox(height: defaultPadding),
                      Text(
                        "Recent Conversations",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: defaultPadding / 2),
                      Expanded(
                        child: StreamBuilder<List<Map<String, dynamic>>>(
                          stream: _chatService.getChatRooms(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            if (snapshot.hasError) {
                              print("Error: ${snapshot.error}");
                            }

                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return const Center(
                                  child: Text("No conversations yet"));
                            }

                            List<Map<String, dynamic>> chats = snapshot.data!;

                            if (_searchQuery.isNotEmpty) {
                              chats = chats.where((chat) {
                                final participants = List<String>.from(
                                    chat['participants'] ?? []);
                                final otherUserId = participants.firstWhere(
                                  (id) => id != currentUserId,
                                  orElse: () => '',
                                );

                                // In a real app, you'd want to fetch user names here
                                // For now, we'll just search by message content
                                final lastMessage = (chat['lastMessage'] ?? '')
                                    .toString()
                                    .toLowerCase();
                                return lastMessage.contains(_searchQuery);
                              }).toList();
                            }

                            return ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: chats.length,
                              separatorBuilder: (context, index) =>
                                  Divider(color: borderColor),
                              itemBuilder: (context, index) {
                                final chat = chats[index];
                                final participants = List<String>.from(
                                    chat['participants'] ?? []);
                                final chatId = chat['id'] as String;
                                final lastMessage =
                                    chat['lastMessage'] as String? ?? '';
                                final lastMessageTime =
                                    chat['lastMessageTimestamp'] != null
                                        ? (chat['lastMessageTimestamp']
                                                as Timestamp)
                                            .toDate()
                                        : null;

                                final otherUserId = participants.firstWhere(
                                  (id) => id != currentUserId,
                                  orElse: () => '',
                                );

                                return FutureBuilder<Map<String, dynamic>>(
                                  future: _getUserData(otherUserId),
                                  builder: (context, userSnapshot) {
                                    if (!userSnapshot.hasData) {
                                      return _buildLoadingChatListItem();
                                    }

                                    final userData = userSnapshot.data!;
                                    final userName =
                                        userData['name'] as String? ??
                                            'Unknown';
                                    final photoUrl =
                                        userData['photoURL'] as String?;
                                    final isOnline =
                                        userData['isOnline'] as bool? ?? false;

                                    return FutureBuilder<int>(
                                      future: _chatService
                                          .getUnreadMessageCount(otherUserId),
                                      builder: (context, unreadSnapshot) {
                                        final unreadCount =
                                            unreadSnapshot.data ?? 0;
                                        final timeText =
                                            _formatMessageTime(lastMessageTime);

                                        return ListTile(
                                          leading: Stack(
                                            children: [
                                              CircleAvatar(
                                                backgroundColor: primaryColor,
                                                backgroundImage:
                                                    photoUrl != null
                                                        ? NetworkImage(photoUrl)
                                                        : null,
                                                child: photoUrl == null
                                                    ? Text(
                                                        userName.isNotEmpty
                                                            ? userName[0]
                                                                .toUpperCase()
                                                            : "?",
                                                        style: const TextStyle(
                                                            color:
                                                                Colors.white),
                                                      )
                                                    : null,
                                              ),
                                              if (isOnline)
                                                Positioned(
                                                  right: 0,
                                                  bottom: 0,
                                                  child: Container(
                                                    height: 12,
                                                    width: 12,
                                                    decoration: BoxDecoration(
                                                      color: Colors.green,
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                          color: bgColor,
                                                          width: 2),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          title: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  userName,
                                                  style: TextStyle(
                                                    fontWeight: unreadCount > 0
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Text(
                                                timeText,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: unreadCount > 0
                                                      ? primaryColor
                                                      : Colors.grey,
                                                  fontWeight: unreadCount > 0
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                            ],
                                          ),
                                          subtitle: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  lastMessage,
                                                  maxLines: 1,
                                                  style: TextStyle(
                                                    fontWeight: unreadCount > 0
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                    color: unreadCount > 0
                                                        ? Colors.white
                                                        : Colors.grey,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (unreadCount > 0)
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: primaryColor,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Text(
                                                    unreadCount.toString(),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ChatScreen(
                                                  chatId: chatId,
                                                  recipientId: otherUserId,
                                                  recipientName: userName,
                                                ),
                                              ),
                                            );
                                          },
                                          onLongPress: () {
                                            _showChatOptions(
                                                context, chatId, userName);
                                          },
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        onPressed: () => _showNewChatDialog(context),
        child: const Icon(Icons.message, color: Colors.white),
      ),
    );
  }

  Widget _buildLoadingChatListItem() {
    return const ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.grey,
        child: Icon(Icons.person, color: Colors.white),
      ),
      title: Text("Loading...", style: TextStyle(color: Colors.grey)),
    );
  }

  Future<Map<String, dynamic>> _getUserData(String userId) async {
    if (userId.isEmpty) return {};

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      return doc.data() ?? {};
    } catch (e) {
      return {};
    }
  }

  void _showChatOptions(
      BuildContext context, String chatId, String recipientName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: bgColor,
        title: Text("Chat with $recipientName"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text("Delete conversation"),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteChat(context, chatId, recipientName);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.notifications_off, color: Colors.orange),
              title: const Text("Mute notifications"),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text("Notifications muted for $recipientName")),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteChat(
      BuildContext context, String chatId, String recipientName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: bgColor,
        title: const Text("Delete conversation"),
        content: Text(
            "Are you sure you want to delete your conversation with $recipientName? This cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              _deleteChat(chatId);
              Navigator.pop(context);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteChat(String chatId) async {
    try {
      // Delete the chat room and all its messages
      final chatRef =
          FirebaseFirestore.instance.collection('chat_rooms').doc(chatId);

      // Delete all messages in the chat
      final messagesQuery = await chatRef.collection('messages').get();
      for (var doc in messagesQuery.docs) {
        await doc.reference.delete();
      }

      // Delete the chat room itself
      await chatRef.delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Conversation deleted")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting conversation: ${e.toString()}")),
      );
    }
  }

  void _showNewChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: bgColor,
        title: const Text("New Message"),
        content: SizedBox(
          width: 400,
          height: 400,
          child: FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance.collection('users').get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              var users = snapshot.data!.docs
                  .where((doc) => doc.id != currentUserId)
                  .toList();

              if (users.isEmpty) {
                return const Center(child: Text("No users found"));
              }

              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  var user = users[index];
                  var userData = user.data() as Map<String, dynamic>;
                  String userName = userData['name'] ?? "Unknown";
                  String? photoUrl = userData['photoURL'];
                  String role = userData['role'];

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: primaryColor,
                      backgroundImage:
                          photoUrl != null ? NetworkImage(photoUrl) : null,
                      child: photoUrl == null
                          ? Text(
                              userName.isNotEmpty
                                  ? userName[0].toUpperCase()
                                  : "?",
                              style: const TextStyle(color: Colors.white),
                            )
                          : null,
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(userName),
                        Text(
                          "(${role.toUpperCase()})",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _startNewChat(user.id, userName);
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  Future<void> _startNewChat(String recipientId, String recipientName) async {
    try {
      // This will automatically handle creating a new chat if one doesn't exist
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatId: _generateChatRoomId(currentUserId!, recipientId),
            recipientId: recipientId,
            recipientName: recipientName,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error starting chat: ${e.toString()}")),
      );
    }
  }
}
