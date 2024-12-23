import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:data_sweep/config.dart';
import 'package:data_sweep/issues_page.dart';
import 'package:data_sweep/main.dart';
import 'package:data_sweep/outliers.dart';
import 'package:data_sweep/preview_page.dart';
import 'package:data_sweep/visualization_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class FeatureScalingPage extends StatefulWidget {
  final List<List<dynamic>> csvData;
  final List<String> columns;
  final List<List<int>> classifications;
  final List<String> casingSelections;
  final List<String> dateFormats;

  const FeatureScalingPage({
    required this.csvData,
    required this.columns,
    required this.classifications,
    required this.casingSelections,
    required this.dateFormats,
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
          title: Text("Error", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Data cleaning is required before you can proceed. Please review and fix the data issues",
              ),
              SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(
                      255, 61, 126, 64), // Green color for the button
                ),
                onPressed: () {
                  Navigator.of(context).pop(); // Close the error dialog
                  Navigator.of(context).pop(); // Go back to the previous page
                },
                child: Text("Ok",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 255, 255, 255),
                    )),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDownloadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Download Confirmation",
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "What you see in the ",
                      style: TextStyle(fontSize: 16),
                    ),
                    TextSpan(
                      text: "preview",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    TextSpan(
                      text:
                          " is what will be downloaded. Please double-check before proceeding.",
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(
                      255, 61, 126, 64), // Green color for the button
                ),
                child: Text("Download File",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 255, 255, 255),
                    )),
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
      backgroundColor: const Color.fromARGB(255, 229, 234, 222),
      appBar: AppBar(
        title: const Text(
          "Feature Scaling",
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(0),
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
                              color: const Color.fromARGB(255, 126, 173, 128),
                              borderRadius: BorderRadius.circular(6),
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
                                  'Preview File', // Display the file name
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Roboto',
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                        color: Color.fromARGB(255, 0, 0, 0),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PreviewPage(
                              csvData: scaledData,
                              fileName: 'Classified Data',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16.0),
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
                  return Card(
                    elevation: 2,
                    color: Color.fromARGB(255, 240, 245, 240),
                    margin: EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text(numericalColumns[index]),
                      trailing: DropdownButton<String>(
                        dropdownColor: const Color.fromARGB(255, 229, 234, 222),
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _scaleFeatures,
                  child: const Text(
                    "Resolve",
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3D7E40),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12), // Set the radius here
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white, // Set background to white
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero, // No padding for this button
                    foregroundColor: const Color.fromARGB(255, 61, 126,
                        64), // Use the green color for text and icons
                  ),
                  onPressed: () {
                    _showDownloadDialog(context); // Show download confirmation
                  },
                  child: Column(
                    children: [
                      Icon(
                        Icons.download,
                        size: 20.0,
                        color: const Color.fromARGB(
                            255, 61, 126, 64), // Green color for icon
                      ),
                      Text(
                        "Download",
                        style: TextStyle(
                          fontSize: 10.0, // Adjust the font size
                          color: const Color.fromARGB(
                              255, 61, 126, 64), // Green color for text
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Column(
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero, // No padding for this button
                    foregroundColor: const Color.fromARGB(
                        255, 61, 126, 64), // Green color for text and icons
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => IssuesPage(
                          csvData: scaledData,
                          columns: widget.columns,
                          classifications: widget.classifications,
                          casingSelections: widget.casingSelections,
                          dateFormats: widget.dateFormats,
                        ),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: const Color.fromARGB(
                            255, 61, 126, 64), // Green color for icon
                      ),
                      Text(
                        "Issues",
                        style: TextStyle(
                            fontSize: 10.0,
                            color: const Color.fromARGB(
                                255, 61, 126, 64)), // Green color for text
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Column(
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero, // No padding for this button
                    foregroundColor: const Color.fromARGB(
                        255, 61, 126, 64), // Green color for text and icons
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OutliersPage(
                          csvData: scaledData,
                          columns: widget.columns,
                          classifications: widget.classifications,
                          casingSelections: widget.casingSelections,
                          dateFormats: widget.dateFormats,
                        ),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Icon(
                        Icons.scatter_plot,
                        color: const Color.fromARGB(
                            255, 61, 126, 64), // Green color for icon
                      ),
                      Text(
                        "Outliers",
                        style: TextStyle(
                            fontSize: 10.0,
                            color: const Color.fromARGB(
                                255, 61, 126, 64)), // Green color for text
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Column(
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero, // No padding for this button
                    foregroundColor: const Color.fromARGB(
                        255, 61, 126, 64), // Green color for text and icons
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VisualizationPage(
                          csvData: scaledData,
                          columns: widget.columns,
                          classifications: widget.classifications,
                        ),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Icon(
                        Icons.bar_chart,
                        color: const Color.fromARGB(
                            255, 61, 126, 64), // Green color for icon
                      ),
                      Text(
                        "Visualize",
                        style: TextStyle(
                            fontSize: 10.0,
                            color: const Color.fromARGB(
                                255, 61, 126, 64)), // Green color for text
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Column(
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero, // No padding for this button
                    foregroundColor: const Color.fromARGB(
                        255, 61, 126, 64), // Green color for text and icons
                  ),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => HomePage()),
                      (Route<dynamic> route) => false,
                    );
                  },
                  child: Column(
                    children: [
                      Icon(
                        Icons.home,
                        color: const Color.fromARGB(
                            255, 61, 126, 64), // Green color for icon
                      ),
                      Text(
                        "Home",
                        style: TextStyle(
                            fontSize: 10.0,
                            color: const Color.fromARGB(
                                255, 61, 126, 64)), // Green color for text
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
