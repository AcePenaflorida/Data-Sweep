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
      'column': widget.columnName, // Only needed for "Fill Missing Values" action
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 25,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Non-Categorical: ${widget.columnName}",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF3D7E40),
      ),
      backgroundColor: const Color.fromARGB(255, 212, 216, 207),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                '${widget.columnName}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3D7E40), // Green color for text
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
                    color: Color.fromARGB(255, 136, 136, 136), // Light gray text
                  ),
                ),
              )
            else if (hasMissingValues) ...[
              Text(
                'Missing Values',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black, // Black text color
                ),
              ),
              Column(
                children: [
                  CheckboxListTile(
                    title: const Text("Leave Blank"),
                    value: selectedOption == "Leave Blank",
                    onChanged: (bool? value) {
                      setState(() {
                        selectedOption = value! ? "Leave Blank" : selectedOption;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading, // Align checkbox on the left
                    activeColor: Color(0xFF3D7E40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4), // Square checkbox shape
                    ),
                  ),
                  CheckboxListTile(
                    title: const Text("Fill with ____"),
                    value: selectedOption == "Fill with",
                    onChanged: (bool? value) {
                      setState(() {
                        selectedOption = value! ? "Fill with" : selectedOption;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading, // Align checkbox on the left
                    activeColor: Color(0xFF3D7E40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4), // Square checkbox shape
                    ),
                  ),
                  CheckboxListTile(
                    title: const Text("Remove Rows with Missing Values"),
                    value: selectedOption == "Remove Rows",
                    onChanged: (bool? value) {
                      setState(() {
                        selectedOption = value! ? "Remove Rows" : selectedOption;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading, // Align checkbox on the left
                    activeColor: Color(0xFF3D7E40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4), // Square checkbox shape
                    ),
                  ),
                  if (selectedOption == "Fill with")
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextField(
                        controller: fillValueController,
                        decoration: InputDecoration(
                          labelText: "Enter value",
                          border: OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16.0),
              Center(
              child: Container(
                width: double.infinity, // Make the button width take up full space
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    _reformattedData = await resolveIssue();
                    Navigator.pop(context, _reformattedData);
                  },
                  icon: const Icon(
                    Icons.check_circle, // Use check_circle icon
                    size: 22,
                    color: Colors.white,
                  ),
                  label: const Text(
                    "Resolve",
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3D7E40), // Green background
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                    foregroundColor: Colors.white, // White text color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            )
            ]
          ],
        ),
      ),
    );
  }
}
