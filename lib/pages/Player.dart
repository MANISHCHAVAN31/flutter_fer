import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_fer/pages/Song.dart';
import 'package:just_audio/just_audio.dart';

class PlayerScreen extends StatefulWidget {
  Song song;
  Function changeTrack;
  final GlobalKey<PlayerScreenState> key;

  PlayerScreen({this.song, this.changeTrack, this.key}) : super(key: key);

  @override
  PlayerScreenState createState() => PlayerScreenState();
}

class PlayerScreenState extends State<PlayerScreen> {
  double minimumValue = 0.0;
  double maximumValue = 0.0;
  double currentValue = 0.0;
  String currentTime = '';
  String endTime = '';
  bool isPlaying = false;

  final AudioPlayer player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    setSong(widget.song);
  }

  void dispose() {
    super.dispose();
    player?.dispose();
  }

  String getDuration(double value) {
    Duration duration = Duration(milliseconds: value.round());

    return [duration.inMinutes, duration.inSeconds]
        .map((element) => element.remainder(60).toString().padLeft(2, '0'))
        .join(':');
  }

  void setSong(Song song) async {
    widget.song = song;
    await player.setUrl(widget.song.songurl);
    currentValue = minimumValue;
    maximumValue = player.duration.inMilliseconds.toDouble();
    setState(() {
      currentTime = getDuration(currentValue);
      endTime = getDuration(maximumValue);

      // Running status change
      isPlaying = false;
      changeStatus();

      player.positionStream.listen((duration) {
        currentValue = duration.inMilliseconds.toDouble();
        setState(() {
          currentTime = getDuration(currentValue);
        });
      });
    });
  }

  void changeStatus() {
    setState(() {
      isPlaying = !isPlaying;
    });

    if (isPlaying) {
      player.play();
    } else {
      player.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: Color(0xFF1D6FcF),
        ),
        title: Text(
          "Music Player",
          style: TextStyle(color: Color(0xFF1D6FcF)),
        ),
      ),
      body: Container(
        margin: EdgeInsets.fromLTRB(5, 20, 5, 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(30.0),
              child: Container(
                height: 300.0,
                width: 300.0,
                color: Colors.white,
                child: Image(
                  image: widget.song.imageurl == null
                      ? AssetImage('assets/music_image.jpg')
                      : NetworkImage(widget.song.imageurl),
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.fromLTRB(0, 10, 0, 7),
              child: Center(
                child: Text(
                  widget.song.songTitle,
                  style: TextStyle(
                      color: Color(0xFF1D6FcF),
                      fontSize: 18.0,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
              child: Text(
                widget.song.artist,
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Slider(
                  activeColor: Color(0xFF1D6FcF),
                  inactiveColor: Colors.grey[300],
                  min: minimumValue,
                  max: maximumValue + 1,
                  value: currentValue,
                  onChanged: (value) {
                    currentValue = value;
                    player.seek(
                      Duration(
                        milliseconds: currentValue.round(),
                      ),
                    );
                  },
                ),
              ],
            ),
            Container(
              transform: Matrix4.translationValues(0, -5, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    currentTime,
                    style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500),
                  ),
                  Text(
                    endTime,
                    style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  GestureDetector(
                    child: Icon(Icons.skip_previous,
                        color: Color(0xFF1D6FcF), size: 55),
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      widget.changeTrack(false);
                    },
                  ),
                  GestureDetector(
                    child: Icon(isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Color(0xFF1D6FcF), size: 75),
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      changeStatus();
                    },
                  ),
                  GestureDetector(
                    child: Icon(Icons.skip_next,
                        color: Color(0xFF1D6FcF), size: 55),
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      widget.changeTrack(true);
                    },
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
