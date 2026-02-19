import 'package:admin/constants.dart';
import 'package:admin/models/event.dart';
import 'package:admin/screens/events/event_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    return Container(
      decoration: cardDecoration,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetails(event: event),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.imageUrl != null)
              Image.network(
                event.imageUrl!,
                height: 250,
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: warningColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'FEATURED',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    event.title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: darkTextColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  if (event.description != null)
                    Text(
                      event.description!,
                      style:
                          GoogleFonts.inter(fontSize: 13, color: bodyTextColor),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: primaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${DateFormat('MMM dd, yyyy').format(event.startDate)}'
                          '${event.endDate != event.startDate ? ' - ${DateFormat('MMM dd, yyyy').format(event.endDate)}' : ''}',
                          style: GoogleFonts.inter(
                              color: darkTextColor, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  if (event.location != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: primaryColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            event.location!,
                            style: GoogleFonts.inter(
                                color: darkTextColor, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
