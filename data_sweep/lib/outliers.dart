import 'dart:convert';
import 'dart:typed_data';
import 'package:data_sweep/config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class OutliersPage extends StatefulWidget {
  final List<List<dynamic>> csvData;

  const OutliersPage({
    required this.csvData,
  });

  @override
  _OutliersPageState createState() => _OutliersPageState();
}

class _OutliersPageState extends State<OutliersPage> {
  late List<TextEditingController> textControllers;
  late List<String> handleOutliersOptions = ['Remove Rows', 'Cap and Floor', 'Replace with Mean', 'Replace with '];
  List<String> numericalColumns = ['Age']; // Sample data
  String outlierStatus = ""; // Resolved or Not Resolved
  bool isLoading = false;
  Uint8List? imageBytes;
  String resolve_outlier_method = "";

  @override
  void initState() {
    super.initState();
    textControllers = numericalColumns.map((e) => TextEditingController()).toList();
  }

  @override
  void dispose() {
    for (var controller in textControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void showGraphOverlay(BuildContext context, String columnName, String outlierStatus, String resolveOutlierMethod) async {
    List<List<dynamic>> data = widget.csvData;
    Map<String, dynamic> requestPayload = {};

    if (outlierStatus == "Not Resolved") {
      setState(() {
        isLoading = true;
      });

      requestPayload = {
      'data': data,
      'column_name': columnName,
      'task' : "Show Outliers",
      'method': resolveOutlierMethod,
      };

      var response = await http.post(
        Uri.parse('$baseURL/outliers_graph'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestPayload),
      );

      if (response.statusCode == 200) {
        setState(() {
          imageBytes = response.bodyBytes;
          isLoading = false;
        });
        _showImageOverlay(context, outlierStatus);
      } else {
        setState(() {
          isLoading = false;
        });
        // Handle error, maybe show a message
      }
    } else {
      setState(() {
        isLoading = true;
      });

      requestPayload = {
        'data': data,
        'column_name': columnName,
        'task' : "Resolve Outliers",
        'method': resolveOutlierMethod,
        };
      
      var response = await http.post(
        Uri.parse('$baseURL/outliers_graph'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestPayload),
      );

      if (response.statusCode == 200) {
        setState(() {
          imageBytes = response.bodyBytes;
          isLoading = false;
        });
        _showImageOverlay(context, outlierStatus);
      } else {
        setState(() {
          isLoading = false;
        });
        // Handle error, maybe show a message
      }
      print('Outlier status is resolved');
    }
  }

void _showImageOverlay(BuildContext context, String outlierStatus) {
  final overlay = Overlay.of(context);
  String graphTitle = "";
  OverlayEntry? overlayEntry;

  if(outlierStatus == "Not Resolved"){
    graphTitle = "Unresolved Outliers Graph";
  }else{
    graphTitle = "Resolved Outliers Graph";
  }

  overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: 100.0,
      left: 50.0,
      right: 50.0,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 300.0,
          height: 400.0,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(graphTitle, style: TextStyle(fontWeight: FontWeight.bold)),
              if (isLoading)
                CircularProgressIndicator()
              else
                Image.memory(imageBytes!), // Display the image from the server
              
              ElevatedButton(
                onPressed: () {
                  overlayEntry?.remove();
                },
                child: Text("Close"),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  overlay.insert(overlayEntry);
  
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Handle Outliers")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Table(
                  border: TableBorder.all(),
                  children: [
                    TableRow(
                      children: [
                        TableCell(
                          child: Center(
                            child: Text(
                              "Numerical Columns",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        TableCell(
                          child: Center(
                            child: Text(
                              "View Outliers",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        TableCell(
                          child: Center(
                            child: Text(
                              "Resolve Outliers",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        TableCell(
                          child: Center(
                            child: Text(
                              "View Resolved Outliers",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                    ...List.generate(numericalColumns.length, (index) {
                      return TableRow(
                        children: [
                          TableCell(
                            child: Center(child: Text(numericalColumns[index])),
                          ),
                          TableCell(
                            child: Center(
                              child: TextButton(
                                onPressed: () {
                                  outlierStatus = "Not Resolved";
                                  showGraphOverlay(context, numericalColumns[index], outlierStatus, "");
                                  print("Outliers Not Resolved");
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: const Color.fromARGB(255, 25, 156, 4),
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  minimumSize: Size(0, 0),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  "Graph View",
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                          TableCell(
                            child: Center(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButtonFormField<String>(
                                  items: handleOutliersOptions.map((value) {
                                    return DropdownMenuItem(
                                      value: value, 
                                      child: Text(value, style: TextStyle(fontSize: 11)),
                                    );
                                  }).toList(),
                                  onChanged: (selectedValue) {
                                    textControllers[index].text = selectedValue ?? '';


                                    if(selectedValue == handleOutliersOptions[0]){
                                      resolve_outlier_method = "Remove";
                                    }
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'Options',
                                    hintStyle: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                            ), 
                          ),
                          TableCell(
                            child: Center(
                              child: TextButton(
                                onPressed: () {
                                  outlierStatus = "Resolved";
                                  showGraphOverlay(context, numericalColumns[index], outlierStatus, resolve_outlier_method);
                                  print("Outliers Resolved");
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: const Color.fromARGB(255, 25, 156, 4),
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  minimumSize: Size(0, 0),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  "Graph View",
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}











// import 'package:flutter/material.dart';

// class OutliersPage extends StatefulWidget {
//   final List<List<dynamic>> csvData;

//   const OutliersPage({
//     required this.csvData,
//   });

//   @override
//   _OutliersPageState createState() => _OutliersPageState();
// }

// class _OutliersPageState extends State<OutliersPage> {
//   late List<TextEditingController> textControllers;
//   late List<String> handleOutliersOptions = ['Remove Rows', 'Cap and Floor'];
//   List<String> numericalColumns = ['Age', 'Salary', 'Height']; // Sample data
//   String outlierStatus = ""; // Resolved or Not Resolved

//   @override
//   void initState() {
//     super.initState();
//     textControllers = numericalColumns.map((e) => TextEditingController()).toList();
//   }

//   @override
//   void dispose() {
//     for (var controller in textControllers) {
//       controller.dispose();
//     }
//     super.dispose();
//   }

//   // Function to show graph overlay
//   void showGraphOverlay(BuildContext context, String columnName, String outlierStatus) {
//     final overlay = Overlay.of(context);
//     OverlayEntry? overlayEntry;

//     if(outlierStatus == "Resolved"){
//       print("Outliers Resolved");
//     }else{
//       print("Outliers Not Resolved");
//     }

//     overlayEntry = OverlayEntry(
//       builder: (context) => Positioned(
//         top: 100.0,
//         left: 50.0,
//         right: 50.0,
//         child: Material(
//           color: Colors.transparent,
//           child: Container (width: 300.0, height: 300.0, padding: const EdgeInsets.all(16.0),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(12),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.2),
//                   blurRadius: 8,
//                   offset: Offset(0, 4),
//                 ),
//               ],
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text("Graph View for $columnName"),
//                 Text("Display graph for outliers here..."),
//                 ElevatedButton(
//                   onPressed: () {
//                     overlayEntry?.remove();
//                   },
//                   child: Text("Close"),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//     overlay.insert(overlayEntry);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Handle Outliers")),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Expanded(
//               child: SingleChildScrollView(
//                 child: Table(
//                   border: TableBorder.all(),
//                   children: [
//                     TableRow(
//                       children: [
//                         TableCell(
//                           child: Center(
//                             child: Text("Numerical Columns", style: TextStyle(fontWeight: FontWeight.bold),),),
//                         ),
//                         TableCell(
//                           child: Center(
//                             child: Text("View Outliers", style: TextStyle(fontWeight: FontWeight.bold),),),
//                         ),
//                         TableCell(
//                           child: Center(
//                             child: Text("Resolve Outliers", style: TextStyle(fontWeight: FontWeight.bold),),),
//                         ),
//                         TableCell(
//                           child: Center(
//                             child: Text("View Resolved Outliers", style: TextStyle(fontWeight: FontWeight.bold),),),
//                         ),
//                       ],
//                     ),
                    
//                     ...List.generate(numericalColumns.length, (index) {
//                       return TableRow(
//                         children: [
//                           TableCell(
//                             child: Center(child: Text(numericalColumns[index])),
//                           ),
//                           TableCell(
//                             child: Center(
//                               child: TextButton(
//                                 onPressed: () {
//                                   outlierStatus = "Not Resolved";
//                                   showGraphOverlay(context, numericalColumns[index], outlierStatus);
//                                   print("Outliers Not Resolved");
//                                 },
//                                 style: TextButton.styleFrom(
//                                   foregroundColor: Colors.white,
//                                   backgroundColor: const Color.fromARGB(255, 25, 156, 4),
//                                   padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                                   minimumSize: Size(0, 0),
//                                   tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(8),
//                                   ),
//                                 ),
//                                 child: Text(
//                                   "Graph View",
//                                   style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
//                                 ),
//                               ),
//                             ),
//                           ),
//                           TableCell(
//                             child: Center(
//                               child: DropdownButtonHideUnderline(
//                                 child: DropdownButtonFormField<String>(
//                                   items: handleOutliersOptions.map((value) {
//                                     return DropdownMenuItem(
//                                       value: value,
//                                       child: Text(value, style: TextStyle(fontSize: 11)),
//                                     );
//                                   }).toList(),
//                                   onChanged: (selectedValue) {
//                                     textControllers[index].text = selectedValue ?? '';
//                                   },
//                                   decoration: InputDecoration(
//                                     hintText: 'Options',
//                                     hintStyle: TextStyle(fontSize: 12),
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//                           TableCell(
//                             child: Center(
//                               child: TextButton(
//                                 onPressed: () {
//                                   outlierStatus = "Resolved";
//                                   showGraphOverlay(context, numericalColumns[index], outlierStatus);
//                                   print("Outliers Resolved");
//                                 },
//                                 style: TextButton.styleFrom(
//                                   foregroundColor: Colors.white,
//                                   backgroundColor: const Color.fromARGB(255, 25, 156, 4),
//                                   padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                                   minimumSize: Size(0, 0),
//                                   tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(8),
//                                   ),
//                                 ),
//                                 child: Text(
//                                   "Graph View",
//                                   style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       );
//                     }),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }




// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:data_sweep/config.dart';


// class Outliers extends StatefulWidget{
//   final List<List<dynamic>> csvData;
//   // final String filename;
//   // final List<String> numericalColumns;

//   const Outliers({
//     required this.csvData, 
//     // required this.filename,
//     // required this.numericalColumns,
//     });

//   @override
//   _OutliersPageState createState() => _OutliersPageState();
// }

// class _OutliersPageState extends State<Outliers>{
//   late List<List<dynamic>> _reformattedDataset;
//   late List<TextEditingController> textControllers;
//   late List<String> handleOutliersOptions = ['Remove Rows', 'Cap and Floor'];
//   late List<String> viewOutliersOptions = ['Dataset', 'Graph'];
//   late List<String> numericalColumns = ['Age'];

//   @override
//     void initState() {
//       super.initState();
//       _reformattedDataset = widget.csvData;  // Initialize with the original data
//       textControllers = numericalColumns.map((e) => TextEditingController()).toList();
//     }

//     @override
//     void dispose() {
//       for (var controller in textControllers) {
//         controller.dispose();
//       }
//       super.dispose();
//     }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Handle Outliers")),
//       body: Padding(padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [

          // Expanded(
          //   child: SingleChildScrollView(
          //     child: Table(
          //       border: TableBorder.all(),
          //       children: [
          //         TableRow(children: [
          //             TableCell(
          //               child: Center(
          //                 child: Text("Numerical Columns", style: TextStyle(fontWeight: FontWeight.bold),),
          //               ),
          //             ),
          //             TableCell(
          //               child: Center(
          //                 child: Text("View Outliers",style: TextStyle(fontWeight: FontWeight.bold),),
          //               ),
          //             ),
          //             TableCell(
          //               child: Center(
          //                 child: Text("Handle Outliers",style: TextStyle(fontWeight: FontWeight.bold),),
          //               ),
          //             ),
          //             TableCell(
          //               child: Center(
          //                 child: Text("View Resolved Outliers",style: TextStyle(fontWeight: FontWeight.bold),),
          //               ),
          //             ),
          //           ]),
                
                  // ...List.generate(numericalColumns.length, (index){
                  //   return TableRow(children: [
                  //       TableCell(
                  //         child: Center(child: Text(numericalColumns[index])),
                  //       ),
                  //       TableCell(
                  //         child: Center(
                  //           child: DropdownButtonHideUnderline(
                  //             child: DropdownButtonFormField<String>(
                  //               items: viewOutliersOptions.map((value) {
                  //                 return DropdownMenuItem(
                  //                   value: value,
                  //                   child: Text(value, style: TextStyle(fontSize: 11),),
                  //                 );
                  //               }).toList(),
                  //               onChanged: (selectedValue) {
                  //                 textControllers[index].text = selectedValue ?? '';
                  //               },
                  //               decoration: InputDecoration(
                  //                 hintText: 'Options',
                  //                 hintStyle: TextStyle(fontSize: 12),
                  //               ),
                  //             ),
                  //           ),
                  //         ),
                  //       ),

//                         TableCell(
//                           child: Center(
//                             child: DropdownButtonHideUnderline(
//                               child: DropdownButtonFormField<String>(
//                                 items: handleOutliersOptions.map((value) {
//                                   return DropdownMenuItem(
//                                     value: value,
//                                     child: Text(value, style: TextStyle(fontSize: 11),),
//                                   );
//                                 }).toList(),
//                                 onChanged: (selectedValue) {
//                                   textControllers[index].text = selectedValue ?? '';
//                                 },
//                                 decoration: InputDecoration(
//                                   hintText: 'Options',
//                                   hintStyle: TextStyle(fontSize: 12),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),

//                         TableCell(
//                           child: Center(
//                             child: DropdownButtonHideUnderline(
//                               child: DropdownButtonFormField<String>(
//                                 items: viewOutliersOptions.map((value) {
//                                   return DropdownMenuItem(
//                                     value: value,
//                                     child: Text(value, style: TextStyle(fontSize: 11),),
//                                   );
//                                 }).toList(),
//                                 onChanged: (selectedValue) {
//                                   textControllers[index].text = selectedValue ?? '';
//                                 },
//                                 decoration: InputDecoration(
//                                   hintText: 'Options',
//                                   hintStyle: TextStyle(fontSize: 12),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ]);


//                   })

                
                
//                 ],
//               )
//             ),
//           )

//         ],
//       ))
//     );
//   }
// }