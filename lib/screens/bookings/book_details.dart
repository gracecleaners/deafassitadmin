import 'package:admin/constants.dart';
import 'package:admin/controllers/chat.dart';
import 'package:admin/models/message.dart';
import 'package:admin/responsive.dart';
import 'package:admin/screens/dashboard/components/header.dart';
import 'package:admin/screens/main/components/side_menu.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
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
      backgroundColor: bgColor,
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
              padding: EdgeInsets.all(defaultPadding * 1.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Header(title: ''),
                  SizedBox(height: defaultPadding),
                  Text(
                    "Booking Details",
                    style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: darkTextColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "View and manage this booking",
                    style:
                        GoogleFonts.inter(fontSize: 14, color: bodyTextColor),
                  ),
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
      return const Center(
          child:
              CircularProgressIndicator(color: primaryColor, strokeWidth: 2));
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: dangerColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  size: 40, color: dangerColor),
            ),
            const SizedBox(height: 16),
            Text(_errorMessage,
                style: GoogleFonts.inter(fontSize: 14, color: bodyTextColor)),
          ],
        ),
      );
    }

    if (_bookingData == null) {
      return Center(
        child: Text('No booking data available',
            style: GoogleFonts.inter(fontSize: 14, color: bodyTextColor)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            Text('Send Payment Request',
                style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: darkTextColor)),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _formField('Phone Number', '254712345678', phoneController,
                  Icons.phone_outlined, TextInputType.phone,
                  validator: (v) =>
                      v?.isEmpty ?? true ? 'Please enter phone number' : null),
              const SizedBox(height: 14),
              _formField(
                  'Account Name',
                  'M-PESA John Doe',
                  accountNameController,
                  Icons.account_circle_outlined,
                  TextInputType.text,
                  validator: (v) =>
                      v?.isEmpty ?? true ? 'Please enter account name' : null),
              const SizedBox(height: 14),
              _formField(
                  'Amount (UGX)',
                  '1500',
                  amountController,
                  Icons.payments_outlined,
                  TextInputType.number, validator: (v) {
                if (v == null || v.isEmpty) return 'Please enter amount';
                if (double.tryParse(v) == null) return 'Enter valid amount';
                return null;
              }),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: infoColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 16, color: infoColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This payment request will be sent to the user via chat.',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: bodyTextColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('Cancel', style: GoogleFonts.inter(color: bodyTextColor)),
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
              if (formKey.currentState!.validate()) {
                try {
                  final userId = _bookingData!['userId'] as String?;
                  if (userId == null) throw Exception('User ID not found');

                  await chatService.sendMessage(
                    receiverId: userId,
                    content:
                        'Payment Request for In-Person Booking\n\nBooking ID: ${widget.bookingId}\nAmount: UGX ${amountController.text}\nPay to: ${accountNameController.text}\nNumber: ${phoneController.text}\n\nPlease make the payment and upload proof of payment.',
                    type: MessageType.text,
                  );

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
                    'paymentAmount': amountController.text,
                    'paymentMethod': 'Mobile Money',
                    'paymentStatus': 'Pending',
                    'timestamp': FieldValue.serverTimestamp(),
                  });

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

                  await FirebaseFirestore.instance
                      .collection('user_notifications')
                      .add({
                    'userId': userId,
                    'title': 'Payment Request',
                    'message':
                        'Payment request for your booking (ID: ${widget.bookingId}). Check chat for details.',
                    'timestamp': FieldValue.serverTimestamp(),
                    'read': false,
                  });

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
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text('Payment request sent successfully',
                                style: GoogleFonts.inter()),
                          ],
                        ),
                        backgroundColor: successColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e', style: GoogleFonts.inter()),
                        backgroundColor: dangerColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    );
                  }
                }
              }
            },
            child: Text('Send Request',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _formField(String label, String hint, TextEditingController controller,
      IconData icon, TextInputType keyboardType,
      {String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: darkTextColor)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
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

  Widget _buildStatusCard(String status) {
    Color statusColor;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'confirmed':
        statusColor = successColor;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'declined':
        statusColor = dangerColor;
        statusIcon = Icons.cancel_rounded;
        break;
      case 'pending':
        statusColor = warningColor;
        statusIcon = Icons.access_time_rounded;
        break;
      case 'completed':
        statusColor = infoColor;
        statusIcon = Icons.task_alt_rounded;
        break;
      case 'pending payment':
        statusColor = primaryColor;
        statusIcon = Icons.payment_rounded;
        break;
      default:
        statusColor = bodyTextColor;
        statusIcon = Icons.info_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 28),
          const SizedBox(width: 16),
          Text(
            'Status: ${status.toUpperCase()}',
            style: GoogleFonts.inter(
              color: statusColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
      {required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: darkTextColor,
            ),
          ),
          const Divider(color: borderColor),
          const SizedBox(height: 8),
          ...children,
        ],
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
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: darkTextColor,
              ),
            ),
          ),
          Expanded(
            child: isLink
                ? GestureDetector(
                    onTap: onTap,
                    child: Text(
                      value,
                      style: GoogleFonts.inter(
                        color: primaryColor,
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                : Text(
                    value,
                    style:
                        GoogleFonts.inter(fontSize: 13, color: bodyTextColor),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final status = _bookingData!['status'] as String? ?? 'Unknown';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actions',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: darkTextColor,
            ),
          ),
          const Divider(color: borderColor),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 12,
            children: [
              if (status.toLowerCase() == 'pending')
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: Text('Approve',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: successColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  onPressed: () => _updateStatus('confirmed'),
                ),
              if (status.toLowerCase() == 'pending')
                ElevatedButton.icon(
                  icon: const Icon(Icons.cancel_rounded, size: 18),
                  label: Text('Decline',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dangerColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  onPressed: () => _updateStatus('declined'),
                ),
              if (widget.collectionName == 'interpreter_bookings' &&
                  status.toLowerCase() == 'confirmed')
                ElevatedButton.icon(
                  icon: const Icon(Icons.payment_rounded, size: 18),
                  label: Text('Invoke Payment',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  onPressed: _showPaymentRequestDialog,
                ),
              if (status.toLowerCase() == 'confirmed' ||
                  status.toLowerCase() == 'pending payment')
                ElevatedButton.icon(
                  icon:
                      const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: Text('Mark as Completed',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: infoColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  onPressed: () => _updateStatus('completed'),
                ),
            ],
          ),
        ],
      ),
    );
  }

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

      final userId = _bookingData!['userId'] as String?;
      final interpreterId = _bookingData!['interpreterId'] as String?;
      final userName = _bookingData!['userName'] as String? ??
          _relatedData['userName'] ??
          'User';
      final interpreterName = _relatedData['interpreterName'] ?? 'Interpreter';
      final bookingType = widget.collectionName == 'online_interpretations'
          ? 'Online Interpretation'
          : 'In-Person Booking';

      // Notify deaf user on confirm/decline
      if (newStatus == 'confirmed' || newStatus == 'declined') {
        if (userId != null) {
          final title = newStatus == 'confirmed'
              ? 'Booking Confirmed'
              : 'Booking Declined';
          final message = newStatus == 'confirmed'
              ? 'Your $bookingType with $interpreterName has been confirmed by the admin.'
              : 'Your $bookingType with $interpreterName has been declined by the admin.';

          // Write to notifications collection
          await FirebaseFirestore.instance.collection('notifications').add({
            'userId': userId,
            'title': title,
            'message': message,
            'bookingId': widget.bookingId,
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
            'type': 'booking_$newStatus',
          });

          // Write to user_notifications collection
          await FirebaseFirestore.instance
              .collection('user_notifications')
              .add({
            'userId': userId,
            'title': title,
            'message': message,
            'bookingId': widget.bookingId,
            'timestamp': FieldValue.serverTimestamp(),
            'read': false,
            'type': 'booking_$newStatus',
          });

          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .update({
            'unreadNotifications': FieldValue.increment(1),
          });

          // Send chat message
          try {
            final chatService = ChatService();
            await chatService.sendMessage(
              receiverId: userId,
              content:
                  'Your $bookingType (ID: ${widget.bookingId}) has been ${newStatus}.',
            );
          } catch (e) {
            print('Error sending chat notification: $e');
          }
        }

        // Also notify interpreter
        if (interpreterId != null) {
          final interpTitle = newStatus == 'confirmed'
              ? 'Booking Confirmed by Admin'
              : 'Booking Declined by Admin';
          final interpMessage = newStatus == 'confirmed'
              ? 'The $bookingType with $userName has been confirmed by the admin.'
              : 'The $bookingType with $userName has been declined by the admin.';

          await FirebaseFirestore.instance.collection('notifications').add({
            'userId': interpreterId,
            'title': interpTitle,
            'message': interpMessage,
            'bookingId': widget.bookingId,
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
            'type': 'booking_$newStatus',
          });

          await FirebaseFirestore.instance
              .collection('users')
              .doc(interpreterId)
              .update({
            'unreadNotifications': FieldValue.increment(1),
          });
        }
      }

      // Notify both parties when marking as completed
      if (newStatus == 'completed') {
        if (interpreterId != null) {
          await FirebaseFirestore.instance.collection('notifications').add({
            'userId': interpreterId,
            'title': 'Booking Completed - Payment Received',
            'message':
                'Payment has been received for your booking (ID: ${widget.bookingId}). The booking is now completed.',
            'bookingId': widget.bookingId,
            'bookingType': widget.collectionName == 'interpreter_bookings'
                ? 'in-person'
                : 'online',
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
            'type': 'booking_completed',
          });

          await FirebaseFirestore.instance
              .collection('users')
              .doc(interpreterId)
              .update({
            'unreadNotifications': FieldValue.increment(1),
          });
        }

        if (userId != null) {
          await FirebaseFirestore.instance.collection('notifications').add({
            'userId': userId,
            'title': 'Booking Completed',
            'message':
                'Your $bookingType (ID: ${widget.bookingId}) has been marked as completed.',
            'bookingId': widget.bookingId,
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
            'type': 'booking_completed',
          });

          await FirebaseFirestore.instance
              .collection('user_notifications')
              .add({
            'userId': userId,
            'title': 'Booking Completed',
            'message':
                'Your $bookingType (ID: ${widget.bookingId}) has been marked as completed.',
            'bookingId': widget.bookingId,
            'timestamp': FieldValue.serverTimestamp(),
            'read': false,
            'type': 'booking_completed',
          });

          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .update({
            'unreadNotifications': FieldValue.increment(1),
          });
        }
      }

      await _loadBookingData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to $newStatus')),
        );
      }
    } catch (e) {
      print('Error updating status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
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
