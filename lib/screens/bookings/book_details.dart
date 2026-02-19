import 'package:admin/constants.dart';
import 'package:admin/controllers/chat.dart';
import 'package:admin/models/message.dart';
import 'package:admin/responsive.dart';
import 'package:admin/screens/dashboard/components/header.dart';
import 'package:admin/screens/main/components/side_menu.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class BookingDetailScreen extends StatefulWidget {
  final String bookingId;
  final String collectionName;

  const BookingDetailScreen({
    Key? key,
    required this.bookingId,
    required this.collectionName,
  }) : super(key: key);

  @override
  _BookingDetailScreenState createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  bool _isLoading = true;
  bool _isUpdating = false;
  bool _hasError = false;
  String _errorMessage = '';
  Map<String, dynamic>? _bookingData;
  Map<String, dynamic> _relatedData = {};

  @override
  void initState() {
    super.initState();
    _loadBookingData();
  }

  Future<void> _loadBookingData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection(widget.collectionName)
          .doc(widget.bookingId)
          .get();

      if (doc.exists) {
        setState(() {
          _bookingData = doc.data()!;
        });
        await _loadRelatedData();
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = 'Booking not found';
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Error loading booking: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRelatedData() async {
    if (_bookingData == null) return;

    try {
      final interpreterId = _bookingData!['interpreterId'] as String?;
      final userId = _bookingData!['userId'] as String?;

      if (interpreterId != null) {
        final interpreterDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(interpreterId)
            .get();

        if (interpreterDoc.exists) {
          _relatedData['interpreterName'] = interpreterDoc['name'] ?? 'Unknown';
          _relatedData['interpreterEmail'] = interpreterDoc['email'];
          _relatedData['interpreterContact'] = interpreterDoc['contact'];
          _relatedData['interpreterRegion'] = interpreterDoc['region'];
          _relatedData['interpreterExperience'] =
              interpreterDoc['yearsOfExperience'];
        }
      }

      if (userId != null && userId != interpreterId) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userDoc.exists) {
          _relatedData['userName'] = userDoc['name'] ?? 'Unknown';
          _relatedData['userEmail'] = userDoc['email'];
          _relatedData['userPhone'] = userDoc['contact'];
        }
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Error loading related data: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Responsive.isDesktop(context)
          ? null
          : const Drawer(child: SideMenu()),
      body: SafeArea(
          child: Row(
        children: [
          if (Responsive.isDesktop(context))
            const SizedBox(width: 260, child: SideMenu()),
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Header(title: "Booking Details"),
                  SizedBox(height: defaultPadding),
                  Expanded(child: _buildContent()),
                ],
              ),
            ),
          ),
        ],
      )),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return Center(
        child: Text(
          _errorMessage,
          style: const TextStyle(color: Colors.white),
        ),
      );
    }

    if (_bookingData == null) {
      return const Center(
        child: Text(
          'No booking data available',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    final status = _bookingData!['status'] as String? ?? 'Unknown';
    final interpreterName = _relatedData['interpreterName'] ?? 'Unknown';
    final userName = _bookingData!['userName'] as String? ??
        _relatedData['userName'] ??
        'Unknown';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(status),
          const SizedBox(height: 20),
          _buildSectionCard(
            title: 'Booking Information',
            children: [
              _buildDetailRow(
                  'Type',
                  widget.collectionName == 'online_interpretations'
                      ? 'Online Interpretation'
                      : 'In-Person Booking'),
              _buildDetailRow('Status', status),
              if (_bookingData!.containsKey('bookingDate'))
                _buildDetailRow(
                    'Booking Date', _formatDate(_bookingData!['bookingDate'])),
              if (_bookingData!.containsKey('timestamp'))
                _buildDetailRow(
                    'Last Updated', _formatDate(_bookingData!['timestamp'])),
            ],
          ),
          const SizedBox(height: 20),
          _buildSectionCard(
            title: 'User Information',
            children: [
              _buildDetailRow('Name', userName),
              if (_relatedData.containsKey('userEmail'))
                _buildDetailRow(
                  'Email',
                  _relatedData['userEmail'],
                  isLink: true,
                  onTap: () => _launchEmail(_relatedData['userEmail']),
                ),
              if (_relatedData.containsKey('userPhone'))
                _buildDetailRow(
                  'Phone',
                  _relatedData['userPhone'],
                  isLink: true,
                  onTap: () => _launchPhone(_relatedData['userPhone']),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSectionCard(
            title: 'Interpreter Information',
            children: [
              _buildDetailRow('Interpreter', interpreterName),
              if (_relatedData.containsKey('interpreterEmail'))
                _buildDetailRow(
                  'Email',
                  _relatedData['interpreterEmail'],
                  isLink: true,
                  onTap: () => _launchEmail(_relatedData['interpreterEmail']),
                ),
              if (_relatedData.containsKey('interpreterContact'))
                _buildDetailRow(
                  'Phone',
                  _relatedData['interpreterContact'],
                  isLink: true,
                  onTap: () => _launchPhone(_relatedData['interpreterContact']),
                ),
              if (_relatedData.containsKey('interpreterRegion'))
                _buildDetailRow('Region', _relatedData['interpreterRegion']),
              if (_relatedData.containsKey('interpreterExperience'))
                _buildDetailRow('Experience',
                    '${_relatedData['interpreterExperience']} years'),
            ],
          ),
          const SizedBox(height: 20),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Future<void> _showPaymentRequestDialog() async {
    final phoneController = TextEditingController();
    final accountNameController = TextEditingController();
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final chatService = ChatService();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Payment Request'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'e.g. 254712345678',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: accountNameController,
                decoration: const InputDecoration(
                  labelText: 'Account Name',
                  hintText: 'e.g. M-PESA John Doe',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter account name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount (UGX)',
                  hintText: 'e.g. 1500',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'This payment request will be sent to the user via chat.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  final userId = _bookingData!['userId'] as String?;
                  if (userId == null) {
                    throw Exception('User ID not found');
                  }

                  // Send payment request message
                  await chatService.sendMessage(
                    receiverId: userId,
                    content:
                        'Payment Request for In-Person Booking\n\nBooking ID: ${widget.bookingId}\nAmount: UGX ${amountController.text}\nPay to: ${accountNameController.text}\nNumber: ${phoneController.text}\n\nPlease make the payment and upload proof of payment.',
                    type: MessageType.text,
                  );

                  // Update booking status to indicate payment request sent
                  await FirebaseFirestore.instance
                      .collection(widget.collectionName)
                      .doc(widget.bookingId)
                      .update({
                    'status': 'Pending Payment',
                    'paymentDetails': {
                      'phone': phoneController.text,
                      'accountName': accountNameController.text,
                      'amount': amountController.text,
                      'requestSentAt': FieldValue.serverTimestamp(),
                    },
                    'timestamp': FieldValue.serverTimestamp(),
                  });

                  // Send notification
                  await FirebaseFirestore.instance
                      .collection('notifications')
                      .add({
                    'userId': userId,
                    'title': 'Payment Request',
                    'message':
                        'Payment request for your booking (ID: ${widget.bookingId})',
                    'timestamp': FieldValue.serverTimestamp(),
                    'isRead': false,
                  });

                  // Update user's unread notifications count
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .update({
                    'unreadNotifications': FieldValue.increment(1),
                  });

                  Navigator.pop(context);
                  await _loadBookingData();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Payment request sent successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error sending payment request: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String status) {
    Color statusColor;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'confirmed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'declined':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.access_time;
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusIcon = Icons.task_alt;
        break;
      case 'pending payment':
        statusColor = Colors.purple;
        statusIcon = Icons.payment;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info;
    }

    return Card(
      color: statusColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(statusIcon, color: Colors.white, size: 28),
            const SizedBox(width: 16),
            Text(
              'Status: ${status.toUpperCase()}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
      {required String title, required List<Widget> children}) {
    return Card(
      color: Colors.grey[850],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Divider(color: Colors.white54),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value,
      {bool isLink = false, VoidCallback? onTap}) {
    if (value == null || value.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: isLink
                ? GestureDetector(
                    onTap: onTap,
                    child: Text(
                      value,
                      style: const TextStyle(
                        color: Colors.lightBlue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                : Text(
                    value,
                    style: const TextStyle(color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final status = _bookingData!['status'] as String? ?? 'Unknown';

    return Card(
      color: Colors.grey[850],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Divider(color: Colors.white54),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 12,
              children: [
                if (status.toLowerCase() == 'pending')
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () => _updateStatus('confirmed'),
                  ),
                if (status.toLowerCase() == 'pending')
                  ElevatedButton.icon(
                    icon: const Icon(Icons.cancel),
                    label: const Text('Decline'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () => _updateStatus('declined'),
                  ),
                // Invoke Payment button for confirmed in-person bookings
                if (widget.collectionName == 'interpreter_bookings' &&
                    status.toLowerCase() == 'confirmed')
                  ElevatedButton.icon(
                    icon: const Icon(Icons.payment),
                    label: const Text('Invoke Payment'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _showPaymentRequestDialog,
                  ),
                if (status.toLowerCase() == 'confirmed' ||
                    status.toLowerCase() == 'pending payment')
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Mark as Completed'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    onPressed: () => _updateStatus('completed'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Updated _updateStatus method with better debugging
  Future<void> _updateStatus(String newStatus) async {
    try {
      setState(() => _isUpdating = true);

      await FirebaseFirestore.instance
          .collection(widget.collectionName)
          .doc(widget.bookingId)
          .update({
        'status': newStatus,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (newStatus == 'confirmed') {
        final userId = _bookingData!['userId'] as String?;
        if (userId != null) {
          try {
            final chatService = ChatService();
            await chatService.sendMessage(
              receiverId: userId,
              content:
                  'Your booking (ID: ${widget.bookingId}) has been confirmed.',
            );
          } catch (e) {
            print('Error sending confirmation notification: $e');
          }
        }
      }

      // UPDATED: Send notification to interpreter when marking in-person booking as completed
      if (newStatus == 'completed' &&
          widget.collectionName == 'interpreter_bookings') {
        final interpreterId = _bookingData!['interpreterId'] as String?;

        print('DEBUG: Creating notification for interpreterId: $interpreterId');
        print('DEBUG: BookingId: ${widget.bookingId}');

        if (interpreterId != null) {
          try {
            // Create the notification data
            final notificationData = {
              'userId': interpreterId,
              'title': 'Booking Completed - Payment Received',
              'message':
                  'Payment has been received for your booking (ID: ${widget.bookingId}). The booking is now completed.',
              'bookingId': widget.bookingId,
              'bookingType': 'in-person',
              'timestamp': FieldValue.serverTimestamp(),
              'isRead': false, // Make sure this is explicitly false
              'type': 'booking_completed',
            };

            print('DEBUG: Notification data being sent: $notificationData');

            // Send notification to interpreter
            final docRef = await FirebaseFirestore.instance
                .collection('notifications')
                .add(notificationData);

            print('DEBUG: Notification created with ID: ${docRef.id}');

            // Verify the notification was created correctly
            final createdNotification = await docRef.get();
            print(
                'DEBUG: Created notification data: ${createdNotification.data()}');

            // Update interpreter's unread notifications count
            await FirebaseFirestore.instance
                .collection('users')
                .doc(interpreterId)
                .update({
              'unreadNotifications': FieldValue.increment(1),
              'hasCompletedBookings': true,
            });

            print(
                'DEBUG: Notification successfully sent to interpreter: $interpreterId');

            // Additional verification - query for the notification
            final verificationQuery = await FirebaseFirestore.instance
                .collection('notifications')
                .where('userId', isEqualTo: interpreterId)
                .where('type', isEqualTo: 'booking_completed')
                .where('isRead', isEqualTo: false)
                .get();

            print(
                'DEBUG: Verification query found ${verificationQuery.docs.length} unread booking_completed notifications');
          } catch (e) {
            print(
                'ERROR: Failed to send completion notification to interpreter: $e');
            print('ERROR: Stack trace: ${StackTrace.current}');
          }
        } else {
          print('DEBUG: No interpreterId found in booking data');
          print('DEBUG: Booking data: $_bookingData');
        }
      }

      await _loadBookingData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to $newStatus')),
      );
    } catch (e) {
      print('ERROR: Failed to update status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    if (date is Timestamp)
      return DateFormat.yMMMd().add_jm().format(date.toDate());
    if (date is String)
      return DateFormat.yMMMd().add_jm().format(DateTime.parse(date));
    return date.toString();
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (!await launchUrl(uri)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch email client')),
      );
    }
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (!await launchUrl(uri)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch phone dialer')),
      );
    }
  }
}
