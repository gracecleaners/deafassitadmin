import 'package:admin/models/event.dart';
import 'package:admin/responsive.dart';
import 'package:admin/screens/dashboard/components/header.dart';
import 'package:admin/screens/events/add_event_dialog.dart';
import 'package:admin/screens/main/components/side_menu.dart';
import 'package:flutter/material.dart';
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
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Header(title: "Event Detail"),
            SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image column
                      Flexible(
                        flex: 1,
                        child: LayoutBuilder(
                          builder: (context, innerConstraints) {
                            return SingleChildScrollView(
                              physics: NeverScrollableScrollPhysics(),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: 0, // Important change
                                  maxHeight: double.infinity,
                                ),
                                child: AspectRatio(
                                  aspectRatio:
                                      3 / 4, // Adjust this ratio as needed
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      event.imageUrl ??
                                          'https://via.placeholder.com/400',
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(width: 24),
                      // Details column
                      Flexible(
                        flex: 1,
                        child: _buildEventDetails(context),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          event.imageUrl ?? 'https://via.placeholder.com/400',
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(height: 24),
                      _buildEventDetails(context),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventDetails(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                event.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            IconButton(
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
                      builder: (context) => EventDetails(event: updatedEvent),
                    ),
                  );
                }
              },
              icon: Icon(Icons.edit),
            ),
          ],
        ),
        SizedBox(height: 16),
        // Date and Time
        _buildDetailRow(
          context,
          icon: Icons.calendar_today,
          title: 'Date & Time',
          content: _buildDateTimeText(),
        ),
        SizedBox(height: 16),

        // Location
        if (event.location != null)
          Column(
            children: [
              _buildDetailRow(
                context,
                icon: Icons.location_on,
                title: 'Location',
                content: Text(event.location!),
              ),
              SizedBox(height: 16),
            ],
          ),

        // Category
        if (event.category != null)
          Column(
            children: [
              _buildDetailRow(
                context,
                icon: Icons.category,
                title: 'Category',
                content: Text(event.category!),
              ),
              SizedBox(height: 16),
            ],
          ),

        // Tags
        if (event.tags != null && event.tags!.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tags',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    event.tags!.map((tag) => Chip(label: Text(tag))).toList(),
              ),
              SizedBox(height: 24),
            ],
          ),

        // Description
        if (event.description != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Description',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              SizedBox(height: 8),
              Text(
                event.description!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              SizedBox(height: 24),
            ],
          ),
      ],
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
        Icon(icon, size: 24),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              SizedBox(height: 4),
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
          Text(dateFormat.format(event.startDate)),
          SizedBox(height: 4),
          Text(
            '${timeFormat.format(event.startDate)} - ${timeFormat.format(event.endDate)}',
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('From: ${dateFormat.format(event.startDate)}'),
          SizedBox(height: 4),
          Text('To: ${dateFormat.format(event.endDate)}'),
        ],
      );
    }
  }
}
