import 'dart:async';
import 'dart:developer';
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:ExpectoPatronum/Service/local_notifcation.dart';
import 'package:ExpectoPatronum/home.dart';
import 'package:ExpectoPatronum/user.dart';
import 'package:logger/logger.dart';
import 'Service/fetch_user_profile.dart';
import 'Service/line.dart';
import 'login.dart';
import 'register.dart';
import 'check_login.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalNotifications.intit(); // แก้การสะกด
  await LocalNotifications.requestNotificationPermissions();
  
 // await initializeService(); // เรียกใช้เพื่อเริ่ม background service
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // ซ่อน Debug banner
      home: check_login(),
      routes: {
        'login': (context) => login(),
        'home': (context) => homepage(),
      },
    );
  }
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    iosConfiguration: IosConfiguration(),
    androidConfiguration: AndroidConfiguration(onStart: onStart, isForegroundMode: true),
  );
  await service.startService();
}

var logger = Logger();
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }
  
  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  Timer.periodic(const Duration(seconds: 5), (timer) async {
  //  logger.i('Timer triggered: calling LocalNotification and checkAndSendLineNotification');
    
   
      await LocalNotification();  // เรียกใช้ฟังก์ชัน LocalNotification
      await checkAndSendLineNotification();  // เรียกใช้ฟังก์ชันส่งการแจ้งเตือน

  });
}

//@pragma('vm:entry-point')