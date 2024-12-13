import 'package:flutter/material.dart';

class PreviewPage extends StatelessWidget {
  final List<List<dynamic>> csvData;
  final String fileName;

  const PreviewPage({
    Key? key,
    required this.csvData,
    required this.fileName,
  }) : super(key: key);

  // Simulate a delay to mimic loading or processing
  Future<List<List<dynamic>>> loadData() async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate loading time
    return csvData; // Return the data after delay
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 229, 234, 222),
      appBar: AppBar(
        title: const Text(
          "FILE PREVIEW",
          style: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.bold,
            fontSize: 24,
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
        color: const Color.fromARGB(255, 229, 234, 222),
        child: FutureBuilder<List<List<dynamic>>>(
          future: loadData(), // Call the loadData function
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // Show a loading spinner while data is loading
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Color.fromARGB(255, 61, 126, 64)),
                ),
              );
            } else if (snapshot.hasError) {
              // Handle errors
              return Center(
                child: Text(
                  'Error loading data: ${snapshot.error}',
                  style: TextStyle(fontSize: 18, color: Colors.red),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              // Handle empty data
              return Center(
                child: const Text(
                  'No data available',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              );
            } else {
              // Data loaded successfully, display the table
              final data = snapshot.data!;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(
                      const Color.fromARGB(
                          255, 61, 126, 64), // Green background
                    ),
                    columns: data.first
                        .map((column) => DataColumn(
                              label: Container(
                                width: 150,
                                child: Text(
                                  column.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  softWrap: true,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ))
                        .toList(),
                    rows: data.skip(1).map((row) {
                      return DataRow(
                        cells: row.map((cell) {
                          return DataCell(
                            Container(
                              width: 150,
                              child: Text(
                                cell.toString(),
                                softWrap: true,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    }).toList(),
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
