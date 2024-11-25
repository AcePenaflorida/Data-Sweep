import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:data_sweep/config.dart';

class DateIssuePage extends StatefulWidget {
  final String columnName;
  final List<String> issues;
  final List<List<dynamic>> dataset;
  final List<String> chosenDateFormat;
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
  late List<Map<String, dynamic>> _invalidDates;

  int totalDates = 0;
  int invalidDatesCount = 0;
  int validDatesCount = 0;

  @override
  void initState() {
    super.initState();
    _reformattedDataset = widget.dataset; // Initialize with the original data
    _invalidDates = []; // Initialize empty invalid dates
    _fetchInvalidDates();
  }

  // Function to fetch invalid dates from the backend
  Future<void> _fetchInvalidDates() async {
    try {
      print("Chosen Date Format: ${widget.chosenDateFormat}");
      print("Column Name: ${widget.columnName}");
      print("Chosen Columns: ${widget.chosenColumns}");
      print("Chosen Classifications: ${widget.chosenClassifications}");

      int columnIndex = widget.chosenColumns.indexOf(widget.columnName);
      String selectedDateFormat = '';

      if (widget.chosenClassifications[columnIndex][3] == 1) {
        selectedDateFormat = widget.chosenDateFormat[columnIndex];
      }

      var uri = Uri.parse('$baseURL/show_invalid_dates');
      var response = await http.post(uri,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'data': widget.dataset,
            'dateFormat': selectedDateFormat,
            'classifications': widget.chosenClassifications,
            'columnIndex': columnIndex,
          }));

      if (response.statusCode == 200) {
        List<Map<String, dynamic>> rawInvalidDates =
            List<Map<String, dynamic>>.from(
                json.decode(response.body)['invalid_dates']);

        // Filter out unwanted entries
        setState(() {
          _invalidDates = rawInvalidDates.where((date) {
            return date.containsKey('invalid_date');
          }).toList();

          // Count the invalid dates
          invalidDatesCount = _invalidDates.length;

          // Count the total dates (total rows in the dataset)
          totalDates = widget.dataset.length - 1; // minus 1 para sa column name

          // Calculate valid dates
          validDatesCount = totalDates - invalidDatesCount;
        });

        print("Filtered invalid dates: $_invalidDates");
      } else {
        throw Exception('Failed to fetch invalid dates');
      }
    } catch (e) {
      print("Error fetching invalid dates: $e");
    }
  }

  // Function to call the backend and reformat the selected column
  Future<void> _reformatColumn() async {
    try {
      String selectedDateFormat = '';
      int columnIndex = widget.chosenColumns.indexOf(widget.columnName);

      // Check the classification array for the correct column and get the date format
      if (widget.chosenClassifications[columnIndex][3] == 1) {
        selectedDateFormat = widget.chosenDateFormat[columnIndex];
      }

      var uri = Uri.parse('$baseURL/reformat_column');
      var response = await http.post(uri,
          headers: {
            'Content-Type': 'application/json'
          }, // Ensure the correct header
          body: json.encode({
            'data': widget.dataset,
            'dateFormat': selectedDateFormat,
            'classifications': widget.chosenClassifications,
            'columnIndex': widget.chosenColumns
                .indexOf(widget.columnName), // Send column index
          }));

      if (response.statusCode == 200) {
        setState(() {
          _reformattedDataset =
              List<List<dynamic>>.from(json.decode(response.body));
        });
        Navigator.pop(context, _reformattedDataset);
      } else {
        throw Exception('Failed to reformat the column');
      }
    } catch (e) {
      print("Error reformatting column: $e");
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
            // Display the count of total, invalid, and valid dates horizontally
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text("Total Dates: $totalDates | "),
                Text("Invalid Dates: $invalidDatesCount | "),
                Text("Valid Dates: $validDatesCount"),
              ],
            ),

            // List of invalid dates with small gap and border
            SizedBox(height: 16),
            Text(
              "Invalid Dates for ${widget.columnName}:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              "Expected Format: ${_invalidDates.isNotEmpty ? _invalidDates[0]['expected_format'] : 'N/A'}",
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),

            // Container with border and padding to display invalid dates
            Container(
              margin: EdgeInsets.symmetric(vertical: 5),
              padding: EdgeInsets.all(0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              constraints: BoxConstraints(
                maxHeight: 300, // Set your desired maximum height here
              ),
              child: ListView.builder(
                shrinkWrap: true, // Allow ListView to take only required space
                physics: _invalidDates.length > 5
                    ? AlwaysScrollableScrollPhysics()
                    : NeverScrollableScrollPhysics(), // Enable scrolling when the list is too large
                itemCount: _invalidDates.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(
                        bottom: 8.0), // Small gap between items
                    child: ListTile(
                      title: Text("${_invalidDates[index]['invalid_date']}"),
                    ),
                  );
                },
              ),
            ),

            // Buttons for actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _reformatColumn,
                  child: Text("Delete Invalid Dates"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context,
                        _reformattedDataset); // Return the reformatted data
                  },
                  child: Text("Cancel"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
