import 'dart:io';
import 'dart:ui';

import 'package:csv/csv.dart';
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
      debugShowCheckedModeBanner: false,
      title: 'Data Sweep',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 100),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "DATA SWEEP",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 61, 126, 64),
        centerTitle: true,
      ),
      body: Container(
        color: const Color.fromARGB(255, 229, 234, 222),
        padding: EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Welcome to Data Sweep!",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Click here to upload your dataset\nand to start cleaning.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 20),
              Stack(
                children: [
                  CustomPaint(
                    painter: DashedBorderPainter(borderRadius: 12.0),
                    child: Container(
                      width: 200, // Adjusted size
                      height: 140,
                      color: Colors.transparent,
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTapDown: (_) {
                        _scaleController.forward();
                      },
                      onTapUp: (_) {
                        _scaleController.reverse();
                      },
                      onTap: () async {
                        FilePickerResult? result = await FilePicker.platform
                            .pickFiles(type: FileType.any);

                        if (result != null) {
                          String filePath = result.files.single.path!;
                          String fileExtension = filePath.split('.').last;
                          await checkCSV(context, filePath, fileExtension);
                        }
                      },
                      splashColor: Colors.green.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          width: 200, // Adjusted size
                          height: 140,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.upload_file,
                                  size: 36, color: Colors.black87),
                              SizedBox(height: 8),
                              Text(
                                "Upload file",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description,
                    size: 18,
                    color: Colors.grey[700],
                  ),
                  SizedBox(width: 6),
                  Text(
                    "supported formats: CSV only",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final double borderRadius;

  DashedBorderPainter({this.borderRadius = 12.0});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = const Color.fromARGB(137, 0, 0, 0)
      ..strokeWidth = 2 // Smaller border
      ..style = PaintingStyle.stroke;

    double dashWidth = 10;
    double dashSpace = 6;

    final RRect roundedRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final Path path = Path()..addRRect(roundedRect);
    final PathMetrics pathMetrics = path.computeMetrics();
    for (final PathMetric pathMetric in pathMetrics) {
      double distance = 0;

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


Future<void> checkCSV(BuildContext context, String filePath, String fileExtension) async {
  try {
    // Check if the file exists
    final file = File(filePath);
    if (!await file.exists()) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            title: Text(
              "File Not Found",
              style: TextStyle(
                color: Color.fromARGB(255, 61, 126, 64),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            content: Text(
              "The file was not found. Please check the file path.",
              style: TextStyle(fontSize: 14.0),
              textAlign: TextAlign.center,
            ),
            actions: [
              Center(
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 61, 126, 64),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6.0),
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
      return;
    }

    // Check if the file is a CSV by its extension
    if (!filePath.endsWith('.csv')) {
       ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Unsupported file type: $fileExtension'),
          ),
        );
    }
    

    // Read the contents of the CSV file
    final content = await file.readAsString();

    // Parse the CSV content
    final csvData = CsvToListConverter().convert(content);

    // Check if the CSV is completely empty
    if (csvData.isEmpty) {
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
              "The CSV file is completely empty. Please check the file content.",
              style: TextStyle(fontSize: 14.0),
              textAlign: TextAlign.center,
            ),
            actions: [
              Center(
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 61, 126, 64),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6.0),
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
      return;
    }

     if (csvData.length <= 1 || (csvData.length == 1 && csvData.first.every((element) => element == null || element.toString().trim().isEmpty))) {
    // Show a dialog if the CSV file is empty or only contains headers
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
              "The CSV file has no rows of data. Please check the file.",
              style: TextStyle(fontSize: 14.0),
              textAlign: TextAlign.center,
            ),
            actions: [
              Center(
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 61, 126, 64),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6.0),
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
      return;
    }else{
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              DeleteColumnPage(filePath: filePath),
        ),
      );
    }
  } catch (e) {
    print("Error reading CSV");
  }
}


