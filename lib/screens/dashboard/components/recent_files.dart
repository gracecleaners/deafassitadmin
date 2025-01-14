import 'package:admin/models/recent_file.dart';

import 'package:flutter/material.dart';

import '../../../constants.dart';

class RecentFiles extends StatelessWidget {
  const RecentFiles({
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
            "User Locations",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            "Distribution of users around Uganda",
            style: TextStyle(color: Colors.grey.withOpacity(0.5)),
          ),
          SizedBox(
            width: double.infinity,
            child: DataTable(
              columnSpacing: defaultPadding,
              // minWidth: 600,
              columns: [
                DataColumn(
                  label: Text("ID"),
                ),
                DataColumn(
                  label: Text("Region"),
                ),
                DataColumn(
                  label: Text("Interpreters"),
                ),
                DataColumn(
                  label: Text("Deaf Users"),
                ),
              ],
              rows: List.generate(
                demoRecentFiles.length,
                (index) => recentFileDataRow(demoRecentFiles[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

DataRow recentFileDataRow(RecentFile fileInfo) {
  return DataRow(
    cells: [
      DataCell(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
          child: Text(fileInfo.id!),
        ),
      ),
      DataCell(Text(fileInfo.region!)),
      DataCell(Text(fileInfo.interpreters!)),
      DataCell(Text(fileInfo.deaf!)),
    ],
  );
}
