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
  late List<TextEditingController> textControllers;
  late List<String> uniqueValues;
  late List<List<dynamic>> _reformattedDataset;

  String? missingValueOption =
      "Leave Blank"; // Default option set to "Leave Blank"
  TextEditingController fillValueController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _reformattedDataset = widget.dataset;

    uniqueValues = widget.categoricalData
        .where((value) => value.isNotEmpty) // Exclude missing values
        .toSet()
        .toList();

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

  Future<List<List<dynamic>>> resolveMissingValuesAndStandardize(
      List<String> standardizedValues) async {
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
    print("NAKUAH");

    // Step 2: Update dataset with resolved missing values
    String responseBody = responseMissing.body;

    // Sanitize response body by replacing 'NaN' and any unwanted values with an empty string
    responseBody =
        responseBody.replaceAll('NaN', '""').replaceAll('null', '""');

    try {
      // Decode the sanitized response body
      List<List<dynamic>> resolvedData =
          List<List<dynamic>>.from(json.decode(responseBody));

      // Step 3: Filter out rows with missing values
      List<List<dynamic>> rowsWithoutMissingValues = resolvedData
          .where(
              (row) => row[widget.dataset[0].indexOf(widget.columnName)] != "")
          .toList();

      // Step 4: Standardize Values
      var uriStandardize = Uri.parse('$baseURL/map_categorical_values');
      var requestDataStandardize = {
        'data': rowsWithoutMissingValues,
        'column': widget.columnName,
        'unique_values': uniqueValues,
        'standard_format': standardizedValues,
      };

      var responseStandardize = await http.post(
        uriStandardize,
        body: json.encode(requestDataStandardize),
        headers: {'Content-Type': 'application/json'},
      );

      if (responseStandardize.statusCode == 200) {
        // Replace rows with standardized rows and keep missing data untouched
        List<List<dynamic>> standardizedData =
            List<List<dynamic>>.from(json.decode(responseStandardize.body));

        for (int i = 0; i < resolvedData.length; i++) {
          if (resolvedData[i][widget.dataset[0].indexOf(widget.columnName)] ==
              "") {
            // Retain missing rows
            standardizedData.insert(i, resolvedData[i]);
          }
        }

        return standardizedData;
      } else {
        throw Exception('Failed to standardize categorical values.');
      }
    } catch (e) {
      print("Error while processing response: $e");
      throw Exception(
          'Error processing missing values or standardizing the dataset.');
    }
  }

  @override
  Widget build(BuildContext context) {
    bool hasMissingValues = widget.issues.contains("Missing Values");

    return Scaffold(
      appBar: AppBar(
        title: Text("Standardize Categorical Values - ${widget.columnName}"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasMissingValues) ...[
              Text(
                'Missing Values',
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
              const SizedBox(height: 20),
            ],
            Text("Standardize the categorical values below:"),
            const SizedBox(height: 20),
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
                            child: DropdownButtonHideUnderline(
                              child: DropdownButtonFormField<String>(
                                value: uniqueValues[index],
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
                        ),
                      ]);
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                List<String> standardizedValues = textControllers
                    .map((controller) => controller.text)
                    .toList();

                if (standardizedValues.any((value) => value.isEmpty)) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text("Warning"),
                        content: Text("Complete Standardization"),
                        actions: <Widget>[
                          TextButton(
                            child: Text("OK"),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                } else {
                  try {
                    _reformattedDataset =
                        await resolveMissingValuesAndStandardize(
                            standardizedValues);
                    Navigator.pop(context, _reformattedDataset);
                  } catch (e) {
                    print("Error: $e");
                  }
                }
              },
              child: Text("Resolve & Standardize"),
            ),
          ],
        ),
      ),
    );
  }
}
