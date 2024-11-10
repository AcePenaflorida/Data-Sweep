import 'package:flutter/material.dart';

class DateIssuePage extends StatelessWidget {
  final String columnName;
  final List<String> issues;

  DateIssuePage({required this.columnName, required this.issues});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Date Issues in $columnName")),
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
