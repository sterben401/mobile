
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:ExpectoPatronum/user.dart';
import 'package:shared_preferences/shared_preferences.dart';



Future<void> fetchUserProfile() async {
    Map<String, String?> settings = await User.getSettings();
  String? ip = settings['ip'];
  String? port = settings['port'];
    SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('jwt_token');
  // URL ของ API ที่ดึงข้อมูลผู้ใช้
  String url = "http://$ip:$port/routes/data/users";
  
  try {
    // เรียกข้อมูลจาก API
    final response = await http.get(Uri.parse(url),
     headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },);
        String? userEmail = await User.getEmail();
        print("LoginCheck : $userEmail");

    if (response.statusCode == 200) {
      // แปลงข้อมูลจาก JSON
      var data = json.decode(response.body);
      
      // ตรวจสอบว่ามีข้อมูลผู้ใช้หรือไม่
      if (data is List) {
        bool userFound = false;
        // วนลูปเพื่อหาผู้ใช้ตามอีเมล
        for (var item in data) {
          String email = item['email'];
          if (email ==userEmail) {
            // กำหนดข้อมูลผู้ใช้
            User.firstName = item['firstname'] as String;
            User.lastName = item['lastname'] as String;
            User.email = item['email'] as String;
            User.phone = item['phone'] as String;
            User.description = item['description'] as String;
            User.token = item['token'] as String;
            userFound = true;
            break; // หยุดวนลูปเมื่อพบผู้ใช้
          }
        }

        if (!userFound) {
          print("User data not found for email: $userEmail");
        }
      } else {
        print("Invalid data format received");
      }
    } else {
      print("Failed to fetch data: ${response.statusCode}");
    }
  } catch (e) {
    print("Error: $e");
  }
}