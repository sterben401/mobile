import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

import '../Service/checkLogout.dart';
import '../Service/fetch_user_profile.dart';
import '../user.dart';
import 'settings.dart';

class FileContentPage extends StatefulWidget {
  final String filePath;

  const FileContentPage({Key? key, required this.filePath}) : super(key: key);

  @override
  _FileContentPageState createState() => _FileContentPageState();
}

class _FileContentPageState extends State<FileContentPage> {
  String fileContent = '';
  bool isLoading = true;
  bool isError = false;
  List<List<Record>> pages = [];
  int recordsPerPage = 5; // จำนวน Records ต่อหน้า

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
    checkToken(context);

    if (widget.filePath.isNotEmpty) {
      _fetchFileContent();
    } else {
      setState(() {
        isError = true;
        isLoading = false;
      });
    }
  }

  Future<void> _fetchFileContent() async {
    Map<String, String?> settings = await User.getSettings();
    String? ip = settings['ip'];
    String? port = settings['port'];
       SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('jwt_token');
    final encodedFilePath = Uri.encodeComponent(widget.filePath);
    var url = Uri.parse("http://$ip:$port/routes/readfile/file-content/$encodedFilePath");

    try {
   var response = await http.get(url,
       headers: {
        'Authorization': 'Bearer $token',
      
      },);

      if (response.statusCode == 200) {
        setState(() {
          fileContent = response.body;
          isLoading = false;
          pages = _parseFileContent(fileContent);
        });
      } else {
        setState(() {
          isError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isError = true;
        isLoading = false;
      });
    }
  }

  Color getRandomColor() {
    Random random = Random();
    Color randomColor;

    do {
      randomColor = Color.fromRGBO(
        random.nextInt(256), // สุ่มค่า R
        random.nextInt(256), // สุ่มค่า G
        random.nextInt(256), // สุ่มค่า B
        1, // ค่า opacity เป็น 1 หรือ 100% ความทึบแสง
      );
    } while (randomColor == Colors.black || randomColor == Colors.white);

    return randomColor;
  }

  @override
  Widget build(BuildContext context) {
   return  Scaffold(
      appBar: AppBar(
        title: Text('File Content'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : isError
              ? Center(child: Text('Failed to load file content.'))
              : PageView.builder(
                  itemCount: pages.length,
                  itemBuilder: (context, pageIndex) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ListView.builder(
                        itemCount: pages[pageIndex].length,
                        itemBuilder: (context, recordIndex) {
                          Record record = pages[pageIndex][recordIndex];
                          return Card(
                            elevation: 3,
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Date
                                  Text(
                                    'Date: ${record.date}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  // Type
                                  Text(
                                    'Type: ${record.type}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: record.typeColor,
                                    ),
                                  ),
                                  // Pattern
                                  Text(
                                    '${record.pattern}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  // Additional Content (ถ้ามี)
                                  if (record.additionalContent.isNotEmpty)
                                    Text(
                                      record.additionalContent,
                                      style: TextStyle(fontSize: 14),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
    
  }

  List<List<Record>> _parseFileContent(String content) {
    List<String> lines = content.split('\n');
    List<Record> records = [];
    Record? currentRecord;

    for (var line in lines) {
      if (RegExp(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$').hasMatch(line)) {
        // เริ่มต้น Record ใหม่เมื่อพบบรรทัดที่เป็นวันที่และเวลา
        if (currentRecord != null) {
          records.add(currentRecord);
        }
        currentRecord = Record(date: line, type: '', pattern: '', additionalContent: '');
      } else if (line.startsWith('Type :') && currentRecord != null) {
        currentRecord.type = line.substring(5).trim();
        currentRecord.typeColor = getRandomColor();
      } else if (line.startsWith('Pattern :') && currentRecord != null) {
        currentRecord.pattern = line.substring(8).trim();
      } else if (line.isNotEmpty && currentRecord != null) {
        // เพิ่มข้อมูลเพิ่มเติมถ้ามี
        currentRecord.additionalContent += line + '\n';
      }
    }

    // เพิ่ม Record สุดท้ายถ้ามี
    if (currentRecord != null) {
      records.add(currentRecord);
    }

    // แบ่ง Records เป็นหน้าๆ
    List<List<Record>> pages = [];
    for (int i = 0; i < records.length; i += recordsPerPage) {
      int end = (i + recordsPerPage < records.length) ? i + recordsPerPage : records.length;
      pages.add(records.sublist(i, end));
    }

    return pages;
  }
}

class Record {
  String date;
  String type;
  String pattern;
  String additionalContent;
  Color typeColor;

  Record({
    required this.date,
    required this.type,
    required this.pattern,
    required this.additionalContent,
    this.typeColor = Colors.black, // ค่าเริ่มต้นสีสำหรับ Type
  });
}