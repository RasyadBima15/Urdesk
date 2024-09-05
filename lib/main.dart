// ignore_for_file: prefer_const_constructors

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:urdesk/login.dart';
import 'package:urdesk/register.dart';
import 'landing.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();

  // Plugin must be initialized before using
  await FlutterDownloader.initialize(
      debug:
          true, // optional: set to false to disable printing logs to console (default: true)
      ignoreSsl:
          true // option: set to false to disable working with http links (default: false)
      );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UrDesk',
      // theme: ThemeData(
      //   primarySwatch: Colors.purple,
      //   visualDensity: VisualDensity.adaptivePlatformDensity,
      // ),
      home: AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return LandingPage();
        } else {
          return MainPage();
        }
      },
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 30),
            Image(
              image: AssetImage("images/urdesk.png"),
              fit: BoxFit.cover,
              width: 250,
            ),
            SizedBox(height: 50),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 30),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Selamat datang di UrDesk! \n\nAplikasi cerdas yang membantu Anda menjaga meja tetap rapi dan teratur. Dengan teknologi AI, UrDesk akan mendeteksi kondisi meja Anda, memberikan penilaian, serta merekomendasikan produk yang sesuai untuk meningkatkan kenyamanan dan produktivitas Anda. Temukan inspirasi dari pengguna lain dan bagikan setup meja Anda sendiri.\n\nMulai pengalaman menyenangkan bersama UrDesk sekarang!',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    height: 1.5,
                    fontWeight: FontWeight.w500),
                textAlign: TextAlign.justify,
              ),
            ),
            SizedBox(height: 30),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.purple,
                backgroundColor: Colors.purple,
                padding: EdgeInsets.symmetric(horizontal: 140, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterScreen()),
                );
              },
              child: Text(
                'Mulai',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 10),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.purple,
                backgroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 60, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              child: Text(
                'Sudah Punya Akun? Masuk',
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
