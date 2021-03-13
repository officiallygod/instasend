import 'package:flutter/material.dart';

AppBar profileHeader(context, String profileName) {
  return AppBar(
    elevation: 0.0,
    title: Text(
      profileName,
      style: TextStyle(
        color: Colors.black87,
        fontSize: 18.0,
        fontFamily: 'Roboto',
        letterSpacing: 1.5,
        fontWeight: FontWeight.w700,
      ),
    ),
    centerTitle: true,
    backgroundColor: Colors.white,
  );
}
