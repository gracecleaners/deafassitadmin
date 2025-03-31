import 'package:admin/models/event.dart';
import 'package:admin/screens/events/add_event_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class EventDetailsScreen extends StatelessWidget {
  final Event event;

  const EventDetailsScreen({Key? key, required this.event}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(event.title),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEventDialog(event: event),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Image
            if (event.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  event.imageUrl!,
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                ),
              ),
            SizedBox(height: 24),

            // Event Title and Featured Badge
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
                if (event.isFeatured)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'FEATURED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                    children: event.tags!
                        .map((tag) => Chip(label: Text(tag)))
                        .toList(),
                  ),
                  SizedBox(height: 24),
                ],
              ),

            // Action Buttons
          ],
        ),
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
