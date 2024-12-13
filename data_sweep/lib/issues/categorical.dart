import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:data_sweep/config.dart';

class CategoricalPage extends StatefulWidget {
  final List<List<dynamic>> dataset;
  final String columnName;
  final List<String> categoricalData;
  final List<String> issues;

  CategoricalPage({
    required this.columnName,
    required this.categoricalData,
    required this.issues,
    required this.dataset,
  });

  @override
  _CategoricalPageState createState() => _CategoricalPageState();
}

class _CategoricalPageState extends State<CategoricalPage> {
  bool missingValuesResolved = false;
  late List<TextEditingController> textControllers;
  late List<String> uniqueValues;
  late List<List<dynamic>> _reformattedDataset;

  String? missingValueOption = ""; // Default option set to "Leave Blank"
  TextEditingController fillValueController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _reformattedDataset = widget.dataset;

    // Identify unique values excluding missing ones
    uniqueValues = widget.categoricalData
        .where((value) => value.isNotEmpty) // Exclude missing values
        .toSet()
        .toList();

    // Check for missing values in the column
    bool hasMissingValues =
        widget.categoricalData.any((value) => value.trim().isEmpty);

    // Set missingValuesResolved based on whether there are missing values
    missingValuesResolved = !hasMissingValues;

    // Initialize text controllers with unique values
    textControllers = uniqueValues
        .map((value) => TextEditingController(text: value))
        .toList();
  }

  @override
  void dispose() {
    for (var controller in textControllers) {
      controller.dispose();
    }
    fillValueController.dispose();
    super.dispose();
  }

  Future<List<List<dynamic>>> resolveMissingValues() async {
    String fillValue =
        missingValueOption == "Fill with" && fillValueController.text.isNotEmpty
            ? fillValueController.text
            : '';
    var uriMissing = Uri.parse('$baseURL/non_categorical_missing_values');
    var requestDataMissing = {
      'column': widget.columnName,
      'action': missingValueOption,
      'fillValue': missingValueOption == "Fill with" ? fillValue : null,
      'data': _reformattedDataset,
    };

    var responseMissing = await http.post(
      uriMissing,
      body: json.encode(requestDataMissing),
      headers: {'Content-Type': 'application/json'},
    );

    if (responseMissing.statusCode != 200) {
      throw Exception('Failed to resolve missing values.');
    }

    try {
      // Decode and return resolved dataset
      List<List<dynamic>> resolvedDataset =
          List<List<dynamic>>.from(json.decode(responseMissing.body));

      // Add custom value to uniqueValues if applicable
      if (missingValueOption == "Fill with" && fillValue.isNotEmpty) {
        setState(() {
          if (!uniqueValues.contains(fillValue)) {
            uniqueValues.add(fillValue);
            textControllers.add(TextEditingController(text: fillValue));
          }
        });
      }

      return resolvedDataset;
    } catch (e) {
      print("Error processing missing values: $e");
      throw Exception('Error resolving missing values.');
    }
  }

  Future<List<List<dynamic>>> standardizeValues(
      List<List<dynamic>> resolvedData, List<String> standardizedValues) async {
    // Filter out rows with missing or NaN values in the target column
    int columnIndex = widget.dataset[0].indexOf(widget.columnName);
    List<List<dynamic>> filteredData = resolvedData
        .where((row) => row[columnIndex] != null && row[columnIndex] != '')
        .toList();

    var uriStandardize = Uri.parse('$baseURL/map_categorical_values');
    var requestDataStandardize = {
      'data': filteredData, // Use filtered data
      'column': widget.columnName,
      'unique_values': uniqueValues,
      'standard_format': standardizedValues,
    };

    var responseStandardize = await http.post(
      uriStandardize,
      body: json.encode(requestDataStandardize),
      headers: {'Content-Type': 'application/json'},
    );

    if (responseStandardize.statusCode != 200) {
      throw Exception('Failed to standardize categorical values.');
    }

    try {
      // Parse and return standardized data
      List<List<dynamic>> standardizedData =
          List<List<dynamic>>.from(json.decode(responseStandardize.body));

      // Reinsert the rows with missing or NaN values (unchanged)
      for (var row in resolvedData) {
        if (row[columnIndex] == null || row[columnIndex] == '') {
          standardizedData.insert(resolvedData.indexOf(row), row);
        }
      }

      return standardizedData;
    } catch (e) {
      print("Error processing standardization: $e");
      throw Exception('Error standardizing values.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Categorical Data",
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
      backgroundColor: const Color.fromARGB(255, 229, 234, 222),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            // Entire body becomes scrollable
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!missingValuesResolved) ...[
                  Center(
                    child: Text(
                      'Column: ${widget.columnName}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3D7E40), // Green color for text
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    'Resolve Missing Values',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Column(
                    children: [
                      RadioListTile<String>(
                        title: const Text("Remove Rows with Missing Values"),
                        value: "Remove Rows",
                        groupValue: missingValueOption,
                        activeColor: const Color.fromARGB(255, 61, 126, 64),
                        onChanged: (value) {
                          setState(() {
                            missingValueOption = value;
                          });
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text("Fill with Mode"),
                        value: "Fill with Mode",
                        groupValue: missingValueOption,
                        activeColor: const Color.fromARGB(255, 61, 126, 64),
                        onChanged: (value) {
                          setState(() {
                            missingValueOption = value;
                          });
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text("Fill with Custom Value"),
                        value: "Fill with",
                        groupValue: missingValueOption,
                        activeColor: const Color.fromARGB(255, 61, 126, 64),
                        onChanged: (value) {
                          setState(() {
                            missingValueOption = value;
                          });
                        },
                      ),
                      if (missingValueOption == "Fill with")
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: TextField(
                            controller: fillValueController,
                            decoration: InputDecoration(
                              labelText: "Enter value",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      RadioListTile<String>(
                        title: const Text("Leave Blank"),
                        value: "Leave Blank",
                        groupValue: missingValueOption,
                        activeColor: const Color.fromARGB(255, 61, 126, 64),
                        onChanged: (value) {
                          setState(() {
                            missingValueOption = value;
                          });
                        },
                      ),
                    ],
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          // Check if the user selected "Fill with" but didn't enter a value
                          if (missingValueOption == "Fill with" &&
                              fillValueController.text.isEmpty) {
                            // Show alert dialog to inform the user to fill in the value
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text(
                                    "Missing Value",
                                    style: TextStyle(
                                      color: Color(
                                          0xFF3D7E40), // Green color matching the app's theme
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  content: const Text(
                                    "Please enter a value to fill with.",
                                    style: TextStyle(
                                        color: Colors
                                            .black), // Black text for content
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(
                                            context); // Close the dialog
                                      },
                                      child: const Text(
                                        "OK",
                                        style: TextStyle(
                                          color: Color(
                                              0xFF3D7E40), // Green color for the button text
                                          fontWeight: FontWeight
                                              .bold, // Bold text for the button
                                        ),
                                      ),
                                    ),
                                  ],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        12), // Rounded corners for the dialog
                                  ),
                                  backgroundColor: Colors
                                      .white, // White background to keep the focus on the message
                                  elevation:
                                      5, // Slight shadow for better visibility
                                );
                              },
                            );

                            return; // Exit the function without continuing
                          }

                          // Proceed with resolving missing values if all conditions are met
                          if (missingValueOption == "Leave Blank") {
                            setState(() {
                              missingValuesResolved = true;
                            });
                          } else {
                            List<List<dynamic>> resolvedData =
                                await resolveMissingValues();
                            setState(() {
                              _reformattedDataset = resolvedData;
                              missingValuesResolved = true;
                            });
                            Navigator.pop(context, _reformattedDataset);
                          }
                        } catch (e) {
                          print("Error resolving missing values: $e");
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3D7E40),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12), // Set the radius here
                        ),
                      ),
                      child: const Text(
                        "Resolve",
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
                if (missingValuesResolved) ...[
                  Center(
                    child: Text(
                      'Column: ${widget.columnName}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3D7E40), // Green color for text
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Standardize Categorical Values',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Table(
                    border: TableBorder.all(),
                    children: [
                      // Header Row
                      TableRow(children: [
                        TableCell(
                          child: Container(
                            color: const Color(0xFF3D7E40), // Green background
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Center(
                                child: Text(
                                  "Unique Values",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Colors.white, // White text for contrast
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        TableCell(
                          child: Container(
                            color: const Color(0xFF3D7E40), // Green background
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Center(
                                child: Text(
                                  "Standardized Value",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Colors.white, // White text for contrast
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ]),
                      // Data Rows
                      ...List.generate(uniqueValues.length, (index) {
                        return TableRow(children: [
                          TableCell(
                            child: SizedBox(
                              height: 48, // Set the desired height for the cell
                              child: Center(
                                child: Text(
                                  uniqueValues[index],
                                  style: const TextStyle(
                                    color: Colors.black, // Text color
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow
                                      .ellipsis, // Add ellipsis for overflowed text
                                  maxLines: 1,
                                ),
                              ),
                            ),
                          ),
                          TableCell(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: 150, // Adjust maxWidth as needed
                              ),
                              child: DropdownButtonFormField<String>(
                                value: textControllers[index].text,
                                items: [
                                  ...uniqueValues.map((value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(
                                        value,
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    );
                                  }).toList(),
                                  const DropdownMenuItem<String>(
                                    value: 'None',
                                    child: Text(
                                      'None',
                                      style: TextStyle(
                                        color: Colors.black,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    textControllers[index].text = value!;
                                  });
                                },
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor:
                                      const Color.fromARGB(0, 255, 255, 255),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                        color:
                                            Color.fromARGB(0, 158, 158, 158)),
                                  ),
                                ),
                                style: const TextStyle(color: Colors.black),
                                dropdownColor:
                                    const Color.fromARGB(255, 229, 234, 222),
                              ),
                            ),
                          ),
                        ]);
                      }),
                    ],
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          List<String> standardizedValues = textControllers
                              .map((controller) => controller.text)
                              .toList();
                          List<List<dynamic>> standardizedData =
                              await standardizeValues(
                                  _reformattedDataset, standardizedValues);
                          Navigator.pop(context, standardizedData);
                        } catch (e) {
                          print("Error standardizing categorical values: $e");
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3D7E40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Standardize Values",
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
