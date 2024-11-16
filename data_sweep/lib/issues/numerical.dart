import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:data_sweep/config.dart';

class NumericalIssuePage extends StatefulWidget {
  final String columnName;
  final List<String> issues;
  final List<List<dynamic>> csvData;

  NumericalIssuePage({
    required this.columnName,
    required this.issues,
    required this.csvData,
  });

  @override
  _NumericalIssuePageState createState() => _NumericalIssuePageState();
}

class _NumericalIssuePageState extends State<NumericalIssuePage> {
  late List<List<dynamic>> _reformattedData;
  String? selectedOption = "Leave Blank";
  final TextEditingController customValueController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _reformattedData = widget.csvData;
    // Debug logs
    print("Column Name: ${widget.columnName}");
    print("Issues: ${widget.issues}");
    print("CSV Data: ${widget.csvData}");
  }

  Future<List<List<dynamic>>> resolveIssue() async {
    var uri = Uri.parse('$baseURL/numerical_missing_values'); // Backend route

    Map<String, dynamic> requestData = {
      'column': widget.columnName,
      'action': selectedOption, // Selected action
      'fillValue': selectedOption == "Fill/Replace with Custom Value"
          ? customValueController.text
          : null,
      'data': widget.csvData,
    };

    var response = await http.post(
      uri,
      body: json.encode(requestData),
      headers: {'Content-Type': 'application/json'},
    );
    print("Response Status: ${response.statusCode}");

    if (response.statusCode == 200) {
      final resolvedData = List<List<dynamic>>.from(json.decode(response.body));
      print(
          "Reformatted Data: $resolvedData"); // Print resolved data to console
      return resolvedData;
    } else {
      throw Exception('Failed to resolve issue');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool hasMissingValues = widget.issues.contains("Missing Values") ||
        widget.issues.contains("Non-Numerical");

    return Scaffold(
      appBar: AppBar(title: Text("Numerical: ${widget.columnName}")),
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
                'Missing Values / Non-Numerical',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Column(
                children: [
                  RadioListTile<String>(
                    title: const Text("Fill/Replace with Mean"),
                    value: "Fill/Replace with Mean",
                    groupValue: selectedOption,
                    onChanged: (value) {
                      setState(() {
                        selectedOption = value;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text("Fill/Replace with Median"),
                    value: "Fill/Replace with Median",
                    groupValue: selectedOption,
                    onChanged: (value) {
                      setState(() {
                        selectedOption = value;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text("Fill/Replace with Mode"),
                    value: "Fill/Replace with Mode",
                    groupValue: selectedOption,
                    onChanged: (value) {
                      setState(() {
                        selectedOption = value;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text("Fill/Replace with Custom Value"),
                    value: "Fill/Replace with Custom Value",
                    groupValue: selectedOption,
                    onChanged: (value) {
                      setState(() {
                        selectedOption = value;
                      });
                    },
                  ),
                  if (selectedOption == "Fill/Replace with Custom Value")
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextField(
                        controller: customValueController,
                        decoration: InputDecoration(
                          labelText: "Enter custom value",
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  RadioListTile<String>(
                    title: const Text(
                        "Remove Rows with Missing/Non-Numerical Values"),
                    value: "Remove Rows",
                    groupValue: selectedOption,
                    onChanged: (value) {
                      setState(() {
                        selectedOption = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    if (selectedOption == "Fill/Replace with Custom Value") {
                      final customValue = customValueController.text;
                      if (double.tryParse(customValue) == null) {
                        _showErrorDialog(
                            "Non-numerical value entered. Please enter a numeric value.");
                        return;
                      }
                    }
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
