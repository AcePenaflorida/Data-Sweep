import 'package:data_sweep/selection_page.dart';
import 'package:flutter/material.dart';
import 'preview_page.dart';

class ClassificationPage extends StatefulWidget {
  final List<List<dynamic>> csvData;
  final String fileName;

  ClassificationPage({
    required this.csvData,
    required this.fileName,
  });

  @override
  _ClassificationPageState createState() =>
      _ClassificationPageState(); //testing merge temp
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
    columnCasingSelections =
        List.generate(columns.length, (index) => "UPPERCASE");
    columnDateFormats = List.generate(columns.length, (index) => "mm/dd/yyyy");
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
      backgroundColor: const Color.fromARGB(255, 229, 234, 222),
      appBar: AppBar(
        title: const Text(
          "Classification",
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(0),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 126, 173, 128),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.description,
                                size: 40,
                                color: const Color.fromARGB(255, 17, 17, 17),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Preview File', // Display the file name
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Roboto',
                                      color: Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.remove_red_eye,
                          size: 28,
                          color: Color.fromARGB(255, 0, 0, 0),
                        ),
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
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 1.0),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: "Next step,",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.normal,
                          color: Colors.black,
                        ),
                      ),
                      TextSpan(
                        text:
                            " let's classify your data to detect and analyze issues.",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 0),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 1, // Control space between columns
                  columns: [
                    DataColumn(
                      label: Text(
                        "Column",
                        style: TextStyle(
                          fontSize: 12.0,
                          color: const Color.fromARGB(255, 61, 126, 64),
                        ),
                        softWrap: true,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DataColumn(
                      label: InkWell(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                              minWidth: 70), // Adjust width if necessary
                          child: Text(
                            "Numerical",
                            style: TextStyle(
                              fontSize: 12.0,
                              color: const Color.fromARGB(255, 61, 126, 64),
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
                          constraints: BoxConstraints(minWidth: 70),
                          child: Text(
                            "Categorical",
                            style: TextStyle(
                              fontSize: 12.0,
                              color: const Color.fromARGB(255, 61, 126, 64),
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
                          constraints:
                              BoxConstraints(minWidth: 30, maxWidth: 64),
                          child: Text(
                            "Non-Categorical",
                            style: TextStyle(
                              fontSize: 12.0,
                              color: const Color.fromARGB(255, 61, 126, 64),
                            ),
                            softWrap: true,
                            maxLines: 2,
                            textAlign: TextAlign.center,
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
                            "  Date",
                            style: TextStyle(
                              fontSize: 12.0,
                              color: const Color.fromARGB(255, 61, 126, 64),
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
                              maxWidth: 100), // Set max width for text wrapping
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
                      const Divider(
                        color: Color.fromARGB(255, 200, 200, 200),
                        thickness: 1,
                        indent: 8,
                        endIndent: 3,
                        height:
                            0, // Set height of the Divider to 0 to reduce spacing
                      ),
                      if (columnClassifications[index][1] == 1 ||
                          columnClassifications[index][2] == 1)
                        Row(
                          children: [
                            Flexible(
                                child: Text(
                                    "Letter Casing:  ${columns[index]}: ")),
                            SizedBox(width: 16.0),
                            Flexible(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                hint: Text("Select casing"),
                                value: columnCasingSelections[index].isNotEmpty
                                    ? columnCasingSelections[index]
                                    : null,
                                dropdownColor:
                                    const Color.fromARGB(255, 229, 234, 222),
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
                                    columnCasingSelections[index] =
                                        value ?? "UPPERCASE";
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
                                    Text("Date Format: ${columns[index]}: ")),
                            SizedBox(width: 16.0),
                            Flexible(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                hint: Text("Select format"),
                                value: columnDateFormats[index].isNotEmpty
                                    ? columnDateFormats[index]
                                    : null,
                                dropdownColor:
                                    const Color.fromARGB(255, 229, 234, 222),
                                items: [
                                  DropdownMenuItem(
                                      value: "mm/dd/yyyy",
                                      child: Text("mm/dd/yyyy")),
                                  DropdownMenuItem(
                                      value: "dd/mm/yyyy",
                                      child: Text("dd/mm/yyyy")),
                                  DropdownMenuItem(
                                      value: "yyyy/mm/dd",
                                      child: Text("yyyy/mm/dd")),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    columnDateFormats[index] =
                                        value ?? "mm/dd/yyyy";
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      const Divider(
                        color: Color.fromARGB(255, 200, 200, 200),
                        thickness: 1,
                        indent: 8,
                        endIndent: 3,
                        height:
                            0, // Set height of the Divider to 0 to reduce spacing
                      ),
                    ],
                  );
                }),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 0),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 61, 126, 64),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: GestureDetector(
                        onTap: () {
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
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  title: Text(
                                    "Incomplete Classification",
                                    style: TextStyle(
                                      color: Color.fromARGB(255, 61, 126, 64),
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  content: Text(
                                    "Please select a classification for each column.",
                                    style: TextStyle(fontSize: 14.0),
                                    textAlign: TextAlign.center,
                                  ),
                                  actions: [
                                    Center(
                                      child: TextButton(
                                        style: TextButton.styleFrom(
                                          backgroundColor:
                                              Color.fromARGB(255, 61, 126, 64),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(6.0),
                                          ),
                                        ),
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: Text(
                                          "OK",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
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
                                  content: Text(
                                      "Please complete all dropdown selections."),
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
                              print(
                                  "Classification: ${columnClassifications[i]}");
                              print(
                                  "Casing Selection: ${columnCasingSelections[i]}");
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
                                  classificationText +=
                                      " - ${columnDateFormats[index]}";
                                }
                                return classificationText;
                              });
                            });
                            print(columnDateFormats);
                            print("CATEGORY TO ISSUE: ${columns}");

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SelectionPages(
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
                        child: const Text(
                          "Submit Classification",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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
      activeColor: const Color.fromARGB(
          255, 61, 126, 64), // Set the color of the selected radio button
    );
  }
}
