import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminNotificationsScreen extends StatelessWidget {
  const AdminNotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('admin_notifications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No notifications'));
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index].data() as Map<String, dynamic>;
              final isRead = notification['isRead'] ?? false;

              return ListTile(
                title: Text(notification['eventName']),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Date: ${DateFormat('MMM d, yyyy').format((notification['eventDate'] as Timestamp).toDate())}'),
                    Text('Time: ${notification['eventTime']}'),
                    Text('Duration: ${notification['duration']} minutes'),
                  ],
                ),
                trailing: !isRead
                    ? Icon(Icons.circle, color: Colors.red, size: 12)
                    : null,
                onTap: () {
                  // Mark as read
                  notifications[index].reference.update({'isRead': true});
                  // Decrement the unread notification count
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser?.uid)
                      .update({
                    'unreadNotifications': FieldValue.increment(-1),
                  });
                },
              );
            },
          );
        },
      ),
    );
  }
}