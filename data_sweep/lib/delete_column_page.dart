import 'dart:io';
import 'dart:convert';
import 'package:data_sweep/config.dart'; // to get ip
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
      List<String> columnsToRemove = selectedColumns
          .asMap()
          .entries
          .where((entry) => entry.value)
          .map((entry) => columns[entry.key])
          .toList();

      if (columnsToRemove.isEmpty) {
        ScaffoldMessenger.of(context as BuildContext).showSnackBar(
          const SnackBar(
            content: Text("No columns selected for deletion."),
          ),
        );
        return [];
      }
      print('$baseURL');
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

      print('POST request sent.');

      print('$response');

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
        title: const Text("Data Sweep"),
        actions: [
          IconButton(
            icon: const Icon(Icons.remove_red_eye),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PreviewPage(
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

          // Wrap this Column inside a SingleChildScrollView
          Expanded(
            child: SingleChildScrollView(
              child: Column(
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
            ),
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
                      csvData: updatedCsvData, // Pass the cleaned CSV data
                      fileName: basename(widget.filePath), // Pass the file name
                    ),
                  ),
                );
              } else {
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
