import 'package:csv/csv.dart';
import 'package:data_sweep/issues/categorical.dart';
import 'package:data_sweep/issues/numerical.dart';
import 'package:data_sweep/issues/date.dart';
import 'package:data_sweep/issues/non_categorical.dart';
import 'package:data_sweep/main.dart';
import 'package:data_sweep/outliers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'preview_page.dart';
import 'package:data_sweep/config.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class IssuesPage extends StatefulWidget {
  final List<List<dynamic>> csvData;
  final List<String> columns;
  final List<List<int>> classifications;
  final List<String> casingSelections;
  final String dateFormats;

  IssuesPage({
    required this.csvData,
    required this.columns,
    required this.classifications,
    required this.casingSelections,
    required this.dateFormats,
  });

  @override
  _IssuesPageState createState() => _IssuesPageState();
}

class _IssuesPageState extends State<IssuesPage> {
  late List<List<dynamic>> cleanedData;
  final _fileNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    cleanedData = widget.csvData;
  }

  Future<Map<String, List<String>>> detectIssues(
      List<List<dynamic>> data) async {
    var uri = Uri.parse('$baseURL/detect_issues');
    var response = await http.post(
      uri,
      body: json.encode({
        'columns': widget.columns,
        'classifications': widget.classifications,
        'data': data,
      }),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      return decoded.map<String, List<String>>((key, value) {
        return MapEntry(key as String, List<String>.from(value));
      });
    } else {
      throw Exception('Failed to detect issues');
    }
  }

  Future<List<List<dynamic>>> applyLetterCasing(
      List<List<dynamic>> data) async {
    var uri = Uri.parse('$baseURL/apply_letter_casing');
    var response = await http.post(uri,
        body: json.encode({
          'data': data,
          'columns': widget.columns,
          'casingSelections': widget.casingSelections,
        }),
        headers: {'Content-Type': 'application/json'});

    if (response.statusCode == 200) {
      return List<List<dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to apply letter casing');
    }
  }

  Future<List<List<dynamic>>> applyDateFormat(List<List<dynamic>> data) async {
    var uri = Uri.parse('$baseURL/apply_date_format');
    var response = await http.post(uri,
        body: json.encode({
          'data': data,
          'columns': widget.columns,
          'dateFormats': widget.dateFormats,
          'classifications': widget.classifications,
        }),
        headers: {'Content-Type': 'application/json'});
    if (response.statusCode == 200) {
      return List<List<dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to apply date format');
    }
  }

  Future<Map<String, dynamic>> _formatDataFindIssues() async {
    // Apply letter casing
    List<List<dynamic>> formattedData = await applyLetterCasing(cleanedData);

    // Check if there are any date columns based on classifications
    bool hasDateColumn = widget.classifications.any((classification) =>
        classification.contains(3)); // Assuming '3' represents 'date'

    // Only apply date formatting if a date column is present
    if (hasDateColumn) {
      formattedData = await applyDateFormat(formattedData);
    }

    // Detect issues
    Map<String, List<String>> issues = await detectIssues(formattedData);

    return {
      'formattedData': formattedData,
      'issues': issues,
    };
  }

  Future<void> _downloadCSV() async {
    // Check storage permission before proceeding
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
      status = await Permission.storage.status;
    }

    if (status.isGranted) {
      if (cleanedData.isEmpty) {
        print('No data available for CSV conversion.');
        return;
      }

      List<List<String>> csvFormattedData = cleanedData
          .map((row) => row.map((item) => item.toString()).toList())
          .toList();

      if (csvFormattedData.isEmpty || csvFormattedData[0].isEmpty) {
        print('CSV conversion produced no data.');
        return;
      }

      String csvContent = const ListToCsvConverter().convert(csvFormattedData);
      print('CSV Content generated:\n$csvContent');

      try {
        String path = await _getDownloadsDirectoryPath();

        Directory directory = Directory(path);
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }

        String fileName = _fileNameController.text.isNotEmpty
            ? _fileNameController.text + ".csv"
            : "cleaned_file.csv";

        File file = File('$path/$fileName');
        await file.writeAsString(csvContent);
        await Future.delayed(Duration(seconds: 1));

        print('File saved to: $path');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV file saved to: $path')),
        );
      } catch (e) {
        print('Error saving the file: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving the file: $e')),
        );
      }
    } else {
      print('Storage permission not granted');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Storage permission is required to save the file.')),
      );
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Downloaded!"),
          content: Text("Would you like to do more things, Kimi?"),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OutliersPage(
                      csvData: cleanedData,
                      columns: widget.columns,
                      classifications: widget.classifications,
                    ),
                  ),
                );
              },
              child: Text("Go to Outliers"),
            ),
            ElevatedButton(
              onPressed: () {
                // Navigator.of(context).pop(); // Close dialog
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) => FeatureScalingPage(), // Placeholder page
                //   ),
                // );
              },
              child: Text("Go to Feature Scaling"),
            ),
            ElevatedButton(
              onPressed: () {
                // Navigate to Home page
                Navigator.of(context).pop(); // Close dialog
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => HomePage()),
                  (Route<dynamic> route) => false, // Remove all previous routes
                );
              },
              child: Text("Go to Home"),
            ),
          ],
        );
      },
    );
  }

  Future<String> _getDownloadsDirectoryPath() async {
    // Always return the standard Downloads directory path on Android
    if (Platform.isAndroid && await Permission.storage.request().isGranted) {
      return '/storage/emulated/0/Download';
    }

    // Fallback path for other platforms
    Directory? directory = await getExternalStorageDirectory();
    return directory!.path;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Data Sweep - Issues")),
      body: FutureBuilder(
        future: _formatDataFindIssues(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          Map<String, dynamic> result = snapshot.data as Map<String, dynamic>;
          cleanedData = result['formattedData'];
          Map<String, List<String>> issues = result['issues'];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PreviewPage(
                          csvData: cleanedData,
                          fileName: "Formatted Data",
                        ),
                      ),
                    );
                  },
                  child: Text("Preview CSV Data"),
                ),
                const SizedBox(height: 20),
                Text("Oh no, inconsistencies found!"),
                const SizedBox(height: 10),
                ...widget.columns.map((column) {
                  List<String> columnIssues = issues[column] ?? [];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      title: Text(column),
                      subtitle: columnIssues.isEmpty
                          ? Text("No issues found.")
                          : Text("Issues: ${columnIssues.join(', ')}"),
                      onTap: () async {
                        print("Column value: $column");
                        int columnIndex = widget.columns.indexOf(column);
                        List<int> columnClassification =
                            widget.classifications[columnIndex];
                        int columnType = columnClassification.indexOf(1);
                        List<String> columnIssues = issues[column] ?? [];

                        // Switch case based on the determined column type
                        switch (columnType) {
                          case 0:
                            List<List<dynamic>>? updatedDataset =
                                await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NumericalIssuePage(
                                  columnName: column,
                                  issues: columnIssues,
                                  csvData: cleanedData,
                                ),
                              ),
                            );
                            if (updatedDataset != null) {
                              setState(() {
                                cleanedData = updatedDataset;
                              });
                            }
                            break;
                          case 1: // Categorical
                            List<List<dynamic>>? updatedDataset =
                                await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CategoricalPage(
                                  dataset: cleanedData,
                                  columnName: column,
                                  categoricalData: List<String>.from(cleanedData
                                      .skip(1) // Skip the header row
                                      .map((row) =>
                                          row[widget.columns.indexOf(column)]
                                              .toString())),
                                  issues: columnIssues,
                                ),
                              ),
                            );

                            if (updatedDataset != null) {
                              setState(() {
                                cleanedData = updatedDataset;
                              });
                            }

                            break;
                          case 2:
                            List<List<dynamic>>? updatedDataset =
                                await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NonCategoricalPage(
                                  columnName: column,
                                  issues: columnIssues,
                                  csvData: cleanedData,
                                ),
                              ),
                            );
                            if (updatedDataset != null) {
                              setState(() {
                                cleanedData = updatedDataset;
                              });
                            }
                            break;
                          default:
                            List<List<dynamic>>? updatedDataset =
                                await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DateIssuePage(
                                  columnName: column,
                                  issues: columnIssues,
                                  dataset: cleanedData,
                                  chosenDateFormat: widget.dateFormats,
                                  chosenColumns: widget.columns,
                                  chosenClassifications: widget.classifications,
                                ),
                              ),
                            );

                            if (updatedDataset != null) {
                              setState(() {
                                cleanedData = updatedDataset;
                              });
                            }
                            break;
                        }
                      },
                    ),
                  );
                }).toList(),
                TextField(
                  controller: _fileNameController,
                  decoration: InputDecoration(
                    labelText: "Enter Filename for Download (without .csv)",
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _downloadCSV,
                  child: Text("Download CSV"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OutliersPage(
                          csvData: cleanedData,
                          columns: widget.columns,
                          classifications: widget.classifications,
                        ),
                      ),
                    );
                  },
                  child: Text("Go to Outliers"),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Navigator.of(context).pop(); // Close dialog
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //     builder: (context) => FeatureScalingPage(), // Placeholder page
                    //   ),
                    // );
                  },
                  child: Text("Go to Feature Scaling"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => HomePage()),
                      (Route<dynamic> route) =>
                          false, // This removes all previous routes
                    );
                  },
                  child: Text("Go to Upload Page"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
