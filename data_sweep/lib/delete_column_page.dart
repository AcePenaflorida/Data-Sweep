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
  double scaleFactor1 = 1.0;
  double scaleFactor2 = 1.0;
  bool _isLoading = false; // Track loading state

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // File name and preview button
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(
                                  255, 126, 173, 128), // Background color
                              borderRadius: BorderRadius.circular(
                                  6), // Set the border radius here
                            ),
                            child: Icon(
                              Icons.description,
                              size: 40,
                              color: const Color.fromARGB(255, 17, 17, 17),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.basename(widget.filePath),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Roboto',
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _getFileSize(widget.filePath),
                                  style: const TextStyle(
                                    fontSize: 14,
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
                      icon: const Icon(
                        Icons.remove_red_eye,
                        size: 28,
                        color: Color.fromARGB(
                            255, 0, 0, 0), // Add color to the icon for emphasis
                      ),
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
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "Before we delve deeper, ",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.normal,
                        color: Colors.black,
                      ),
                    ),
                    TextSpan(
                      text: "do you want to remove any unnecessary columns?",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // "COLUMNS" label
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                "COLUMNS:",
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
            ),
            // Column list
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(0),
                child: Container(
                  color: const Color.fromARGB(255, 231, 237, 224),
                  child: Scrollbar(
                    thumbVisibility:
                        true, // This makes the scrollbar always visible
                    child: ListView.builder(
                      itemCount: columns.length,
                      itemBuilder: (context, index) {
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 0), // No vertical padding
                              child: ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 0), // No extra padding
                                minVerticalPadding:
                                    0, // Ensures no extra vertical padding
                                horizontalTitleGap:
                                    0, // No gap between title and leading icon
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
                                    fontSize: 14,
                                    fontFamily: 'Roboto',
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                            const Divider(
                              color: Color.fromARGB(255, 200, 200, 200),
                              thickness: 1,
                              indent: 8,
                              endIndent: 3,
                              height:
                                  0, // Set height of the Divider to 0 to reduce spacing
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            // Buttons
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 20),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 61, 126, 64),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _isLoading
                        ? Center(
                            child: SizedBox(
                              width:
                                  24, // Adjust width to make the spinner smaller
                              height:
                                  24, // Adjust height to make the spinner smaller
                              child: CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth:
                                    3, // Keep strokeWidth for the border thickness, adjust for visual appeal
                              ),
                            ),
                          )
                        : GestureDetector(
                            onTap: () async {
                              if (_isLoading)
                                return; // Prevent multiple taps while loading
                              setState(() {
                                _isLoading = true; // Start loading
                              });

                              final updatedCsvData = await deleteColumns();

                              setState(() {
                                _isLoading = false; // End loading
                              });

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
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity, // Full width button
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color.fromARGB(255, 61, 126, 64),
                          width: 2,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
                          color: Color.fromARGB(255, 61, 126, 64),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  String _getFileSize(String filePath) {
    final file = File(filePath);
    final fileSize = file.lengthSync();
    if (fileSize < 1024) {
      return '$fileSize bytes';
    } else if (fileSize < 1048576) {
      return '${(fileSize / 1024).toStringAsFixed(2)} KB';
    } else {
      return '${(fileSize / 1048576).toStringAsFixed(2)} MB';
    }
  }
}
