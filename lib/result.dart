// ignore_for_file: prefer_const_constructors, unused_element

import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:urdesk/landing.dart';

class Result extends StatelessWidget {
  final File? imageTop;
  final File? imageFront;
  final String? fileTop;
  final String? fileFront;
  final String? timestamp;
  final int? rating = 2;

  const Result(
      {Key? key,
      required this.imageTop,
      required this.imageFront,
      required this.fileTop,
      required this.fileFront,
      required this.timestamp})
      : super(key: key);

  Future<String> _uploadImageToFirebase(File imageFile, String fileName) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      String uid = user!.uid; // Mendapatkan uid pengguna

      // Menyimpan file gambar di folder berdasarkan uid pengguna
      Reference storageRef =
          FirebaseStorage.instance.ref().child("images/$uid/$fileName");

      // Upload gambar ke Firebase Storage
      UploadTask uploadTask = storageRef.putFile(imageFile);

      // Tunggu hingga upload selesai
      TaskSnapshot snapshot = await uploadTask.whenComplete(() {});

      // Mendapatkan URL download gambar
      String downloadURL = await snapshot.ref.getDownloadURL();
      return downloadURL;
    } catch (e) {
      throw Exception("Error uploading image: $e");
    }
  }

  Future<void> _saveImageMetadata(
      {required String imageUrl,
      required String rating,
      required String timestamp}) async {
    final user = FirebaseAuth.instance.currentUser;
    String uid = user!.uid;

    // Mendapatkan referensi ke data pengguna di Firebase Database
    final databaseReference = FirebaseDatabase.instance.ref('images/$uid');

    // Ambil username dari database
    final userRef = FirebaseDatabase.instance.ref('users/$uid');
    final snapshot = await userRef.get();
    if (snapshot.exists) {
      final data = snapshot.value as Map;
      String username = data['username'];

      // Simpan metadata gambar di Firebase Database
      await databaseReference.push().set({
        'imageUrl': imageUrl,
        'rating': rating,
        'username': username,
        'timestamp': timestamp,
      });
    }
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: Text(
            'Konfirmasi Posting',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Apakah Anda yakin ingin memposting kedua gambar?',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
              },
              child: Text(
                'Batal',
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () async {
                // Lakukan aksi posting gambar di sini
                // tambahkan method _saveImageMetadata dan _uploadImageToFirebase
                try {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: Colors.purple,
                        ),
                      );
                    },
                  );

                  // Upload kedua gambar
                  String downloadUrlTop =
                      await _uploadImageToFirebase(imageTop!, fileTop!);
                  String downloadUrlFront =
                      await _uploadImageToFirebase(imageFront!, fileFront!);

                  // Simpan metadata gambar untuk keduanya
                  await _saveImageMetadata(
                      imageUrl: downloadUrlTop,
                      rating: '4',
                      timestamp: timestamp!);
                  await _saveImageMetadata(
                      imageUrl: downloadUrlFront,
                      rating: '4',
                      timestamp: timestamp!);

                  Fluttertoast.showToast(
                    msg: 'Gambar berhasil diposting!',
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                    backgroundColor: Colors.black,
                    textColor: Colors.white,
                    fontSize: 16.0,
                  );

                  Navigator.of(context).pop();

                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => LandingPage()),
                    (Route<dynamic> route) => false,
                  );
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saat memposting gambar: $e')),
                  );
                }
              },
              child: Text(
                'Ya',
                style: TextStyle(color: Colors.purple),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.white, // Ubah warna tombol back menjadi putih
        ),
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
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.only(left: 16, top: 20, right: 16, bottom: 35),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCriteriaCard(1, 'Kerapihan',
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit.bjkhkhukhulvgrgiuegliewrguegoiehlugwitghjekgulieurghihprgtjireg;owij;eorglewrhfloewrvhiulerv'),
            _buildCriteriaCard(2, 'Kepadatan Objek Keseluruhan',
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit.'),
            _buildCriteriaCard(3, 'Objek Yang Tidak Dihendaki',
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit.'),
            _buildCriteriaCard(4, 'Kehadiran Sampah',
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit.'),
            const SizedBox(height: 16),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Rating',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                      height: 8), // Add some spacing between the text and stars
                  Row(
                    mainAxisAlignment: MainAxisAlignment
                        .center, // Center the stars horizontally
                    children: _buildRatingStars(rating!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Post action here
                  _showConfirmationDialog(context);
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  backgroundColor: Colors.purple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize
                      .min, // Adjusts the button size to fit its content
                  children: const [
                    Text(
                      'Post',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    SizedBox(width: 15), // Adds spacing between text and icon
                    Icon(Icons.arrow_outward_outlined, color: Colors.white),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCriteriaCard(int number, String title, String description) {
    return Card(
      color: Colors.black,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Colors.white, width: 1),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              radius: 16,
              child: Text(
                number.toString(),
                style: const TextStyle(color: Colors.black),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Conditionally display images based on the number
                  if (number == 2 || number == 3 || number == 4) ...[
                    const SizedBox(height: 7),
                    Container(
                      height: 150,
                      width: 275,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        image: DecorationImage(
                          image: FileImage(
                              imageFront!), // Assuming imageFront is defined
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 150,
                      width: 275,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        image: DecorationImage(
                          image: FileImage(
                              imageTop!), // Assuming imageTop is defined
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  if (number == 3) ...[
                    const SizedBox(height: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rekomendasi Produk',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Berikut Rekomendasi Produk yang mungkin anda gunakan untuk merapihkan meja anda!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 16),
                        // Ensure that the ListView has a fixed height
                        SizedBox(
                          height:
                              150, // Fixed height for the horizontal ListView
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _cardProduct(),
                              SizedBox(width: 16),
                              _cardProduct(),
                              SizedBox(width: 16),
                              _cardProduct(),
                              SizedBox(width: 16),
                              _cardProduct(),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardProduct() {
    return Container(
      width: 220, // Fixed width for each product image
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        image: DecorationImage(
          image:
              AssetImage('images/atas.png'), // Replace with actual image path
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  List<Widget> _buildRatingStars(int rating) {
    int fullStars =
        rating.floor(); // Number of full stars (e.g., 3.75 -> 3 full stars)
    int emptyStars = 4 - fullStars; // The rest are empty stars

    List<Widget> stars = [];

    // Add full stars
    for (int i = 0; i < fullStars; i++) {
      stars.add(Icon(Icons.star, color: Colors.yellow, size: 30));
    }

    // Add empty stars (if any)
    for (int i = 0; i < emptyStars; i++) {
      stars.add(Icon(Icons.star_border, color: Colors.yellow, size: 30));
    }

    return stars;
  }
}
