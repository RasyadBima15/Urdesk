import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/material.dart';
// import 'package:fluttertoast/fluttertoast.dart';

class AuthService {
  Future<void> signup({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      String uid = userCredential.user!.uid;
      DatabaseReference databaseReference =
          FirebaseDatabase.instance.ref('users');
      await databaseReference.child(uid).set({
        'username': username,
      });
    } on FirebaseAuthException catch (e) {
      String message = '';
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak!';
      } else if (e.code == 'email-already-in-use') {
        message = 'An account already exists with that email!';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid Email!';
      }
      throw message;
    } catch (e) {
      print(e);
      rethrow;
    }
  }

  Future<void> signin({
    required String email,
    required String password,
  }) async {
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      String message = '';
      if (e.code == 'invalid-email') {
        message = 'Invalid email!';
      } else if (e.code == 'invalid-credential') {
        message = 'Wrong email or password provided for that user.';
      } else {
        message = 'An unknown error occurred.';
      }
      throw message; // Rethrow the exception so it can be caught by _login
    } catch (e) {
      rethrow; // Rethrow the exception so it can be caught by _login
    }
  }

  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      rethrow;
    }
  }
}
