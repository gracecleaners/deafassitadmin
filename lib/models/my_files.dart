import 'package:admin/constants.dart';
import 'package:flutter/material.dart';

class CloudStorageInfo {
  final String? svgSrc, title, totalStorage;
  final int? numOfFiles, percentage;
  final Color? color;

  CloudStorageInfo({
    this.svgSrc,
    this.title,
    this.totalStorage,
    this.numOfFiles,
    this.percentage,
    this.color,
  });
}

List demoMyFiles = [
  CloudStorageInfo(
    title: "Deaf Users",
    // numOfFiles: 1328,
    svgSrc: "assets/icons/users.svg",
    totalStorage: "1003",
    color: primaryColor,
    percentage: 100,
  ),
  CloudStorageInfo(
    title: "Interpreters",
    // numOfFiles: 1328,
    svgSrc: "assets/icons/users.svg",
    totalStorage: "500",
    color: Color(0xFFFFA113),
    percentage: 100,
  ),
  CloudStorageInfo(
    title: "Lessons",
    // numOfFiles: 1328,
    svgSrc: "assets/icons/menu_doc.svg",
    totalStorage: "15",
    color: Color(0xFFA4CDFF),
    percentage: 100,
  ),
  CloudStorageInfo(
    title: "Bookings",
    // numOfFiles: 5328,
    svgSrc: "assets/icons/menu_store.svg",
    totalStorage: "1000",
    color: Color(0xFF007EE5),
    percentage: 100,
  ),
];
