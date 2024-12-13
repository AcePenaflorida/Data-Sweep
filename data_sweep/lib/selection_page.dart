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
            fontSize: 28,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 61, 126, 64),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 30, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        color: const Color.fromARGB(255, 212, 216, 207),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              Expanded(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildCard(
                      context,
                      "assets/DataCleaning.png",
                      "Fix inconsistencies for accurate analysis.",
                      "Data Cleaning",
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
                    _buildCard(
                      context,
                      "assets/HandleOutliers.png",
                      "Detect and handle outliers to refine your dataset.",
                      "Outliers",
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OutliersPage(
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
                    _buildCard(
                      context,
                      "assets/FeatureScaling.png",
                      "Normalize your data for better model performance.",
                      "Feature Scaling",
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FeatureScalingPage(
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
                    _buildCard(
                      context,
                      "assets/DataVisualization.png",
                      "Visualize your data.",
                      "Data Visualization",
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    String imagePath,
    String description,
    String title,
    VoidCallback onPressed,
  ) {
    return Container(
      width: 320,
      margin: EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Color(0xFF999999)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset(
              imagePath,
              height: 300,
              fit: BoxFit.contain,
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              description,
              style: TextStyle(
                fontSize: 18,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 61, 126, 64),
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text(
                "Select",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto',
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
