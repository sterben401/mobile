import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'user.dart';

class check_login extends StatefulWidget {
  const check_login({super.key});

  @override
  State<check_login> createState() => CheckLoginState();
}

class CheckLoginState extends State<check_login> {
  Future<void> checklogin() async {
    bool? sigin = await User.getsignin();
    print("CheckLogin: $sigin");
    
    // เพิ่มการรอคอยให้ UI มีเวลาในการแสดงผล
    await Future.delayed(const Duration(seconds: 1)); // รอ 1 วินาที (คุณสามารถปรับเปลี่ยนเวลาได้)

    if (sigin == false || sigin == null) {
      FlutterBackgroundService().invoke('stopService');
      Navigator.pushReplacementNamed(context, 'login'); // ใช้ pushReplacementNamed เพื่อไม่ให้กลับไปหน้า check_login
    } else {
      print("CheckLogin: $sigin");
      Navigator.pushReplacementNamed(context, 'home'); // ใช้ pushReplacementNamed เพื่อไม่ให้กลับไปหน้า check_login
    }
  }

  @override
  void initState() {
    checklogin();
    super.initState();
     // เรียกใช้ฟังก์ชันเมื่อเริ่มต้น
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold();
  }
}