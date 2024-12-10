import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ExpectoPatronum/main.dart';

import '../Service/checkLogout.dart';
import '../Service/fetch_user_profile.dart';
import 'package:ExpectoPatronum/user.dart';

class pro_file extends StatefulWidget {
  final String email;

  const pro_file({Key? key, required this.email}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<pro_file> {
  @override
  void initState() {
    super.initState();
    fetchUserProfile();
    User.checkLoginStatus();
    checkToken(context);
  }

  Future<void> updateUserProfile(String field, String value) async {
    // ตรวจสอบว่าฟิลด์ไม่ใช่ token และค่าว่าง
    if (value.isEmpty && field != 'token') {
      await showPopup('Error: $field cannot be empty!');
      return; // ยกเลิกการอัปเดต
    }

    // ตรวจสอบว่าค่าในฟิลด์ phone เป็นตัวเลขทั้งหมด
    if (field == 'phone' && !RegExp(r'^\d+$').hasMatch(value)) {
      await showPopup('Error: Phone number must contain only digits!');
      return; // ยกเลิกการอัปเดต
    }

    // ดำเนินการอัปเดตโปรไฟล์หากไม่มีปัญหา
    Map<String, String?> settings = await User.getSettings();
    String? ip = settings['ip'];
    String? port = settings['port'];
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');
    String url = "http://$ip:$port/routes/update_user";

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': User.email,
        'field': field,
        'value': value,
      }),
    );

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      if (responseBody['status'] == 'success') {
        setState(() {
          switch (field) {
            case 'firstname':
              User.firstName = value;
              break;
            case 'lastname':
              User.lastName = value;
              break;
            case 'phone':
              User.phone = value;
              break;
            case 'description':
              User.description = value;
              break;
            case 'token':
              User.token = value;
              break;
          }
        });
        await showPopup('Profile updated successfully!');
      } else {
        log('Error updating profile: ${responseBody['message']}');
      }
    } else {
      log('Error updating profile: ${response.statusCode}');
    }
  }

  Future<void> _showEditDialog(String field, String currentValue) async {
    TextEditingController controller =
        TextEditingController(text: currentValue);
    bool isValid = true;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit $field'),
          content: TextField(
            controller: controller,
            keyboardType: field == 'phone'
                ? TextInputType.number
                : TextInputType
                    .text, // ตั้งค่าให้ใช้คีย์บอร์ดตัวเลขสำหรับ phone
            decoration: InputDecoration(
              labelText: field,
              errorText: isValid ? null : 'This field cannot be empty',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  // ตรวจสอบว่า phone เป็นตัวเลข
                  if (field == 'phone' &&
                      !RegExp(r'^\d+$').hasMatch(controller.text)) {
                    showPopup('Error: กรอกเฉพาะตัวเลขเท่านั้น!');
                    isValid = false;
                  }
                  // ตรวจสอบว่า ชื่อและนามสกุลมีแต่ตัวอักษร (ไทยหรืออังกฤษ)
                  else if ((field == 'firstname' || field == 'lastname') &&
                      !RegExp(r'^[a-zA-Zก-๙\s]+$').hasMatch(controller.text)) {
                    showPopup(
                        'Error: ชื่อและนามสกุลต้องประกอบด้วยตัวอักษรเท่านั้น!');
                    isValid = false;
                  }
                  // ตรวจสอบว่าค่าว่าง (ยกเว้น token)
                  else if (controller.text.isEmpty && field != 'token') {
                    isValid = false;
                    showPopup('Error: $field cannot be empty!');
                  } else {
                    isValid = true;
                  }
                });

                if (isValid) {
                  Navigator.pop(context);
                  updateUserProfile(field, controller.text);
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget buildProfileCard(
    String title,
    String value,
    String field,
    IconData icon,
  ) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(icon, color: Colors.blueAccent),
        title: Text(
          title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(value),
        trailing: IconButton(
          icon: Icon(Icons.edit, color: Colors.blueAccent),
          onPressed: () => _showEditDialog(field, value),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // ป้องกันการกดย้อนกลับ
  onPopInvokedWithResult: (didPop, result) {
  },
    
    child:  Scaffold(
      appBar: AppBar(
        title: Text('User Profile'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildProfileCard(
              'First Name',
              User.firstName,
              'firstname',
              Icons.person,
            ),
            buildProfileCard(
              'Last Name',
              User.lastName,
              'lastname',
              Icons.person_outline,
            ),
            buildProfileCard(
              'Phone',
              User.phone,
              'phone',
              Icons.phone,
            ),
            buildProfileCard(
              'Description',
              User.description,
              'description',
              Icons.description,
            ),
            buildProfileCard(
              'TokenLine',
              User.token,
              'token',
              Icons.token,
            ),
            // No edit button for email
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Icon(Icons.email, color: Colors.blueAccent),
                title: Text(
                  'Email',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(User.email),
              ),
            ),
          ],
        ),
      ),
    )
    );
  }

  Future<void> showPopup(String message) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: Row(
            children: [
              Icon(Icons.notification_important, color: Colors.blue),
              SizedBox(width: 8),
              Text('แจ้งเตือน', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            // เพิ่ม SingleChildScrollView
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                message,
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'OK',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        );
      },
    );
  }
}
