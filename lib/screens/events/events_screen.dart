import 'package:admin/constants.dart';
import 'package:admin/models/event.dart';
import 'package:admin/responsive.dart';
import 'package:admin/screens/dashboard/components/header.dart';
import 'package:admin/screens/main/components/side_menu.dart';
import 'package:admin/screens/events/add_event_dialog.dart';
import 'package:admin/screens/events/event_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EventsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: SideMenu(),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (Responsive.isDesktop(context))
              Expanded(
                child: SideMenu(),
              ),
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
    final Size _size = MediaQuery.of(context).size;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(defaultPadding),
          child: Container(
            height: MediaQuery.of(context).size.height - 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Header(title: "Events Management"),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Upcoming Events",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AddEventDialog(),
                );
              },
              icon: Icon(Icons.add),
              label: Text("Add Event"),
            ),
          ],
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
                return Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text("No events available"));
              }
              
              // Filter out past events if needed
              final currentEvents = snapshot.data!.docs.where((doc) {
                final endDate = (doc.data() as Map<String, dynamic>)['endDate']?.toDate();
                return endDate == null || endDate.isAfter(DateTime.now().subtract(Duration(days: 1)));
              }).toList();

              if (currentEvents.isEmpty) {
                return Center(child: Text("No upcoming events"));
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: AlwaysScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _size.width > 1200 ? 3 : _size.width > 800 ? 2 : 1,
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