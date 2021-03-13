import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instasend/models/user.dart';
import 'package:instasend/pages/home.dart';
import 'package:instasend/pages/search.dart';
import 'package:instasend/widgets/post.dart';
import 'package:instasend/widgets/progress.dart';

class Timeline extends StatefulWidget {
  final User currentUser;

  Timeline({this.currentUser});

  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  List<Post> posts;
  List<String> followingList = [];

  @override
  void initState() {
    super.initState();
    getTimeline();
    getFollowing();
  }

  getTimeline() async {
    QuerySnapshot snapshot = await timelineRef
        .document(widget.currentUser.id)
        .collection('timelinePosts')
        .orderBy('timestamp', descending: true)
        .getDocuments();
    List<Post> posts =
        snapshot.documents.map((doc) => Post.fromDocument(doc)).toList();
    setState(() {
      this.posts = posts;
    });
  }

  getFollowing() async {
    QuerySnapshot snapshot = await followingRef
        .document(currentUser.id)
        .collection('userFollowing')
        .getDocuments();
    setState(() {
      followingList = snapshot.documents.map((doc) => doc.documentID).toList();
    });
  }

  buildUsersToFollow() {
    return StreamBuilder(
      stream:
          usersRef.orderBy('timestamp', descending: true).limit(30).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress2();
        }
        List<UserResult> userResults = [];
        snapshot.data.documents.forEach((doc) {
          User user = User.fromDocument(doc);
          final bool isAuthUser = currentUser.id == user.id;
          final bool isFollowingUser = followingList.contains(user.id);
          //remove Auth User from Recommended List
          if (isAuthUser) {
            return;
          } else if (isFollowingUser) {
            return;
          } else {
            UserResult userResult = UserResult(user: user);
            userResults.add(userResult);
          }
        });
        return Container(
          padding: const EdgeInsets.all(50.0),
          color: Colors.white,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_add,
                        color: Colors.red,
                        size: 20.0,
                      ),
                      SizedBox(
                        width: 8.0,
                      ),
                      Text(
                        'Your to be Friends',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 20.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                children: userResults,
              ),
            ],
          ),
        );
      },
    );
  }

  buildTimeline() {
    if (posts == null) {
      return circularProgress();
    } else if (posts.isEmpty) {
      return buildUsersToFollow();
    } else {
      return ListView(
        children: posts,
      );
    }
  }

  @override
  Widget build(context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0.0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image(
            image: AssetImage('assets/images/logo64.png'),
          ),
        ),
        title: Hero(
          tag: 'mainAppName',
          child: Text(
            'Instasend',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 42.0,
              letterSpacing: 1,
              fontFamily: 'GreatVibes',
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Colors.black,
            ),
            onPressed: () => getTimeline(),
          )
        ],
        backgroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () => getTimeline(),
        child: buildTimeline(),
        color: Theme.of(context).primaryColor,
        strokeWidth: 3,
        backgroundColor: Colors.white,
      ),
    );
  }
}
