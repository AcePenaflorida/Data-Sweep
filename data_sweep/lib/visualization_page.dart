import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For JSON encoding/decoding
import 'package:data_sweep/config.dart'; // Make sure this includes your baseURL

class VisualizationPage extends StatelessWidget {
  final List<List<dynamic>> csvData;
  final List<String> columns;
  final List<List<int>> classifications;

  VisualizationPage({
    required this.csvData,
    required this.columns,
    required this.classifications,
  });

  @override
  Widget build(BuildContext context) {
    int rowCount = csvData.length;
    int columnCount = columns.length;

    // Encode data and classifications into JSON
    String encodedData = jsonEncode({
      'csv_data': csvData,
      'columns': columns,
    });

    return Scaffold(
      appBar: AppBar(
        title: Text("Data Visualization"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Row and Column Count Display
              Text(
                'Rows: $rowCount, Columns: $columnCount',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),

              // Loop through each column and fetch the chart image and statistics
              ...columns.asMap().entries.map((entry) {
                int columnIndex = entry.key; // Get the column index
                String columnTitle = entry.value; // Get the column name
                List<int> columnClassification = classifications[
                    columnIndex]; // Get the classification for this column

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      columnTitle, // Display column title
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),

                    // Fetch image for this column
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: FutureBuilder<Uint8List>(
                        future: _fetchChartImage(
                          columnTitle,
                          encodedData,
                          jsonEncode(
                              columnClassification), // Pass the specific classification for this column
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return CircularProgressIndicator();
                          } else if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          } else {
                            return Image.memory(
                                snapshot.data!); // Display the chart image
                          }
                        },
                      ),
                    ),

                    // Fetch statistics for numerical and categorical columns
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: FutureBuilder<Map<String, dynamic>>(
                        future: _fetchStatistics(columnTitle, encodedData),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return CircularProgressIndicator();
                          } else if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          } else {
                            if (snapshot.hasData) {
                              var stats = snapshot.data!;

                              // Display statistics only for numerical and categorical data
                              if (columnClassification[0] == 1) {
                                // Numerical
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Mean: ${stats['mean']}"),
                                    Text("Median: ${stats['median']}"),
                                    Text("Mode: ${stats['mode']}"),
                                  ],
                                );
                              } else if (columnClassification[1] == 1) {
                                // Categorical
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Mode: ${stats['mode']}"),
                                  ],
                                );
                              } else if (columnClassification[3] == 1) {
                                // Date
                                return SizedBox.shrink(); // No stats for date
                              } else {
                                return SizedBox
                                    .shrink(); // No stats for non-categorical
                              }
                            } else {
                              return Text('No statistics available');
                            }
                          }
                        },
                      ),
                    ),
                    SizedBox(height: 20), // Space between sections
                  ],
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  // Function to fetch the chart image from Flask server
  Future<Uint8List> _fetchChartImage(
      String columnTitle, String data, String columnClassification) async {
    final requestPayload = {
      'data': data,
      'columns': columns, // Full list of columns
      'classifications': classifications, // Full list of classifications
      'column_name': columnTitle, // Send the column name as well
    };

    final response = await http.post(
      Uri.parse('$baseURL/generate-chart'), // Endpoint to generate the chart
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestPayload),
    );

    if (response.statusCode == 200) {
      return response.bodyBytes; // Return the image bytes
    } else {
      throw Exception('Failed to load image');
    }
  }

  // Function to fetch the statistics (mean, median, mode) from Flask server
  Future<Map<String, dynamic>> _fetchStatistics(
      String columnTitle, String data) async {
    final requestPayload = {
      'data': csvData,
      'columns': columns, // Full list of columns
      'classifications': classifications,
      'column_name': columnTitle, // Send the column name for statistics
    };

    final response = await http.post(
      Uri.parse(
          '$baseURL/calculate-statistics'), // New endpoint to calculate statistics
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestPayload),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body); // Return the statistics as a map
    } else {
      throw Exception('Failed to load statistics');
    }
  }
}
