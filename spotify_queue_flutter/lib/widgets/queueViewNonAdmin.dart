import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:spotify_queue/widgets/songWidgets.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
import 'package:spotify_queue/models/room.dart';
import 'package:spotify_queue/models/song.dart';

import 'package:spotify_sdk/models/player_state.dart';
import 'package:spotify_queue/spotifyAPI.dart';


class QueueViewBuilderNonAdmin extends StatefulWidget {
  QueueViewBuilderNonAdmin({Key key, this.roomID,this.authToken}):super(key:key);
  final String roomID;
  final String authToken;
  @override
  _QueueViewBuilderNonAdminState createState() => _QueueViewBuilderNonAdminState();
}

class _QueueViewBuilderNonAdminState extends State<QueueViewBuilderNonAdmin> {
  TextEditingController searchCon = new TextEditingController();
  // Talks to spotify sdk to handle queue
  
  void test(String input, Room room) async {
    Map<String,List<dynamic>> results = await fullSearch(input,widget.authToken);
    List<Song> songs = results["songs"];
    for(var i = 0; i < 3 && i != songs.length; i++){
      Song s = songs[i];
      await room.addSong(s);
    }
}
  @override
  Widget build(BuildContext context) { 
    String roomKey = "";
    return StreamBuilder(
      stream: Firestore.instance.collection("room").document(widget.roomID).snapshots(),
      builder: (context, snapshot){
        List<Widget> children = [];
        if(!snapshot.hasData){
          // Add padding
          children.add(
            const Padding(
              padding: EdgeInsets.only(top: 100),
            )
          );
          children.add(
            Center(
              child: SizedBox(
              child: CircularProgressIndicator(),
              width: 100,
              height: 100,
              )
            )
          );
          children.add(
            const Padding(
              padding: EdgeInsets.only(top: 20),
              child: Center(
                child: Text('Joining room...'),
              )
            )
          );
        }
        else if(snapshot.hasError){
          roomKey = "ERROR";
          children.add(Text("Error has occured"));
        }
        else if(snapshot.hasData && snapshot.data.data != null){
          Room r = new Room.fromDocumentSnapshot(snapshot.data);
          roomKey = r.getRoomKey();
          r.sortQueue();
          // Search bar
          children.add(TextField(
            controller: searchCon,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Search',
            )
          ));
           children.add(
            RaisedButton(
              onPressed: () => test(searchCon.text,r),
              child:Text("Test add songs")
            )
          );

         // Show the current queue
          if(!r.queueIsEmpty()){
            r.getSongs().asMap().forEach((index,song){
                children.add(
                  GestureDetector(
                    child: SongCard(song: song), 
                    onTap: (){
                      r.vote(index);
                    }
                    ,)
                  );
            });
          } // end queue is not empty            
            else{
              children.add(Text("Queue is currently empty"));
            }
          // Show current song
          if(r.getCurrentSong() != null){
            children.add(
              Column(
                children: <Widget>[
                  Text("Now Playing:"),
                  SongCard(song: r.getCurrentSong())
                ]));
          }
          } // end snapshot
        
        return 
          Center(
            child: Column(
              children: children,
            ),
        );
      } // end build 
    );
  }
}