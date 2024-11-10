import 'package:flutter/material.dart';

class CategoricalPage extends StatefulWidget {
  final String columnName; // Column name for reference
  final List<String> categoricalData; // Data of the column
  final List<String> issues; // List of issues for this column

  CategoricalPage({
    required this.columnName,
    required this.categoricalData,
    required this.issues,
  });

  @override
  _CategoricalPageState createState() => _CategoricalPageState();
}

class _CategoricalPageState extends State<CategoricalPage> {
  late List<TextEditingController> textControllers;
  late List<String> uniqueValues;

  @override
  void initState() {
    super.initState();
    // Get unique values from the categorical data
    uniqueValues = widget.categoricalData.toSet().toList();
    // Initialize the text controllers for each unique value
    textControllers = uniqueValues.map((e) => TextEditingController()).toList();
  }

  @override
  void dispose() {
    for (var controller in textControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Standardize Categorical Values - ${widget.columnName}"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Standardize the categorical values below:"),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Table(
                  border: TableBorder.all(),
                  children: [
                    // Header row with bold styling
                    TableRow(children: [
                      TableCell(
                        child: Center(
                          child: Text(
                            "Unique Values",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      TableCell(
                        child: Center(
                          child: Text(
                            "Standardized Value",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ]),
                    // Second row (CSV column titles) with bold styling
                    TableRow(children: [
                      TableCell(
                        child: Center(
                          child: Text(
                            uniqueValues.isNotEmpty ? uniqueValues[0] : '',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      TableCell(
                        child: Center(
                          child: TextField(
                            controller: textControllers.isNotEmpty
                                ? textControllers[0]
                                : TextEditingController(),
                            decoration: InputDecoration(
                              hintText: 'Enter Standardized Value',
                              hintStyle: TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                    ]),
                    // Remaining rows without bold styling
                    ...List.generate(uniqueValues.length - 1, (index) {
                      return TableRow(children: [
                        TableCell(
                          child: Center(child: Text(uniqueValues[index + 1])),
                        ),
                        TableCell(
                          child: Center(
                            child: TextField(
                              controller: textControllers[index + 1],
                              decoration: InputDecoration(
                                hintText: 'Enter Standardized Value',
                                hintStyle: TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ),
                      ]);
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Get the standardized values entered by the user
                List<String> standardizedValues = textControllers
                    .map((controller) => controller.text)
                    .toList();

                // Handle standardized values, e.g., send back to the IssuesPage
                Navigator.pop(context, standardizedValues);
              },
              child: Text("Submit Standardized Values"),
            ),
          ],
        ),
      ),
    );
  }
}
