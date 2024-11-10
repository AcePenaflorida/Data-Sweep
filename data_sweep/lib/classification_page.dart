import 'package:data_sweep/main.dart';
import 'package:flutter/material.dart';
import 'issues_page.dart';
import 'preview_page.dart';

class ClassificationPage extends StatefulWidget {
  final List<List<dynamic>> csvData;
  final String fileName;

  ClassificationPage({
    required this.csvData,
    required this.fileName,
  });

  @override
  _ClassificationPageState createState() => _ClassificationPageState();
}

class _ClassificationPageState extends State<ClassificationPage> {
  late List<String> columns;
  List<List<int>> columnClassifications = [];
  List<String> selectedClassifications = [];
  List<String> columnCasingSelections = [];
  List<String> columnDateFormats = [];

  @override
  void initState() {
    super.initState();
    columns = List<String>.from(widget.csvData[0]);
    columnClassifications =
        List.generate(columns.length, (index) => [0, 0, 0, 0]);
    columnCasingSelections = List.generate(columns.length, (index) => "");
    columnDateFormats = List.generate(columns.length, (index) => "");
  }

  String getClassificationText(int index) {
    print(
        "Column Classification for index $index: ${columnClassifications[index]}"); // Debugging line
    if (columnClassifications[index][0] == 1) return "Numerical";
    if (columnClassifications[index][1] == 1) return "Categorical";
    if (columnClassifications[index][2] == 1) return "Non-Categorical";
    if (columnClassifications[index][3] == 1) return "Date";
    return "Unclassified";
  }

  void showCategoryDescription(String category) {
    String description;
    switch (category) {
      case "Numerical":
        description =
            "Numerical columns contain numbers only. Example: Age, Salary.";
        break;
      case "Categorical":
        description =
            "Categorical columns contain discrete categories. With choices. Example: Gender, Country.";
        break;
      case "Non-Categorical":
        description =
            "Non-Categorical columns contain free-form text. Example: Name, comments.";
        break;
      case "Date":
        description = "Date columns contain date values. Example: 01/01/2023.";
        break;
      default:
        description = "No description available.";
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(category),
          content: Text(description),
          actions: <Widget>[
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Data Sweep"),
        leading: IconButton(
          icon: Icon(Icons.cancel),
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text("Are you sure you want to cancel?"),
                  actions: <Widget>[
                    TextButton(
                      child: Text("Yes"),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => HomePage()),
                          (Route<dynamic> route) => false,
                        );
                      },
                    ),
                    TextButton(
                      child: Text("No"),
                      onPressed: () {
                        Navigator.pop(context);
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Uploaded file: ${widget.fileName}"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PreviewPage(
                      csvData: widget.csvData,
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
            Text("Classify columns to clean and analyze your dataset!"),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 10, // Control space between columns
                columns: [
                  DataColumn(label: Text("")),
                  DataColumn(
                    label: InkWell(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                            maxWidth: 100), // Adjust width if necessary
                        child: Text(
                          "Numerical",
                          style: TextStyle(
                            fontSize: 12.0,
                            decoration: TextDecoration.underline,
                            color: Colors.blue,
                          ),
                          softWrap: true,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      onTap: () => showCategoryDescription("Numerical"),
                    ),
                  ),
                  DataColumn(
                    label: InkWell(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 100),
                        child: Text(
                          "Categorical",
                          style: TextStyle(
                            fontSize: 12.0,
                            decoration: TextDecoration.underline,
                            color: Colors.blue,
                          ),
                          softWrap: true,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      onTap: () => showCategoryDescription("Categorical"),
                    ),
                  ),
                  DataColumn(
                    label: InkWell(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 100),
                        child: Text(
                          "Non-Categorical",
                          style: TextStyle(
                            fontSize: 12.0,
                            decoration: TextDecoration.underline,
                            color: Colors.blue,
                          ),
                          softWrap: true,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      onTap: () => showCategoryDescription("Non-Categorical"),
                    ),
                  ),
                  DataColumn(
                    label: InkWell(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 100),
                        child: Text(
                          "Date",
                          style: TextStyle(
                            fontSize: 12.0,
                            decoration: TextDecoration.underline,
                            color: Colors.blue,
                          ),
                          softWrap: true,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      onTap: () => showCategoryDescription("Date"),
                    ),
                  ),
                ],
                rows: List.generate(columns.length, (index) {
                  return DataRow(cells: [
                    DataCell(
                      ConstrainedBox(
                        constraints: BoxConstraints(
                            maxWidth: 50), // Set max width for text wrapping
                        child: Text(
                          columns[index], // Dynamically set column title
                          style: TextStyle(fontSize: 12.0),
                          softWrap: true, // Enable text wrapping
                          maxLines: 2, // Allow up to 2 lines
                          overflow: TextOverflow
                              .ellipsis, // Use ellipsis if text overflows
                        ),
                      ),
                    ),
                    DataCell(_buildRadioButton(index, 0, "Numerical")),
                    DataCell(_buildRadioButton(index, 1, "Categorical")),
                    DataCell(_buildRadioButton(index, 2, "Non-Categorical")),
                    DataCell(_buildRadioButton(index, 3, "Date")),
                  ]);
                }),
              ),
            ),
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(columns.length, (index) {
                return Column(
                  children: [
                    if (columnClassifications[index][1] == 1 ||
                        columnClassifications[index][2] == 1)
                      Row(
                        children: [
                          Flexible(
                              child: Text(
                                  "Letter casing for ${columns[index]}: ")),
                          Flexible(
                            child: DropdownButton<String>(
                              isExpanded: true,
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
                    if (columnClassifications[index][3] == 1)
                      Row(
                        children: [
                          Flexible(
                              child:
                                  Text("Date format for ${columns[index]}: ")),
                          Flexible(
                            child: DropdownButton<String>(
                              isExpanded: true,
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
            ElevatedButton(
              onPressed: () {
                bool allClassified = true;
                bool allDropdownsSelected = true;

                for (int i = 0; i < columns.length; i++) {
                  if (columnClassifications[i].indexOf(1) == -1) {
                    allClassified = false;
                    break;
                  }
                  if ((columnClassifications[i][1] == 1 ||
                          columnClassifications[i][2] == 1) &&
                      columnCasingSelections[i].isEmpty) {
                    allDropdownsSelected = false;
                    break;
                  }
                  if (columnClassifications[i][3] == 1 &&
                      columnDateFormats[i].isEmpty) {
                    allDropdownsSelected = false;
                    break;
                  }
                }

                if (!allClassified) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text("Incomplete Classification"),
                        content: Text(
                            "Please select a classification for each column."),
                        actions: [
                          TextButton(
                            child: Text("OK"),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      );
                    },
                  );
                } else if (!allDropdownsSelected) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text("Incomplete Selections"),
                        content:
                            Text("Please complete all dropdown selections."),
                        actions: [
                          TextButton(
                            child: Text("OK"),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      );
                    },
                  );
                } else {
                  // Print columns, classifications, casing selections, and date formats before updating the state
                  for (int i = 0; i < columns.length; i++) {
                    print("Column: ${columns[i]}");
                    print("Classification: ${columnClassifications[i]}");
                    print("Casing Selection: ${columnCasingSelections[i]}");
                    print("Date Format: ${columnDateFormats[i]}");
                  }

                  setState(() {
                    selectedClassifications =
                        List.generate(columns.length, (index) {
                      String classificationText =
                          '${columns[index]}: ${getClassificationText(index)}';
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

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => IssuesPage(
                        csvData: widget.csvData,
                        columns: columns,
                        classifications: columnClassifications,
                        casingSelections: columnCasingSelections,
                        dateFormats: columnDateFormats,
                      ),
                    ),
                  );
                }
              },
              child: Text("Submit Classification"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioButton(int index, int value, String category) {
    return Radio<int>(
      value: value,
      groupValue: columnClassifications[index]
          .indexOf(1), // Keep the correct value for groupValue
      onChanged: (int? newValue) {
        if (newValue != null) {
          setState(() {
            // Reset other classifications and update the selected category
            columnClassifications[index] =
                List.generate(4, (i) => i == newValue ? 1 : 0);
          });
        }
      },
    );
  }
}
