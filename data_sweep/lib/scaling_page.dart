import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:data_sweep/config.dart';
import 'package:data_sweep/main.dart';
import 'package:data_sweep/preview_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class FeatureScalingPage extends StatefulWidget {
  final List<List<dynamic>> csvData;
  final List<String> columns;
  final List<List<int>> classifications;

  const FeatureScalingPage({
    required this.csvData,
    required this.columns,
    required this.classifications,
  });

  @override
  _FeatureScalingPageState createState() => _FeatureScalingPageState();
}

class _FeatureScalingPageState extends State<FeatureScalingPage> {
  final _fileNameController = TextEditingController();
  late List<String> numericalColumns;
  late List<List<dynamic>> scaledData = widget.csvData;

  bool isLoading = false;
  late Map<String, String> columnScalingMethods;

  @override
  void initState() {
    super.initState();
    numericalColumns = getNumericalColumns();
    columnScalingMethods = {for (var col in numericalColumns) col: 'None'};
  }

  List<String> getNumericalColumns() {
    List<String> numericalColumns = [];
    for (int i = 0; i < widget.classifications.length; i++) {
      if (widget.classifications[i][0] == 1) {
        numericalColumns.add(widget.columns[i]);
      }
    }
    return numericalColumns;
  }

  Future<void> _downloadCSV() async {
    // Check storage permission before proceeding
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
      status = await Permission.storage.status;
    }

    if (status.isGranted) {
      if (scaledData.isEmpty) {
        print('No data available for CSV conversion.');
        return;
      }

      List<List<String>> csvFormattedData = scaledData
          .map((row) => row.map((item) => item.toString()).toList())
          .toList();

      String csvContent = const ListToCsvConverter().convert(csvFormattedData);

      try {
        String path = await _getDownloadsDirectoryPath();
        Directory directory = Directory(path);
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }

        String fileName = _fileNameController.text.isNotEmpty
            ? _fileNameController.text + ".csv"
            : "scaled_file.csv";

        File file = File('$path/$fileName');
        await file.writeAsString(csvContent);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV file saved to: $path')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving the file: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Storage permission is required to save the file.')),
      );
    }
  }

  Future<String> _getDownloadsDirectoryPath() async {
    if (Platform.isAndroid && await Permission.storage.request().isGranted) {
      return '/storage/emulated/0/Download';
    }

    Directory? directory = await getExternalStorageDirectory();
    return directory!.path;
  }

  Future<void> _scaleFeatures() async {
    setState(() {
      isLoading = true;
    });

    Map<String, dynamic> requestPayload = {
      'data': widget.csvData,
      'numerical_columns': numericalColumns,
      'scaling_methods': columnScalingMethods,
    };

    try {
      var response = await http.post(
        Uri.parse('$baseURL/scale_features'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestPayload),
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        List<List<dynamic>> scaledDataset =
            List<List<dynamic>>.from(jsonResponse);
        setState(() {
          scaledData = scaledDataset;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        _showErrorDialog(context);
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Error occurred while scaling features. Try again!")),
      );
    }
  }

  void _showErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Error"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Data cleaning is required before you can proceed. Please review and fix the data issues in this column.",
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the error dialog
                  Navigator.of(context).pop(); // Go back to the previous page
                },
                child: Text('Go Back'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showDownloadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Download Confirmation"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "What you see in the preview is what will be downloaded. Please double-check before proceeding.",
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _fileNameController,
                decoration: InputDecoration(
                  labelText: "Enter Filename (without .csv)",
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _downloadCSV(); // Proceed to download
                },
                child: Text("Download File"),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Feature Scaling")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PreviewPage(
                      csvData: scaledData,
                      fileName: "Formatted Data",
                    ),
                  ),
                );
              },
              child: Text("Preview CSV Data"),
            ),
            // Numerical Columns Section
            Text(
              "Numerical Columns:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: numericalColumns.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(numericalColumns[index]),
                    trailing: DropdownButton<String>(
                      value: columnScalingMethods[numericalColumns[index]],
                      onChanged: (String? newValue) {
                        setState(() {
                          columnScalingMethods[numericalColumns[index]] =
                              newValue!;
                        });
                      },
                      items: <String>[
                        'None',
                        'Normalization',
                        'Standardization'
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Buttons and Actions
            if (isLoading)
              Center(child: CircularProgressIndicator())
            else ...[
              ElevatedButton(
                onPressed: _scaleFeatures,
                child: Text("Scale and Proceed"),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  _showDownloadDialog(context); // Show download confirmation
                },
                child: Text("Download Scaled CSV"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => HomePage()),
                    (Route<dynamic> route) => false,
                  );
                },
                child: Text("Go Back to Home Page"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
