import 'package:admin/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CloudStorageInfo {
  final String? svgSrc, title, totalStorage;
  final int? numOfFiles, percentage;
  final Color? color;
  final String collection;
  final String? roleFilter;

  CloudStorageInfo({
    this.svgSrc,
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
    svgSrc: "assets/icons/users.svg",
    totalStorage: "0", // Will be updated
    color: primaryColor,
    percentage: 100,
    collection: "users",
    roleFilter: "deaf",
  ),
  CloudStorageInfo(
    title: "Interpreters",
    svgSrc: "assets/icons/users.svg",
    totalStorage: "0", // Will be updated
    color: Color(0xFFFFA113),
    percentage: 100,
    collection: "users",
    roleFilter: "interpreter",
  ),
  CloudStorageInfo(
    title: "Lessons",
    svgSrc: "assets/icons/menu_doc.svg",
    totalStorage: "0", // Will be updated
    color: Color(0xFFA4CDFF),
    percentage: 100,
    collection: "courses",
  ),
  CloudStorageInfo(
    title: "Bookings",
    svgSrc: "assets/icons/menu_store.svg",
    totalStorage: "0", // Will be updated
    color: Color(0xFF007EE5),
    percentage: 100,
    collection: "interpreter_bookings",
  ),
];

