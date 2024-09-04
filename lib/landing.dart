// ignore_for_file: prefer_const_constructors, use_build_context_synchronously, use_key_in_widget_constructors, unnecessary_string_interpolations, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
// import 'login.dart'; // Import LoginScreen
// import 'services/auth_service.dart'; // Import AuthService
import 'explore.dart';
import './upload.dart';
import './profile.dart';

class LandingPage extends StatefulWidget {
  @override
  _LandingPageState createState() => new _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  int _bottomNavCurrentIndex = 0;
  List<Widget> _container = [new Explore(), new Upload(), new Profile()];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _container[_bottomNavCurrentIndex],
      bottomNavigationBar: BottomNavigationBar(
        unselectedIconTheme: IconThemeData(size: 28),
        selectedIconTheme: IconThemeData(size: 34),
        unselectedItemColor: Colors.black,
        unselectedLabelStyle: TextStyle(
            color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold),
        selectedLabelStyle: TextStyle(
          fontSize: 17,
        ),
        selectedItemColor: Colors.white,
        backgroundColor: Colors.purple,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _bottomNavCurrentIndex = index;
          });
        },
        currentIndex: _bottomNavCurrentIndex,
        items: [
          BottomNavigationBarItem(
            activeIcon: Icon(
              Icons.explore,
              color: Colors.white,
            ),
            icon: Icon(
              Icons.explore,
              color: Colors.black,
            ),
            label: 'Explore', // Directly pass the string
          ),
          BottomNavigationBarItem(
            activeIcon: Icon(
              Icons.photo_camera,
              color: Colors.white,
            ),
            icon: Icon(
              Icons.photo_camera,
              color: Colors.black,
            ),
            label: 'Upload', // Directly pass the string
          ),
          BottomNavigationBarItem(
            activeIcon: Icon(
              Icons.people,
              color: Colors.white,
            ),
            icon: Icon(
              Icons.people,
              color: Colors.black,
            ),
            label: 'Profle', // Directly pass the string
          ),
        ],
      ),
    );
  }
}
