import 'dart:async';

import 'package:animator/animator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:instasend/models/user.dart';
import 'package:instasend/pages/activity_feed.dart';
import 'package:instasend/pages/comments.dart';
import 'package:instasend/pages/home.dart';
import 'package:instasend/widgets/progress.dart';

import 'custom_image.dart';

class Post extends StatefulWidget {
  final String postId;
  final String ownerId;
  final String username;
  final String description;
  final String location;
  final String mediaUrl;
  final bool isComment;
  final dynamic likes;

  Post(
      {this.postId,
      this.ownerId,
      this.username,
      this.description,
      this.location,
      this.mediaUrl,
      this.isComment,
      this.likes});

  factory Post.fromDocument(DocumentSnapshot doc) {
    return Post(
      postId: doc['postId'],
      ownerId: doc['ownerId'],
      username: doc['username'],
      description: doc['description'],
      location: doc['location'],
      mediaUrl: doc['mediaUrl'],
      likes: doc['likes'],
      isComment: false,
    );
  }

  int getLikeCount(likes) {
    // if No Likes
    if (likes == null) {
      return 0;
    }
    int count = 0;
    // if key is explicitly set to true
    likes.values.forEach((val) {
      if (val == true) {
        count += 1;
      }
    });
    return count;
  }

  @override
  _PostState createState() => _PostState(
        postId: this.postId,
        ownerId: this.ownerId,
        username: this.username,
        location: this.location,
        description: this.description,
        mediaUrl: this.mediaUrl,
        likes: this.likes,
        isComment: this.isComment,
        likesCount: getLikeCount(this.likes),
      );
}

class _PostState extends State<Post> {
  final String currentUserId = currentUser?.id;

  final String postId;
  final String ownerId;
  final String username;
  final String description;
  final String location;
  final String mediaUrl;
  final bool isComment;
  int likesCount;
  Map likes;
  bool isLiked;
  bool showHeart = false;

  _PostState(
      {this.postId,
      this.ownerId,
      this.username,
      this.description,
      this.location,
      this.mediaUrl,
      this.likesCount,
      this.isComment,
      this.likes});

  buildPostHeader() {
    return FutureBuilder(
      future: usersRef.document(ownerId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        User user = User.fromDocument(snapshot.data);
        bool isPostOwner = currentUserId == ownerId;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor,
            child: Padding(
              padding: const EdgeInsets.all(1.0),
              child: CircleAvatar(
                backgroundColor: Colors.grey,
                backgroundImage: CachedNetworkImageProvider(user.photoUrl),
              ),
            ),
          ),
          title: GestureDetector(
            onTap: () => showProfile(context, profileId: user.id),
            child: Text(
              user.username,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 16.0,
                letterSpacing: 1.2,
                fontFamily: 'Mukta',
              ),
            ),
          ),
          subtitle: Text(
            location,
            style: TextStyle(
              color: Colors.black54,
              fontSize: 12.0,
              letterSpacing: 1,
              fontWeight: FontWeight.w300,
            ),
          ),
          trailing: isPostOwner
              ? IconButton(
                  onPressed: () => handleDeletePost(context),
                  icon: Icon(
                    Icons.expand_more,
                    color: Colors.black87,
                  ),
                )
              : Text(''),
        );
      },
    );
  }
//
//  handleDeletePost(BuildContext parentContext) {
//    return showDialog(
//      context: parentContext,
//      builder: (context) {
//        return SimpleDialog(
//          title: Text('Delete this memory ?'),
//          children: [
//            SimpleDialogOption(
//              onPressed: () {
//                Navigator.pop(context);
//                deletePost();
//              },
//              child: Text(
//                'Delete',
//                style: TextStyle(color: Colors.red),
//              ),
//            ),
//            SimpleDialogOption(
//              onPressed: () => Navigator.pop(context),
//              child: Text(
//                'Cancel',
//                style: TextStyle(color: Colors.black87),
//              ),
//            ),
//          ],
//        );
//      },
//    );
//  }

  handleDeletePost(BuildContext parentContext) {
    return showDialog(
        context: parentContext,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              'Delete Post',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26.0,
                fontFamily: 'Caveat',
              ),
            ),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(
                    'Do you wish to Delete this memory?',
                    style: TextStyle(
                      fontFamily: 'Mukta',
                    ),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              FlatButton(
                child: Text(
                  'Delete',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 18.0,
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  deletePost();
                },
              ),
              FlatButton(
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 18.0,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  // To Delete a post OwnerId and current user id must be equal so as to use interchangeably
  deletePost() async {
    postsRef
        .document(ownerId)
        .collection('userPosts')
        .document(postId)
        .get()
        .then(
          (doc) => {
            if (doc.exists)
              {
                doc.reference.delete(),
              },
          },
        );
//
//    //Delete the Uploaded Image for the Post
//    storageRef
//        .child('posts')
//        .child(currentUser.id)
//        .child('post_$postId.jpg')
//        .delete();

    // then delete all activity feed notification
    QuerySnapshot activityFeedSnapshot = await activityFeedRef
        .document(ownerId)
        .collection('feedItems')
        .where('postId', isEqualTo: postId)
        .getDocuments();

    activityFeedSnapshot.documents.forEach(
      (doc) {
        if (doc.exists) {
          doc.reference.delete();
        }
      },
    );

    //Delete All Comments
    QuerySnapshot commentsSnapshot = await commentsRef
        .document(postId)
        .collection('comments')
        .getDocuments();

    commentsSnapshot.documents.forEach(
      (doc) {
        if (doc.exists) {
          doc.reference.delete();
        }
      },
    );
  }

  handleLikePost() {
    bool _isLiked = likes[currentUserId] == true;

    if (_isLiked) {
      postsRef
          .document(ownerId)
          .collection('userPosts')
          .document(postId)
          .updateData({'likes.$currentUserId': false});
      removeLikeFromActivityFeed();
      setState(() {
        likesCount -= 1;
        _isLiked = false;
        likes[currentUserId] = false;
      });
    } else if (!_isLiked) {
      postsRef
          .document(ownerId)
          .collection('userPosts')
          .document(postId)
          .updateData({'likes.$currentUserId': true});
      addLikeToActivityFeed();
      setState(() {
        likesCount += 1;
        _isLiked = true;
        likes[currentUserId] = true;
        showHeart = true;
      });
      Timer(Duration(milliseconds: 500), () {
        setState(() {
          showHeart = false;
        });
      });
    }
  }

  addLikeToActivityFeed() {
    bool isNotPostOwner = currentUserId != ownerId;

    if (isNotPostOwner) {
      activityFeedRef
          .document(ownerId)
          .collection('feedItems')
          .document(postId)
          .setData({
        'type': 'like',
        'username': currentUser.username,
        'userId': currentUser.id,
        'userProfileImg': currentUser.photoUrl,
        'postId': postId,
        'mediaUrl': mediaUrl,
        'timestamp': timestamp,
      });
    }
  }

  removeLikeFromActivityFeed() {
    bool isNotPostOwner = currentUserId != ownerId;

    if (isNotPostOwner) {
      activityFeedRef
          .document(ownerId)
          .collection('feedItems')
          .document(postId)
          .get()
          .then((value) {
        if (value.exists) {
          value.reference.delete();
        }
      });
    }
  }

  buildPostImage() {
    return Container(
      margin: const EdgeInsets.only(bottom: 6.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey,
            offset: Offset(0.0, 0.4), //(x,y)
            blurRadius: 6.0,
          ),
        ],
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: GestureDetector(
        onDoubleTap: handleLikePost,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: cachedNetworkImage(mediaUrl),
            ),
            showHeart
                ? Animator(
                    duration: Duration(
                      milliseconds: 300,
                    ),
                    tween: Tween(
                      begin: 0.6,
                      end: 1.5,
                    ),
                    curve: Curves.elasticOut,
                    cycles: 0,
                    builder: (context, animatorState, child) => Transform.scale(
                      scale: animatorState.value,
                      child: Icon(
                        Icons.favorite,
                        size: 80.0,
                        color: Colors.red.withOpacity(0.6),
                      ),
                    ),
                  )
                : Text(''),
          ],
        ),
      ),
    );
  }

  buildPostFooter() {
    return Column(
      children: [
        isComment
            ? Text('')
            : Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 45.0, left: 20.0),
                  ),
                  GestureDetector(
                    onTap: handleLikePost,
                    child: Row(
                      children: [
                        Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: Colors.red,
                          size: 28.0,
                        ),
                        Container(
                          margin: EdgeInsets.only(left: 10.0),
                          child: Text(
                            '$likesCount',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      right: 30.0,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => showComments(
                      context,
                      postId: postId,
                      ownerId: ownerId,
                      mediaUrl: mediaUrl,
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.blue,
                      size: 28.0,
                    ),
                  ),
                ],
              ),
        isComment
            ? SizedBox(
                height: 10.0,
              )
            : SizedBox(
                height: 0.0,
              ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16.0,
            ),
            Expanded(
              child: Text(
                description,
                style: TextStyle(
                  fontSize: 22.0,
                  color: Colors.black87,
                  fontWeight: FontWeight.w300,
                  fontFamily: 'Caveat',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    isLiked = (likes[currentUserId] == true);
    return Padding(
      padding: const EdgeInsets.only(
          left: 10.0, right: 10.0, top: 16.0, bottom: 16.0),
      child: Container(
        padding:
            EdgeInsets.only(left: 8.0, right: 8.0, top: 16.0, bottom: 20.0),
        margin: const EdgeInsets.only(bottom: 6.0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey,
              offset: Offset(0.0, 0.2), //(x,y)
              blurRadius: 1.0,
            ),
          ],
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildPostHeader(),
            buildPostImage(),
            buildPostFooter(),
          ],
        ),
      ),
    );
  }
}

showComments(BuildContext context,
    {String postId, String ownerId, String mediaUrl}) {
  Navigator.push(context, MaterialPageRoute(builder: (context) {
    return Comments(
      postId: postId,
      postOwnerId: ownerId,
      postMediaUrl: mediaUrl,
    );
  }));
}
