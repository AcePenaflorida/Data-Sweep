import 'dart:ui';

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

                          if (fileExtension == 'csv') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DeleteColumnPage(filePath: filePath),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Unsupported file type: $fileExtension'),
                              ),
                            );
                          }
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
