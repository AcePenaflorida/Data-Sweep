import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'delete_column_page.dart'; // Make sure this is handling different file types

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
                // Allow any type of file
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  type: FileType.any, // Allow any file type
                );

                if (result != null) {
                  String filePath = result.files.single.path!;

                  // You can check the file extension to handle different types
                  String fileExtension = filePath.split('.').last;

                  if (fileExtension == 'csv') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              DeleteColumnPage(filePath: filePath)),
                    );
                  } else {
                    // Handle other file types here
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('Selected file is of type: $fileExtension')),
                    );
                    // You can add more logic to process non-CSV files
                  }
                }
              },
              child: Text("Upload File"),
            ),
          ],
        ),
      ),
    );
  }
}
