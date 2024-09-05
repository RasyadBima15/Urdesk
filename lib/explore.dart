// ignore_for_file: prefer_final_fields, prefer_const_constructors, avoid_print

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class Explore extends StatefulWidget {
  @override
  _ExploreState createState() => new _ExploreState();
}

class _ExploreState extends State<Explore> {
  List<String> _imageUrls = [];
  @override
  void initState() {
    super.initState();
    _loadAllPostImages();
  }

  Future<void> _loadAllPostImages() async {
    final databaseReference = FirebaseDatabase.instance.ref('images');
    final snapshot = await databaseReference.get();

    if (snapshot.exists) {
      final data = snapshot.value as Map;
      List<String> allImageUrls = [];

      data.forEach((uid, userImages) {
        final userImageMap = userImages as Map;
        userImageMap.forEach((timestamp, imageData) {
          allImageUrls.add(imageData['imageUrl'] as String);
        });
      });

      setState(() {
        _imageUrls = allImageUrls;
        // print(_imageUrls); // Set all image URLs to the state variable
      });
    }
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
      body: GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 2 columns of images
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 16 / 9,
        ),
        itemCount: _imageUrls.length,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: DecorationImage(
                image: NetworkImage(_imageUrls[index]),
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }
}
