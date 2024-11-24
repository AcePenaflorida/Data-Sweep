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
  late List<List<dynamic>> _standardizedDataset;

  String? missingValueOption =
      "Leave Blank"; // Default option set to "Leave Blank"
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
        widget.categoricalData.any((value) => value.isEmpty);

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
        title: Text("Standardize Categorical Values - ${widget.columnName}"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step 1: Resolve Missing Values
            if (!missingValuesResolved) ...[
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
                    onChanged: (value) {
                      setState(() {
                        missingValueOption = value;
                      });
                    },
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    if (missingValueOption == "Leave Blank") {
                      // If 'Leave Blank' is selected, just set missingValuesResolved to true
                      setState(() {
                        missingValuesResolved = true;
                      });
                      // Proceed with the existing dataset
                    } else {
                      // Resolve missing values when it's not "Leave Blank"
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
                child: Text("Resolve Missing Values"),
              ),
            ],

            // Step 2: Standardize Values
            if (missingValuesResolved) ...[
              Text(
                'Standardize Categorical Values',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Table(
                    border: TableBorder.all(),
                    children: [
                      TableRow(children: [
                        TableCell(
                          child: Center(
                            child: Text(
                              "Unique Values",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        TableCell(
                          child: Center(
                            child: Text(
                              "Standardized Value",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ]),
                      ...List.generate(uniqueValues.length, (index) {
                        return TableRow(children: [
                          TableCell(
                            child: Center(child: Text(uniqueValues[index])),
                          ),
                          TableCell(
                            child: Center(
                              child: DropdownButtonFormField<String>(
                                value: textControllers[index].text,
                                items: uniqueValues.map((value) {
                                  return DropdownMenuItem(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (selectedValue) {
                                  textControllers[index].text =
                                      selectedValue ?? '';
                                },
                                decoration: InputDecoration(
                                  hintText: 'Select a standard value',
                                  hintStyle: TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          ),
                        ]);
                      }),
                    ],
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    List<String> standardizedValues = textControllers
                        .map((controller) => controller.text)
                        .toList();

                    _standardizedDataset = await standardizeValues(
                        _reformattedDataset, standardizedValues);
                    Navigator.pop(context, _standardizedDataset);
                  } catch (e) {
                    print("Error standardizing values: $e");
                  }
                },
                child: Text("Standardize Values"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
