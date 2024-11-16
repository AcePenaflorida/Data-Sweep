import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:data_sweep/config.dart';

class CategoricalPage extends StatefulWidget {
  final List<List<dynamic>> dataset;
  final String columnName; // Column name for reference
  final List<String> categoricalData; // Data of the column
  final List<String> issues; // List of issues for this column

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

  @override
  void initState() {
    super.initState();
    _reformattedDataset = widget.dataset;
    print("DATA COLUMN: ${widget.categoricalData}");
    uniqueValues = widget.categoricalData
        .toSet()
        .toList(); // Get unique values from the categorical data
    textControllers = uniqueValues
        .map((e) => TextEditingController())
        .toList(); // Initialize the text controllers for each unique value
  }

  @override
  void dispose() {
    for (var controller in textControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<List<List<dynamic>>> standardizeCategoryValues(
      List<List<dynamic>> data, standardizedValues) async {
    print("Function Invoked: standardizeCategoryValues...");
    var uri = Uri.parse('$baseURL/map_categorical_values');
    var response = await http.post(uri,
        body: json.encode({
          'data': data,
          'column': widget.columnName,
          'unique_values': uniqueValues,
          'standard_format': standardizedValues,
        }),
        headers: {'Content-Type': 'application/json'});
    print("Response Status: ${response.statusCode}");
    print("Response Body: ${response.body}");
    if (response.statusCode == 200) {
      return List<List<dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to standardized categorical columns......');
    }
  }

  Future<void> resolveStandardization(standardizedValues) async {
    try {
      List<List<dynamic>> reformattedData =
          await standardizeCategoryValues(widget.dataset, standardizedValues);
      setState(() {
        _reformattedDataset = reformattedData;
      });
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    print("Column: ${widget.columnName}");
    print("Unique Values: ${uniqueValues}");
    print("Column All Data: ${widget.categoricalData}");
    return Scaffold(
      appBar: AppBar(
        title: Text("Standardize Categorical Values - ${widget.columnName}"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Standardize the categorical values below:"),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Table(
                  border: TableBorder.all(),
                  children: [
                    // Header row with bold styling
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

                    // Rows for each unique value
                    ...List.generate(uniqueValues.length, (index) {
                      return TableRow(children: [
                        TableCell(
                          child: Center(child: Text(uniqueValues[index])),
                        ),
                        TableCell(
                          child: Center(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButtonFormField<String>(
                                items: uniqueValues.map((value) {
                                  return DropdownMenuItem(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (selectedValue) { 
                                  textControllers[index].text = selectedValue ?? '';
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
                // Get the standardized values entered or selected by the user
                List<String> standardizedValues = textControllers
                    .map((controller) => controller.text)
                    .toList();

                print("Selected Standard: ${standardizedValues}");

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
                  await resolveStandardization(standardizedValues);
                  Navigator.pop(context, _reformattedDataset);
                }
              },
              child: Text("Submit Standardized Values"),
            ),
          ],
        ),
      ),
    );
  }
}
