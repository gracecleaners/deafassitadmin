import 'package:admin/constants.dart';
import 'package:admin/models/booking.dart';
import 'package:admin/responsive.dart';
import 'package:admin/screens/bookings/book_details.dart';
import 'package:admin/screens/dashboard/components/header.dart';
import 'package:admin/screens/main/components/side_menu.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
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

      // Sort bookings by date (latest first)
      allBookings.sort((a, b) {
        final dateA = _getDateTimeFromField(a.data['bookingDate']);
        final dateB = _getDateTimeFromField(b.data['bookingDate']);

        // Handle null dates by putting them at the end
        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;

        // Sort in descending order (latest first)
        return dateB.compareTo(dateA);
      });

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

  // Helper method to convert field value to DateTime for sorting
  DateTime? _getDateTimeFromField(dynamic fieldValue) {
    if (fieldValue == null) return null;

    try {
      if (fieldValue is Timestamp) {
        return fieldValue.toDate();
      } else if (fieldValue is String) {
        return DateTime.parse(fieldValue);
      }
    } catch (e) {
      print('Error parsing date for sorting: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Responsive.isDesktop(context)
          ? null
          : const Drawer(child: SideMenu()),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchAllBookings,
        tooltip: 'Refresh',
        backgroundColor: primaryColor,
        child: const Icon(Icons.refresh_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
          child:
              CircularProgressIndicator(color: primaryColor, strokeWidth: 2));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: dangerColor, size: 40),
            const SizedBox(height: 12),
            Text('Error: $_error',
                style: GoogleFonts.inter(color: darkTextColor)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchAllBookings,
              style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor, foregroundColor: Colors.white),
              child: Text('Retry',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      );
    }

    if (_combinedBookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.calendar_today_outlined,
                  color: primaryColor, size: 36),
            ),
            const SizedBox(height: 16),
            Text('No bookings found',
                style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: darkTextColor)),
          ],
        ),
      );
    }

    return SafeArea(
      child: Row(
        children: [
          if (Responsive.isDesktop(context))
            const SizedBox(width: 260, child: SideMenu()),
          Expanded(
            flex: 5,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(defaultPadding * 1.5),
                child: Container(
                  height: MediaQuery.of(context).size.height - 100,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Header(title: "Bookings"),
                      SizedBox(height: defaultPadding),
                      // Title section
                      Text(
                        "Booking Management",
                        style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: darkTextColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${_combinedBookings.length} total bookings",
                        style: GoogleFonts.inter(
                            fontSize: 14, color: bodyTextColor),
                      ),
                      const SizedBox(height: defaultPadding),
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

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: cardDecoration,
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (eventName != null ? infoColor : primaryColor)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                eventName != null
                    ? Icons.videocam_rounded
                    : Icons.person_pin_rounded,
                color: eventName != null ? infoColor : primaryColor,
                size: 22,
              ),
            ),
            title: Text(
              eventName != null ? 'Event: $eventName' : 'In-person Booking',
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  color: darkTextColor,
                  fontSize: 14),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 13, color: bodyTextColor),
                  const SizedBox(width: 4),
                  Text(formattedDate,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: bodyTextColor)),
                  const SizedBox(width: 16),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status ?? 'Unknown',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: _getStatusColor(status)),
                    ),
                  ),
                ],
              ),
            ),
            trailing:
                const Icon(Icons.chevron_right_rounded, color: bodyTextColor),
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

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'confirmed':
      case 'completed':
      case 'accepted':
        return successColor;
      case 'pending':
      case 'pending payment':
        return warningColor;
      case 'declined':
      case 'cancelled':
        return dangerColor;
      default:
        return bodyTextColor;
    }
  }
}
