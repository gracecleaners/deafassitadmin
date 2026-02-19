import 'package:admin/screens/dashboard/components/header.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../constants.dart';
import '../../responsive.dart';
import '../main/components/side_menu.dart';

class AdminNotificationsScreen extends StatelessWidget {
  const AdminNotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      drawer: Responsive.isDesktop(context)
          ? null
          : const Drawer(child: SideMenu()),
      body: SafeArea(
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (Responsive.isDesktop(context))
            const SizedBox(width: 260, child: SideMenu()),
          Expanded(
            flex: 5,
            child: SafeArea(
              child: SingleChildScrollView(
                primary: false,
                padding: EdgeInsets.all(defaultPadding * 1.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Header(title: ''),
                    SizedBox(height: defaultPadding),
                    Text(
                      "Notifications",
                      style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: darkTextColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Manage interpretation requests and bookings",
                      style: GoogleFonts.inter(
                          fontSize: 14, color: bodyTextColor),
                    ),
                    SizedBox(height: defaultPadding),
                    Container(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height - 250,
                      ),
                      decoration: cardDecoration,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('admin_notifications')
                                .orderBy('timestamp', descending: true)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: Padding(
                                  padding: EdgeInsets.all(40),
                                  child: CircularProgressIndicator(
                                      color: primaryColor, strokeWidth: 2),
                                ));
                              }

                              if (!snapshot.hasData ||
                                  snapshot.data!.docs.isEmpty) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(40),
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color:
                                                primaryColor.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                              Icons.notifications_none_rounded,
                                              size: 40,
                                              color: primaryColor),
                                        ),
                                        const SizedBox(height: 16),
                                        Text('No notifications yet',
                                            style: GoogleFonts.inter(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                color: bodyTextColor)),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              final notifications = snapshot.data!.docs;

                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: notifications.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(
                                        color: borderColor, height: 1),
                                itemBuilder: (context, index) {
                                  final notification =
                                      notifications[index].data()
                                          as Map<String, dynamic>;
                                  final isRead =
                                      notification['isRead'] ?? false;
                                  final docId = notifications[index].id;
                                  final status =
                                      notification['status'] ?? 'Pending';

                                  return _buildNotificationTile(
                                      context, notification, isRead, docId, status);
                                },
                              );
                            },
                          ),
                        ],
                      ),
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return successColor;
      case 'pending payment':
        return warningColor;
      case 'declined':
        return dangerColor;
      default:
        return infoColor;
    }
  }

  Widget _buildNotificationTile(BuildContext context,
      Map<String, dynamic> notification, bool isRead, String docId, String status) {
    return InkWell(
      onTap: () {
        if (!isRead) _markAsRead(docId);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isRead ? Colors.transparent : primaryColor.withOpacity(0.03),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                status == 'Confirmed'
                    ? Icons.check_circle_outline
                    : status == 'Declined'
                        ? Icons.cancel_outlined
                        : Icons.event_note_rounded,
                color: _getStatusColor(status),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification['eventName'] ??
                              'Online Interpretation Request',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight:
                                isRead ? FontWeight.w500 : FontWeight.w600,
                            color: darkTextColor,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(status),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 16,
                    runSpacing: 4,
                    children: [
                      _infoChip(Icons.calendar_today_rounded,
                          DateFormat('MMM d, yyyy').format((notification['eventDate'] as Timestamp).toDate())),
                      _infoChip(Icons.access_time_rounded,
                          '${notification['eventTime']}'),
                      _infoChip(Icons.timer_outlined,
                          '${notification['duration']} min'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor,
                    ),
                  ),
                PopupMenuButton(
                  icon: Icon(Icons.more_vert, color: bodyTextColor, size: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  itemBuilder: (context) => [
                    _buildPopupItem(Icons.check_circle_outline, 'Accept Request', 'accept', successColor),
                    if (status == 'Pending Payment')
                      _buildPopupItem(Icons.payment_rounded, 'Confirm Payment', 'confirm_payment', primaryColor),
                    _buildPopupItem(Icons.cancel_outlined, 'Decline Request', 'decline', warningColor),
                    _buildPopupItem(
                        isRead ? Icons.mark_email_unread_outlined : Icons.mark_email_read_outlined,
                        isRead ? 'Mark as unread' : 'Mark as read',
                        'mark_read', bodyTextColor),
                    _buildPopupItem(Icons.delete_outline_rounded, 'Delete Booking', 'delete', dangerColor),
                  ],
                  onSelected: (value) async {
                    if (value == 'accept') {
                      _showPaymentDetailsDialog(context, docId, notification);
                    } else if (value == 'confirm_payment') {
                      _showPaymentConfirmationDialog(context, docId, notification);
                    } else if (value == 'decline') {
                      await _updateStatus(docId, notification, 'Declined');
                    } else if (value == 'mark_read') {
                      await _toggleReadStatus(docId, isRead);
                    } else if (value == 'delete') {
                      _showDeleteConfirmationDialog(context, docId, notification);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: bodyTextColor),
        const SizedBox(width: 4),
        Text(text, style: GoogleFonts.inter(fontSize: 12, color: bodyTextColor)),
      ],
    );
  }

  PopupMenuItem _buildPopupItem(IconData icon, String text, String value, Color color) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(text, style: GoogleFonts.inter(fontSize: 13, color: darkTextColor)),
        ],
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.check_circle_outline,
                    color: successColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Accept Request',
                    style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: darkTextColor)),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Provide payment details for this interpretation session:',
                  style: GoogleFonts.inter(fontSize: 13, color: bodyTextColor),
                ),
                const SizedBox(height: 20),
                _buildDialogField('Payment Number', '2547XXXXXXXX',
                    paymentNumberController, Icons.phone_outlined,
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 14),
                _buildDialogField('Account Name', 'e.g., John Doe',
                    paymentNameController, Icons.account_circle_outlined),
                const SizedBox(height: 14),
                _buildDialogField('Amount (UGX)', 'e.g., 5000',
                    amountController, Icons.payments_outlined,
                    keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel',
                  style: GoogleFonts.inter(color: bodyTextColor)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: successColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              onPressed: () async {
                if (paymentNumberController.text.isEmpty ||
                    paymentNameController.text.isEmpty ||
                    amountController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please fill all payment details',
                          style: GoogleFonts.inter()),
                      backgroundColor: dangerColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
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
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text('Request accepted with payment details',
                            style: GoogleFonts.inter()),
                      ],
                    ),
                    backgroundColor: successColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                );
              },
              child:
                  Text('Accept Request', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDialogField(String label, String hint,
      TextEditingController controller, IconData icon,
      {TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: darkTextColor)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(fontSize: 14, color: darkTextColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(fontSize: 13, color: bodyTextColor),
            prefixIcon: Icon(icon, size: 18, color: bodyTextColor),
            fillColor: bgColor,
            filled: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: primaryColor)),
          ),
        ),
      ],
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.payment_rounded,
                    color: primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Confirm Payment',
                    style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: darkTextColor)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Have you received payment for this booking?',
                  style: GoogleFonts.inter(fontSize: 14, color: bodyTextColor)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    _detailRow('Amount', 'UGX ${notification['amount']}'),
                    const SizedBox(height: 8),
                    _detailRow('Pay to', '${notification['paymentName']}'),
                    const SizedBox(height: 8),
                    _detailRow('Number', '${notification['paymentNumber']}'),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel',
                  style: GoogleFonts.inter(color: bodyTextColor)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                await _confirmPayment(docId, notification);
              },
              child: Text('Confirm Payment',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.inter(fontSize: 13, color: bodyTextColor)),
        Text(value,
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: darkTextColor)),
      ],
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: dangerColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    color: dangerColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Delete Booking',
                    style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: darkTextColor)),
              ),
            ],
          ),
          content: Text(
              'Are you sure you want to delete this booking? This action cannot be undone.',
              style: GoogleFonts.inter(fontSize: 14, color: bodyTextColor)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel',
                  style: GoogleFonts.inter(color: bodyTextColor)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: dangerColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteBooking(docId, notification);
              },
              child: Text('Delete',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
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
