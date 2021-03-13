import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:instasend/models/user.dart';
import 'package:instasend/pages/edit_profile.dart';
import 'package:instasend/pages/home.dart';
import 'package:instasend/widgets/post.dart';
import 'package:instasend/widgets/post_tile.dart';
import 'package:instasend/widgets/profile_header.dart';
import 'package:instasend/widgets/progress.dart';

class Profile extends StatefulWidget {
  final String profileId;

  Profile({this.profileId});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final String currentUserId = currentUser?.id;
  String postOrientation = 'grid';
  bool isFollowing = false;
  bool isLoading = false;
  int followerCount = 0;
  int followingCount = 0;
  int postCount = 0;
  List<Post> posts = [];

  @override
  void initState() {
    super.initState();
    getProfilePosts();
    getFollowers();
    getFollowing();
    checkIfFollowing();
  }

  checkIfFollowing() async {
    DocumentSnapshot doc = await followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .document(currentUserId)
        .get();

    setState(() {
      isFollowing = doc.exists;
    });
  }

  getFollowers() async {
    QuerySnapshot snapshot = await followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .getDocuments();

    setState(() {
      followerCount = snapshot.documents.length;
    });
  }

  getFollowing() async {
    QuerySnapshot snapshot = await followingRef
        .document(widget.profileId)
        .collection('userFollowing')
        .getDocuments();

    setState(() {
      followingCount = snapshot.documents.length;
    });
  }

  getProfilePosts() async {
    setState(() {
      isLoading = true;
    });

    QuerySnapshot snapshot = await postsRef
        .document(widget.profileId)
        .collection('userPosts')
        .orderBy('timestamp', descending: true)
        .getDocuments();

    setState(() {
      isLoading = false;
      postCount = snapshot.documents.length;
      posts = snapshot.documents.map((doc) => Post.fromDocument(doc)).toList();
    });
  }

  Column buildCountColumn(String label, int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 19.0,
            fontFamily: 'Mukta',
            color: Colors.black,
            fontWeight: FontWeight.w900,
          ),
        ),
        Container(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.black54,
              fontSize: 13.0,
              letterSpacing: 2,
              fontFamily: 'Mukta',
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  editProfile() {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditProfile(currentUserId: currentUserId),
        ));
  }

  buildButton({String text, Function function}) {
    return GestureDetector(
      onTap: function,
      child: isFollowing
          ? Container(
              height: 50.0,
              width: 180.0,
              padding: EdgeInsets.all(3.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).accentColor,
                  ],
                ),
                borderRadius: BorderRadius.circular(5.0),
              ),
              child: Container(
                height: 40.0,
                width: 170.0,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5.0),
                ),
                child: Center(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 20.0,
                      fontFamily: 'Mukta',
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).accentColor,
                    ),
                  ),
                ),
              ),
            )
          : Container(
              height: 50.0,
              width: 180.0,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).accentColor,
                  ],
                ),
                borderRadius: BorderRadius.circular(5.0),
              ),
              child: Center(
                child: Text(
                  text,
                  style: TextStyle(
                      fontSize: 20.0,
                      fontFamily: 'Mukta',
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
    );
  }

  handleUnFollowUser() {
    setState(() {
      isFollowing = false;
    });
    // remove follower
    followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .document(currentUserId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });

    // remove following
    followingRef
        .document(currentUserId)
        .collection('userFollowing')
        .document(widget.profileId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });

    // Delete activity feed item to notify abt new follower
    activityFeedRef
        .document(widget.profileId)
        .collection('feedItems')
        .document(currentUserId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
  }

  handleFollowUser() {
    setState(() {
      isFollowing = true;
    });
    // Make Auth user follower or other user and update
    followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .document(currentUserId)
        .setData({});

    // Make other (that) user as our following and update
    followingRef
        .document(currentUserId)
        .collection('userFollowing')
        .document(widget.profileId)
        .setData({});

    // Add activity feed item to notify abt new follower
    activityFeedRef
        .document(widget.profileId)
        .collection('feedItems')
        .document(currentUserId)
        .setData({
      'type': 'follow',
      'ownerId': widget.profileId,
      'username': currentUser.username,
      'userId': currentUser.id,
      'userProfileImg': currentUser.photoUrl,
      'timestamp': timestamp,
    });
  }

  buildProfileButton() {
    bool isProfileOwner = currentUserId == widget.profileId;
    if (isProfileOwner) {
      return buildButton(
        text: 'Edit Profile',
        function: editProfile,
      );
    } else if (isFollowing) {
      return buildButton(
        text: 'Unfollow',
        function: handleUnFollowUser,
      );
    } else if (!isFollowing) {
      return buildButton(
        text: 'Follow',
        function: handleFollowUser,
      );
    }

    return GestureDetector(
      child: Container(
        height: 50.0,
        width: 180.0,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).accentColor,
            ],
          ),
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: Center(
          child: Text(
            'Edit Profile',
            style: TextStyle(
                fontSize: 20.0,
                fontFamily: 'Mukta',
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
        ),
      ),
    );
  }

  buildProfileHeader() {
    return FutureBuilder(
      future: usersRef.document(widget.profileId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        User user = User.fromDocument(snapshot.data);
        return Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16.0, horizontal: 16.0),
                    child: CircleAvatar(
                      radius: 52.0,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: CircleAvatar(
                          radius: 50.0,
                          backgroundColor: Colors.grey,
                          backgroundImage:
                              CachedNetworkImageProvider(user.photoUrl),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.only(top: 24.0),
                          child: Text(
                            user.username,
                            style: TextStyle(
                              fontFamily: 'Caveat',
                              fontSize: 25.0,
                              letterSpacing: 1,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.only(top: 4.0),
                          child: Text(
                            user.displayName,
                            style: TextStyle(
                              fontSize: 13.0,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.only(top: 2.0),
                          child: Text(
                            user.bio,
                            style: TextStyle(
                              fontSize: 16.0,
                              fontFamily: 'Mukta',
                              wordSpacing: 1,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(19.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Divider(
                      height: 2,
                      color: Colors.black54,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 24.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          buildCountColumn('Posts', postCount),
                          buildCountColumn('Followers', followerCount),
                          buildCountColumn('Following', followingCount),
                        ],
                      ),
                    ),
                    Divider(
                      height: 2,
                      color: Colors.black54,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 24.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          buildProfileButton(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  buildProfilePosts() {
    if (isLoading) {
      return circularProgress();
    } else if (posts.isEmpty) {
      return Container(
        color: Colors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 20.0,
            ),
            SvgPicture.asset(
              'assets/images/no_content.svg',
              height: 260.0,
            ),
            SizedBox(
              height: 20.0,
            ),
            Container(
              height: 50.0,
              width: 140.0,
              padding: EdgeInsets.all(4.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).accentColor,
                  ],
                ),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Container(
                height: 40.0,
                width: 130.0,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Center(
                  child: Text(
                    'No Posts',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontFamily: 'Comfortaa',
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else if (postOrientation == 'grid') {
      List<GridTile> gridTiles = [];
      posts.forEach((post) {
        gridTiles.add(GridTile(
          child: PostTile(
            post: post,
          ),
        ));
      });
      return GridView.count(
        crossAxisCount: 2,
        childAspectRatio: 1,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        shrinkWrap: true,
        padding: EdgeInsets.all(8.0),
        physics: NeverScrollableScrollPhysics(),
        children: gridTiles,
      );
    } else if (postOrientation == 'list') {
      return Column(
        children: posts,
      );
    }
  }

  setPostOrientation(String postOrientation) {
    setState(() {
      this.postOrientation = postOrientation;
    });
  }

  buildTogglePostOrientation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          onPressed: () => setPostOrientation('grid'),
          icon: Icon(
            Icons.grid_on,
            color: postOrientation == 'grid'
                ? Theme.of(context).primaryColor
                : Colors.black38,
          ),
        ),
        IconButton(
          onPressed: () => setPostOrientation('list'),
          icon: Icon(
            Icons.list,
            color: postOrientation == 'list'
                ? Theme.of(context).primaryColor
                : Colors.black38,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: profileHeader(context, 'Profile'),
      body: ListView(
        children: [
          buildProfileHeader(),
          Divider(),
          buildTogglePostOrientation(),
          Divider(
            height: 0.0,
          ),
          buildProfilePosts(),
        ],
      ),
    );
  }
}
