// import 'package:admin/controllers/menu_app_controller.dart';
import 'package:admin/responsive.dart';
import 'package:admin/screens/main/components/side_menu.dart';
import 'package:admin/screens/transactions/transaction_header.dart';
import 'package:admin/screens/videos/video_widget.dart';
import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

class TransactionScreen extends StatelessWidget {
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
              child: TransactionHeader(),
            ),
          ],
        ),
      ),
    );
  }
}
