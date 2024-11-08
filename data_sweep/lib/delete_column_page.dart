import 'dart:io';
import 'package:csv/csv.dart';
import 'package:data_sweep/classification_page.dart';
import 'package:data_sweep/preview_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';

class DeleteColumnPage extends StatefulWidget {
  final String filePath;
  const DeleteColumnPage({super.key, required this.filePath});

  @override
  // ignore: library_private_types_in_public_api
  _DeleteColumnPageState createState() => _DeleteColumnPageState();
}

class _DeleteColumnPageState extends State<DeleteColumnPage> {
  List<String> columns = [];
  List<bool> selectedColumns = [];
  List<List<dynamic>> csvData = []; // Store loaded CSV data

  @override
  void initState() {
    super.initState();
    _loadColumns();
  }

  // Function to read and load the CSV columns
  void _loadColumns() async {
    try {
      final file = File(widget.filePath);
      final contents = await file.readAsString();

      // Handle potential encoding issues by converting to UTF-8 and then parsing CSV
      List<List<dynamic>> rows = const CsvToListConverter().convert(contents);
      if (rows.isNotEmpty) {
        setState(() {
          csvData = rows; // Store all data rows
          columns = List<String>.from(rows[0]); // Use the first row as headers
          selectedColumns = List.generate(columns.length, (index) => false);
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error loading CSV: $e");
      }
    }
  }

  // Function to handle the deletion of selected columns
  Future<List<List<dynamic>>> deleteColumns() async {
    try {
      var uri = Uri.parse('http://192.168.254.106:5000/remove_columns');
      var request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('file', widget.filePath));

      // Adding selected columns to remove in the request
      request.fields['columns'] = selectedColumns
          .asMap()
          .entries
          .where((entry) => entry.value)
          .map((entry) => columns[entry.key])
          .join(',');

      var response = await request.send();
      if (response.statusCode == 200) {
        // Assuming the server sends back the cleaned CSV data
        final responseBody = await response.stream.bytesToString();
        List<List<dynamic>> updatedCsvData =
            const CsvToListConverter().convert(responseBody);
        return updatedCsvData; // Return cleaned data
      } else {
        if (kDebugMode) {
          print(
              "Error: ${response.statusCode} - ${await response.stream.bytesToString()}");
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        print("Exception: $e");
      }
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Data Sweep"),
        leading: IconButton(
          icon: const Icon(Icons.cancel),
          onPressed: () {
            // Show cancel confirmation dialog
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text("Are you sure you want to cancel?"),
                  actions: <Widget>[
                    TextButton(
                      child: const Text("Yes"),
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context); // Go back to homepage
                      },
                    ),
                    TextButton(
                      child: const Text("No"),
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                      },
                    ),
                  ],
                );
              },
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.remove_red_eye),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PreviewPage(
                    filePath: widget.filePath,
                    csvData: csvData, // Pass CSV data to preview
                    fileName: basename(widget.filePath),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Text("Uploaded file: ${basename(widget.filePath)}"),
          const Text(
              "Before we dive deeper, let’s tidy up your dataset. Do you want to remove any unnecessary columns?"),
          Column(
            children: List.generate(columns.length, (index) {
              return CheckboxListTile(
                title: Text(columns[index]),
                value: selectedColumns[index],
                onChanged: (bool? value) {
                  setState(() {
                    selectedColumns[index] = value!;
                  });
                },
              );
            }),
          ),
          ElevatedButton(
            onPressed: () async {
              List<List<dynamic>> updatedCsvData = await deleteColumns();

              if (updatedCsvData.isNotEmpty) {
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Columns successfully deleted!"),
                  ),
                );

                // Pass the cleaned CSV data directly to the ClassificationPage
                Navigator.push(
                  // ignore: use_build_context_synchronously
                  context,
                  MaterialPageRoute(
                    builder: (context) => ClassificationPage(
                      filePath: widget.filePath, // Pass the file path
                      csvData: updatedCsvData, // Pass the cleaned CSV data
                      fileName: basename(widget.filePath), // Pass the file name
                    ),
                  ),
                );
              } else {
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Error deleting columns!"),
                  ),
                );
              }
            },
            child: const Row(
              children: [Icon(Icons.delete), Text("Remove Selected Columns")],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ClassificationPage(
                    filePath: widget.filePath, // Pass the file path
                    csvData: csvData, // Pass the original CSV data
                    fileName: basename(widget.filePath), // Pass the file name
                  ),
                ),
              );
            },
            child: const Row(
              children: [
                Icon(Icons.cancel),
                Text("No, I don’t want to delete")
              ],
            ),
          ),
        ],
      ),
    );
  }
}
