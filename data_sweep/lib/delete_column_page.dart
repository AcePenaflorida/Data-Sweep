import 'dart:io';
import 'dart:convert';
import 'package:data_sweep/config.dart'; // to get IP
import 'package:csv/csv.dart';
import 'package:data_sweep/classification_page.dart';
import 'package:data_sweep/preview_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;

class DeleteColumnPage extends StatefulWidget {
  final String filePath;

  const DeleteColumnPage({super.key, required this.filePath});

  @override
  _DeleteColumnPageState createState() => _DeleteColumnPageState();
}

class _DeleteColumnPageState extends State<DeleteColumnPage> {
  List<String> columns = [];
  List<bool> selectedColumns = [];
  List<List<dynamic>> csvData = [];
  double scaleFactor1 =
      1.0; // For the scaling effect of the "Confirm & Proceed" button
  double scaleFactor2 = 1.0; // For the scaling effect of the "Cancel" button

  @override
  void initState() {
    super.initState();
    _loadColumns();
  }

  void _loadColumns() async {
    try {
      final file = File(widget.filePath);
      final contents = await file.readAsString();
      List<List<dynamic>> rows = const CsvToListConverter().convert(contents);

      if (rows.isNotEmpty) {
        setState(() {
          csvData = rows;
          columns = List<String>.from(rows[0]);
          selectedColumns = List.generate(columns.length, (index) => false);
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error loading CSV: $e");
      }
    }
  }

  String _getFileSize(String filePath) {
    final file = File(filePath);
    final bytes = file.lengthSync();
    const kb = 1024;
    const mb = kb * 1024;
    if (bytes >= mb) {
      return '${(bytes / mb).toStringAsFixed(2)} MB';
    } else if (bytes >= kb) {
      return '${(bytes / kb).toStringAsFixed(2)} KB';
    } else {
      return '$bytes Bytes';
    }
  }

  Future<List<List<dynamic>>> deleteColumns() async {
    try {
      List<String> columnsToRemove = selectedColumns
          .asMap()
          .entries
          .where((entry) => entry.value)
          .map((entry) => columns[entry.key])
          .toList();

      if (columnsToRemove.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No columns selected for deletion."),
          ),
        );
        return [];
      }

      var uri = Uri.parse('$baseURL/remove_columns');
      var requestBody = {
        'data': csvData,
        'columns': columns,
        'columnsToRemove': columnsToRemove,
      };

      var response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        return List<List<dynamic>>.from(
            decodedResponse.map((row) => List<dynamic>.from(row)));
      } else {
        throw Exception('Failed to delete columns');
      }
    } catch (e) {
      print("Exception caught: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "DATA SWEEP",
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
        color: const Color.fromARGB(255, 229, 234, 222),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // File name and preview button
            Padding(
              padding: const EdgeInsets.all(12.0), // Reduced padding
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(6), // Smaller border radius
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.description,
                            size: 30, // Reduced icon size
                            color: const Color.fromARGB(255, 17, 17, 17),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.basename(widget.filePath),
                                  style: const TextStyle(
                                    fontSize: 16, // Reduced font size
                                    fontFamily: 'Roboto',
                                  ),
                                  maxLines:
                                      1, // Allows wrapping for longer text
                                  overflow: TextOverflow
                                      .ellipsis, // Handles overflow gracefully
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _getFileSize(widget.filePath),
                                  style: const TextStyle(
                                    fontSize: 12, // Reduced font size
                                    fontFamily: 'Roboto',
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_red_eye, size: 24),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PreviewPage(
                              csvData: csvData,
                              fileName: p.basename(widget.filePath),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: 12.0), // Reduced padding
              child: Text(
                "Do you want to remove any unnecessary columns?",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto',
                  color: Colors.black,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // "COLUMNS" label
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                "COLUMNS",
                style: TextStyle(
                  fontSize: 18, // Reduced font size
                  fontFamily: 'Roboto',
                  color: Colors.black,
                ),
              ),
            ),
            const Divider(
              color: Color.fromARGB(255, 200, 200, 200), // Light gray line
              thickness: 1, // Thin line
              indent: 8, // Add some indentation to match the content padding
              endIndent: 3, // Same as above to align with content
            ),
            // Column list
            Expanded(
              child: ListView.builder(
                itemCount: columns.length,
                itemBuilder: (context, index) {
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 0),
                        child: ListTile(
                          dense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 0),
                          minVerticalPadding: 0, // No extra vertical padding
                          horizontalTitleGap:
                              0, // Closer alignment of the title
                          leading: Transform.scale(
                            scale: 1,
                            child: Checkbox(
                              value: selectedColumns[index],
                              activeColor:
                                  const Color.fromARGB(255, 61, 126, 64),
                              checkColor: Colors.white,
                              onChanged: (bool? value) {
                                setState(() {
                                  selectedColumns[index] = value ?? false;
                                });
                              },
                            ),
                          ),
                          title: Text(
                            columns[index],
                            style: const TextStyle(
                              fontSize: 14, // Reduced font size
                              fontFamily: 'Roboto',
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      // Thin line between each column
                      const Divider(
                        color: Color.fromARGB(
                            255, 200, 200, 200), // Light gray line
                        thickness: 1, // Thin line
                        indent:
                            8, // Add some indentation to match the content padding
                        endIndent: 3, // Same as above to align with content
                      ),
                    ],
                  );
                },
              ),
            ),

            // Buttons
            Padding(
              padding: const EdgeInsets.all(12.0), // Reduced padding
              child: Column(
                children: [
                  GestureDetector(
                    onTapDown: (_) {
                      setState(() {
                        scaleFactor1 = 0.95; // Scale down on tap for button 1
                      });
                    },
                    onTapUp: (_) {
                      setState(() {
                        scaleFactor1 = 1.0; // Reset scale for button 1
                      });
                    },
                    onTapCancel: () {
                      setState(() {
                        scaleFactor1 = 1.0; // Reset scale for button 1
                      });
                    },
                    onTap: () async {
                      final updatedCsvData = await deleteColumns();
                      if (updatedCsvData.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ClassificationPage(
                              csvData: updatedCsvData,
                              fileName: p.basename(widget.filePath),
                            ),
                          ),
                        );
                      }
                    },
                    child: Transform.scale(
                      scale: scaleFactor1,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 20,
                        ),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 61, 126, 64),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          "Remove Selected Columns",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTapDown: (_) {
                      setState(() {
                        scaleFactor2 =
                            0.95; // Scale down on tap for Skip Step button
                      });
                    },
                    onTapUp: (_) {
                      setState(() {
                        scaleFactor2 = 1.0; // Reset scale for Skip Step button
                      });
                    },
                    onTapCancel: () {
                      setState(() {
                        scaleFactor2 = 1.0; // Reset scale for Skip Step button
                      });
                    },
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ClassificationPage(
                            csvData: csvData,
                            fileName: p.basename(widget.filePath),
                          ),
                        ),
                      );
                    },
                    child: Transform.scale(
                      scale: scaleFactor2,
                      child: SizedBox(
                        width: double
                            .infinity, // Make the button take up the full width
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: Color.fromARGB(255, 61, 126, 64),
                                width: 2),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ClassificationPage(
                                  csvData: csvData,
                                  fileName: p.basename(widget.filePath),
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            "Skip Step",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Roboto',
                              color: Color.fromARGB(255, 61, 126, 64),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
