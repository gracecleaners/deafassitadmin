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
      drawer: Responsive.isDesktop(context) ? null : const Drawer(child: SideMenu()),
      body: SafeArea(
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (Responsive.isDesktop(context))
            const SizedBox(width: 260, child: SideMenu()),
          Expanded(
            flex: 5,
            child: SafeArea(
              child: SingleChildScrollView(
                primary: false,
                padding: EdgeInsets.all(defaultPadding),
                child: Column(
                  children: [
                    Header(
                      title: '',
                    ),
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
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                    ),
                                    SizedBox(height: 16),
                                    Expanded(
                                      child: StreamBuilder<QuerySnapshot>(
                                        stream: FirebaseFirestore.instance
                                            .collection('admin_notifications')
                                            .orderBy('timestamp',
                                                descending: true)
                                            .snapshots(),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return Center(
                                                child:
                                                    CircularProgressIndicator());
                                          }

                                          if (!snapshot.hasData ||
                                              snapshot.data!.docs.isEmpty) {
                                            return Center(
                                                child:
                                                    Text('No notifications'));
                                          }

                                          final notifications =
                                              snapshot.data!.docs;

                                          return ListView.separated(
                                            itemCount: notifications.length,
                                            separatorBuilder:
                                                (context, index) => Divider(),
                                            itemBuilder: (context, index) {
                                              final notification =
                                                  notifications[index].data()
                                                      as Map<String, dynamic>;
                                              final isRead =
                                                  notification['isRead'] ??
                                                      false;
                                              final docId =
                                                  notifications[index].id;
                                              final status =
                                                  notification['status'] ??
                                                      'Pending';

                                              return ListTile(
                                                title: Text(
                                                  notification['eventName'] ??
                                                      'Online Interpretation Request',
                                                  style: TextStyle(
                                                    fontWeight: isRead
                                                        ? FontWeight.normal
                                                        : FontWeight.bold,
                                                  ),
                                                ),
                                                subtitle: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                        'Date: ${DateFormat('MMM d, yyyy').format((notification['eventDate'] as Timestamp).toDate())}'),
                                                    Text(
                                                        'Time: ${notification['eventTime']}'),
                                                    Text(
                                                        'Duration: ${notification['duration']} minutes'),
                                                    Text('Status: $status'),
                                                    if (status ==
                                                        'Pending Payment')
                                                      Text('Payment Required',
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .orange)),
                                                  ],
                                                ),
                                                trailing: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    if (!isRead)
                                                      Container(
                                                        width: 12,
                                                        height: 12,
                                                        decoration:
                                                            BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                    SizedBox(width: 8),
                                                    PopupMenuButton(
                                                      icon:
                                                          Icon(Icons.more_vert),
                                                      itemBuilder: (context) =>
                                                          [
                                                        PopupMenuItem(
                                                          value: 'accept',
                                                          child: Text(
                                                              'Accept Request'),
                                                        ),
                                                        if (status ==
                                                            'Pending Payment')
                                                          PopupMenuItem(
                                                            value:
                                                                'confirm_payment',
                                                            child: Text(
                                                                'Confirm Payment'),
                                                          ),
                                                        PopupMenuItem(
                                                          value: 'decline',
                                                          child: Text(
                                                              'Decline Request'),
                                                        ),
                                                        PopupMenuItem(
                                                          value: 'mark_read',
                                                          child: Text(isRead
                                                              ? 'Mark as unread'
                                                              : 'Mark as read'),
                                                        ),
                                                        PopupMenuItem(
                                                          value: 'delete',
                                                          child: Text(
                                                              'Delete Booking'),
                                                        ),
                                                      ],
                                                      onSelected:
                                                          (value) async {
                                                        if (value == 'accept') {
                                                          _showPaymentDetailsDialog(
                                                              context,
                                                              docId,
                                                              notification);
                                                        } else if (value ==
                                                            'confirm_payment') {
                                                          _showPaymentConfirmationDialog(
                                                              context,
                                                              docId,
                                                              notification);
                                                        } else if (value ==
                                                            'decline') {
                                                          await _updateStatus(
                                                              docId,
                                                              notification,
                                                              'Declined');
                                                        } else if (value ==
                                                            'mark_read') {
                                                          await _toggleReadStatus(
                                                              docId, isRead);
                                                        } else if (value ==
                                                            'delete') {
                                                          _showDeleteConfirmationDialog(
                                                              context,
                                                              docId,
                                                              notification);
                                                        }
                                                      },
                                                    ),
                                                  ],
                                                ),
                                                onTap: () {
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
        ]),
      ),
    );
  }

  // Updated method - ONLY payment details, NO meeting link
  void _showPaymentDetailsDialog(BuildContext context, String docId,
      Map<String, dynamic> notification) async {
    final TextEditingController paymentNumberController =
        TextEditingController();
    final TextEditingController paymentNameController = TextEditingController();
    final TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Accept Request - Payment Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Please provide payment details for this interpretation session:',
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: paymentNumberController,
                  decoration: InputDecoration(
                    labelText: 'Payment Number',
                    hintText: '2547XXXXXXXX',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: paymentNameController,
                  decoration: InputDecoration(
                    labelText: 'Account Name',
                    hintText: 'e.g., John Doe or Company Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.account_circle),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  decoration: InputDecoration(
                    labelText: 'Amount to Pay',
                    hintText: 'e.g., 5000',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (paymentNumberController.text.isEmpty ||
                    paymentNameController.text.isEmpty ||
                    amountController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please fill all payment details')),
                  );
                  return;
                }

                Navigator.of(context).pop();

                await _acceptRequestWithPaymentDetails(
                  docId,
                  notification,
                  paymentNumberController.text.trim(),
                  paymentNameController.text.trim(),
                  amountController.text.trim(),
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Request accepted with payment details')),
                );
              },
              child: Text('Accept Request'),
            ),
          ],
        );
      },
    );
  }

  // New method - ONLY handles payment details
  Future<void> _acceptRequestWithPaymentDetails(
    String docId,
    Map<String, dynamic> notification,
    String paymentNumber,
    String paymentName,
    String amount,
  ) async {
    final adminId = FirebaseAuth.instance.currentUser?.uid;
    final userId = notification['userId'];
    final eventName = notification['eventName'] ?? 'Online Interpretation';
    final eventDate = notification['eventDate'];
    final eventTime = notification['eventTime'];

    // Update status with payment details in admin_notifications
    await FirebaseFirestore.instance
        .collection('admin_notifications')
        .doc(docId)
        .update({
      'status': 'Pending Payment',
      'isRead': true,
      'paymentNumber': paymentNumber,
      'paymentName': paymentName,
      'amount': amount,
    });

    // Find and update the corresponding online_interpretations record
    if (userId != null && eventDate != null) {
      final interpretationsQuery = await FirebaseFirestore.instance
          .collection('online_interpretations')
          .where('userId', isEqualTo: userId)
          .where('eventDate', isEqualTo: eventDate)
          .get();

      for (var doc in interpretationsQuery.docs) {
        await doc.reference.update({
          'status': 'Pending Payment',
          'paymentNumber': paymentNumber,
          'paymentName': paymentName,
          'amount': amount,
        });
      }
    }

    // Create chat collection if it doesn't exist
    final chatId = _generateChatId(adminId!, userId!);
    final chatDoc =
        await FirebaseFirestore.instance.collection('chats').doc(chatId).get();

    if (!chatDoc.exists) {
      await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
        'participants': [adminId, userId],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': null,
        'lastMessageTime': null,
      });
    }

    // Add status update message
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': adminId,
      'receiverId': userId,
      'text': 'Your request for "$eventName" has been accepted.',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'type': 'system',
    });

    // Send payment details message
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': adminId,
      'receiverId': userId,
      'text': 'Payment Details:\n'
          'Amount: UGX $amount\n'
          'Pay to: $paymentName\n'
          'Number: $paymentNumber\n\n'
          'Please upload picture of payment message after paying.',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'type': 'payment_details',
    });

    // Update last chat message
    await FirebaseFirestore.instance.collection('chats').doc(chatId).update({
      'lastMessage': 'Payment details sent',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    // Create user notification
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': userId,
      'title': 'Interpretation Request Accepted',
      'message':
          'Your request for $eventName requires payment. Please check chat for payment details and upload payment proof.',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'chatId': chatId,
    });

    // Update user's unread counts (1 notification + 2 messages)
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'unreadNotifications': FieldValue.increment(1),
      'unreadMessages': FieldValue.increment(2),
    });

    // Decrement admin's unread count if needed
    if (!(notification['isRead'] ?? false)) {
      await FirebaseFirestore.instance.collection('users').doc(adminId).update({
        'unreadNotifications': FieldValue.increment(-1),
      });
    }
  }

  void _showPaymentConfirmationDialog(
      BuildContext context, String docId, Map<String, dynamic> notification) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Have you received payment for this booking?'),
              SizedBox(height: 20),
              Text('Amount: UGX ${notification['amount']}'),
              Text('Payment to: ${notification['paymentName']}'),
              Text('Number: ${notification['paymentNumber']}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _confirmPayment(docId, notification);
              },
              child: Text('Confirm Payment'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmPayment(
      String docId, Map<String, dynamic> notification) async {
    final adminId = FirebaseAuth.instance.currentUser?.uid;
    final userId = notification['userId'];
    final eventName = notification['eventName'] ?? 'Online Interpretation';

    // Update status to Confirmed in admin_notifications
    await FirebaseFirestore.instance
        .collection('admin_notifications')
        .doc(docId)
        .update({
      'status': 'Confirmed',
    });

    // Find and update the corresponding online_interpretations record
    final eventDate = notification['eventDate'];
    if (userId != null && eventDate != null) {
      final interpretationsQuery = await FirebaseFirestore.instance
          .collection('online_interpretations')
          .where('userId', isEqualTo: userId)
          .where('eventDate', isEqualTo: eventDate)
          .get();

      for (var doc in interpretationsQuery.docs) {
        await doc.reference.update({
          'status': 'Confirmed',
        });
      }
    }

    // Create chat message
    final chatId = _generateChatId(adminId!, userId!);

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': adminId,
      'receiverId': userId,
      'text':
          'Payment confirmed for "$eventName". You will receive the meeting link soon.',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'type': 'system',
    });

    // Update last chat message
    await FirebaseFirestore.instance.collection('chats').doc(chatId).update({
      'lastMessage': 'Payment confirmed',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    // Create notification for user
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': userId,
      'title': 'Payment Confirmed',
      'message':
          'Your payment for $eventName has been confirmed. You will receive the meeting link soon.',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'chatId': chatId,
    });

    // Update user's unread counts
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'unreadNotifications': FieldValue.increment(1),
      'unreadMessages': FieldValue.increment(1),
    });
  }

  Future<void> _markAsRead(String docId) async {
    await FirebaseFirestore.instance
        .collection('admin_notifications')
        .doc(docId)
        .update({'isRead': true});

    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .update({
      'unreadNotifications': FieldValue.increment(-1),
    });
  }

  Future<void> _toggleReadStatus(String docId, bool currentStatus) async {
    await FirebaseFirestore.instance
        .collection('admin_notifications')
        .doc(docId)
        .update({'isRead': !currentStatus});

    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .update({
      'unreadNotifications': FieldValue.increment(currentStatus ? 1 : -1),
    });
  }

  Future<void> _updateStatus(
      String docId, Map<String, dynamic> notification, String status) async {
    await FirebaseFirestore.instance
        .collection('admin_notifications')
        .doc(docId)
        .update({'status': status, 'isRead': true});

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

    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': notification['userId'],
      'title': 'Interpretation Request $status',
      'message':
          'Your request for ${notification['eventName']} has been $status',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    if (notification['userId'] != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(notification['userId'])
          .update({
        'unreadNotifications': FieldValue.increment(1),
      });
    }

    if (!(notification['isRead'] ?? false)) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .update({
        'unreadNotifications': FieldValue.increment(-1),
      });
    }
  }

  void _showDeleteConfirmationDialog(
      BuildContext context, String docId, Map<String, dynamic> notification) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Booking'),
          content: Text(
              'Are you sure you want to delete this booking? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteBooking(docId, notification);
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteBooking(
      String docId, Map<String, dynamic> notification) async {
    try {
      await FirebaseFirestore.instance
          .collection('admin_notifications')
          .doc(docId)
          .delete();

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

      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': notification['userId'],
        'title': 'Booking Deleted',
        'message':
            'Your interpretation request for ${notification['eventName']} has been deleted by the administrator',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      if (notification['userId'] != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(notification['userId'])
            .update({
          'unreadNotifications': FieldValue.increment(1),
        });
      }

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

  String _generateChatId(String adminId, String userId) {
    List<String> ids = [adminId, userId];
    ids.sort();
    return ids.join('_');
  }
}
