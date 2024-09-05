import 'dart:async';
// import 'dart:io';
import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:fluttertoast/fluttertoast.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:gcloud/storage.dart';
import 'package:gcloud/pubsub.dart';
import 'package:gcloud/datastore.dart' as datastore;
import 'package:mime/mime.dart';
import 'package:flutter/services.dart' show rootBundle;

class CloudApi {
  final String projectId;
  final String bucketName;
  final String json;
  late final auth.ServiceAccountCredentials credentials;
  auth.AutoRefreshingAuthClient? client; // Make client nullable

  CloudApi(this.json, this.projectId, this.bucketName);

  Future<void> initialize() async {
    try {
      var jsonCredentials = await rootBundle.loadString(json);
      credentials = auth.ServiceAccountCredentials.fromJson(jsonCredentials);

      var scopes = <String>[
        ...datastore.Datastore.Scopes,
        ...Storage.SCOPES,
        ...PubSub.SCOPES,
      ];
      client = await auth.clientViaServiceAccount(credentials, scopes);
    } catch (e) {
      print('Error initializing API: $e');
      rethrow;
    }
  }

  Future<ObjectInfo> save(String? name, Uint8List imgBytes,
      {String? folderPrefix = ''}) async {
    if (client == null) {
      print('Client not initialized.');
      throw Exception('Client is not initialized.');
    }

    try {
      final storage = Storage(client!, projectId);
      final bucket = storage.bucket(bucketName);

      // Gabungkan folderPrefix dengan nama file untuk menyimulasikan struktur folder
      final fullPath = folderPrefix!.isNotEmpty ? '$folderPrefix/$name' : name;

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final type = lookupMimeType(name!);

      // Unggah gambar ke cloud storage
      ObjectInfo result = await bucket.writeBytes(
        fullPath!,
        imgBytes,
        metadata: ObjectMetadata(
          contentType: type ?? 'application/octet-stream',
          custom: {'timestamp': '$timestamp'},
        ),
      );

      // // Tampilkan pesan sukses
      // Fluttertoast.showToast(
      //   msg: "Image $fullPath uploaded successfully!",
      //   toastLength: Toast.LENGTH_SHORT,
      //   gravity: ToastGravity.BOTTOM,
      //   backgroundColor: Colors.green,
      //   textColor: Colors.white,
      //   fontSize: 16.0,
      // );

      return result;
    } catch (e) {
      print('Error uploading to cloud storage: $e');
      rethrow;
    }
  }

  // Method to close the client when no longer needed
  void dispose() {
    client?.close();
  }
}
