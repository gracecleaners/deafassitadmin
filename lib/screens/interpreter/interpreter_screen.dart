import 'package:admin/responsive.dart';
import 'package:admin/screens/interpreter/add_interpreter.dart';
import 'package:admin/screens/main/components/side_menu.dart';
import 'package:flutter/material.dart';

class InterpreterScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Responsive.isDesktop(context) ? null : Drawer(child: SideMenu()),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (Responsive.isDesktop(context))
              SizedBox(width: 260, child: SideMenu()),
            Expanded(child: AddInterpreterScreen()),
          ],
        ),
      ),
    );
  }
}
