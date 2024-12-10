import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'delete_column_page.dart'; // Make sure this is handling different file types
import 'dart:ui'; // Make sure to import dart:ui

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Data Sweep',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "DATA SWEEP",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 28,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 61, 126, 64),
        automaticallyImplyLeading: false, 
      ),
      body: Container(
        color: const Color.fromARGB(255, 212, 216, 207),
        padding: EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Welcome to Data Sweep!",
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Click here to upload your dataset\nand to start cleaning.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 24),
              GestureDetector(
                onTap: () async {
                  FilePickerResult? result =
                      await FilePicker.platform.pickFiles(type: FileType.any);

                  if (result != null) {
                    String filePath = result.files.single.path!;
                    String fileExtension = filePath.split('.').last;

                    if (fileExtension == 'csv') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DeleteColumnPage(filePath: filePath),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Unsupported file type: $fileExtension'),
                        ),
                      );
                    }
                  }
                },
                child: CustomPaint(
                  painter: DashedBorderPainter(borderRadius: 16.0), // Rounded corners
                  child: Container(
                    width: 270,
                    height: 200,
                    color: const Color.fromARGB(255, 212, 216, 207),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.upload_file, size: 40, color: Colors.black87),
                        SizedBox(height: 10),
                        Text(
                          "Upload file",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description, // File icon
                    size: 20, // Icon size
                    color: Colors.grey[700], // Match text color
                  ),
                  SizedBox(width: 6), // Small space between icon and text
                  Text(
                    "supported formats: CSV, XLSX, TSV",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ], // Closing the children list of Column
          ),
        ),
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final double borderRadius; // Allow customizable border radius

  DashedBorderPainter({this.borderRadius = 12.0}); // Default border radius

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = const Color.fromARGB(137, 0, 0, 0)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    double dashWidth = 14;
    double dashSpace = 8;

    // Define the rounded rectangle with border radius
    final RRect roundedRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    // Create the path for the rounded rectangle
    final Path path = Path()..addRRect(roundedRect);

    // Get the path metrics for the rounded rectangle
    final PathMetrics pathMetrics = path.computeMetrics();
    for (final PathMetric pathMetric in pathMetrics) {
      double distance = 0;

      // Draw dashes along the path
      while (distance < pathMetric.length) {
        final Path segment = pathMetric.extractPath(
          distance,
          distance + dashWidth,
        );
        canvas.drawPath(segment, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
