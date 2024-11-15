import 'package:flutter/material.dart';

class OutliersPage extends StatelessWidget {
  final List<List<dynamic>> csvData;
  final List<String> columns;
  final List<List<int>> classifications;

  OutliersPage({
    required this.csvData, //buong data set
    required this.columns, //
    required this.classifications,
  });

  List<String> getNumericalColumns() {
    List<String> numericalColumns = [];
    for (int i = 0; i < classifications.length; i++) {
      if (classifications[i][0] == 1) {
        numericalColumns.add(columns[i]);
      }
    }
    return numericalColumns;
  }

  @override
  Widget build(BuildContext context) {
    print("Outliers/CSV Data: $csvData");
    print("Outliers/Columns: $columns");
    print("Outliers/Classifications: $classifications");

    List<String> numericalColumns = getNumericalColumns();
    print("Numerical Columns: $numericalColumns");

    return Scaffold(
      appBar: AppBar(title: Text("Outliers")),
      body: Center(
        child: Text(
          "Hello Ace, Check the debug console for received data. Detected Numerical Columns: ${numericalColumns.join(", ")}",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13),
        ),
      ),
    );
  }
}
