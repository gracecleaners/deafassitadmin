import 'package:admin/constants.dart';
import 'package:admin/models/event.dart';
import 'package:admin/responsive.dart';
import 'package:admin/screens/dashboard/components/header.dart';
import 'package:admin/screens/main/components/side_menu.dart';
import 'package:admin/screens/events/add_event_dialog.dart';
import 'package:admin/screens/events/event_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EventsScreen extends StatelessWidget {
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
              child: EventsListScreen(),
            ),
          ],
        ),
      ),
    );
  }
}

class EventsListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(defaultPadding * 1.5),
          child: Container(
            height: MediaQuery.of(context).size.height - 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Header(title: "Events"),
                SizedBox(height: defaultPadding),
                Text(
                  "Events Management",
                  style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: darkTextColor),
                ),
                const SizedBox(height: 4),
                Text(
                  "Create and manage upcoming events",
                  style: GoogleFonts.inter(fontSize: 14, color: bodyTextColor),
                ),
                SizedBox(height: defaultPadding),
                Expanded(
                  child: EventsGrid(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EventsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Size _size = MediaQuery.of(context).size;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: cardDecoration,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.event_rounded,
                        color: primaryColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text("Upcoming Events",
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: darkTextColor)),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  showDialog(
                      context: context, builder: (context) => AddEventDialog());
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text("Add Event",
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ],
          ),
        ),
        SizedBox(height: defaultPadding),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('events')
                .orderBy('startDate')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: primaryColor, strokeWidth: 2));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.event_busy,
                            color: primaryColor, size: 36),
                      ),
                      const SizedBox(height: 16),
                      Text("No events available",
                          style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: darkTextColor)),
                    ],
                  ),
                );
              }

              // Filter out past events if needed
              final currentEvents = snapshot.data!.docs.where((doc) {
                final endDate =
                    (doc.data() as Map<String, dynamic>)['endDate']?.toDate();
                return endDate == null ||
                    endDate.isAfter(DateTime.now().subtract(Duration(days: 1)));
              }).toList();

              if (currentEvents.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.event_available,
                            color: primaryColor, size: 36),
                      ),
                      const SizedBox(height: 16),
                      Text("No upcoming events",
                          style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: darkTextColor)),
                    ],
                  ),
                );
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: AlwaysScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _size.width > 1200
                      ? 3
                      : _size.width > 800
                          ? 2
                          : 1,
                  crossAxisSpacing: defaultPadding,
                  mainAxisSpacing: defaultPadding,
                  childAspectRatio: 0.8,
                ),
                itemCount: currentEvents.length,
                itemBuilder: (context, index) {
                  var eventData = currentEvents[index];
                  return EventCard(
                    event: Event.fromJson(
                      eventData.data() as Map<String, dynamic>,
                      eventData.id,
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AddEventDialog(
                          event: Event.fromJson(
                            eventData.data() as Map<String, dynamic>,
                            eventData.id,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
