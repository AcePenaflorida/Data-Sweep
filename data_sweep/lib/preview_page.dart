import 'package:flutter/material.dart';

class PreviewPage extends StatelessWidget {
  final List<List<dynamic>> csvData;
  final String fileName;

  const PreviewPage({
    Key? key,
    required this.csvData,
    required this.fileName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "FILE PREVIEW",
          style: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.bold,
            fontSize: 24, // Reduced font size
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 61, 126, 64),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 24, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        color: const Color.fromARGB(
            255, 229, 234, 222), // Set the background color for the entire body
        child: csvData.isNotEmpty
            ? SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(
                      const Color.fromARGB(
                          255, 61, 126, 64), // Green background
                    ),
                    columns: csvData.first
                        .map((column) => DataColumn(
                              label: Text(
                                column.toString(),
                                style: const TextStyle(
                                  color: Colors.white, // White text color
                                  fontWeight: FontWeight.bold, // Bold text
                                ),
                              ),
                            ))
                        .toList(),
                    rows: csvData.skip(1).map((row) {
                      return DataRow(
                        cells: row
                            .map((cell) => DataCell(
                                  Text(cell.toString()),
                                ))
                            .toList(),
                      );
                    }).toList(),
                  ),
                ),
              )
            : Center(
                child: const Text(
                  'No data available',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ),
      ),
    );
  }
}
