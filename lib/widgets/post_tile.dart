import 'package:flutter/material.dart';
import 'package:instasend/pages/post_screen.dart';
import 'package:instasend/widgets/custom_image.dart';
import 'package:instasend/widgets/post.dart';

class PostTile extends StatelessWidget {
  final Post post;

  PostTile({this.post});

  showPost(context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostScreen(
          postId: post.postId,
          userId: post.ownerId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        boxShadow: [
          BoxShadow(
            color: Colors.grey,
            offset: Offset(0.0, 0.1), //(x,y)
            blurRadius: 6.0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.0),
        child: GestureDetector(
          onTap: () => showPost(context),
          child: cachedNetworkImage(post.mediaUrl),
        ),
      ),
    );
  }
}
