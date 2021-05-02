import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:flutter_fer/pages/captureImage.dart';
import 'package:flutter_fer/pages/imageResult.dart';
import 'package:flutter_fer/pages/SongList.dart';
import 'package:flutter_fer/pages/Player.dart';
import 'package:flutter_fer/routes.dart';

List<CameraDescription> cameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(App());
}

class App extends StatelessWidget {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FutureBuilder(
        future: _initialization,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text("Something went wrong in firebase");
          }

          if (snapshot.connectionState == ConnectionState.done) {
            return MyApp();
          }

          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FER',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primaryColor: Color(0xFF1D6FcF),
      ),
      initialRoute: CAPTURE_IMAGE,
      routes: {
        CAPTURE_IMAGE: (context) => CaptureImage(),
        IMAGE_RESULT: (context) => ImageResult(),
        PLAYER_SCREEN: (context) => PlayerScreen(),
        SONG_LIST: (context) => SongList(),
      },
    );
  }
}
