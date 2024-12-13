// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class SettingsPage extends StatefulWidget {
//   @override
//   _SettingsPageState createState() => _SettingsPageState();
// }

// class _SettingsPageState extends State<SettingsPage> {
//   final TextEditingController _urlController = TextEditingController();
//   String? _currentURL;

//   final List<String> _defaultServers = [
//     "https://data-sweep-server.onrender.com/",
//     "https://local-server.example.com/",
//     "https://backup-server.example.com/",
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _loadCurrentURL();
//   }

//   Future<void> _loadCurrentURL() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String? currentURL = prefs.getString('baseURL') ?? _defaultServers[0];
//     setState(() {
//       _currentURL = currentURL;
//       _urlController.text = currentURL;
//     });
//   }

//   Future<void> _saveNewURL() async {
//     String newURL = _urlController.text.trim();
//     if (newURL.isNotEmpty) {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       await prefs.setString('baseURL', newURL);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Server URL updated successfully!')),
//       );
//       setState(() {
//         _currentURL = newURL;
//       });
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('URL cannot be empty!')),
//       );
//     }
//   }

//   void _selectDefaultServer(String server) {
//     setState(() {
//       _urlController.text = server;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Settings"),
//         backgroundColor: const Color.fromARGB(255, 61, 126, 64),
//       ),
//       body: Padding(
//         padding: EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               "Current Server URL:",
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//             SizedBox(height: 8),
//             Text(
//               _currentURL ?? "Loading...",
//               style: TextStyle(fontSize: 14, color: Colors.black87),
//             ),
//             SizedBox(height: 20),
//             TextField(
//               controller: _urlController,
//               decoration: InputDecoration(
//                 labelText: "New Server URL",
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: _saveNewURL,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color.fromARGB(255, 61, 126, 64),
//               ),
//               child: Text("Save"),
//             ),
//             SizedBox(height: 20),
//             Text(
//               "Or select a default server:",
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//             SizedBox(height: 8),
//             Column(
//               children: _defaultServers.map((server) {
//                 return ListTile(
//                   title: Text(server),
//                   trailing: IconButton(
//                     icon: Icon(Icons.check),
//                     onPressed: () => _selectDefaultServer(server),
//                   ),
//                 );
//               }).toList(),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
