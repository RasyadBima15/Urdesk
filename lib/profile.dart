// ignore_for_file: unused_field, prefer_const_constructors, unused_element, prefer_final_fields

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class Profile extends StatefulWidget {
  @override
  _ProfileState createState() => new _ProfileState();
}

class _ProfileState extends State<Profile> {
  String? _username;
  int _postCount = 0;
  List<String> _imageUrls = [];

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _loadPostCountAndImages();
  }

  Future<void> _loadUsername() async {
    String? username = await getUsername();
    setState(() {
      _username = username ?? 'Unknown User';
    });
  }

  Future<void> _loadPostCountAndImages() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final uid = user.uid;
      final databaseReference = FirebaseDatabase.instance.ref('images/$uid');
      final snapshot = await databaseReference.get();
      if (snapshot.exists) {
        // Count the number of images (posts) and retrieve image URLs
        final data = snapshot.value as Map;
        setState(() {
          _postCount = data.length; // Count the number of posts
          _imageUrls = data.values
              .map<String>((imageData) => imageData['imageUrl'] as String)
              .toList(); // Get image URLs
        });
      } else {
        setState(() {
          _postCount = 0; // No posts found
        });
      }
    }
  }

  Future<String?> getUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final uid = user.uid;
      final databaseReference = FirebaseDatabase.instance.ref('users/$uid');
      final snapshot = await databaseReference.get();
      if (snapshot.exists) {
        final data = snapshot.value as Map;
        return data['username'] as String?;
      }
    }
    return null;
  }

  void _showDialog() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Color.fromARGB(95, 46, 46, 46),
            title: Text(
              "Konfirmasi Logout",
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              "Apakah anda yakin ingin logout?",
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              MaterialButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  "Tidak",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              MaterialButton(
                onPressed: () {
                  FirebaseAuth.instance.signOut();
                  Navigator.pop(context);
                },
                child: Text(
                  "Ya",
                  style: TextStyle(color: Colors.red),
                ),
              )
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        actions: [
          Theme(
            data: Theme.of(context).copyWith(
              popupMenuTheme: PopupMenuThemeData(
                color: Color.fromARGB(
                    95, 46, 46, 46), // Ganti warna background popup
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: TextStyle(color: Colors.white), // Ganti warna teks
              ),
            ),
            child: PopupMenuButton(
              offset: Offset(0, 40),
              itemBuilder: (context) => [
                PopupMenuItem(
                  onTap: () {
                    // Aksi logout di sini
                    _showDialog();
                  },
                  child: Row(
                    children: [
                      Icon(
                        Icons.logout,
                        color: Colors.red,
                      ),
                      SizedBox(width: 10),
                      Text(
                        "Logout",
                        style: TextStyle(color: Colors.red, fontSize: 17),
                      ),
                    ],
                  ),
                ),
              ],
              child: Icon(
                Icons.more_vert,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(width: 4, color: Colors.white),
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          fit: BoxFit.cover,
                          image: AssetImage("images/user_logo.jpg"),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        height: 24,
                        width: 24,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                          border: Border.all(width: 2, color: Colors.white),
                        ),
                        child: Icon(Icons.edit, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _username ?? "",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "$_postCount Postingan",
                        style: TextStyle(fontSize: 14, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(color: Colors.grey, thickness: 0.2),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2 columns of images
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
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
          ),
        ],
      ),
    );
  }
}
