import 'package:ExpectoPatronum/check_login.dart';
import 'package:flutter/material.dart';
import 'package:ExpectoPatronum/screen/history.dart';
import 'package:ExpectoPatronum/screen/notifi.dart';
import 'package:ExpectoPatronum/screen/profile.dart';
import 'package:ExpectoPatronum/screen/settings.dart';
import 'user.dart';

class homepage extends StatefulWidget {
  const homepage({super.key});

  @override
  State<homepage> createState() => _homepageState();
}

class _homepageState extends State<homepage> {
  int _selectedIndex =0;


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  @override
  Widget build(BuildContext context) {
    final tabs = [
      const noti_fi(),
      const his_tory(),
      const pro_file(email: '',),
      const set_ting(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: tabs[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.blue,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.white,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',

          ),
        ],
      ),


    );
  }
}