// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

class Result extends StatelessWidget {
  const Result({super.key});

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
            _buildCriteriaCard(3, 'Keberadaan Objek yang Tercecer',
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit.'),
            _buildCriteriaCard(4, 'Kepadatan Objek Tidak Dihendaki',
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit.'),
            _buildCriteriaCard(5, 'Kehadiran Sampah',
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
                    children: const [
                      Icon(Icons.star, color: Colors.yellow, size: 32),
                      Icon(Icons.star, color: Colors.yellow, size: 32),
                      Icon(Icons.star, color: Colors.yellow, size: 32),
                      Icon(Icons.star, color: Colors.yellow, size: 32),
                      Icon(Icons.star_border, color: Colors.yellow, size: 33),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Post action here
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
                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
