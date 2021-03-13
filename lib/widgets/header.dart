import 'package:flutter/material.dart';

AppBar header(context) {
  return AppBar(
    elevation: 0.0,
    leading: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Image(
        image: AssetImage('assets/images/logo64.png'),
      ),
    ),
    title: Text(
      'Instasend',
      style: TextStyle(
        color: Colors.black87,
        fontSize: 42.0,
        letterSpacing: 1,
        fontFamily: 'GreatVibes',
        fontWeight: FontWeight.w500,
      ),
    ),
    centerTitle: true,
    actions: <Widget>[
      IconButton(
        icon: Icon(
          Icons.chat_bubble_outline,
          color: Colors.black,
        ),
        onPressed: () {},
      )
    ],
    backgroundColor: Colors.white,
  );
}
