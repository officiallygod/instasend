import 'package:flutter/material.dart';
import 'package:instasend/pages/home.dart';
import 'package:instasend/widgets/post.dart';
import 'package:instasend/widgets/progress.dart';

class PostScreen extends StatelessWidget {
  final String userId;
  final String postId;

  PostScreen({this.postId, this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: postsRef
          .document(userId)
          .collection('userPosts')
          .document(postId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        Post post = Post.fromDocument(snapshot.data);
        return Center(
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.arrow_back,
                  color: Colors.black87,
                ),
              ),
              backgroundColor: Colors.white,
              centerTitle: true,
              title: Text(
                post.description,
                style: TextStyle(
                  color: Colors.black,
                ),
                overflow: TextOverflow.fade,
              ),
            ),
            body: ListView(
              children: [
                Container(
                  child: post,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
