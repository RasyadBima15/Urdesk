// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors, no_leading_underscores_for_local_identifiers, use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:urdesk/result.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:urdesk/services/api.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Upload extends StatefulWidget {
  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload> {
  File? imageTop;
  File? imageFront;
  CloudApi? api;
  String? timestamp;
  String? fileNameTop;
  String? fileNameFront;

  static final String? jsonFile = dotenv.env['JSON_FILE_PATH'];
  static const String projectId = 'UrDesk';
  static const String bucketName = 'urdesk-data';

  @override
  void initState() {
    super.initState();
    initializeApi();
  }

  @override
  void dispose() {
    api?.dispose(); // Close the client safely when the widget is disposed
    super.dispose();
  }

  Future<void> initializeApi() async {
    try {
      api = CloudApi(jsonFile!, projectId, bucketName);
      await api!.initialize();
    } catch (e) {
      print('Error initializing API: $e');
      Fluttertoast.showToast(
        msg: "Failed to initialize API. Check your credentials.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Color.fromARGB(255, 46, 46, 46),
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  bool get isButtonEnabled => imageTop != null && imageFront != null;

  Future<void> getImageFromCamera(
      CropAspectRatio cropAspectRatio, bool isTop) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? imagePicked =
        await _picker.pickImage(source: ImageSource.camera);

    if (imagePicked != null) {
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: imagePicked.path,
        aspectRatio: cropAspectRatio,
        compressQuality: 90,
        compressFormat: ImageCompressFormat.jpg,
      );

      if (croppedFile != null) {
        setState(() {
          if (isTop) {
            imageTop = File(croppedFile.path);
          } else {
            imageFront = File(croppedFile.path);
          }
        });
      }
    }
  }

  Future<void> getImageFromGallery(
      CropAspectRatio cropAspectRatio, bool isTop) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? imagePicked =
        await _picker.pickImage(source: ImageSource.gallery);

    if (imagePicked != null) {
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: imagePicked.path,
        aspectRatio: cropAspectRatio,
        compressQuality: 90,
        compressFormat: ImageCompressFormat.jpg,
      );

      if (croppedFile != null) {
        setState(() {
          if (isTop) {
            imageTop = File(croppedFile.path);
          } else {
            imageFront = File(croppedFile.path);
          }
        });
      }
    }
  }

  void _openCameraButton(String cameraAngle, bool isTop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => ModalBottonUI(
        onCameraTap: () async {
          await getImageFromCamera(
              CropAspectRatio(ratioX: 16, ratioY: 9), isTop);
        },
        onGalleryTap: () async {
          await getImageFromGallery(
              CropAspectRatio(ratioX: 16, ratioY: 9), isTop);
        },
        cameraAngle: cameraAngle,
        onClose: () {
          Navigator.of(context).pop(); // Close modal
        },
      ),
    );
  }

  Future<void> _analyzeImages() async {
    if (api == null) {
      Fluttertoast.showToast(
        msg: "API not initialized. Please try again.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Color.fromARGB(255, 46, 46, 46),
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return;
    }

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

      timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      // Upload images if they exist
      if (imageTop != null) {
        fileNameTop = '${timestamp}_top.jpg'; // Updated filename format
        await api!.save(fileNameTop, await imageTop!.readAsBytes(),
            folderPrefix: timestamp);
      }
      if (imageFront != null) {
        fileNameFront = '${timestamp}_front.jpg'; // Updated filename format
        await api!.save(fileNameFront, await imageFront!.readAsBytes(),
            folderPrefix: timestamp);
      }
    } catch (e) {
      print('Error during image analysis: $e');
      Fluttertoast.showToast(
        msg: "Error processing images. Please try again.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Color.fromARGB(255, 46, 46, 46),
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } finally {
      if (Navigator.canPop(context)) {
        // Close loading dialog
        Navigator.of(context).pop();

        // Navigate to result page
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => Result(
              imageTop: imageTop,
              imageFront: imageFront,
              fileTop: fileNameTop,
              fileFront: fileNameFront,
              timestamp: timestamp,
            ),
          ),
        ); // Ensure dialog is closed if error occurs
      }
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
              'images/urdesk.png', // Change to your logo path
              height: 30,
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CameraButton(
              label: 'Tampak Depan',
              icon: Icons.camera_alt,
              backgroundImage: 'images/depan.png',
              selectedImage: imageFront,
              onTap: () {
                _openCameraButton("Tampak Depan", false);
              },
            ),
            SizedBox(height: 16),
            CameraButton(
              label: 'Tampak Atas',
              icon: Icons.camera_alt,
              backgroundImage: 'images/atas.png',
              selectedImage: imageTop,
              onTap: () {
                _openCameraButton("Tampak Atas", true);
              },
            ),
            SizedBox(height: 20),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(text: 'Ingin Mengecek\n'),
                  TextSpan(
                    text: "Kerapian Meja",
                    style: TextStyle(
                      color: Colors.purpleAccent,
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(text: " Anda?"),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Unggah kedua gambar untuk memulai pengecekan kerapian meja!',
              textAlign: TextAlign.start,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.purple,
                  backgroundColor:
                      isButtonEnabled ? Colors.purple : Colors.grey,
                  padding: EdgeInsets.symmetric(horizontal: 69, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: isButtonEnabled
                    ? _analyzeImages
                    : () {
                        Fluttertoast.showToast(
                          msg: "User harus mengupload kedua gambar!",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                          backgroundColor: Color.fromARGB(255, 46, 46, 46),
                          textColor: Colors.white,
                          fontSize: 16.0,
                        );
                      },
                child: Text(
                  'Analisis Gambar',
                  style: TextStyle(
                    color: isButtonEnabled ? Colors.white : Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Modal UI component
class ModalBottonUI extends StatelessWidget {
  final Future<void> Function() onCameraTap;
  final Future<void> Function() onGalleryTap;
  final String cameraAngle;
  final VoidCallback onClose; // Tambahkan parameter ini

  const ModalBottonUI({
    super.key,
    required this.onCameraTap,
    required this.onGalleryTap,
    required this.cameraAngle,
    required this.onClose, // Inisialisasi parameter ini
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.all(15),
        height: 240,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Color.fromARGB(255, 46, 46, 46),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 35,
                    ),
                    SizedBox(width: 10),
                    Text(
                      cameraAngle,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    )
                  ],
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
            SizedBox(height: 15),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.purple,
                backgroundColor: Colors.purple,
                padding: EdgeInsets.symmetric(horizontal: 69, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                await onCameraTap(); // Tunggu operasi selesai
                onClose(); // Tutup modal setelah operasi selesai
              },
              child: Text(
                'Ambil Gambar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 15),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.purple,
                backgroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 60, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                await onGalleryTap(); // Tunggu operasi selesai
                onClose(); // Tutup modal setelah operasi selesai
              },
              child: Text(
                'Pilih dari Gallery',
                style: TextStyle(
                  color: Colors.purple,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CameraButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final String backgroundImage;
  final File? selectedImage; // Tambahkan properti ini

  const CameraButton({
    Key? key,
    required this.label,
    required this.icon,
    required this.backgroundImage,
    required this.onTap,
    this.selectedImage, // Inisialisasi properti ini
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background Image or Selected Image
        Container(
          width: double.infinity,
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: selectedImage != null
                ? DecorationImage(
                    image: FileImage(
                        selectedImage!), // Gunakan gambar yang dipilih
                    fit: BoxFit.cover,
                  )
                : DecorationImage(
                    image: AssetImage(backgroundImage),
                    fit: BoxFit.cover,
                  ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.black
                  .withOpacity(0.7), // Overlay warna untuk kecerahan
            ),
          ),
        ),
        // Button Content
        SizedBox(
          width: double.infinity,
          height: 180,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: onTap,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 40,
                ),
                SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
