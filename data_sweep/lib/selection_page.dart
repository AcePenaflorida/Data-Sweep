import 'package:data_sweep/outliers.dart';
import 'package:data_sweep/outliers.dart';
import 'package:flutter/material.dart';
import 'issues_page.dart';

class SelectionPages extends StatelessWidget {
  final List<List<dynamic>> csvData;
  final List<String> columns;
  final List<List<int>> classifications;
  final List<String> casingSelections;
  final String dateFormats;

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
        title: Text("Selection Page"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Ace, What do you want to do with the file?",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
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
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      "Data Cleaning",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Clean your data by fixing inconsistencies for accurate analysis.",
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OutliersPage(
                      // NOT SURE KUNG ANO NEED MO. **PERA :<** dejok HHHAHA
                      //Gawa nalng u ng function sa outlierspage para madiregard ang hindi numerical
                      csvData: csvData,
                      columns: columns,
                      classifications: classifications, //CATEGORIES PER COLUMN
                    ),
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Handle Outliers By Column")),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      "Outliers",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Detect and handle outliers to refine your dataset.",
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) => ScalingPage(
                //       csvData: csvData,
                //       columns: columns,
                //       classifications: classifications,
                //     ),
                //   ),
                // );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text("Feature Scaling feature coming soon!")),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      "Feature Scaling",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Normalize your data for better model performance.",
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
