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
    _reformattedDataset = widget.dataset;
    _invalidDates = [];
    _fetchInvalidDates();
  }

  Future<void> _fetchInvalidDates() async {
    try {
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

        setState(() {
          _invalidDates = rawInvalidDates.where((date) {
            return date.containsKey('invalid_date');
          }).toList();

          invalidDatesCount = _invalidDates.length;
          totalDates = widget.dataset.length - 1;
          validDatesCount = totalDates - invalidDatesCount;
        });
      } else {
        throw Exception('Failed to fetch invalid dates');
      }
    } catch (e) {
      print("Error fetching invalid dates: $e");
    }
  }

  Future<void> _reformatColumn() async {
    try {
      String selectedDateFormat = '';
      int columnIndex = widget.chosenColumns.indexOf(widget.columnName);

      if (widget.chosenClassifications[columnIndex][3] == 1) {
        selectedDateFormat = widget.chosenDateFormat[columnIndex];
      }

      var uri = Uri.parse('$baseURL/reformat_column');
      var response = await http.post(uri,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'data': widget.dataset,
            'dateFormat': selectedDateFormat,
            'classifications': widget.chosenClassifications,
            'columnIndex': columnIndex,
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
          "Date Issues in ${widget.columnName}",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard("Total Dates", totalDates.toString()),
                _buildStatCard("Invalid Dates", invalidDatesCount.toString()),
                _buildStatCard("Valid Dates", validDatesCount.toString()),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              "Invalid Dates for ${widget.columnName}:",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              "Expected Format: ${_invalidDates.isNotEmpty ? _invalidDates[0]['expected_format'] : 'N/A'}",
              style: const TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: Color.fromARGB(255, 136, 136, 136)),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: ListView.builder(
                  itemCount: _invalidDates.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            bottom: BorderSide(
                                color: Colors.grey.shade300, width: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.redAccent,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "${_invalidDates[index]['invalid_date']}",
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: double
                      .infinity, // Make the button width match the container width
                  child: ElevatedButton.icon(
                    onPressed: _reformatColumn,
                    icon: const Icon(Icons.delete_forever),
                    label: const Text("Delete Invalid Dates"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3D7E40),
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 20),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(10), // Reduced border radius
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context, _reformattedDataset);
                    },
                    icon: const Icon(Icons.cancel),
                    label: const Text("Cancel"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(
                          255, 212, 216, 207), // Same as Scaffold's background
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 20),
                      foregroundColor:
                          const Color(0xFF3D7E40), // White text color
                      side:
                          BorderSide(color: const Color(0xFF3D7E40), width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(10), // Reduced border radius
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFEF),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3D7E40),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
