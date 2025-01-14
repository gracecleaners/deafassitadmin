import 'package:flutter/material.dart';

import '../../../constants.dart';
import 'chart.dart';
import 'storage_info_card.dart';

class StorageDetails extends StatelessWidget {
  const StorageDetails({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "User Analysis",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: defaultPadding),
          Chart(),
          StorageInfoCard(
            svgSrc: "assets/icons/users.svg",
            title: "Central Region",
            amountOfFiles: "300",
            numOfFiles: 1328, colors: primaryColor.withOpacity(0.3), color1: primaryColor,
          ),
          StorageInfoCard(
            svgSrc: "assets/icons/users.svg",
            title: "Eastern Region",
            amountOfFiles: "300",
            numOfFiles: 1328, colors: Color(0xFF26E5FF).withOpacity(0.3), color1: Color(0xFF26E5FF),
          ),
          StorageInfoCard(
            svgSrc: "assets/icons/users.svg",
            title: "Northern Region",
            amountOfFiles: "400",
            numOfFiles: 1328, colors: Color(0xFFFFCF26).withOpacity(0.3), color1: Color(0xFFFFCF26),
          ),
          StorageInfoCard(
            svgSrc: "assets/icons/users.svg",
            title: "Western Region",
            amountOfFiles: "500",
            numOfFiles: 140, colors: Colors.red.withOpacity(0.3), color1: Colors.red,
          ),
        ],
      ),
    );
  }
}
