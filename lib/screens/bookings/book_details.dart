import 'package:admin/constants.dart';
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
      drawer: SideMenu(),
      body: SafeArea(
        
        child: Row(
          children: [
            if (Responsive.isDesktop(context))
            Expanded(
              flex: 1,
              child: SideMenu(),
            ),
            Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Header(title: "Booking"),
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
              // _buildDetailRow('Booking ID', widget.bookingId),
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
          if (widget.collectionName == 'online_interpretations') ...[
            _buildSectionCard(
              title: 'Event Information',
              children: [
                if (_bookingData!.containsKey('eventName'))
                  _buildDetailRow(
                      'Event Name', _bookingData!['eventName'] as String?),
                if (_bookingData!.containsKey('eventDate'))
                  _buildDetailRow(
                      'Event Date', _formatDate(_bookingData!['eventDate'])),
                if (_bookingData!.containsKey('eventTime'))
                  _buildDetailRow(
                      'Event Time', _bookingData!['eventTime'] as String?),
                if (_bookingData!.containsKey('duration'))
                  _buildDetailRow(
                      'Duration', '${_bookingData!['duration']} minutes'),
              ],
            ),
            const SizedBox(height: 20),
          ],
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
              // if (_bookingData!.containsKey('userId'))
              //   _buildDetailRow('User ID', _bookingData!['userId'] as String?),
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
              // if (_bookingData!.containsKey('interpreterId'))
              //   _buildDetailRow('Interpreter ID', _bookingData!['interpreterId'] as String?),
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

  Widget _buildStatusCard(String status) {
    Color statusColor;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'approved':
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
                    onPressed: () => _updateStatus('approved'),
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
                ElevatedButton.icon(
                  icon: const Icon(Icons.note_add),
                  label: const Text('Add Note'),
                  onPressed: _addNote,
                ),
              ],
            ),
          ],
        ),
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

      await _loadBookingData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to $newStatus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _addNote() async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Note'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter your note here',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                try {
                  await FirebaseFirestore.instance
                      .collection(widget.collectionName)
                      .doc(widget.bookingId)
                      .update({
                    'notes': FieldValue.arrayUnion([
                      {
                        'text': controller.text.trim(),
                        'timestamp': FieldValue.serverTimestamp(),
                        'addedBy': 'Admin',
                      }
                    ]),
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Note added successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error adding note: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
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
