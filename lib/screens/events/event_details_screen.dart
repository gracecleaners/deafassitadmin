import 'package:admin/constants.dart';
import 'package:admin/models/event.dart';
import 'package:admin/responsive.dart';
import 'package:admin/screens/dashboard/components/header.dart';
import 'package:admin/screens/events/add_event_dialog.dart';
import 'package:admin/screens/main/components/side_menu.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class EventDetails extends StatelessWidget {
  final Event event;
  const EventDetails({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Responsive.isDesktop(context)
          ? null
          : const Drawer(child: SideMenu()),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (Responsive.isDesktop(context))
              const SizedBox(width: 260, child: SideMenu()),
            Expanded(
              flex: 5,
              child: EventDetailsScreen(
                event: event,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EventDetailsScreen extends StatelessWidget {
  final Event event;

  const EventDetailsScreen({Key? key, required this.event}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(defaultPadding * 1.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Header(title: ''),
          SizedBox(height: defaultPadding),
          Text(
            "Event Details",
            style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: darkTextColor),
          ),
          const SizedBox(height: 4),
          Text(
            "View event information",
            style: GoogleFonts.inter(fontSize: 14, color: bodyTextColor),
          ),
          SizedBox(height: defaultPadding),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 600) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      flex: 1,
                      child: Container(
                        decoration: cardDecoration,
                        clipBehavior: Clip.antiAlias,
                        child: AspectRatio(
                          aspectRatio: 3 / 4,
                          child: Image.network(
                            event.imageUrl ?? 'https://via.placeholder.com/400',
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Flexible(
                      flex: 1,
                      child: _buildEventDetails(context),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    Container(
                      decoration: cardDecoration,
                      clipBehavior: Clip.antiAlias,
                      child: Image.network(
                        event.imageUrl ?? 'https://via.placeholder.com/400',
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildEventDetails(context),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEventDetails(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  event.title,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: darkTextColor,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: () async {
                    final updatedEvent = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddEventDialog(event: event),
                      ),
                    );

                    if (updatedEvent != null) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EventDetails(event: updatedEvent),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.edit_rounded,
                      color: primaryColor, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDetailRow(
            context,
            icon: Icons.calendar_today_rounded,
            title: 'Date & Time',
            content: _buildDateTimeText(),
          ),
          const SizedBox(height: 16),
          if (event.location != null) ...[
            _buildDetailRow(
              context,
              icon: Icons.location_on_rounded,
              title: 'Location',
              content: Text(event.location!,
                  style: GoogleFonts.inter(fontSize: 14, color: bodyTextColor)),
            ),
            const SizedBox(height: 16),
          ],
          if (event.category != null) ...[
            _buildDetailRow(
              context,
              icon: Icons.category_rounded,
              title: 'Category',
              content: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(event.category!,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: primaryColor)),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (event.tags != null && event.tags!.isNotEmpty) ...[
            Text('Tags',
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: darkTextColor)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: event.tags!
                  .map((tag) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: borderColor),
                        ),
                        child: Text(tag,
                            style: GoogleFonts.inter(
                                fontSize: 12, color: bodyTextColor)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],
          if (event.description != null) ...[
            const Divider(color: borderColor),
            const SizedBox(height: 16),
            Text('Description',
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: darkTextColor)),
            const SizedBox(height: 8),
            Text(
              event.description!,
              style: GoogleFonts.inter(
                  fontSize: 14, color: bodyTextColor, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget content,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: primaryColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: darkTextColor)),
              const SizedBox(height: 4),
              content,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeText() {
    final dateFormat = DateFormat('MMMM d, y');
    final timeFormat = DateFormat('h:mm a');

    final isSameDay = event.startDate.day == event.endDate.day &&
        event.startDate.month == event.endDate.month &&
        event.startDate.year == event.endDate.year;

    if (isSameDay) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dateFormat.format(event.startDate),
              style: GoogleFonts.inter(fontSize: 14, color: bodyTextColor)),
          const SizedBox(height: 4),
          Text(
            '${timeFormat.format(event.startDate)} - ${timeFormat.format(event.endDate)}',
            style: GoogleFonts.inter(fontSize: 13, color: bodyTextColor),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('From: ${dateFormat.format(event.startDate)}',
              style: GoogleFonts.inter(fontSize: 14, color: bodyTextColor)),
          const SizedBox(height: 4),
          Text('To: ${dateFormat.format(event.endDate)}',
              style: GoogleFonts.inter(fontSize: 14, color: bodyTextColor)),
        ],
      );
    }
  }
}
