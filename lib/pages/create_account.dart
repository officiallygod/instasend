import 'dart:async';

import 'package:flutter/material.dart';

class CreateAccount extends StatefulWidget {
  @override
  _CreateAccountState createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  String username;

  submit() {
    final form = _formKey.currentState;

    if (form.validate()) {
      form.save();
      SnackBar snackBar = SnackBar(
        content: Text('Welcome $username!'),
      );
      _scaffoldKey.currentState.showSnackBar(snackBar);
      Timer(Duration(seconds: 1), () {
        Navigator.pop(context, username);
      });
    }
  }

  @override
  Widget build(BuildContext parentContext) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        iconTheme: IconThemeData(
          color: Colors.black87,
        ),
        title: Text(
          'New Account',
          style: TextStyle(color: Colors.black87),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.topRight,
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).accentColor,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                            top: 40.0,
                            left: 24.0,
                          ),
                          child: Text(
                            'Welcome',
                            style: TextStyle(
                              fontSize: 14.0,
                              fontFamily: 'Mukta',
                              fontWeight: FontWeight.w300,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                            top: 5.0,
                            left: 16.0,
                          ),
                          child: Text(
                            'Sign Up',
                            style: TextStyle(
                              fontSize: 50.0,
                              fontFamily: 'GreatVibes',
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 5,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20.0),
                      topRight: Radius.circular(20.0),
                    ),
                  ),
                  child: ListView(
                    children: [
                      Container(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                left: 16,
                                top: 50.0,
                                right: 16.0,
                                bottom: 200.0,
                              ),
                              child: Container(
                                child: Form(
                                  key: _formKey,
                                  child: TextFormField(
                                    onSaved: (val) => username = val.trim(),
                                    autovalidate: true,
                                    validator: (val) {
                                      if (val.trim().length < 3 ||
                                          val.isEmpty) {
                                        return 'Username too Short!';
                                      } else if (val.trim().length > 18) {
                                        return 'Username too Long!';
                                      } else {
                                        return null;
                                      }
                                    },
                                    maxLength: 18,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(),
                                      labelText: "Username",
                                      hintText: "Be a little Creative !",
                                      labelStyle: TextStyle(
                                        fontSize: 20.0,
                                        fontFamily: 'Mukta',
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: submit,
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
                                  borderRadius: BorderRadius.circular(50.0),
                                ),
                                child: Center(
                                  child: Text(
                                    'Submit',
                                    style: TextStyle(
                                        fontSize: 20.0,
                                        fontFamily: 'Satisfy',
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
