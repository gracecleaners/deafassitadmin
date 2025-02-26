import 'package:flutter/material.dart';

class NavigationUtils {
  static void navigateTo(BuildContext context, Widget destination) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => destination),
    );
  }

  static void navigateToAndReplace(BuildContext context, Widget destination) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => destination),
    );
  }
}
