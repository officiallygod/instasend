import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:instasend/pages/home.dart';
import 'package:instasend/widgets/post.dart';
import 'package:instasend/widgets/progress.dart';
import 'package:timeago/timeago.dart' as timeago;

class Comments extends StatefulWidget {
  final String postId;
  final String postOwnerId;
  final String postMediaUrl;
  Post post;

  Comments({
    this.postId,
    this.postOwnerId,
    this.postMediaUrl,
  });

  @override
  CommentsState createState() => CommentsState(
        postId: this.postId,
        postOwnerId: this.postOwnerId,
        postMediaUrl: this.postMediaUrl,
      );
}

class CommentsState extends State<Comments> {
  final String postId;
  final String postOwnerId;
  final String postMediaUrl;
  bool isLoading = false;
  Post post;

  TextEditingController commentController = TextEditingController();

  CommentsState({
    this.postId,
    this.postOwnerId,
    this.postMediaUrl,
  });

  @override
  void initState() {
    super.initState();
    getProfilePosts();
  }

  buildComments() {
    return StreamBuilder(
      stream: commentsRef
          .document(postId)
          .collection('comments')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress2();
        }
        List<Comment> comments = [];
        snapshot.data.documents.forEach((doc) {
          comments.add(Comment.fromDocument(doc));
        });
        return Column(
          children: comments,
        );
      },
    );
  }

  addComment() {
    commentsRef.document(postId).collection('comments').add({
      'username': currentUser.username,
      'comment': commentController.text.trim(),
      'timestamp': timestamp,
      'avatarUrl': currentUser.photoUrl,
      'userId': currentUser.id,
    });

    bool isNotPostOwner = postOwnerId != currentUser.id;
    if (isNotPostOwner) {
      activityFeedRef.document(postOwnerId).collection('feedItems').add({
        'type': 'comment',
        'commentData': commentController.text.trim(),
        'username': currentUser.username,
        'userId': currentUser.id,
        'userProfileImg': currentUser.photoUrl,
        'postId': postId,
        'mediaUrl': postMediaUrl,
        'timestamp': timestamp,
      });
    }
    commentController.clear();
  }

  getProfilePosts() async {
    setState(() {
      isLoading = true;
    });

    DocumentSnapshot snapshot = await postsRef
        .document(postOwnerId)
        .collection('userPosts')
        .document(postId)
        .get();

    setState(() {
      isLoading = false;
      post = Post.fromDocument(snapshot);
    });
  }

  buildProfilePosts() {
    if (isLoading) {
      return circularProgress2();
    } else {
      return Column(children: [
        Post(
          postId: post.postId,
          description: post.description,
          likes: post.likes,
          location: post.location,
          mediaUrl: post.mediaUrl,
          ownerId: post.ownerId,
          isComment: true,
          username: post.username,
        ),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black87,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Comments',
          style: TextStyle(
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.9),
              Theme.of(context).accentColor.withOpacity(0.9),
            ],
          ),
        ),
        child: ListView(
          scrollDirection: Axis.vertical,
          children: [
            buildProfilePosts(),
            buildComments(),
            Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    top: 48.0,
                    bottom: 16.0,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black54,
                          offset: Offset(0.5, 0.8), //(x,y)
                          blurRadius: 6.0,
                        ),
                      ],
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: ListTile(
                      hoverColor: Colors.white,
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Padding(
                          padding: const EdgeInsets.all(1.0),
                          child: CircleAvatar(
                            backgroundColor: Colors.grey,
                            backgroundImage: CachedNetworkImageProvider(
                                currentUser.photoUrl),
                          ),
                        ),
                      ),
                      title: TextFormField(
                        style: TextStyle(
                          fontSize: 17.0,
                          color: Colors.black87,
                          letterSpacing: 1,
                          fontFamily: 'Caveat',
                        ),
                        controller: commentController,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintStyle: TextStyle(
                            color: Colors.black54,
                          ),
                          hintText: 'Write something nice...',
                        ),
                      ),
                      trailing: OutlineButton(
                        onPressed: addComment,
                        borderSide: BorderSide.none,
                        child: Text(
                          'Post',
                          style: TextStyle(
                            fontSize: 14.0,
                            letterSpacing: 1,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class Comment extends StatelessWidget {
  final String username;
  final String userId;
  final String avatarUrl;
  final String comment;
  final Timestamp timestamp;

  Comment({
    this.username,
    this.userId,
    this.avatarUrl,
    this.comment,
    this.timestamp,
  });

  factory Comment.fromDocument(DocumentSnapshot doc) {
    return Comment(
      username: doc['username'],
      userId: doc['userId'],
      avatarUrl: doc['avatarUrl'],
      comment: doc['comment'],
      timestamp: doc['timestamp'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ListTile(
            leading: CircleAvatar(
              maxRadius: 23.0,
              backgroundColor: Colors.grey,
              backgroundImage: CachedNetworkImageProvider(avatarUrl),
            ),
            title: Text(
              comment,
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1,
                fontFamily: 'Caveat',
              ),
            ),
            subtitle: Text(
              timeago.format(
                timestamp.toDate(),
              ),
              style: TextStyle(
                fontSize: 12.0,
                color: Colors.white54,
                fontFamily: 'Mukta',
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Divider(
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}
