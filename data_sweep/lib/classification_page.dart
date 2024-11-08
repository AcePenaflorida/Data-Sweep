import 'package:data_sweep/main.dart';
import 'package:flutter/material.dart';
import 'preview_page.dart'; // Assuming you have this page to display the preview

class ClassificationPage extends StatefulWidget {
  final String filePath;
  final List<List<dynamic>>
      csvData; // Store CSV data passed from previous pages
  final String fileName;

  ClassificationPage({
    required this.filePath,
    required this.csvData,
    required this.fileName,
  });

  @override
  _ClassificationPageState createState() => _ClassificationPageState();
}

class _ClassificationPageState extends State<ClassificationPage> {
  late List<String> columns; // To store column names

  // Variables to track selected classifications for each column
  List<List<int>> columnClassifications = [];

  // To store the text-based classifications
  List<String> selectedClassifications = [];

  @override
  void initState() {
    super.initState();
    // Extract column names from the first row of the CSV data
    columns = List<String>.from(widget.csvData[0]);

    // Initialize classifications for each column (4 options for each)
    columnClassifications =
        List.generate(columns.length, (index) => [0, 0, 0, 0]);
  }

  // Function to get the classification text based on the selection
  String getClassificationText(int index) {
    if (columnClassifications[index][0] == 1) {
      return "Numerical";
    } else if (columnClassifications[index][1] == 1) {
      return "Categorical";
    } else if (columnClassifications[index][2] == 1) {
      return "Non-Categorical";
    } else if (columnClassifications[index][3] == 1) {
      return "Date";
    }
    return "Unclassified";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Data Sweep"),
        leading: IconButton(
          icon: Icon(Icons.cancel),
          onPressed: () {
            // Show cancel confirmation dialog
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text("Are you sure you want to cancel?"),
                  actions: <Widget>[
                    TextButton(
                      child: Text("Yes"),
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => HomePage()),
                          (Route<dynamic> route) =>
                              false, // Removes all previous routes
                        ); // Go back to previous page
                      },
                    ),
                    TextButton(
                      child: Text("No"),
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                      },
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        // Wrap the entire body in SingleChildScrollView
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Uploaded file: ${widget.fileName}"),

            const SizedBox(height: 20),
            // Preview button to go to PreviewPage
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PreviewPage(
                      filePath: widget.filePath,
                      csvData: widget.csvData, // Pass CSV data to preview
                      fileName: widget.fileName,
                    ),
                  ),
                );
              },
              child: Row(
                children: [Icon(Icons.remove_red_eye), Text("Preview Data")],
              ),
            ),

            const SizedBox(height: 20),
            Text(
                "Let’s classify the remaining columns to better clean and analyze your dataset!"),

            const SizedBox(height: 20),

            // Horizontal scrolling for the DataTable
            SingleChildScrollView(
              scrollDirection: Axis.horizontal, // Horizontal scroll for columns
              child: Container(
                // Fixed height for vertical scrolling of rows
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical, // Vertical scroll for rows
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text("Column Name")),
                      DataColumn(label: Text("Numerical")),
                      DataColumn(label: Text("Categorical")),
                      DataColumn(label: Text("Non-Categorical")),
                      DataColumn(label: Text("Date")),
                    ],
                    rows: List.generate(columns.length, (index) {
                      return DataRow(cells: [
                        DataCell(Text(columns[index])),
                        DataCell(_buildRadioButton(index, 0, "Numerical")),
                        DataCell(_buildRadioButton(index, 1, "Categorical")),
                        DataCell(
                            _buildRadioButton(index, 2, "Non-Categorical")),
                        DataCell(_buildRadioButton(index, 3, "Date")),
                      ]);
                    }),
                  ),
                ),
              ),
            ),

            // Submit Button
            ElevatedButton(
              onPressed: () {
                setState(() {
                  // Generate the selected classifications for each column
                  selectedClassifications =
                      List.generate(columns.length, (index) {
                    return '${columns[index]}: ${getClassificationText(index)}';
                  });
                });
              },
              child: Text("Submit Classification"),
            ),

            const SizedBox(height: 20),

            // Display selected classifications
            if (selectedClassifications.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: selectedClassifications.map((classification) {
                  return Text(classification);
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  // Function to create a radio button for each classification option
  Widget _buildRadioButton(int columnIndex, int optionIndex, String label) {
    return Row(
      children: [
        Radio<int>(
          value: optionIndex,
          groupValue: columnClassifications[columnIndex].indexOf(1),
          onChanged: (int? value) {
            setState(() {
              // Update the classification for this column
              columnClassifications[columnIndex] =
                  List.generate(4, (i) => i == value ? 1 : 0);
            });
          },
        ),
      ],
    );
  }
}
