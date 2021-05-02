import 'package:flutter/material.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:flutter_fer/pages/Player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_fer/pages/Song.dart';

class SongList extends StatefulWidget {
  String prediction;
  SongList({this.prediction});

  @override
  _SongListState createState() => _SongListState();
}

class _SongListState extends State<SongList> {
  // List of songs
  final FlutterAudioQuery audioQuery = FlutterAudioQuery();

  List<Song> songs = [];
  List music = [];
  int currentIndex = 0;

  final GlobalKey<PlayerScreenState> key = GlobalKey<PlayerScreenState>();

  void initState() {
    super.initState();
    getFirebaseData();
  }

  // Connect and get data from firebase
  void getFirebaseData() async {
    String predictedResult =
        "${widget.prediction[0].toUpperCase()}${widget.prediction.substring(1)}";

    Query musicList = FirebaseFirestore.instance
        .collection('MUSIC')
        .where('type', isEqualTo: predictedResult);

    QuerySnapshot snapshots = await musicList.get();

    for (DocumentSnapshot snapshot in snapshots.docs) {
      // Adding data in songs list
      songs.add(Song(
          songTitle: snapshot.data()['song'],
          artist: snapshot.data()['artist'],
          type: snapshot.data()['type'],
          imageurl: snapshot.data()['imageurl'],
          songurl: snapshot.data()['songurl']));

      setState(() {
        songs = songs;
      });
    }
  }

  void changeTrack(bool isNext) {
    if (isNext) {
      if (currentIndex != songs.length - 1) {
        currentIndex++;
      }
    } else {
      if (currentIndex != 0) {
        currentIndex--;
      }
    }

    key.currentState.setSong(songs[currentIndex]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Icon(Icons.music_note, color: Colors.white),
        title: Text("Music Player"),
        elevation: 50.0,
      ),
      body: ListView.separated(
        itemCount: songs.length,
        itemBuilder: (context, index) => ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(10.0), //or 15.0
            child: Container(
              height: 50.0,
              width: 50.0,
              color: Color(0xffFF0E58),
              child: Image(
                image: songs[index].imageurl == null
                    ? AssetImage('assets/music_image.jpg')
                    : NetworkImage(songs[index].imageurl),
              ),
            ),
          ),
          title: Text(
            songs[index].songTitle,
            style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            songs[index].artist,
            style: TextStyle(
              fontSize: 13.0,
            ),
          ),
          onTap: () {
            currentIndex = index;
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PlayerScreen(
                  changeTrack: changeTrack,
                  song: songs[index],
                  key: key,
                ),
              ),
            );
          },
        ),
        separatorBuilder: (BuildContext context, int index) => Divider(),
      ),
    );
  }
}
