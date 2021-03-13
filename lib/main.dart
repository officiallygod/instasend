import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:instasend/pages/home.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.white),
    );

    return MaterialApp(
      title: 'Instasend',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(
        primaryColor: Color(0xFFFF512F),
        accentColor: Color(0xFFDD2476),
      ),
      home: Home(),
    );
  }
}
