import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ExpectoPatronum/check_login.dart';
import 'package:ExpectoPatronum/home.dart';
import 'package:ExpectoPatronum/screen/readfile.dart';
import 'package:ExpectoPatronum/user.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../Service/checkLogout.dart';
import '../Service/fetch_user_profile.dart';

class noti_fi extends StatefulWidget {
  const noti_fi({Key? key}) : super(key: key);

  @override
  State<noti_fi> createState() => _noti_fiState();
}

class _noti_fiState extends State<noti_fi> with TickerProviderStateMixin {
  late List<dynamic> warning = [];
  late List<dynamic> filteredWarning = [];
  late TabController _tabController;
  late TextEditingController _dateController;
  late List<String> _attackGroups = ['All']; // Default value including 'All'
  String? _selectedType = 'All'; // Default value to match dropdown options
  int currentPage = 1;
  int itemsPerPage = 5; // จำนวนรายการต่อหน้า

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController();
    checkToken(context);
    _tabController = TabController(length: 4, vsync: this);
    getAllWarning().then((_) {
      _tabController.addListener(() {
        if (_tabController.indexIsChanging) {
          filterWarnings();
        }
      });
    });
    _fetchAttackGroups();
        fetchUserProfile();

  }

  Future<void> getAllWarning() async {
    Map<String, String?> settings = await User.getSettings();
    String? ip = settings['ip'];
    String? port = settings['port'];
            SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');
    var url = Uri.parse("http://$ip:$port/routes/history/fetch_detec_history");

  var response = await http.get(url,
       headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },);

    if (response.statusCode == 200) {
      setState(() {
        var data = json.decode(response.body);
        warning = data['DetecPattern'].map((item) {
          item['date_detec'] = formatDate(item['date_detec']);
          return item;
        }).toList();
        filteredWarning = List.from(warning);
      });
    } else {
      throw Exception('Failed to load data');
    }
  }

List<dynamic> getPaginatedWarnings() {
  final startIndex = (currentPage - 1) * itemsPerPage;

  // ตรวจสอบว่า startIndex อยู่ในขอบเขตของรายการหรือไม่
  if (startIndex >= filteredWarning.length) {
    return []; // คืนค่าเป็นรายการว่างถ้าไม่มีข้อมูลในหน้าปัจจุบัน
  }

  final endIndex = startIndex + itemsPerPage;

  // ตรวจสอบว่า endIndex เกินขอบเขตของรายการหรือไม่
  return filteredWarning.sublist(
    startIndex,
    endIndex > filteredWarning.length ? filteredWarning.length : endIndex,
  );
}

  int totalPages() {
    return (filteredWarning.length / itemsPerPage).ceil();
  }

  String formatDate(String dateString) {
    try {
      DateTime dateTime = DateTime.parse(dateString);
      final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
      return formatter.format(dateTime.toLocal());
    } catch (e) {
      print('Error parsing date: $e');
      return 'Invalid date';
    }
  }

   Future<void> deleteHistory(int historyId) async {
       Map<String, String?> settings = await User.getSettings();
  String? ip = settings['ip'];
  String? port = settings['port'];
           SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');
    try {
      var response = await http.delete(
        Uri.parse("http://$ip:$port/routes/deleteHistory"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'},
        body: jsonEncode({'id': historyId}),
      );

      if (response.statusCode == 200) {
        setState(() {
          filteredWarning.removeWhere((warning) => warning['id'] == historyId);
        });
      } else {
        throw Exception('Failed to delete history');
      }
    } catch (e) {
      print('Error: $e');
      throw Exception('Failed to delete history: $e');
    }
  }

 Future<void> _fetchAttackGroups() async {
    Map<String, String?> settings = await User.getSettings();
    String? ip = settings['ip'];
    String? port = settings['port'];
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');

 String url = "http://$ip:$port/routes/setThreshold/fetch_group";
    try {
      final response = await http.get(
        Uri.parse(url),
         headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      );
          if (response.statusCode == 200) {
      setState(() {
        var groups = json.decode(response.body)['AttackGroup'];
        List<String> fetchedGroups =
            groups.map<String>((group) => group['name'] as String).toList();
        _attackGroups = ['All'] + fetchedGroups;

        if (!_attackGroups.contains(_selectedType)) {
          _selectedType = 'All';
        }
      });
    } else {
      print('Failed to load attack groups');
    }
    }catch (e){
        print('Error: $e');
     print('Failed to load data');

    }
  
  }


  Future<void> _showDatePicker(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2010),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        _dateController.text = _formattedDate(pickedDate);
      });
      filterWarnings();
    }
  }

  String _formattedDate(DateTime date) {
    return "${date.year}-${_twoDigits(date.month)}-${_twoDigits(date.day)}";
  }

  String _twoDigits(int n) {
    if (n >= 10) return "$n";
    return "0$n";
  }

  void filterWarnings() {
    setState(() {
      filteredWarning = List.from(warning);

      switch (_tabController.index) {
        case 0:
          break;
        case 1:
          filteredWarning =
              filteredWarning.where((warning) => warning['status'] == 'GREEN').toList();
          break;
        case 2:
          filteredWarning =
              filteredWarning.where((warning) => warning['status'] == 'ORANGE').toList();
          break;
        case 3:
          filteredWarning =
              filteredWarning.where((warning) => warning['status'] == 'RED').toList();
          break;
      }

      if (_dateController.text.isNotEmpty) {
        filteredWarning = filteredWarning
            .where((warning) => warning['date_detec'].contains(_dateController.text))
            .toList();
      }

      if (_selectedType != 'All') {
        filteredWarning =
            filteredWarning.where((warning) => warning['type'] == _selectedType).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // ป้องกันการกดย้อนกลับ
  onPopInvokedWithResult: (didPop, result) {
  }, 
    
    child:  Scaffold(
      appBar: AppBar(
        title: const Text('History'),
         automaticallyImplyLeading: false, // ปิดการแสดงปุ่มลูกศรย้อนกลับ
        backgroundColor: Colors.blue,

        actions: [
          IconButton(
            onPressed: () async {
              await _showDatePicker(context);
            },
            icon: const Icon(Icons.calendar_today),
          ),
          DropdownButton<String>(
            value: _selectedType,
            onChanged: (String? newValue) {
              setState(() {
                _selectedType = newValue;
                filterWarnings();
              });
            },
            items: _attackGroups.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Green'),
            Tab(text: 'Orange'),
            Tab(text: 'Red'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: buildWarningList(getPaginatedWarnings()),
          ),
          buildPaginationControls(),
        ],
      ),
    )
    );
  }

Widget buildWarningList(List<dynamic> warnings) {
  if (warnings.isEmpty) {
    return Center(
      child: Text(
        'No History found',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  return ListView.builder(
    itemCount: warnings.length,
    itemBuilder: (context, index) {
      return Card(
        elevation: 6,
        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListTile(
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: getColorForStatus(warnings[index]['status']),
              child: Icon(
                getIconForStatus(warnings[index]['status']),
                color: Colors.white,
                size: 32,
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Type: ${warnings[index]['type']}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4), // เพิ่มช่องว่างระหว่าง Text
                Text(
                  "Count: ${warnings[index]['count']}",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  "Status: ${warnings[index]['status']}",
                  style: TextStyle(
                    fontSize: 14,
                    color: getColorForStatus(warnings[index]['status']),
                  ),
                ),
                Text(
                  "Date Detected: ${warnings[index]['date_detec']}",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Confirm Deletion'),
                    content: Text(
                      'Are you sure you want to delete this history?',
                      style: TextStyle(fontSize: 16),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          deleteHistory(warnings[index]['id']);
                        },
                        child: Text(
                          'Delete',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            onTap: () {
              final filePath = warnings[index]['id'].toString();
              if (filePath.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FileContentPage(filePath: filePath),
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
  );
}

  IconData getIconForStatus(String status) {
  switch (status) {
    case 'GREEN':
      return Icons.check_circle_outline;
    case 'ORANGE':
      return Icons.warning_amber_outlined;
    case 'RED':
      return Icons.dangerous_outlined;
    default:
      return Icons.help_outline;
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

// Function to show file content dialog
void _showFileContentDialog( String filePath) async {
  print('File Path: $filePath');

  final encodedFilePath = Uri.encodeComponent(filePath);

  var url = Uri.parse(
      "http://192.168.1.104:3001/readfile/file-content/$encodedFilePath");
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
                    .split('\n\n\n') // Split the formatted content by double new lines
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


  Widget buildPaginationControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: currentPage > 1
              ? () {
                  setState(() {
                    currentPage--;
                  });
                }
              : null,
          icon: Icon(Icons.arrow_back),
        ),
        Text('$currentPage of ${totalPages()}'),
        IconButton(
          onPressed: currentPage < totalPages()
              ? () {
                  setState(() {
                    currentPage++;
                  });
                }
              : null,
          icon: Icon(Icons.arrow_forward),
        ),
      ],
    );
  }
}