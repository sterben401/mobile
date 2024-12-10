

import 'package:flutter/material.dart';

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ExpectoPatronum/Service/local_notifcation.dart';
import 'package:ExpectoPatronum/check_login.dart';
import 'package:ExpectoPatronum/user.dart';

import 'package:shared_preferences/shared_preferences.dart';

Future<List<String>> sendtocheckAnd() async {
  // รับโทเค็นจาก User
    Map<String, String?> settings = await User.getSettings();
  String? ip = settings['ip'];
  String? port = settings['port'];
  print(port);
  List<String> storedTokens = await User.getLineNotifyTokens();
  print('check update tokens fun: $storedTokens'); // Debugging line
    SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('jwt_token');

  var url = Uri.parse('http://$ip:$port/routes/pushNotification/receiveTokens');

  try {
    var response = await http.post(
      url,
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({'tokens': storedTokens}),
    );

    if (response.statusCode == 200) {
      print('Tokens successfully sent to the server.');
    } else {
      print('Failed to send tokens. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Error sending tokens: $e');
  }

  return storedTokens; // ส่งคืนโทเค็น
}

Future<void> deleteToken(String tokenline) async {
  Map<String, String?> settings = await User.getSettings();
  String? ip = settings['ip'];
  String? port = settings['port'];
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('jwt_token');
  var url = Uri.parse('http://$ip:$port/routes/pushNotification/deleteToken');

  try {
    var response = await http.delete(
      url,
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({'token': tokenline}),
    );
      print("delete: $tokenline");
    if (response.statusCode == 200) {
      print('Token successfully deleted from the server.');
    } else if (response.statusCode == 404) {
      print('Token not found on the server.');
    } else {
      print('Failed to delete token. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Error deleting token: $e');
  }
}


Future<void> checkAndSendLineNotification() async {
  Map<String, String?> settings = await User.getSettings();
  String? ip = settings['ip'];
  String? port = settings['port'];
   SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('jwt_token');
  var url =
      Uri.parse('http://$ip:$port/routes/pushNotification/sendNotifications');

  try {
    // รับข้อมูลจากเซิร์ฟเวอร์โดยไม่ส่งโทเค็น
  var response = await http.post(url, headers: <String, String>{
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json; charset=UTF-8',
    });
    print('Status Code: ${response.statusCode}');
    print('Response Body Line: ${response.body}');

    if (response.statusCode == 200) {
      var responseData = json.decode(response.body) as Map<String, dynamic>;

      if (responseData.containsKey('message') && responseData.containsKey('notificationStatus')) {
        var message = responseData['message'];
        var notificationStatus = responseData['notificationStatus'];

        if (notificationStatus == "Success") {
          print("Notification sent successfully. Message: $message");
        } else {
          print('No new attacks found. Message: $message');
        }
      } else {
        print('Invalid response format or data is null.');
      }
    } else {
      print('Failed to receive notification. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Error receiving notification: $e');
  }
}


Future<void> LocalNotification() async {
  try {
    // ดึงการตั้งค่าผู้ใช้
    Map<String, String?> settings = await User.getSettings();
    String? ip = settings['ip'];
    String? port = settings['port'];
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');
    if (ip == null || port == null) {
      print('IP หรือ Port เป็น null ไม่สามารถดำเนินการได้');
      return;
    }

    var url = Uri.parse('http://$ip:$port/routes/detectRoute/LocalNotification');

    // ส่งคำขอ GET ไปยัง API
    var response = await http.get(
      url,
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      var responseData = json.decode(response.body);

      if (responseData is Map<String, dynamic>) {
        var message = responseData['message'];
        var newData = responseData['localNotificationData'];

        if (message != null && newData is List) {
          if (newData.isNotEmpty) {
            print("พบการเปลี่ยนแปลงสถานะใหม่ กำลังส่งการแจ้งเตือน...");

            for (var data in newData) {
              if (data is Map<String, dynamic>) {
                var notificationMessage = data['message'];
                if (notificationMessage != null) {
                  var lines = notificationMessage.split('\n');
                  var title = lines.isNotEmpty ? lines[0] : 'Notification';
                  var body = lines.skip(1).join('\n');
                  var payload = '';

                  // แสดงการแจ้งเตือน
                  LocalNotifications.showSimple(
                    title: title,
                    body: body,
                    payload: payload,
                  );

                  print('แจ้งเตือนแสดง: $title - $body');
                } else {
                  print('ข้อความการแจ้งเตือนเป็น null สำหรับ id ${data['id']}');
                }
              } else {
                print('รูปแบบข้อมูลใน newData ไม่ถูกต้อง');
              }
            }
          } else {
            print('ไม่พบการโจมตีใหม่');
      
          }
        } else {
          print('รูปแบบการตอบกลับไม่ถูกต้องหรือข้อมูลหายไป');
        }
      } else {
        print('ข้อมูลตอบกลับไม่ใช่ Map<String, dynamic>');
      }
    } else {
      print('ไม่สามารถรับการแจ้งเตือนได้ รหัสสถานะ: ${response.statusCode}');
    }
  } catch (e) {
    print('เกิดข้อผิดพลาดในการรับการแจ้งเตือน: $e');
  }
}

