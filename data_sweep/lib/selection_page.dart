import 'package:data_sweep/outliers.dart';
import 'package:data_sweep/scaling_page.dart';
import 'package:data_sweep/visualization_page.dart';
import 'package:flutter/material.dart';
import 'issues_page.dart';

class SelectionPages extends StatelessWidget {
  final List<List<dynamic>> csvData;
  final List<String> columns;
  final List<List<int>> classifications;
  final List<String> casingSelections;
  final List<String> dateFormats;

  SelectionPages({
    required this.csvData,
    required this.columns,
    required this.classifications,
    required this.casingSelections,
    required this.dateFormats,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "DATA SWEEP",
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
        color: const Color.fromARGB(255, 229, 234, 222),
        child: Center(
          // This centers the entire content
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center, // Center the content vertically
              crossAxisAlignment:
                  CrossAxisAlignment.center, // Center the content horizontally
              children: [
                Text(
                  "Select an action for the file",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                Text(
                  "We recommend starting with data cleaning!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 10),
                _buildActionButton(
                  context,
                  "Data Cleaning",
                  "Clean your data by fixing inconsistencies for accurate analysis.",
                  Icons.cleaning_services,
                  const Color.fromARGB(255, 61, 126, 64),
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => IssuesPage(
                          csvData: csvData,
                          columns: columns,
                          classifications: classifications,
                          casingSelections: casingSelections,
                          dateFormats: dateFormats,
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 20),
                _buildActionButton(
                  context,
                  "Outliers",
                  "Detect and handle outliers to refine your dataset.",
                  Icons.scatter_plot,
                  const Color.fromARGB(255, 86, 159, 85),
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OutliersPage(
                          csvData: csvData,
                          columns: columns,
                          classifications: classifications,
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 20),
                _buildActionButton(
                  context,
                  "Feature Scaling",
                  "Normalize your data for better model performance.",
                  Icons.equalizer_outlined,
                  const Color.fromARGB(255, 61, 126, 64),
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FeatureScalingPage(
                          csvData: csvData,
                          columns: columns,
                          classifications: classifications,
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 20),
                _buildActionButton(
                  context,
                  "Data Visualization",
                  "Visualize your Data",
                  Icons.insert_chart,
                  const Color.fromARGB(255, 86, 159, 85),
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VisualizationPage(
                          csvData: csvData,
                          columns: columns,
                          classifications: classifications,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 5,
        backgroundColor: color, // Use backgroundColor instead of primary
        minimumSize: Size(double.infinity, 80),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(icon, size: 30, color: Colors.white),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13, // Smaller font size for description
                    fontWeight:
                        FontWeight.w400, // Normal weight for description
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.start,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
