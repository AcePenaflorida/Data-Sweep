import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:data_sweep/config.dart';
import 'package:data_sweep/main.dart';
import 'package:data_sweep/preview_page.dart';
import 'package:data_sweep/scaling_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class OutliersPage extends StatefulWidget {
  final List<List<dynamic>> csvData;
  final List<String> columns;
  final List<List<int>> classifications;

  const OutliersPage({
    required this.csvData,
    required this.columns,
    required this.classifications,
  });

  @override
  _OutliersPageState createState() => _OutliersPageState();
}

class _OutliersPageState extends State<OutliersPage> {
  final _fileNameController = TextEditingController();
  late List<TextEditingController> textControllers;
  late List<String> handleOutliersOptions = [
    'Remove Rows',
    'Cap and Floor',
    'Replace with Mean',
    'Replace with Median'
  ];
  late List<String> numericalColumns = getNumericalColumns();

  String outlierStatus = ""; // Resolved or Not Resolved
  bool isLoading = false;
  Uint8List? imageBytes;
  String resolve_outlier_method = "";

  late List<List<dynamic>> cleanedData = widget.csvData;

  @override
  void initState() {
    super.initState();
    textControllers =
        numericalColumns.map((e) => TextEditingController()).toList();
  }

  @override
  void dispose() {
    for (var controller in textControllers) {
      controller.dispose();
    }
    super.dispose();
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
                Navigator.of(context).pop(); // Close dialog
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FeatureScalingPage(
                      csvData: cleanedData,
                      columns: widget.columns,
                      classifications: widget.classifications,
                    ),
                  ),
                );
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

  void showGraphOverlay(BuildContext context, String columnName,
      String outlierStatus, String resolveOutlierMethod) async {
    List<List<dynamic>> data = widget.csvData;
    Map<String, dynamic> requestPayload = {};

    if (outlierStatus == "Not Resolved") {
      setState(() {
        isLoading = true;
      });

      requestPayload = {
        'data': data,
        'column_name': columnName,
        'task': "Show Outliers",
        'method': resolveOutlierMethod,
      };

      var response = await http.post(
        Uri.parse('$baseURL/outliers_graph'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestPayload),
      );

      if (response.statusCode == 200) {
        setState(() {
          imageBytes = response.bodyBytes;
          isLoading = false;
        });
        _showImageOverlay(context, outlierStatus);
      } else {
        setState(() {
          isLoading = false;
        });
        _showErrorDialog(context);
      }
    } else {
      setState(() {
        isLoading = true;
      });

      requestPayload = {
        'data': data,
        'column_name': columnName,
        'task': "Resolve Outliers",
        'method': resolveOutlierMethod,
      };

      var response = await http.post(
        Uri.parse('$baseURL/outliers_graph'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestPayload),
      );

      if (response.statusCode == 200) {
        setState(() {
          imageBytes = response.bodyBytes;
          isLoading = false;
        });
        await getCleanedData(context, columnName, resolveOutlierMethod);
        _showImageOverlay(context, outlierStatus);
      } else {
        setState(() {
          isLoading = false;
        });
        _showErrorDialog(context);
      }
      print('Outlier status is resolved via');
      print(resolveOutlierMethod);
    }
  }

  Future<void> getCleanedData(BuildContext context, String columnName,
      String resolveOutlierMethod) async {
    List<List<dynamic>> data = widget.csvData;
    Map<String, dynamic> requestPayload = {};

    requestPayload = {
      'data': data,
      'column_name': columnName,
      'task': "Resolve Outliers",
      'method': resolveOutlierMethod,
    };

    var response = await http.post(
      Uri.parse('$baseURL/get_cleaned_file'), // URL for getting cleaned data
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestPayload),
    );

    if (response.statusCode == 200) {
      List<List<dynamic>> updatedDataset =
          List<List<dynamic>>.from(jsonDecode(response.body));

      setState(() {
        cleanedData = updatedDataset; // Update the cleanedData state
      });
    } else {
      // Handle error
      setState(() {
        isLoading = false;
      });
      _showErrorDialog(context);
    }
  }

  void _showImageOverlay(BuildContext context, String outlierStatus) {
    final overlay = Overlay.of(context);
    String graphTitle = "";
    OverlayEntry? overlayEntry;

    if (outlierStatus == "Not Resolved") {
      graphTitle = "Unresolved Outliers Graph";
    } else {
      graphTitle = "Resolved Outliers Graph";
    }

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 100.0,
        left: 50.0,
        right: 50.0,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 300.0,
            height: 400.0,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(graphTitle, style: TextStyle(fontWeight: FontWeight.bold)),
                if (isLoading)
                  CircularProgressIndicator()
                else
                  Image.memory(
                      imageBytes!), // Display the image from the server

                ElevatedButton(
                  onPressed: () {
                    overlayEntry?.remove();
                  },
                  child: Text("Close"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    overlay.insert(overlayEntry);
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

  @override
  Widget build(BuildContext context) {
    print("Outliers/Columns: $widget.columns");
    print("Outliers/Classifications: $widget.classifications");
    print("Numerical Columns: $numericalColumns");

    return Scaffold(
      appBar: AppBar(title: Text("Handle Outliers")),
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
                      csvData: cleanedData,
                      fileName: "Formatted Data",
                    ),
                  ),
                );
              },
              child: Text("Preview CSV Data"),
            ),
            const SizedBox(height: 20),

            // Use SingleChildScrollView to ensure the table is scrollable
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Table(
                      border: TableBorder.all(),
                      children: [
                        TableRow(
                          children: [
                            TableCell(
                              child: Center(
                                child: Text(
                                  "Numerical Columns",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            TableCell(
                              child: Center(
                                child: Text(
                                  "View Outliers",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            TableCell(
                              child: Center(
                                child: Text(
                                  "Resolve Outliers",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            TableCell(
                              child: Center(
                                child: Text(
                                  "View Resolved Outliers",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                        ...List.generate(numericalColumns.length, (index) {
                          return TableRow(
                            children: [
                              TableCell(
                                child: Center(
                                    child: Text(numericalColumns[index])),
                              ),
                              TableCell(
                                child: Center(
                                  child: TextButton(
                                    onPressed: () {
                                      outlierStatus = "Not Resolved";
                                      showGraphOverlay(
                                          context,
                                          numericalColumns[index],
                                          outlierStatus,
                                          "");
                                      print("Outliers Not Resolved");
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor:
                                          const Color.fromARGB(255, 25, 156, 4),
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      minimumSize: Size(0, 0),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      "Graph View",
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ),
                              TableCell(
                                child: Center(
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButtonFormField<String>(
                                      items: handleOutliersOptions.map((value) {
                                        return DropdownMenuItem(
                                          value: value,
                                          child: Text(value,
                                              style: TextStyle(fontSize: 11)),
                                        );
                                      }).toList(),
                                      onChanged: (selectedValue) {
                                        textControllers[index].text =
                                            selectedValue ?? '';

                                        if (selectedValue ==
                                            handleOutliersOptions[0]) {
                                          resolve_outlier_method = "Remove";
                                        } else if (selectedValue ==
                                            handleOutliersOptions[1]) {
                                          resolve_outlier_method =
                                              "Cap and Floor";
                                        } else if (selectedValue ==
                                            handleOutliersOptions[2]) {
                                          resolve_outlier_method =
                                              "Replace with Mean";
                                        } else if (selectedValue ==
                                            handleOutliersOptions[3]) {
                                          resolve_outlier_method =
                                              "Replace with Median";
                                        }
                                      },
                                      decoration: InputDecoration(
                                        hintText: 'Options',
                                        hintStyle: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              TableCell(
                                child: Center(
                                  child: TextButton(
                                    onPressed: () {
                                      outlierStatus = "Resolved";
                                      showGraphOverlay(
                                          context,
                                          numericalColumns[index],
                                          outlierStatus,
                                          resolve_outlier_method);
                                      print("Outliers Resolved");
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor:
                                          const Color.fromARGB(255, 25, 156, 4),
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      minimumSize: Size(0, 0),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      "Graph View",
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Keep the TextField and buttons for filename and navigation below the table
            const SizedBox(height: 20),
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
                // Close the current screen
                Navigator.pop(context);

                // Navigate to the HomePage and remove all previous routes
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => HomePage()),
                  (Route<dynamic> route) =>
                      false, // This removes all previous routes
                );
              },
              child: Text("GO BACK TO HOME PAGE"),
            ),
          ],
        ),
      ),
    );
  }
}
