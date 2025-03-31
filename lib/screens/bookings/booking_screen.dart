import 'package:admin/constants.dart';
import 'package:admin/models/booking.dart';
import 'package:admin/responsive.dart';
import 'package:admin/screens/bookings/book_details.dart';
import 'package:admin/screens/dashboard/components/header.dart';
import 'package:admin/screens/main/components/side_menu.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BookingListScreen extends StatefulWidget {
  @override
  _BookingListScreenState createState() => _BookingListScreenState();
}

class _BookingListScreenState extends State<BookingListScreen> {
  List<BookingModel> _combinedBookings = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAllBookings();
  }

  Future<void> _fetchAllBookings() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Fetch from online_interpretations
      final onlineInterpretationsSnapshot = await FirebaseFirestore.instance
          .collection('online_interpretations')
          .get();

      // Fetch from interpreter_bookings
      final interpreterBookingsSnapshot = await FirebaseFirestore.instance
          .collection('interpreter_bookings')
          .get();

      List<BookingModel> allBookings = [];

      // Add online interpretations
      for (var doc in onlineInterpretationsSnapshot.docs) {
        allBookings.add(BookingModel(
          id: doc.id,
          collectionName: 'online_interpretations',
          data: doc.data(),
        ));
      }

      // Add interpreter bookings
      for (var doc in interpreterBookingsSnapshot.docs) {
        allBookings.add(BookingModel(
          id: doc.id,
          collectionName: 'interpreter_bookings',
          data: doc.data(),
        ));
      }

      setState(() {
        _combinedBookings = allBookings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: SideMenu(),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchAllBookings,
        tooltip: 'Refresh',
        child: Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchAllBookings,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_combinedBookings.isEmpty) {
      return Center(child: Text('No bookings found'));
    }

    return SafeArea(
      child: Row(
        children: [
          if (Responsive.isDesktop(context))
                Expanded(
                  child: SideMenu(),
                ),
          Expanded(
            flex: 5,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(defaultPadding),
                child: Container(
                  height: MediaQuery.of(context).size.height - 100,
                  child: Column(
                    children: [
                      Header(title: "Booking"),
                      SizedBox(height: defaultPadding),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _combinedBookings.length,
                          itemBuilder: (context, index) {
                            final booking = _combinedBookings[index];
                            return _buildBookingItem(booking);
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
    );
  }

  Widget _buildBookingItem(BookingModel booking) {
    final String bookingId = booking.id;
    final collectionName = booking.collectionName;

    // Extract common fields based on collection type
    String? status;
    dynamic bookingDate;
    String? interpreterId;
    String? eventName;

    if (collectionName == 'online_interpretations') {
      status = booking.data['status'] as String?;
      bookingDate = booking.data['bookingDate'];
      interpreterId = booking.data['userId'] as String?;
      eventName = booking.data['eventName'] as String?;
    } else {
      status = booking.data['status'] as String?;
      bookingDate = booking.data['bookingDate'];
      interpreterId = booking.data['interpreterId'] as String?;
      eventName = null; // May not exist in interpreter_bookings
    }

    final formattedDate = _getFormattedDateFromField(bookingDate);

    return FutureBuilder<String>(
      future: _getInterpreterName(interpreterId),
      builder: (context, interpreterSnapshot) {
        final interpreterName = interpreterSnapshot.data ?? 'Loading...';

        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(eventName != null
                ? 'Event: $eventName'
                : 'Booking: ${_formatBookingId(bookingId)}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Date: $formattedDate'),
                Text('Status: ${status ?? 'Unknown'}'),
                Text('Interpreter: $interpreterName'),
                Text(
                    'Type: ${collectionName == 'online_interpretations' ? 'Online' : 'In-Person'}'),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookingDetailScreen(
                    bookingId: bookingId,
                    collectionName: collectionName,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<String> _getInterpreterName(String? interpreterId) async {
    if (interpreterId == null || interpreterId.isEmpty) {
      return 'Admin';
    }

    try {
      final interpreterDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(interpreterId)
          .get();

      if (interpreterDoc.exists && interpreterDoc.data() != null) {
        return interpreterDoc.data()!['name'] ?? 'Unknown Interpreter';
      } else {
        return 'Unknown Interpreter';
      }
    } catch (e) {
      print('Error fetching interpreter: $e');
      return 'Error loading interpreter';
    }
  }

  String _formatBookingId(String id) {
    if (id.length > 8) {
      return id.substring(0, 8) + '...';
    }
    return id;
  }

  String _getFormattedDateFromField(dynamic fieldValue) {
    if (fieldValue == null) return 'No date';

    try {
      if (fieldValue is Timestamp) {
        return DateFormat('MMM d, yyyy').format(fieldValue.toDate());
      } else if (fieldValue is String) {
        return DateFormat('MMM d, yyyy').format(DateTime.parse(fieldValue));
      } else {
        return 'Invalid date format';
      }
    } catch (e) {
      return fieldValue.toString();
    }
  }
}
