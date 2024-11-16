import 'package:data_sweep/outliers.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'delete_column_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Data Sweep',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Data Sweep")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/Grizz.jpg',
              height: 150.0,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                    type: FileType.custom, allowedExtensions: ['csv']);
                if (result != null) {
                  String filePath = result.files.single.path!;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            DeleteColumnPage(filePath: filePath)),
                  );
                }
              },
              child: Text("Upload CSV File"),
            ),
          ],
        ),
      ),
    );
  }
}
