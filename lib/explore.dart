// ignore_for_file: prefer_final_fields, prefer_const_constructors, avoid_print, use_build_context_synchronously

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_downloader/flutter_downloader.dart';

class Explore extends StatefulWidget {
  @override
  _ExploreState createState() => new _ExploreState();
}

class _ExploreState extends State<Explore> {
  List<ImageData> _images = [];
  @override
  void initState() {
    super.initState();
    _loadAllPostImages();
  }

  Future<void> _downloadImage(String imageUrl) async {
    // Ensure the directory is not null
    final dir = await getExternalStorageDirectory();
    if (dir == null) {
      Fluttertoast.showToast(
        msg: "Failed to get storage directory",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.black,
        textColor: Colors.white,
      );
      return;
    }

    final savedDir = dir.path;

    try {
      // Show loading dialog
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

      // Enqueue download task
      final taskId = await FlutterDownloader.enqueue(
        url: imageUrl,
        savedDir: savedDir,
        showNotification: true,
        openFileFromNotification: true,
        saveInPublicStorage:
            true, // Set this to true if you want to save in public storage
      );

      if (taskId == null) {
        Fluttertoast.showToast(
          msg: "Failed to download image",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.black,
          textColor: Colors.white,
        );
        return;
      }

      // Notify user of successful download
      Fluttertoast.showToast(
        msg: "Image downloaded successfully",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.black,
        textColor: Colors.white,
      );
    } catch (error) {
      print("ERROR: $error");
      Fluttertoast.showToast(
        msg: "Error downloading image: $error",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.black,
        textColor: Colors.white,
      );
    } finally {
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop(); // Close loading dialog
      }
    }
  }

  Future<void> _loadAllPostImages() async {
    final databaseReference = FirebaseDatabase.instance.ref('images');
    final snapshot = await databaseReference.get();

    if (snapshot.exists) {
      final data = snapshot.value as Map;
      List<ImageData> allImages = [];

      data.forEach((uid, userImages) {
        final userImageMap = userImages as Map;
        userImageMap.forEach((imageId, imageData) {
          final imageUrl = imageData['imageUrl'] as String;
          final username = imageData['username'] as String;
          final ratingString =
              imageData['rating']; // rating could be a string or number

          // Safely parse rating
          double rating = 0.0;
          if (ratingString != null) {
            try {
              rating = ratingString is double
                  ? ratingString
                  : double.parse(ratingString.toString());
            } catch (e) {
              print("Error parsing rating: $e");
            }
          }

          allImages.add(
            ImageData(
              imageUrl: imageUrl,
              username: username,
              rating: rating,
            ),
          );
        });
      });

      setState(() {
        _images = allImages; // Store the ImageData list in the state
      });
    }
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
              'images/urdesk.png', // Replace with your logo path
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
        itemCount: _images.length,
        itemBuilder: (context, index) {
          final image = _images[index]; // Access the current image object
          return GestureDetector(
            onTap: () {
              _showImageDetails(context, image);
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                  image: NetworkImage(image.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showImageDetails(BuildContext context, ImageData image) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Detail Gambar',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white), // "X" icon
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the modal
                      },
                    ),
                  ],
                ),
                Divider(
                  color: Colors.grey,
                  thickness: 0.1,
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border.all(width: 4, color: Colors.white),
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          fit: BoxFit.cover,
                          image: AssetImage(
                              "images/user_logo.jpg"), // Replace with your image path
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      image
                          .username, // Use the username from the ImageData object
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Container(
                  height: 190,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    image: DecorationImage(
                      image: NetworkImage(image.imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _buildRatingStars(image.rating),
                ),
                SizedBox(height: 10),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      // Implement download functionality
                      _downloadImage(image.imageUrl).then((_) {
                        Navigator.of(context).pop();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                    ),
                    child: Text(
                      'Download',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildRatingStars(double rating) {
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

class ImageData {
  final String imageUrl;
  final String username;
  final double rating;

  ImageData({
    required this.imageUrl,
    required this.username,
    required this.rating,
  });
}
