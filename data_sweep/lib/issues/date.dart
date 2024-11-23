import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:data_sweep/config.dart';

class DateIssuePage extends StatefulWidget {
  final String columnName;
  final List<String> issues;
  final List<List<dynamic>> dataset;
  final String chosenDateFormat;
  final List<String> chosenColumns;
  final List<List<int>> chosenClassifications;

  DateIssuePage({
    required this.columnName,
    required this.issues,
    required this.dataset,
    required this.chosenDateFormat, 
    required this.chosenColumns, 
    required this.chosenClassifications,
  });

  @override
  _DateIssuePageState createState() => _DateIssuePageState();
}

class _DateIssuePageState extends State<DateIssuePage> {
  late List<List<dynamic>> _reformattedDataset;

  @override
    void initState() {
      super.initState();
      _reformattedDataset = widget.dataset;  // Initialize with the original data
    }
  // Function to call the backend and reformat the data
  Future<List<List<dynamic>>> reformatInvalidDates(List<List<dynamic>> data) async {
    print("Chosen Format: ${widget.chosenDateFormat}");
    var uri = Uri.parse('$baseURL/reformat_date');
    print("Sending data: ${json.encode(data)}");
    print("Sending dateFormats: ${widget.chosenDateFormat}");

    var response = await http.post(uri,
      body: json.encode({
        'data': data,
        'dateFormats': widget.chosenDateFormat,
        'classifications': widget.chosenClassifications,
      }),
      headers: {'Content-Type': 'application/json'}
    );
    print("Response Status: ${response.statusCode}");
    print("Response Body: ${response.body}");
    
    if (response.statusCode == 200) {
      return List<List<dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to reformat invalid dates...');
    }
  }

  // Function to resolve invalid dates
  Future<void> resolveInvalidDates() async {
    try {
      List<List<dynamic>> reformattedData = await reformatInvalidDates(widget.dataset);
      setState(() {
        _reformattedDataset = reformattedData;
      });
    } catch (e) {
      print("Error: $e");
    }
  }

    // Function to call the backend and delete rows with invalid dates
  Future<List<List<dynamic>>> deleteInvalidDates(List<List<dynamic>> data) async {
    var uri = Uri.parse('$baseURL/delete_invalid_dates');
    var response = await http.post(
      uri,
      body: json.encode({
        'data': data,
        'dateFormat': widget.chosenDateFormat,
        'columns': widget.chosenColumns,
        'classifications' : widget.chosenClassifications,
      }),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      print("Invalid Rows Deleted");
      return List<List<dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to delete rows with invalid dates...');
    }
  }

  // Function to handle the deletion of invalid dates
  Future<void> handleDeleteInvalidDates() async {
    try {
      List<List<dynamic>> filteredData = await deleteInvalidDates(widget.dataset);
      setState(() {
        _reformattedDataset = filteredData;
      });
    } catch (e) {
      print("Error: $e");
    }
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text("Date Issues in ${widget.columnName}")),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // List of Issues
          Container(
            height: 100, // Specify the desired height here
            child: ListView.builder(
              itemCount: widget.issues.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(widget.issues[index]),
                );
              },
            ),
          ),

          // Description
          Text(
            "What to do with rows with invalid dates?",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),

          // Buttons for actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () async {
                  // Invoke reformatting when the button is pressed
                  await resolveInvalidDates();
                  // Return the reformatted data back to the previous page
                  Navigator.pop(context, _reformattedDataset);
                },
                child: Text("Reformat"),
              ),
              ElevatedButton(
                onPressed: () async {
                  await handleDeleteInvalidDates();
                  Navigator.pop(context, _reformattedDataset);
                },
                child: Text("Delete"),
              ),
            ],
          ),
          SizedBox(height: 20),

        ],
      ),
    ),
  );
}

}
