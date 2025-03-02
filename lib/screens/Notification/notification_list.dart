import 'package:admin/screens/dashboard/components/header.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../constants.dart';
import '../../responsive.dart';
import '../main/components/side_menu.dart';

class AdminNotificationsScreen extends StatelessWidget {
  const AdminNotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: SideMenu(),
      body: SafeArea(
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
          children:[
            if (Responsive.isDesktop(context))
              Expanded(
                // default flex = 1
                // and it takes 1/6 part of the screen
                child: SideMenu(),
              ),
            Expanded(
              flex: 5,
              child: SafeArea(
                child: SingleChildScrollView(
                  primary: false,
                  padding: EdgeInsets.all(defaultPadding),
                  child: Column(
                    children: [
                      Header(),
                      SizedBox(height: defaultPadding),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: SizedBox(
                              height: MediaQuery.of(context).size.height - 200,
                              child: Card(
                              elevation: 4,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Notifications',
                                      style: Theme.of(context).textTheme.titleLarge,
                                    ),
                                    SizedBox(height: 16),
                                    Expanded(
                                      child: StreamBuilder<QuerySnapshot>(
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
                  
                                          return ListView.separated(
                                            itemCount: notifications.length,
                                            separatorBuilder: (context, index) => Divider(),
                                            itemBuilder: (context, index) {
                                              final notification = notifications[index].data() as Map<String, dynamic>;
                                              final isRead = notification['isRead'] ?? false;
                                              final docId = notifications[index].id;
                  
                                              return ListTile(
                                                title: Text(
                                                  notification['eventName'] ?? 'Online Interpretation Request',
                                                  style: TextStyle(
                                                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                                  ),
                                                ),
                                                subtitle: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text('Date: ${DateFormat('MMM d, yyyy').format((notification['eventDate'] as Timestamp).toDate())}'),
                                                    Text('Time: ${notification['eventTime']}'),
                                                    Text('Duration: ${notification['duration']} minutes'),
                                                    Text('Status: ${notification['status'] ?? 'Pending'}'),
                                                  ],
                                                ),
                                                trailing: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    if (!isRead)
                                                      Container(
                                                        width: 12,
                                                        height: 12,
                                                        decoration: BoxDecoration(
                                                          shape: BoxShape.circle,
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                    SizedBox(width: 8),
                                                    PopupMenuButton(
                                                      icon: Icon(Icons.more_vert),
                                                      itemBuilder: (context) => [
                                                        PopupMenuItem(
                                                          value: 'accept',
                                                          child: Text('Accept Request'),
                                                        ),
                                                        PopupMenuItem(
                                                          value: 'decline',
                                                          child: Text('Decline Request'),
                                                        ),
                                                        PopupMenuItem(
                                                          value: 'mark_read',
                                                          child: Text(isRead ? 'Mark as unread' : 'Mark as read'),
                                                        ),
                                                        PopupMenuItem(
                                                          value: 'delete',
                                                          child: Text('Delete Booking'),
                                                        ),
                                                      ],
                                                      onSelected: (value) async {
                                                        if (value == 'accept') {
                                                          // Update the status to confirmed in both collections
                                                          await _updateStatus(docId, notification, 'Confirmed');
                                                        } else if (value == 'decline') {
                                                          // Update the status to declined in both collections
                                                          await _updateStatus(docId, notification, 'Declined');
                                                        } else if (value == 'mark_read') {
                                                          // Toggle read status
                                                          await _toggleReadStatus(docId, isRead);
                                                        } else if (value == 'delete') {
                                                          // Show confirmation dialog before deleting
                                                          _showDeleteConfirmationDialog(context, docId, notification);
                                                        }
                                                      },
                                                    ),
                                                  ],
                                                ),
                                                onTap: () {
                                                  // Mark as read when tapped
                                                  if (!isRead) {
                                                    _markAsRead(docId);
                                                  }
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
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ]
        ),
      ),
    );
  }

  Future<void> _markAsRead(String docId) async {
    // Mark notification as read
    await FirebaseFirestore.instance
        .collection('admin_notifications')
        .doc(docId)
        .update({'isRead': true});

    // Decrement the unread notification count
    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .update({
      'unreadNotifications': FieldValue.increment(-1),
    });
  }

  Future<void> _toggleReadStatus(String docId, bool currentStatus) async {
    // Toggle read status
    await FirebaseFirestore.instance
        .collection('admin_notifications')
        .doc(docId)
        .update({'isRead': !currentStatus});

    // Update the unread notification count accordingly
    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .update({
      'unreadNotifications': FieldValue.increment(currentStatus ? 1 : -1),
    });
  }

  Future<void> _updateStatus(String docId, Map<String, dynamic> notification, String status) async {
    // Update status in admin_notifications
    await FirebaseFirestore.instance
        .collection('admin_notifications')
        .doc(docId)
        .update({'status': status, 'isRead': true});

    // Find and update the corresponding online_interpretations record
    final userId = notification['userId'];
    final eventDate = notification['eventDate'];

    if (userId != null && eventDate != null) {
      final interpretationsQuery = await FirebaseFirestore.instance
          .collection('online_interpretations')
          .where('userId', isEqualTo: userId)
          .where('eventDate', isEqualTo: eventDate)
          .get();

      for (var doc in interpretationsQuery.docs) {
        await doc.reference.update({'status': status});
      }
    }

    // Create a new notification for the user
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': notification['userId'],
      'title': 'Interpretation Request $status',
      'message': 'Your request for ${notification['eventName']} has been $status',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    // Increment the user's unread notification count
    if (notification['userId'] != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(notification['userId'])
          .update({
        'unreadNotifications': FieldValue.increment(1),
      });
    }

    // Decrement admin's unread count if it was unread before
    if (!(notification['isRead'] ?? false)) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .update({
        'unreadNotifications': FieldValue.increment(-1),
      });
    }
  }

  void _showDeleteConfirmationDialog(BuildContext context, String docId, Map<String, dynamic> notification) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Booking'),
          content: Text('Are you sure you want to delete this booking? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _deleteBooking(docId, notification);
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteBooking(String docId, Map<String, dynamic> notification) async {
    try {
      // Delete from admin_notifications
      await FirebaseFirestore.instance
          .collection('admin_notifications')
          .doc(docId)
          .delete();

      // Find and delete the corresponding online_interpretations record
      final userId = notification['userId'];
      final eventDate = notification['eventDate'];

      if (userId != null && eventDate != null) {
        final interpretationsQuery = await FirebaseFirestore.instance
            .collection('online_interpretations')
            .where('userId', isEqualTo: userId)
            .where('eventDate', isEqualTo: eventDate)
            .get();

        for (var doc in interpretationsQuery.docs) {
          await doc.reference.delete();
        }
      }

      // Notify the user about the deletion
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': notification['userId'],
        'title': 'Booking Deleted',
        'message': 'Your interpretation request for ${notification['eventName']} has been deleted by the administrator',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // Increment the user's unread notification count
      if (notification['userId'] != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(notification['userId'])
            .update({
          'unreadNotifications': FieldValue.increment(1),
        });
      }

      // Decrement admin's unread count if the notification was unread
      if (!(notification['isRead'] ?? false)) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .update({
          'unreadNotifications': FieldValue.increment(-1),
        });
      }
    } catch (e) {
      print('Error deleting booking: $e');
    }
  }
}