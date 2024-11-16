import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:data_sweep/config.dart';

class NonCategoricalPage extends StatefulWidget {
  final String columnName;
  final List<String> issues;
  final List<List<dynamic>> csvData;

  NonCategoricalPage({
    required this.columnName,
    required this.issues,
    required this.csvData,
  });

  @override
  _NonCategoricalPageState createState() => _NonCategoricalPageState();
}

class _NonCategoricalPageState extends State<NonCategoricalPage> {
  late List<List<dynamic>> _reformattedData;

  String? selectedOption = "Leave Blank";
  TextEditingController fillValueController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _reformattedData = widget.csvData;
    // Printing the data received from the previous page (debugging purpose)
    print("Column Name: ${widget.columnName}");
    print("Issues: ${widget.issues}");
    print("CSV Data: ${widget.csvData}");
  }

  Future<List<List<dynamic>>> resolveIssue() async {
    var uri = Uri.parse(
        '$baseURL/non_categorical_missing_values'); // Update the URL to point to the new route

    Map<String, dynamic> requestData = {
      'column':
          widget.columnName, // Only needed for "Fill Missing Values" action
      'action': selectedOption, // "Fill with" or "Remove Rows"
      'fillValue': selectedOption == "Fill with"
          ? fillValueController.text
          : null, // Only needed for "Fill with"
      'data': widget.csvData, // The actual dataset
    };

    var response = await http.post(
      uri,
      body: json.encode(requestData),
      headers: {'Content-Type': 'application/json'},
    );
    print("Response Status: ${response.statusCode}");

    if (response.statusCode == 200) {
      return List<List<dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to resolve issue');
    }
  }

  @override
  Widget build(BuildContext context) {
    bool hasMissingValues = widget.issues.contains("Missing Values");

    return Scaffold(
      appBar: AppBar(title: Text("Non-Categorical: ${widget.columnName}")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                '${widget.columnName}',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16.0),
            if (widget.issues.isEmpty)
              Center(
                child: Text(
                  "No issues found. Yehey!",
                  style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                ),
              )
            else if (hasMissingValues) ...[
              Text(
                'Missing Values',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Column(
                children: [
                  RadioListTile<String>(
                    title: const Text("Leave Blank"),
                    value: "Leave Blank",
                    groupValue: selectedOption,
                    onChanged: (value) {
                      setState(() {
                        selectedOption = value;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text("Fill with ____"),
                    value: "Fill with",
                    groupValue: selectedOption,
                    onChanged: (value) {
                      setState(() {
                        selectedOption = value;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text("Remove Rows with Missing Values"),
                    value: "Remove Rows",
                    groupValue: selectedOption,
                    onChanged: (value) {
                      setState(() {
                        selectedOption = value;
                      });
                    },
                  ),
                  if (selectedOption == "Fill with")
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
                ],
              ),
              const SizedBox(height: 16.0),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    _reformattedData = await resolveIssue();
                    Navigator.pop(context, _reformattedData);
                  },
                  child: const Text("Resolve"),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
