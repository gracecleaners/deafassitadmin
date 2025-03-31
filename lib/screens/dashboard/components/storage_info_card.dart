import 'dart:ui';

import 'package:admin/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class StorageInfoCard extends StatelessWidget {
  const StorageInfoCard({
    Key? key,
    required this.svgSrc,
    required this.title,
    required this.amountOfFiles,
    required this.amountOfFile,
    required this.numOfFiles,
    required this.colors,
    required this.color1,
    this.subtitle = '',
  }) : super(key: key);

  final String svgSrc, title, amountOfFiles,amountOfFile, subtitle;
  final int numOfFiles;
  final Color colors, color1;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: defaultPadding),
      padding: EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        border: Border.all(width: 2, color: colors),
        borderRadius: BorderRadius.all(Radius.circular(defaultPadding)),
      ),
      child: Row(
        children: [
          SizedBox(
            height: 20,
            width: 20,
            child: SvgPicture.asset(svgSrc, color: color1),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    amountOfFiles,
                    
                  ),
                  Text(
                    amountOfFile,
                    
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      
                    ),
                ],
              ),
            ),
          ),
          Text("$numOfFiles"),
        ],
      ),
    );
  }
}