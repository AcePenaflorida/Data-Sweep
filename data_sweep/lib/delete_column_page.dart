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

  @override
  void initState() {
    super.initState();
    _loadColumns();
  }

  // Function to load CSV columns and data
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

  // Function to get file size in a human-readable format
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

  // Function to delete selected columns
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
            fontSize: 28,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 61, 126, 64),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 30, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        color: const Color.fromARGB(255, 212, 216, 207),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // File name and preview button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.description, // File icon
                          size: 40, // Icon size
                          color: const Color.fromARGB(
                              255, 17, 17, 17), // Match text color
                        ),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.basename(widget.filePath),
                              style: const TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Roboto',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getFileSize(widget.filePath),
                              style: const TextStyle(
                                fontSize: 16,
                                fontFamily: 'Roboto',
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_red_eye),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PreviewPage(
                              csvData: csvData, // Pass CSV data
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

            // Instruction text
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "Before we delve deeper, ",
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight:
                            FontWeight.normal, // Normal weight for this part
                        fontFamily: 'Roboto',
                        color: Colors.black,
                      ),
                    ),
                    TextSpan(
                      text: "do you want to remove any unnecessary columns?",
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight:
                            FontWeight.bold, // Bold weight for this part
                        fontFamily: 'Roboto',
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // "COLUMNS" label
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "COLUMNS",
                style: TextStyle(
                  fontSize: 24,
                  fontFamily: 'Roboto',
                  color: Colors.black,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Column list
            Expanded(
              child: ListView.builder(
                itemCount: columns.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    minVerticalPadding: 0,
                    horizontalTitleGap: 0,
                    leading: Transform.scale(
                      scale: 0.8,
                      child: Checkbox(
                        value: selectedColumns[index],
                        activeColor: const Color.fromARGB(255, 61, 126, 64),
                        checkColor: Colors.white,
                        onChanged: (bool? value) {
                          setState(() {
                            selectedColumns[index] = value ?? false;
                          });
                        },
                      ),
                    ),
                    title: Padding(
                      padding: const EdgeInsets.only(bottom: 0),
                      child: Text(
                        columns[index],
                        style: const TextStyle(
                          fontSize: 23,
                          fontFamily: 'Roboto',
                          color: Colors.black,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        List<List<dynamic>> updatedCsvData =
                            await deleteColumns();
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 61, 126, 64),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "Remove Selected Columns",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Roboto',
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
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
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Color.fromARGB(255, 61, 126, 64), width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "Skip Step",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Roboto',
                          color: Color.fromARGB(255, 61, 126, 64),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
