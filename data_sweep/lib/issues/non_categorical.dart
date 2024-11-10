import 'package:flutter/material.dart';

class NonCategoricalPage extends StatelessWidget {
  final String columnName;
  final List<String> issues;

  NonCategoricalPage({required this.columnName, required this.issues});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Non-Categorical Issues in $columnName")),
      body: Column(
        children: [
          // Display the column name at the top of the page
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Issues found in column: $columnName',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          // Display the issues in a ListView
          Expanded(
            child: ListView.builder(
              itemCount: issues.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(issues[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
