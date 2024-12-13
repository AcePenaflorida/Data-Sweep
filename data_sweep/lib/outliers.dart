import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:data_sweep/config.dart';
import 'package:data_sweep/issues_page.dart';
import 'package:data_sweep/main.dart';
import 'package:data_sweep/preview_page.dart';
import 'package:data_sweep/scaling_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:data_sweep/visualization_page.dart';

class OutliersPage extends StatefulWidget {
  final List<List<dynamic>> csvData;
  final List<String> columns;
  final List<List<int>> classifications;
  final List<String> casingSelections;
  final List<String> dateFormats;

  const OutliersPage({
    required this.csvData,
    required this.columns,
    required this.classifications,
    required this.casingSelections,
    required this.dateFormats,
  });

  @override
  _OutliersPageState createState() => _OutliersPageState();
}

class _OutliersPageState extends State<OutliersPage> {
  final _fileNameController = TextEditingController();
  late List<TextEditingController> textControllers;
  late List<String> handleOutliersOptions = [
    'Remove',
    'Cap and Floor',
    'Replace with Mean',
    'Replace with Median'
  ];
  late List<String> numericalColumns = getNumericalColumns();

  String outlierStatus = ""; // Resolved or Not Resolved
  bool isLoading = false;
  Uint8List? imageBytes;
  String resolve_outlier_method = "Cap and Floor";

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
                      casingSelections: widget.casingSelections,
                      dateFormats: widget.dateFormats,
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
                      casingSelections: widget.casingSelections,
                      dateFormats: widget.dateFormats,
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
    List<List<dynamic>> data = cleanedData;
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

  Future<Uint8List> fetchUnresolvedGraph(String columnName) async {
    Map<String, dynamic> requestPayload = {
      'data': cleanedData,
      'column_name': columnName,
      'task': "Show Outliers",
      'method': "",
    };

    try {
      var response = await http.post(
        Uri.parse('$baseURL/outliers_graph'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestPayload),
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception("Failed to fetch graph");
      }
    } catch (e) {
      throw Exception("Error fetching graph: $e");
    }
  }

  Future<void> getCleanedData(BuildContext context, String columnName,
      String resolveOutlierMethod) async {
    List<List<dynamic>> data = cleanedData;
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
                  Navigator.of(context)
                      .pop(); // Close the error dialog // Go back to the previous page
                },
                child: Text('Go Back'),
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
    print("Outliers/Columns: $widget.columns");
    print("Outliers/Classifications: $widget.classifications");
    print("Numerical Columns: $numericalColumns");

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Handle Outliers",
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
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                                    "Formatted Data",
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
                          color: Color.fromARGB(
                              255, 0, 0, 0), // Add color to the icon for emphasis
                        ),
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
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 0),
        
              // Use SingleChildScrollView to ensure the table is scrollable
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          offset: Offset(0, 4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ...List.generate(numericalColumns.length, (index) {
                            return Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title
                                  Text(
                                    "${numericalColumns[index]}",
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.left,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "View the outliers in your data.",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.grey[600]
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  // Graph Display
                                  FutureBuilder<Uint8List>(
                                    future: fetchUnresolvedGraph(numericalColumns[index]),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return CircularProgressIndicator();
                                      } else if (snapshot.hasError) {
                                        return Text(
                                          "Error loading graph",
                                          style: TextStyle(color: Colors.red),
                                        );
                                      } else {
                                        return SizedBox(
                                          height: 300, // Adjust height as needed
                                          width: double.infinity,
                                          child: Image.memory(
                                            snapshot.data!,
                                            fit: BoxFit.contain,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "Resolve the outliers in your data.",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.grey[600]
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  // Dropdown
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButtonFormField<String>(
                                        value: resolve_outlier_method,
                                        items: handleOutliersOptions.map((value) {
                                          return DropdownMenuItem(
                                            value: value,
                                            child: Text(
                                              value,
                                              style: TextStyle(fontSize: 14),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (selectedValue) {
                                          textControllers[index].text = selectedValue ?? '';
                                          resolve_outlier_method = selectedValue!;
                                        },
                                        decoration: InputDecoration(
                                          hintText: 'Options',
                                          hintStyle: TextStyle(fontSize: 12),
                                          contentPadding: EdgeInsets.symmetric(
                                              vertical: 4, horizontal: 3),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  // View Resolved Graph Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: TextButton(
                                        onPressed: () {
                                          setState(() {
                                            outlierStatus = "Resolved";
                                            fetchUnresolvedGraph(numericalColumns[index]); // Fetch resolved graph
                                          });
                                          print("Outliers Resolved");
                                        },
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        backgroundColor:
                                            const Color.fromARGB(255, 25, 156, 4),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        "View Resolved Graph",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
                          csvData: cleanedData,
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
                        builder: (context) => FeatureScalingPage(
                          csvData: cleanedData,
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
                        Icons.transform,
                        color: const Color.fromARGB(
                            255, 61, 126, 64), // Green color for icon
                      ),
                      Text(
                        "Scaling",
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
                          csvData: cleanedData,
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
