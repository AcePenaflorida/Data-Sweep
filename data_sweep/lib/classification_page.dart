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

  // To store the selected letter casing for each column
  List<String> columnCasingSelections = [];

  // To store the selected date format for each column classified as 'Date'
  List<String> columnDateFormats = [];

  @override
  void initState() {
    super.initState();
    // Extract column names from the first row of the CSV data
    columns = List<String>.from(widget.csvData[0]);

    // Initialize classifications for each column (4 options for each)
    columnClassifications =
        List.generate(columns.length, (index) => [0, 0, 0, 0]);

    // Initialize the casing selections (empty by default)
    columnCasingSelections = List.generate(columns.length, (index) => "");

    // Initialize date format selections (empty by default)
    columnDateFormats = List.generate(columns.length, (index) => "");
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
        // Make everything scrollable
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                      DataCell(_buildRadioButton(index, 2, "Non-Categorical")),
                      DataCell(_buildRadioButton(index, 3, "Date")),
                    ]);
                  }),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Column layout for letter casing and date format selection
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(columns.length, (index) {
                return Column(
                  children: [
                    // Display letter casing section if the column is Categorical or Non-Categorical
                    if (columnClassifications[index][1] == 1 ||
                        columnClassifications[index][2] == 1)
                      Row(
                        children: [
                          Text("Select letter casing for ${columns[index]}:"),
                          Expanded(
                            child: DropdownButton<String>(
                              hint: Text("Select casing"),
                              value: columnCasingSelections[index].isNotEmpty
                                  ? columnCasingSelections[index]
                                  : null,
                              items: [
                                DropdownMenuItem(
                                    value: "UPPERCASE",
                                    child: Text("UPPERCASE")),
                                DropdownMenuItem(
                                    value: "lowercase",
                                    child: Text("lowercase")),
                                DropdownMenuItem(
                                    value: "Sentence case",
                                    child: Text("Sentence case")),
                                DropdownMenuItem(
                                    value: "Title Case",
                                    child: Text("Title Case")),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  columnCasingSelections[index] = value ?? "";
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                    // Display date format section if the column is Date
                    if (columnClassifications[index][3] == 1)
                      Row(
                        children: [
                          Text("Select date format for ${columns[index]}:"),
                          Expanded(
                            child: DropdownButton<String>(
                              hint: Text("Select format"),
                              value: columnDateFormats[index].isNotEmpty
                                  ? columnDateFormats[index]
                                  : null,
                              items: [
                                DropdownMenuItem(
                                    value: "mm/dd/yy", child: Text("mm/dd/yy")),
                                DropdownMenuItem(
                                    value: "dd/mm/yy", child: Text("dd/mm/yy")),
                                DropdownMenuItem(
                                    value: "yy/mm/dd", child: Text("yy/mm/dd")),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  columnDateFormats[index] = value ?? "";
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 20),

            // Submit Button
            ElevatedButton(
              onPressed: () {
                setState(() {
                  // Generate the selected classifications with case and date format for each column
                  selectedClassifications =
                      List.generate(columns.length, (index) {
                    String classificationText =
                        '${columns[index]}: ${getClassificationText(index)}';

                    // Add the casing and date format info
                    if (columnClassifications[index][1] == 1 ||
                        columnClassifications[index][2] == 1) {
                      classificationText +=
                          " - ${columnCasingSelections[index]}";
                    }

                    if (columnClassifications[index][3] == 1) {
                      classificationText += " - ${columnDateFormats[index]}";
                    }

                    return classificationText;
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

  // Function to build radio buttons for each classification option
  Widget _buildRadioButton(int index, int type, String label) {
    return Row(
      children: [
        Radio<int>(
          value: type,
          groupValue: columnClassifications[index].indexOf(1),
          onChanged: (int? value) {
            setState(() {
              // Reset other selections and set the selected value to 1
              for (int i = 0; i < 4; i++) {
                columnClassifications[index][i] = 0;
              }
              columnClassifications[index][value!] = 1;
            });
          },
        ),
        Text(label),
      ],
    );
  }
}
