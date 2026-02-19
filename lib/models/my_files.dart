import 'package:admin/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CloudStorageInfo {
  final IconData icon;
  final String? title, totalStorage;
  final int? numOfFiles, percentage;
  final Color? color;
  final String collection;
  final String? roleFilter;

  CloudStorageInfo({
    required this.icon,
    this.title,
    this.totalStorage,
    this.numOfFiles,
    this.percentage,
    this.color,
    required this.collection,
    this.roleFilter,
  });
}

List<CloudStorageInfo> demoMyFiles = [
  CloudStorageInfo(
    title: "Deaf Users",
    icon: Icons.people_rounded,
    totalStorage: "0",
    color: primaryColor,
    percentage: 100,
    collection: "users",
    roleFilter: "deaf",
  ),
  CloudStorageInfo(
    title: "Interpreters",
    icon: Icons.interpreter_mode_rounded,
    totalStorage: "0",
    color: Color(0xFFFFA113),
    percentage: 100,
    collection: "users",
    roleFilter: "interpreter",
  ),
  CloudStorageInfo(
    title: "Lessons",
    icon: Icons.menu_book_rounded,
    totalStorage: "0",
    color: Color(0xFFA4CDFF),
    percentage: 100,
    collection: "courses",
  ),
  CloudStorageInfo(
    title: "Bookings",
    icon: Icons.event_note_rounded,
    totalStorage: "0",
    color: Color(0xFF007EE5),
    percentage: 100,
    collection: "interpreter_bookings",
  ),
];
