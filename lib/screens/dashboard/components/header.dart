import 'package:admin/controllers/menu_app_controller.dart';
import 'package:admin/responsive.dart';
import 'package:admin/screens/Notification/notification_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../constants.dart';
import '../../Notification/profile.dart';

class Header extends StatelessWidget {
  final String title;
  const Header({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (!Responsive.isDesktop(context))
            Container(
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: secondaryColor,
                borderRadius: BorderRadius.circular(10),
                boxShadow: cardShadow,
              ),
              child: IconButton(
                icon: const Icon(Icons.menu_rounded, color: darkTextColor),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          if (!Responsive.isMobile(context))
            Text(
              title.isEmpty ? "Dashboard" : title,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: darkTextColor,
              ),
            ),
          const Spacer(),
          // Search field
          SizedBox(
            width: Responsive.isMobile(context) ? 160 : 280,
            child: const SearchField(),
          ),
          const SizedBox(width: 12),
          // Notification Bell
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              int unreadNotifications = 0;
              if (snapshot.hasData &&
                  snapshot.data != null &&
                  snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>?;
                unreadNotifications = data?['unreadNotifications'] ?? 0;
              }
              return Container(
                decoration: BoxDecoration(
                  color: secondaryColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: cardShadow,
                ),
                child: Stack(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.notifications_none_rounded,
                        color: unreadNotifications > 0
                            ? primaryColor
                            : bodyTextColor,
                        size: 22,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => AdminNotificationsScreen()),
                        );
                      },
                    ),
                    if (unreadNotifications > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: dangerColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          const ProfileCard(),
        ],
      ),
    );
  }
}

class ProfileCard extends StatelessWidget {
  const ProfileCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AdminProfileScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: secondaryColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: cardShadow,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: primaryColor.withOpacity(0.1),
              child: const Icon(Icons.person_rounded,
                  color: primaryColor, size: 20),
            ),
            if (!Responsive.isMobile(context)) ...[
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Administrator",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: darkTextColor,
                    ),
                  ),
                  Text(
                    "Admin",
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: bodyTextColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down_rounded,
                  color: bodyTextColor, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}

class SearchField extends StatelessWidget {
  const SearchField({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      style: GoogleFonts.inter(fontSize: 14, color: darkTextColor),
      decoration: InputDecoration(
        hintText: "Search...",
        hintStyle: GoogleFonts.inter(
            color: bodyTextColor.withOpacity(0.5), fontSize: 14),
        fillColor: secondaryColor,
        filled: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: Icon(Icons.search_rounded,
            color: bodyTextColor.withOpacity(0.5), size: 20),
      ),
    );
  }
}
