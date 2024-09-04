import 'package:flutter/material.dart';

class Explore extends StatefulWidget {
  @override
  _ExploreState createState() => new _ExploreState();
}

class _ExploreState extends State<Explore> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'images/urdesk.png', // Ganti dengan path logo Anda
              height: 30,
            ),
          ],
        ),
      ),
    );
  }
}
