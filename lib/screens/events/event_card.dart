import 'package:admin/models/event.dart';
import 'package:admin/screens/events/event_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback? onTap;

  const EventCard({
    Key? key,
    required this.event,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        // Add this to the InkWell's onTap in event_card.dart
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailsScreen(event: event),
            ),
          );
        },

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.imageUrl != null)
              Image.network(
                event.imageUrl!,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  SizedBox(height: 8),
                  Text(
                    event.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  if (event.description != null)
                    Text(
                      event.description!,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16),
                      SizedBox(width: 8),
                      Text(
                        '${DateFormat('MMM dd, yyyy').format(event.startDate)}'
                        '${event.endDate != event.startDate ? ' - ${DateFormat('MMM dd, yyyy').format(event.endDate)}' : ''}',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  if (event.location != null) ...[
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16),
                        SizedBox(width: 8),
                        Text(
                          event.location!,
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: 12),
                  // if (event.category != null || event.tags != null)
                  //   Wrap(
                  //     spacing: 8,
                  //     children: [
                  //       if (event.category != null)
                  //         Chip(
                  //           label: Text(event.category!),
                  //           backgroundColor: Colors.blue[100],
                  //         ),
                  //       ...?event.tags?.map((tag) => Chip(
                  //             label: Text(tag, style: ,),
                  //             backgroundColor: Colors.grey[200],
                  //           )),
                  //     ],
                  //   ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
