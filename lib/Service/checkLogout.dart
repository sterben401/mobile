import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../user.dart';

Future<void> checkToken(BuildContext context) async {
  Map<String, String?> settings = await User.getSettings();
  String? ip = settings['ip'];
  String? port = settings['port'];
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('jwt_token');

  final url = Uri.parse('http://$ip:$port/routes/checkToken/checkToken');
  final response = await http.post(
    url,
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    // Token is valid
    final jsonResponse = json.decode(response.body);
    print('Response checkToken: ${jsonResponse['message']}');
  } else if (response.statusCode == 401) {
    // Token has expired
    final jsonResponse = json.decode(response.body);

    print('Error checkToken: ${jsonResponse['message']}');
  } else {
    // Other errors
    final jsonResponse = json.decode(response.body);
    await showPopup(context, "เซสชัน หมดอายุกรุณา Login ใหม่");
    await logout(context);// Decode the response for other errors
    print('Error: ${jsonResponse['message']}');  // Print detailed error message
  }
}
Future<void> logout(BuildContext context) async {
  await User.setsigin(false);
  await User.setEmail('');
  FlutterBackgroundService().invoke('stopService');
  Navigator.pushNamed(context, 'login');
}

Future<void> showPopup(BuildContext context, String message) async {
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
