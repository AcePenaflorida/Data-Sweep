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
  String? selectedOption = "";
  final TextEditingController customValueController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _reformattedData = widget.csvData;
    print("Column Name: ${widget.columnName}");
    print("Issues: ${widget.issues}");
    print("CSV Data: ${widget.csvData}");
  }

  Future<List<List<dynamic>>> resolveIssue() async {
    var uri = Uri.parse('$baseURL/numerical_missing_values');

    Map<String, dynamic> requestData = {
      'column': widget.columnName,
      'action': selectedOption,
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
    if (response.statusCode == 200) {
      return List<List<dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to resolve issue');
    }
  }

  @override
  Widget build(BuildContext context) {
    bool hasMissingValues = widget.issues.contains("Missing Values") ||
        widget.issues.contains("Non-Numerical");

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Numerical Data",
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
      backgroundColor: const Color.fromARGB(255, 212, 216, 207),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  child: Center(
                    child: Text(
                      'Column: ${widget.columnName}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3D7E40),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                if (widget.issues.isEmpty)
                  Center(
                    child: Text(
                      "No issues found. Yehey!",
                      style: const TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: Color.fromARGB(255, 136, 136, 136),
                      ),
                    ),
                  )
                else if (hasMissingValues) ...[
                  Text(
                    'Missing or Non-Numerical Values',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          title: const Text("Fill/Replace with Mean"),
                          value: "Fill/Replace with Mean",
                          groupValue: selectedOption,
                          activeColor: const Color.fromARGB(255, 61, 126, 64),
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
                          activeColor: const Color.fromARGB(255, 61, 126, 64),
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
                          activeColor: const Color.fromARGB(255, 61, 126, 64),
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
                          activeColor: const Color.fromARGB(255, 61, 126, 64),
                          onChanged: (value) {
                            setState(() {
                              selectedOption = value;
                            });
                          },
                        ),
                        if (selectedOption == "Fill/Replace with Custom Value")
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: TextField(
                              controller: customValueController,
                              decoration: const InputDecoration(
                                labelText: "Enter custom value",
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        RadioListTile<String>(
                          title: const Text("Remove Rows"),
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
                  ),
                  const SizedBox(height: 16.0),
                  Center(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (selectedOption == null || selectedOption!.isEmpty) {
                            showCustomDialog(
                              context: context,
                              title: "No Option Selected",
                              content: "Please select a valid method.",
                              buttonLabel: "OK",
                            );
                            return;
                          }
                          
                          if (selectedOption ==
                                  "Fill/Replace with Custom Value" &&
                              double.tryParse(customValueController.text) ==
                                  null) {
                            showCustomDialog(
                              context: context,
                              title: "Oops",
                              content: "Please enter a valid numeric value.",
                              buttonLabel: "OK",
                            );
                            
                            return;
                          }
                          
                          try {
                            _reformattedData = await resolveIssue();
                            Navigator.pop(context, _reformattedData);
                          } catch (error) {
                            showCustomDialog(
                              context: context,
                              title: "Unable to resolve the issue..",
                              content: "Please select a valid method.",
                              buttonLabel: "OK",
                            );
                          }

                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3D7E40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                12), // Set the radius here
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
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void showCustomDialog({
  required BuildContext context,
  required String title,
  required String content,
  required String buttonLabel,
}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Color.fromARGB(255, 61, 126, 64),
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          content,
          style: TextStyle(fontSize: 14.0),
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 61, 126, 64),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6.0),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                buttonLabel,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}