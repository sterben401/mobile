import 'dart:math';

import 'package:ExpectoPatronum/check_login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ExpectoPatronum/Service/local_notifcation.dart';
import 'package:ExpectoPatronum/home.dart';
import 'dart:convert';
import 'package:slider_captcha/slider_captcha.dart';
import 'main.dart';
import 'user.dart';
import 'Service/fetch_user_profile.dart';

class login extends StatefulWidget {
  const login({Key? key}) : super(key: key);
  @override
  State<login> createState() => _loginState();
}


class _loginState extends State<login> {
  late String randomImage; // ย้ายการประกาศไปที่ State ของ Widget

  @override
  void initState() {
    super.initState();
    randomImage = _getRandomImage(); // กำหนดภาพเริ่มต้น
  }

  final _formKey = GlobalKey<FormState>();

  bool? checklogin = false;
  final SliderController _sliderController =
      SliderController(); // เพิ่ม controller ของ SliderCaptcha
  bool _isSliderVerified = false; // ตรวจสอบว่า slider ผ่านหรือไม่
  String _message = '';
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isObscured = true; // สถานะสำหรับควบคุมการแสดงรหัสผ่าน

  Future<void> _signIn() async {
    Map<String, String?> settings = await User.getSettings();
    String? ip = settings['ip'];
    String? port = settings['port'];
    if (ip == null || ip.isEmpty || port == null || port.isEmpty) {
      await showPopup('Please set IP and Port before signing in');
      return;
    }

    String url = "http://$ip:$port/routes/login";

    try {
      final response = await http.post(Uri.parse(url), body: {
        'email': _emailController.text,
        'password': _passwordController.text,
      });

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['message'] == "Login successful.") {
          String token = data['token'];
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt_token', token);
          print(token);

          // ข้อมูลล็อกอินถูกต้อง ให้แสดง SliderCaptcha
          await _showSliderCaptchaDialog();

          // หลังจากยืนยัน slider
          if (_isSliderVerified) {
            if (data['urole'] == "admin") {
              await User.seturole(true);
            } else {
              await User.seturole(false);
            }
            await User.setsigin(true);
            await User.setEmail(_emailController.text);
            await fetchUserProfile();
            try {
              await initializeService(); // เริ่ม background service
            } catch (e) {
              await showPopup('การเริ่ม background service ล้มเหลว: $e');
              return; // หยุดการทำงานหากเกิดข้อผิดพลาด
            }

            try {
              await LocalNotifications.intit(); // แก้การสะกดจาก intit เป็น init
            } catch (e) {
              await showPopup('การตั้งค่า LocalNotifications ล้มเหลว: $e');
              return; // หยุดการทำงานหากเกิดข้อผิดพลาด
            }

            await User.fetchAndPrintSettings();
            Navigator.pushNamed(context, 'home');
          } else {
            await showPopup('Please verify the slider first');
          }
        } else {
          await showPopup('รอผู้ดูแลระบบอนุมัติ');
        }
        //if(data['message'] == "account is pending."){
        //}
      } else {
        await showPopup('Invalid email or password');
      }
    } catch (e) {
      print('Error: $e');
      await showPopup('Please set IP and Port before signing in');
    }
  }

  String _getRandomImage() {
    List<String> images = [
      "assets/mooto1.jpeg",
      "assets/mootoo2.jpeg",
      "assets/mootoo3.jpeg",
      // เพิ่มชื่อไฟล์ภาพอื่นๆ ที่ต้องการ
    ];
    return images[Random().nextInt(images.length)];
  }

  Future<bool> _showSliderCaptchaDialog() async {
    bool isVerified = false;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          content: SingleChildScrollView(
            child: Container(
              width: 550,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SliderCaptcha(
                    key: ValueKey(randomImage), // เพิ่มคีย์ใหม่
                    controller: _sliderController,
                    image: Image.asset(
                      randomImage,
                      fit: BoxFit.contain,
                    ),
                    onConfirm: (bool value) {
                      setState(() {
                        _isSliderVerified = value;
                        isVerified = value;
                      });
                      Navigator.of(context).pop();
                      return Future.value();
                    },
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text("Cancel"),
                      ),
                      /*IconButton(
                        icon: Icon(Icons.refresh),
                        onPressed: () {
                          setState(() {
                            randomImage = _getRandomImage(); // กำหนดรูปภาพใหม่
                            print(randomImage); // พิมพ์ชื่อไฟล์ใหม่
                          });
                        },
                        tooltip: "Refresh",
                      ),*/
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    return isVerified;
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
            Expanded( // Wrap the Text with Expanded
              child: Text(
                'เกิดข้อผิดพลาด',
                style: TextStyle(fontSize: 18.0,fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis, // Ensure text doesn't overflow
              ),
            ),
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

@override
Widget build(BuildContext context) {
return PopScope(
  canPop: false, // ป้องกันการกดย้อนกลับ
  onPopInvokedWithResult: (didPop, result) {
  },
    child: Scaffold(
      
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, size: 30.0, color: Colors.blue),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  String? ip;
                  String? port;

                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20.0)),
                    ),
                    title: Text(
                      'Settings',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'IP Address',
                              hintText: '0.0.0.0',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onChanged: (value) {
                              ip = value;
                            },
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Port',
                              hintText: '0000',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onChanged: (value) {
                              port = value;
                            },
                          ),
                        ],
                      ),
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: Text('Cancel'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      ElevatedButton(
                        child: Text('Save'),
                        onPressed: () async {
                          if (ip == null || ip!.isEmpty || port == null || port!.isEmpty) {
                            showPopup('Error: IP Address and Port cannot be empty!');
                            return;
                          }
                          await User.saveSettings(ip!, port!);
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          backgroundColor: Colors.blueAccent,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 5.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: 10),
                Text(
                  'Welcome!',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Brute Force Attack Monitoring System',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'from Web Access Log Files.',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 30),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                  shadowColor: Colors.black.withOpacity(0.3),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 10.0),
                    child: TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        filled: true,
                        fillColor: Colors.grey[200],
                      ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter your Email';
                        }
                        bool emailValid = RegExp(
                                r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                            .hasMatch(value);
                        if (!emailValid) {
                          return 'Please enter a valid Email';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                SizedBox(height: 15),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                  shadowColor: Colors.black.withOpacity(0.3),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 10.0),
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: _isObscured,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isObscured ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _isObscured = !_isObscured;
                            });
                          },
                        ),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        filled: true,
                        fillColor: Colors.grey[200],
                      ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() {
                              _isLoading = true;
                            });
                            await _signIn();
                            setState(() {
                              _isLoading = false;
                            });
                          }
                        },
                  child: _isLoading
                      ? CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : Text('Sign In'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(vertical: 15.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

}
