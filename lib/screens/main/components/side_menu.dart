import 'package:admin/screens/bookings/booking_screen.dart';
import 'package:admin/screens/chat/chat_list.dart';
import 'package:admin/screens/courses/addcoursewidget.dart';
import 'package:admin/screens/courses/course.dart';
import 'package:admin/screens/deaf/deaf_screen.dart';
import 'package:admin/screens/events/events_screen.dart';
import 'package:admin/screens/interpreter/interpreter_screen.dart';
import 'package:admin/screens/main/main_screen.dart';
import 'package:admin/screens/pdf/pdfs_screen.dart';
import 'package:admin/screens/transactions/transaction_screen.dart';
import 'package:admin/screens/videos/video.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../../../constants.dart';

void navigateWithLoading(BuildContext context, Widget destination) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      Future.delayed(Duration(milliseconds: 500), () {
        Navigator.pop(context);
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                destination,
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: Duration(milliseconds: 300),
          ),
        );
      });
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: cardShadow,
          ),
          child: const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            strokeWidth: 3,
          ),
        ),
      );
    },
  );
}

class SideMenu extends StatelessWidget {
  const SideMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: sidebarGradient),
      child: SafeArea(
        child: Column(
          children: [
            // Logo Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.sign_language,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Deaf Assist",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 12),
            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _SideMenuLabel(label: 'MAIN'),
                  _SideMenuItem(
                    icon: Icons.dashboard_rounded,
                    title: "Dashboard",
                    onTap: () => navigateWithLoading(context, MainScreen()),
                  ),
                  _SideMenuItem(
                    icon: Icons.receipt_long_rounded,
                    title: "Transactions",
                    onTap: () =>
                        navigateWithLoading(context, TransactionScreen()),
                  ),
                  const SizedBox(height: 8),
                  _SideMenuLabel(label: 'USERS'),
                  _SideMenuItem(
                    icon: Icons.interpreter_mode_rounded,
                    title: "Interpreters",
                    onTap: () =>
                        navigateWithLoading(context, InterpreterScreen()),
                  ),
                  _SideMenuItem(
                    icon: Icons.people_alt_rounded,
                    title: "Deaf Users",
                    onTap: () => navigateWithLoading(context, DeafScreen()),
                  ),
                  const SizedBox(height: 8),
                  _SideMenuLabel(label: 'RESOURCES'),
                  _SideMenuItem(
                    icon: Icons.school_rounded,
                    title: "Courses",
                    onTap: () => navigateWithLoading(context, CourseScreen()),
                  ),
                  _SideMenuItem(
                    icon: Icons.play_circle_rounded,
                    title: "Videos",
                    onTap: () => navigateWithLoading(context, VideoScreen()),
                  ),
                  _SideMenuItem(
                    icon: Icons.picture_as_pdf_rounded,
                    title: "PDFs",
                    onTap: () => navigateWithLoading(context, PdfsScreen()),
                  ),
                  const SizedBox(height: 8),
                  _SideMenuLabel(label: 'MANAGEMENT'),
                  _SideMenuItem(
                    icon: Icons.calendar_month_rounded,
                    title: "Bookings",
                    onTap: () =>
                        navigateWithLoading(context, BookingListScreen()),
                  ),
                  _SideMenuItem(
                    icon: Icons.event_rounded,
                    title: "Events",
                    onTap: () => navigateWithLoading(context, EventsScreen()),
                  ),
                  _SideMenuItem(
                    icon: Icons.chat_bubble_rounded,
                    title: "Chats",
                    onTap: () => navigateWithLoading(context, ChatListScreen()),
                  ),
                ],
              ),
            ),
            // Bottom Section
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: const Icon(Icons.admin_panel_settings,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Admin Panel",
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          "v1.0.0",
                          style: GoogleFonts.inter(
                            color: Colors.white60,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideMenuLabel extends StatelessWidget {
  final String label;
  const _SideMenuLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: Colors.white38,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SideMenuItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SideMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  State<_SideMenuItem> createState() => _SideMenuItemState();
}

class _SideMenuItemState extends State<_SideMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 2),
        child: Material(
          color:
              _isHovered ? Colors.white.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                children: [
                  Icon(
                    widget.icon,
                    color: _isHovered ? Colors.white : Colors.white70,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.title,
                    style: GoogleFonts.inter(
                      color: _isHovered ? Colors.white : Colors.white70,
                      fontSize: 14,
                      fontWeight:
                          _isHovered ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DrawerListTile extends StatelessWidget {
  const DrawerListTile({
    Key? key,
    required this.title,
    required this.svgSrc,
    required this.press,
  }) : super(key: key);

  final String title, svgSrc;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: press,
      horizontalTitleGap: 8.0,
      leading: SvgPicture.asset(
        svgSrc,
        colorFilter: const ColorFilter.mode(Colors.white70, BlendMode.srcIn),
        height: 18,
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
      ),
    );
  }
}
