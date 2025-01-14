import 'package:admin/screens/courses/course_main.dart';
import 'package:admin/screens/deaf/deaf_screen.dart';
import 'package:admin/screens/interpreter/interpreter_screen.dart';
import 'package:admin/screens/main/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async'; // For Timer

// Function to handle navigation with a loading spinner
void navigateWithLoading(BuildContext context, Widget destination) {
  showDialog(
    context: context,
    barrierDismissible: false, // Prevent dismissal of the dialog
    builder: (BuildContext context) {
      Future.delayed(Duration(seconds: 1), () {
        Navigator.pop(context); // Close the dialog
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => destination),
        );
      });
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      );
    },
  );
}

class SideMenu extends StatelessWidget {
  const SideMenu({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            child: Text(
              "Deaf Assist",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
            ),
          ),
          DrawerListTile(
            title: "Dashboard",
            svgSrc: "assets/icons/menu_dashboard.svg",
            press: () => navigateWithLoading(context, MainScreen()),
          ),
          DrawerListTile(
            title: "Transactions",
            svgSrc: "assets/icons/menu_tran.svg",
            press: () {
              // Add your navigation logic here
            },
          ),
          UsersExpansionTile(), // Dropdown for "Users"
          ResourcesExpansionTile(),
          DrawerListTile(
            title: "Bookings",
            svgSrc: "assets/icons/menu_store.svg",
            press: () {
              // Add your navigation logic here
            },
          ),
          DrawerListTile(
            title: "Events",
            svgSrc: "assets/icons/event.svg",
            press: () {
              // Add your navigation logic here
            },
          ),
          DrawerListTile(
            title: "Subscription",
            svgSrc: "assets/icons/subscription.svg",
            press: () {
              // Add your navigation logic here
            },
          ),
          DrawerListTile(
            title: "Report",
            svgSrc: "assets/icons/report.svg",
            press: () {
              // Add your navigation logic here
            },
          ),
        ],
      ),
    );
  }
}

class UsersExpansionTile extends StatelessWidget {
  const UsersExpansionTile({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: SvgPicture.asset(
        "assets/icons/users.svg",
        colorFilter: ColorFilter.mode(Colors.white54, BlendMode.srcIn),
        height: 16,
      ),
      title: Text(
        "Users",
        style: TextStyle(color: Colors.white54),
      ),
      children: [
        ListTile(
          onTap: () => navigateWithLoading(context, InterpreterScreen()),
          leading: SvgPicture.asset(
            'assets/icons/users.svg',
            colorFilter: ColorFilter.mode(Colors.white54, BlendMode.srcIn),
            height: 16,
          ),
          title: Text(
            "Interpreters",
            style: TextStyle(color: Colors.white54),
          ),
        ),
        ListTile(
          onTap: () => navigateWithLoading(context, DeafScreen()),
          leading: SvgPicture.asset(
            'assets/icons/users.svg',
            colorFilter: ColorFilter.mode(Colors.white54, BlendMode.srcIn),
            height: 16,
          ),
          title: Text(
            "Deaf Users",
            style: TextStyle(color: Colors.white54),
          ),
        ),
      ],
    );
  }
}

class ResourcesExpansionTile extends StatelessWidget {
  const ResourcesExpansionTile({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: SvgPicture.asset(
        "assets/icons/menu_doc.svg",
        colorFilter: ColorFilter.mode(Colors.white54, BlendMode.srcIn),
        height: 16,
      ),
      title: Text(
        "Resources",
        style: TextStyle(color: Colors.white54),
      ),
      children: [
        ListTile(
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => CourseScreen()));
          },
          leading: SvgPicture.asset(
            'assets/icons/menu_doc.svg',
            colorFilter: ColorFilter.mode(Colors.white54, BlendMode.srcIn),
            height: 16,
          ),
          title: Text(
            "Courses",
            style: TextStyle(color: Colors.white54),
          ),
        ),
        ListTile(
          onTap: () {
            // Handle "Manage Users" action
          },
          leading: SvgPicture.asset(
            'assets/icons/media.svg',
            colorFilter: ColorFilter.mode(Colors.white54, BlendMode.srcIn),
            height: 16,
          ),
          title: Text(
            "Videos",
            style: TextStyle(color: Colors.white54),
          ),
        ),
        ListTile(
          onTap: () {
            // Handle "Manage Users" action
          },
          leading: SvgPicture.asset(
            'assets/icons/Documents.svg',
            colorFilter: ColorFilter.mode(Colors.white54, BlendMode.srcIn),
            height: 16,
          ),
          title: Text(
            "PDFs",
            style: TextStyle(color: Colors.white54),
          ),
        ),
      ],
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
      horizontalTitleGap: 0.0,
      leading: SvgPicture.asset(
        svgSrc,
        colorFilter: ColorFilter.mode(Colors.white54, BlendMode.srcIn),
        height: 16,
      ),
      title: Text(
        title,
        style: TextStyle(color: Colors.white54),
      ),
    );
  }
}
