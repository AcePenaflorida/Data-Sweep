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
  _ClassificationPageState createState() => _ClassificationPageState();
}

class _ClassificationPageState extends State<ClassificationPage> {
  late List<String> columns;
  List<String> columnClassifications = [];
  List<String> columnFormats = [];

  @override
  void initState() {
    super.initState();
    columns = List<String>.from(widget.csvData[0]);
    columnClassifications = List.generate(columns.length, (index) => "Unclassified");
    columnFormats = List.generate(columns.length, (index) => "");
  }

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
        child: SingleChildScrollView(
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
              const SizedBox(height: 10),
              Text(
                "Classify and format columns to clean and analyze your dataset!",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,  // Set background color to white
                    border: Border.all(color: Colors.grey),  // Add gray border
                    borderRadius: BorderRadius.circular(8),  // Optional: Add rounded corners
                  ),
                  child: DataTable(
                    columnSpacing: 10,
                    columns: [
                      DataColumn(
                        label: Container(
                          width: 150,  // Set fixed width for the column
                          child: Center(child: Text("Column", textAlign: TextAlign.center)),
                        ),
                      ),
                      DataColumn(
                        label: Container(
                          width: 150,  // Set fixed width for the column
                          child: Center(child: Text("Classification", textAlign: TextAlign.center)),
                        ),
                      ),
                      DataColumn(
                        label: Container(
                          width: 150,  // Set fixed width for the column
                          child: Center(child: Text("Format", textAlign: TextAlign.center)),
                        ),
                      ),
                    ],
                    rows: List.generate(columns.length, (index) {
                      return DataRow(cells: [
                        DataCell(
                          Container(
                            width: 150,  // Set fixed width for the cell
                            child: Text(
                              columns[index],
                              overflow: TextOverflow.ellipsis,  // Truncate text with ellipsis if it's too long
                              maxLines: 1,
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            width: 150,  // Set fixed width for the cell
                            child: DropdownButton<String>(
                              value: columnClassifications[index],
                              items: [
                                "Unclassified",
                                "Numerical",
                                "Categorical",
                                "Non-Categorical",
                                "Date",
                              ].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                setState(() {
                                  columnClassifications[index] = newValue ?? "Unclassified";
                                  if (newValue == "Categorical" || newValue == "Non-Categorical") {
                                    columnFormats[index] = "UPPERCASE";
                                  } else if (newValue == "Date") {
                                    columnFormats[index] = "mm/dd/yyyy";
                                  } else {
                                    columnFormats[index] = "";
                                  }
                                });
                              },
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            width: 150,  // Set fixed width for the cell
                            child: DropdownButton<String>(
                              value: columnFormats[index].isNotEmpty ? columnFormats[index] : null,
                              items: (columnClassifications[index] == "Categorical" ||
                                      columnClassifications[index] == "Non-Categorical")
                                  ? [
                                      "UPPERCASE",
                                      "lowercase",
                                      "Sentence case",
                                      "Title Case",
                                    ].map((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList()
                                  : columnClassifications[index] == "Date"
                                      ? [
                                          "mm/dd/yyyy",
                                          "dd/mm/yyyy",
                                          "yyyy/mm/dd",
                                        ].map((String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value),
                                          );
                                        }).toList()
                                      : null,
                              onChanged: (newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    columnFormats[index] = newValue;
                                  });
                                }
                              },
                              hint: Text("Select format"),
                              disabledHint: Text("Not applicable"),
                            ),
                          ),
                        ),
                      ]);
                    }),
                  )
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      bool allClassified = columnClassifications.every((classification) =>
                          classification != "Unclassified");
                  
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
                      } else {
                        // Convert columnClassifications to List<List<int>>
                        List<List<int>> classificationsAsInt = columnClassifications
                            .map((classification) => [classification.hashCode]) // Example transformation
                            .toList();
                  
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SelectionPages(
                              csvData: widget.csvData,
                              columns: columns,
                              classifications: classificationsAsInt,
                              casingSelections: columnFormats,
                              dateFormats: columnFormats,
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 61, 126, 64),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Submit Classification",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Roboto',
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}