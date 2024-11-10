import 'package:flutter/material.dart';

class NumericalIssuePage extends StatelessWidget {
  final String columnName;
  final List<String> issues;

  NumericalIssuePage({required this.columnName, required this.issues});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Numeric in $columnName")),
      body: ListView.builder(
        itemCount: issues.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(issues[index]),
          );
        },
      ),
    );
  }
}
