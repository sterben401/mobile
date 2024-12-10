import 'package:ExpectoPatronum/Service/line.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ExpectoPatronum/screen/readfile.dart';

import '../Service/checkLogout.dart';
import '../Service/fetch_user_profile.dart';
import '../user.dart';

class his_tory extends StatefulWidget {
  const his_tory({Key? key}) : super(key: key);

  @override
  _his_toryState createState() => _his_toryState();
}

class _his_toryState extends State<his_tory> {
  late Future<List<Map<String, dynamic>>> _notificationFuture;
  late TextEditingController _dateController;
  int currentPage = 1;
  int itemsPerPage = 5;

  @override
 void initState()  {
    super.initState();
    fetchUserProfile();
    checkToken(context);

    _notificationFuture = fetchNotifications(); // Default fetch without date
    _dateController = TextEditingController();

  }

   // ฟังก์ชันแยกสำหรับการทำงานแบบ async
 Future<bool> _onWillPop() async {
    // return false เพื่อป้องกันไม่ให้ย้อนกลับได้
    return false;
  }


  Future<List<Map<String, dynamic>>> fetchNotifications([String? date]) async {
    Map<String, String?> settings = await User.getSettings();
    String? ip = settings['ip'];
    String? port = settings['port'];
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');
    final uri = Uri.parse(
        'http://$ip:$port/routes/showNotifications/getNotifications${date != null ? '?date=$date' : ''}');
    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      try {
        var data = jsonDecode(response.body);
        print('Response data: $data');

        if (data is Map<String, dynamic> && data.containsKey('data')) {
          List<Map<String, dynamic>> notifications =
              List<Map<String, dynamic>>.from(data['data']);

          // Filter notifications to include only those with the exact date (ignoring time)
          if (date != null) {
            notifications = notifications.where((notification) {
              final notificationDate = notification['date_detec'] as String?;
              return notificationDate != null &&
                  notificationDate.startsWith(date);
            }).toList();
          }

          print('Filtered notifications: $notifications');
          return notifications;
        } else {
          print(
              'Error: Invalid data format. Expected a Map with a "data" key.');
          throw Exception('Invalid data format');
        }
      } catch (e) {
        print('Error parsing response: $e');
        throw Exception('Failed to parse notifications');
      }
    } else {
      print('Failed to load notifications: Status Code ${response.statusCode}');
      throw Exception('Failed to load notifications');
    }
  }

  IconData getIconForStatus(String status) {
    switch (status) {
      case 'GREEN':
        return Icons.check_circle;
      case 'ORANGE':
        return Icons.error_outline;
      case 'RED':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  Color getColorForStatus(String status) {
    switch (status) {
      case 'GREEN':
        return Colors.green;
      case 'ORANGE':
        return Colors.orange;
      case 'RED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // ฟังก์ชันสำหรับการแบ่งหน้า
  List<Map<String, dynamic>> getPaginatedNotifications(
      List<Map<String, dynamic>> notifications) {
    final startIndex = (currentPage - 1) * itemsPerPage;
    if (startIndex >= notifications.length) {
      return [];
    }

    final endIndex = startIndex + itemsPerPage;
    return notifications.sublist(
      startIndex,
      endIndex > notifications.length ? notifications.length : endIndex,
    );
  }

  int totalPages(List<Map<String, dynamic>> notifications) {
    return (notifications.length / itemsPerPage).ceil();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // ป้องกันการกดย้อนกลับ
  onPopInvokedWithResult: (didPop, result) {
  }, 
    
    child:  Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Notifications",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Row(
              children: [
                IconButton(
                  onPressed: () async {
                    await _showDatePicker(context);
                  },
                  icon: Icon(Icons.calendar_today, color: Colors.white),
                  tooltip: 'เลือกวันที่',
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _dateController.clear();
                      currentPage = 1;
                      _notificationFuture = fetchNotifications();
                    });
                  },
                  icon: Icon(Icons.refresh, color: Colors.white),
                  tooltip: 'รีเซ็ตการกรองวันที่',
                ),
              ],
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _notificationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            );
          } else {
            if (snapshot.data!.isEmpty) {
              return Center(
                child: Text(
                  'No notifications found.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              );
            } else {
              // คำนวณจำนวนหน้าทั้งหมด
              int totalPageCount = totalPages(snapshot.data!);
              // ดึงข้อมูลเฉพาะหน้าปัจจุบัน
              List<Map<String, dynamic>> paginatedNotifications =
                  getPaginatedNotifications(snapshot.data!);

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: paginatedNotifications.length,
                      itemBuilder: (context, index) {
                        var notification = paginatedNotifications[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(16),
                              leading: Icon(
                                getIconForStatus(notification['status'] ?? ''),
                                color: getColorForStatus(
                                    notification['status'] ?? ''),
                                size: 32,
                              ),
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Type: ${notification['type'] ?? 'N/A'}",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                      "Count: ${notification['count'] ?? 'N/A'}"),
                                  Text(
                                    "Status: ${notification['status'] ?? 'Unknown'}",
                                    style: TextStyle(
                                      color: getColorForStatus(
                                          notification['status'] ?? ''),
                                    ),
                                  ),
                                  Text(
                                      "Date Detected: ${notification['date_detec'] ?? 'Unknown'}"),
                                ],
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('Confirm Deletion',
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold)),
                                      content: Text(
                                          'Are you sure you want to delete this Notification?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: Text('Cancel',
                                              style: TextStyle(
                                                  color: Colors.grey)),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            print(
                                                "ID to delete: ${notification['id']}"); // แสดงค่า id ที่จะลบ

                                            _deleteNotification(
                                                notification); // ส่ง notification ทั้งหมดไปยังฟังก์ชัน
                                          },
                                          child: Text('Delete',
                                              style:
                                                  TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              onTap: () {
                                final filePath = notification['id'].toString();
                                if (filePath.isNotEmpty) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          FileContentPage(filePath: filePath),
                                    ),
                                  );
                                } else {
                                  print("File path is missing");
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // ระบบการแบ่งหน้า
                  buildPaginationControls(totalPageCount),
                ],
              );
            }
          }
        },
      ),
    )
    );
  }

  Widget buildPaginationControls(int totalPageCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: currentPage > 1
                ? () {
                    setState(() {
                      currentPage--;
                      _notificationFuture = fetchNotifications(
                          _dateController.text.isNotEmpty
                              ? _dateController.text
                              : null);
                    });
                  }
                : null,
            icon: Icon(Icons.arrow_back),
          ),
          Text('$currentPage of $totalPageCount'),
          IconButton(
            onPressed: currentPage < totalPageCount
                ? () {
                    setState(() {
                      currentPage++;
                      _notificationFuture = fetchNotifications(
                          _dateController.text.isNotEmpty
                              ? _dateController.text
                              : null);
                    });
                  }
                : null,
            icon: Icon(Icons.arrow_forward),
          ),
        ],
      ),
    );
  }

  void _showFileContentDialog(BuildContext context, String filePath) async {
    print('File Path: $filePath');

    final encodedFilePath = Uri.encodeComponent(filePath);
    Map<String, String?> settings = await User.getSettings();
    String? ip = settings['ip'];
    String? port = settings['port'];
    var url =
        Uri.parse("http://$ip:$port/readfile/file-content/$encodedFilePath");
    print('Request URL: $url');

    try {
      var response = await http.get(url);

      //print('File Content: ${response.body}');

      if (response.statusCode == 200) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'File Content',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            content: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: formatFileContent(response.body)
                      .split(
                          '\n\n\n') // Split the formatted content by double new lines
                      .map((section) => Container(
                            margin: const EdgeInsets.only(bottom: 8.0),
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Text(
                              section,
                              style: TextStyle(fontSize: 16),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Close',
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
              ),
            ],
          ),
        );
      } else {
        _showErrorDialog(
            context, 'Failed to load file content: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorDialog(context, 'Error: $e');
    }
  }

  String formatFileContent(String content) {
    if (content.isEmpty) {
      return 'No content available';
    }

    // Print content for debugging
    //print('Raw content:\n$content');

    // Split the content into lines
    final lines = content.split('\n');

    // Initialize variables for building formatted content
    StringBuffer formattedContent = StringBuffer();
    String date = '';
    String type = '';
    String patterns = '';

    // Define a regular expression pattern to match date lines
    final datePattern = RegExp(r'\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}');
    final typePattern = RegExp(r'Type\s*:\s*\w+');
    final patternsPattern = RegExp(r'Patterns\s*:\s*.+');

    // Iterate through each line and format accordingly
    for (var line in lines) {
      //print('Processing line: $line'); // Print each line for debugging

      if (datePattern.hasMatch(line)) {
        if (formattedContent.isNotEmpty) {
          formattedContent.writeln('\n'); // Add a new line between sections
        }
        date = line.trim();
      } else if (typePattern.hasMatch(line)) {
        type = line.trim();
      } else if (patternsPattern.hasMatch(line)) {
        patterns = line.trim();
        formattedContent
          ..writeln(date.isNotEmpty ? date : 'Date not available')
          ..writeln(type.isNotEmpty ? type : 'Type not available')
          ..writeln(patterns.isNotEmpty ? patterns : 'Patterns not available')
          ..writeln(); // Add a new line after each block
      }
    }

    // Check if content was added
    if (formattedContent.isEmpty) {
      return 'No valid data found in file content';
    }

    return formattedContent.toString();
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

Future<void> _deleteNotification(Map<String, dynamic> notification) async {
  // พิมพ์ค่า id ที่จะลบ
  print("Deleting notification with id: ${notification['id']}"); // แสดงค่า id

  Map<String, String?> settings = await User.getSettings();
  String? ip = settings['ip'];
  String? port = settings['port'];
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('jwt_token');

  final response = await http.delete(
    Uri.parse('http://$ip:$port/routes/deleteHistory/notification'),
    body: jsonEncode({'id': notification['id']}), // ส่งเฉพาะ 'id' สำหรับลบ
    headers: <String, String>{
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json; charset=UTF-8',
    },
  );

  if (response.statusCode == 200) {
    setState(() {
      _notificationFuture = fetchNotifications(_dateController.text);
    });
  } else {
    throw Exception('Failed to delete notification');
  }
}

  Future<void> _showDatePicker(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2010),
      lastDate: DateTime.now(),
    );

    print('Picked Date: $pickedDate'); // เพิ่มบรรทัดนี้

    if (pickedDate != null && mounted) {
      setState(() {
        _dateController.text = _formattedDate(pickedDate);
        _notificationFuture = fetchNotifications(_formattedDate(pickedDate));
      });
    }
  }

  String _formattedDate(DateTime date) {
    return "${date.year}-${_twoDigits(date.month)}-${_twoDigits(date.day)}";
  }

  String formatDate(String dateString) {
    try {
      // Parse the ISO 8601 date string to a DateTime object
      DateTime dateTime = DateTime.parse(dateString);

      // Format the DateTime object to the desired format
      final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
      return formatter.format(dateTime.toLocal()); // Convert to local time
    } catch (e) {
      // Handle parsing errors
      print('Error parsing date: $e');
      return 'Invalid date';
    }
  }

  String _twoDigits(int n) {
    return n >= 10 ? "$n" : "0$n";
  }
}
