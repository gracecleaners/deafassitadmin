import 'package:admin/screens/courses/addcoursewidget.dart';
import 'package:admin/screens/dashboard/components/header.dart';
import 'package:admin/screens/interpreter/add_interpreter_widget.dart';
import 'package:admin/screens/videos/add_video_widget.dart';
import 'package:flutter/material.dart';

import '../../constants.dart';

class AddVideoScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(defaultPadding),
          child: Container(
            height: MediaQuery.of(context).size.height - 100, // Adjust for SafeArea and padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Header(),
                SizedBox(height: defaultPadding),
                Expanded(
                  child: AddVideoWidget(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
