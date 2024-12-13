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
      backgroundColor: const Color.fromARGB(255, 229, 234, 222),
      appBar: AppBar(
        title: const Text(
          "Data Visualization",
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
      body: Container(
        color: const Color.fromARGB(255, 229, 234, 222), // Background color
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard("Columns", columnCount.toString()),
                  _buildStatCard("Rows", rowCount.toString()),
                ],
              ),

              SizedBox(height: 20),

              // Loop through each column and fetch the chart image and statistics
              ...columns.asMap().entries.map((entry) {
                int columnIndex = entry.key; // Get the column index
                String columnTitle = entry.value; // Get the column name
                List<int> columnClassification = classifications[
                    columnIndex]; // Get the classification for this column

                // Determine the classification label
                String classificationLabel =
                    _getClassificationLabel(columnClassification);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 30.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          offset: Offset(0, 4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Column title with classification below it
                        Text(
                          columnTitle, // Display column title
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 0, 0, 0),
                          ),
                        ),
                        SizedBox(height: 5),

                        // Display classification below column title
                        Text(
                          'Classification: $classificationLabel',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 10),

                        // Fetch chart image for this column with rounded corners
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: FutureBuilder<Uint8List>(
                            future: _fetchChartImage(
                              columnTitle,
                              encodedData,
                              jsonEncode(
                                  columnClassification), // Pass the classification for this column
                            ),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Center(
                                    child: CircularProgressIndicator());
                              } else if (snapshot.hasError) {
                                return Center(
                                    child: Text('Error: ${snapshot.error}'));
                              } else if (snapshot.hasData) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                      8), // Apply rounded corners
                                  child: Image.memory(snapshot
                                      .data!), // Display the chart image
                                );
                              } else {
                                return Center(
                                    child: Text('No chart available.'));
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
                                return Center(
                                    child: CircularProgressIndicator());
                              } else if (snapshot.hasError) {
                                return Center(
                                    child: Text('Error: ${snapshot.error}'));
                              } else if (snapshot.hasData) {
                                var stats = snapshot.data!;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: _buildStatsDisplay(
                                      stats, columnClassification),
                                );
                              } else {
                                return Center(
                                    child: Text('No statistics available.'));
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  // Helper function to display statistics based on column type
  List<Widget> _buildStatsDisplay(
      Map<String, dynamic> stats, List<int> columnClassification) {
    if (columnClassification[0] == 1) {
      // Numerical
      return [
        Text("Mean: ${stats['mean']}"),
        Text("Median: ${stats['median']}"),
        Text("Mode: ${stats['mode']}"),
      ];
    } else if (columnClassification[1] == 1) {
      // Categorical
      return [
        Text("Mode: ${stats['mode']}"),
      ];
    } else if (columnClassification[3] == 1) {
      // Date (no stats)
      return [];
    } else {
      return []; // No stats for non-categorical or non-numerical
    }
  }

  // Helper function to map classification to label
  String _getClassificationLabel(List<int> columnClassification) {
    if (columnClassification[0] == 1) {
      return "Numerical";
    } else if (columnClassification[1] == 1) {
      return "Categorical";
    } else if (columnClassification[3] == 1) {
      return "Date";
    } else {
      return "Non-Numerical";
    }
  }

  // Function to fetch the chart image from Flask server
  Future<Uint8List> _fetchChartImage(
      String columnTitle, String data, String columnClassification) async {
    final requestPayload = {
      'data': data,
      'columns': columns,
      'classifications': classifications,
      'column_name': columnTitle,
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
      'columns': columns,
      'classifications': classifications,
      'column_name': columnTitle,
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

Widget _buildStatCard(String title, String value) {
  return Container(
    width: 130,
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: const Color.fromARGB(255, 244, 243, 243),
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
