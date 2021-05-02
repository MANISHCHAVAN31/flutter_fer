import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fer/pages/SongList.dart';
import 'package:flutter_fer/routes.dart';

class ImageResultArguments {
  final String imagePath;
  ImageResultArguments({this.imagePath});
}

class ImageResult extends StatefulWidget {
  @override
  _ImageResultState createState() => _ImageResultState();
}

class _ImageResultState extends State<ImageResult> {
  String _imagePath = "";
  static const platform = const MethodChannel('dev.sanketnaik.flutter_fer/fer');
  String _timeTaken = "";
  String _prediction = "";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Future.delayed(Duration.zero, () {
      final ImageResultArguments args =
          ModalRoute.of(context).settings.arguments;
      setState(() {
        _imagePath = args.imagePath;
      });
      predict(_imagePath);
    });
  }

  predict(String imagePath) async {
    List<dynamic> result =
        await platform.invokeMethod('predict', {"imagePath": _imagePath});
    setState(() {
      _imagePath = result[0];
      _prediction = result[1];
      _timeTaken = result[2];
    });
    print("RESULT => ${result}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Result'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _imagePath == ""
                ? CircularProgressIndicator()
                : Image.file(
                    File(_imagePath),
                  ),
          ),
          Column(
            children: [
              Text('Prediction => ${_prediction}'),
              Text('Time Taken => ${_timeTaken} ms'),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(
              bottom: 10.0,
              top: 5.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RaisedButton(
                  textColor: Colors.white,
                  color: Colors.blue,
                  padding:
                      EdgeInsets.symmetric(vertical: 10.0, horizontal: 30.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.chevron_left,
                      ),
                      Text(
                        'Retry',
                        style: TextStyle(
                          fontSize: 16.0,
                        ),
                      ),
                    ],
                  ),
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed(CAPTURE_IMAGE);
                  },
                ),
                SizedBox(
                  width: 30.0,
                ),
                ElevatedButton(
                  onPressed: () {
                    // Navigator.of(context).pushReplacementNamed(SONG_LIST);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                SongList(prediction: _prediction)));
                  },
                  child: Row(
                    children: [
                      Text(
                        "Proceed",
                        style: TextStyle(fontSize: 16.0),
                      ),
                      Icon(Icons.chevron_right_sharp),
                    ],
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
