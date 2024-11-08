import 'package:flutter/material.dart';

class PreviewPage extends StatelessWidget {
  final String filePath;
  final List<List<dynamic>> csvData;
  final String fileName;

  const PreviewPage({
    Key? key,
    required this.filePath,
    required this.csvData,
    required this.fileName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Preview: $fileName")),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: DataTable(
            columns: csvData.first
                .map((column) => DataColumn(label: Text(column.toString())))
                .toList(),
            rows: csvData.skip(1).map((row) {
              return DataRow(
                cells:
                    row.map((cell) => DataCell(Text(cell.toString()))).toList(),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
