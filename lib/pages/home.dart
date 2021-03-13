import 'dart:io';
import 'dart:ui';

import 'package:animator/animator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:instasend/models/user.dart';
import 'package:instasend/pages/activity_feed.dart';
import 'package:instasend/pages/create_account.dart';
import 'package:instasend/pages/profile.dart';
import 'package:instasend/pages/search.dart';
import 'package:instasend/pages/timeline.dart';
import 'package:instasend/pages/upload.dart';
import 'package:persistent_bottom_nav_bar/persistent-tab-view.dart';
import 'package:toast/toast.dart';

final GoogleSignIn googleSignIn = GoogleSignIn();
final StorageReference storageRef = FirebaseStorage.instance.ref();
final usersRef = Firestore.instance.collection('users');
final postsRef = Firestore.instance.collection('posts');
final commentsRef = Firestore.instance.collection('comments');
final timelineRef = Firestore.instance.collection('timeline');
final activityFeedRef = Firestore.instance.collection('feed');
final followersRef = Firestore.instance.collection('followers');
final followingRef = Firestore.instance.collection('following');
final DateTime timestamp = DateTime.now();
User currentUser;

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isAuth = false;
  int pageIndex = 0;
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  PageController pageController;

  @override
  void initState() {
    pageController = PageController();
    super.initState();
    // Detects when user signed In
    googleSignIn.onCurrentUserChanged.listen(
      (GoogleSignInAccount account) {
        handleSignIn(account);
      },
      onError: (err) {
        print('Error Signing In: $err');
      },
    );
    // Reauthorise Users when app is opened
    googleSignIn.signInSilently(suppressErrors: false).then(
      (account) {
        handleSignIn(account);
      },
    ).catchError(
      (err) {
        print('Error Signing In: $err');
      },
    );
  }

  handleSignIn(GoogleSignInAccount account) async {
    if (account != null) {
      await createUserInFirebase();
      setState(() {
        isAuth = true;
      });
      configurePushNotifications();
    } else {
      setState(() {
        isAuth = false;
      });
    }
  }

  configurePushNotifications() {
    final GoogleSignInAccount user = googleSignIn.currentUser;
    if (Platform.isIOS) getiOSPermissions();

    _firebaseMessaging.getToken().then((token) {
      usersRef
          .document(user.id)
          .updateData({"androidNotificationToken": token});
    });

    _firebaseMessaging.configure(
      onLaunch: (Map<String, dynamic> message) async {},
      onResume: (Map<String, dynamic> message) async {},
      onMessage: (Map<String, dynamic> message) async {
        final String recipientId = message['data']['recipient'];
        final String body = message['notification']['body'];

        if (recipientId == user.id) {
//          SnackBar snackBar = SnackBar(
//            content: Text(
//              body,
//              overflow: TextOverflow.ellipsis,
//            ),
//          );
//          Scaffold.of(context).showSnackBar(snackBar);
          Toast.show(
            body,
            context,
            duration: Toast.LENGTH_LONG,
            gravity: Toast.BOTTOM,
            backgroundColor: Colors.white,
            textColor: Colors.black87,
            backgroundRadius: 5.0,
          );
        }
      },
    );
  }

  getiOSPermissions() {
    _firebaseMessaging.requestNotificationPermissions(
      IosNotificationSettings(alert: true, badge: true, sound: true),
    );
    _firebaseMessaging.onIosSettingsRegistered.listen((event) {});
  }

  createUserInFirebase() async {
    //1. Check if User already exists in the Database (according to their ID)
    final GoogleSignInAccount user = googleSignIn.currentUser;
    DocumentSnapshot doc = await usersRef.document(user.id).get();

    if (!doc.exists) {
      //2. If the User doesn't exist take them to the create account page
      final username = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateAccount(),
        ),
      );

      //3. Get Username from create account, use it to make new user document in users collection
      usersRef.document(user.id).setData(
        {
          'id': user.id,
          'username': username,
          'photoUrl': user.photoUrl,
          'email': user.email,
          'displayName': user.displayName,
          'bio': "",
          "timestamp": timestamp,
        },
      );
      // Make users their own followers to view ur own posts
      await followingRef
          .document(user.id)
          .collection('userFollowers')
          .document(user.id)
          .setData({});

      // If not present make an Document and update it.
      doc = await usersRef.document(user.id).get();
    }

    currentUser = User.fromDocument(doc);
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  login() {
    googleSignIn.signIn();
  }

  logout() {
    googleSignIn.signOut();
  }

  onPageChanged(int pageIndex) {
    setState(() {
      this.pageIndex = pageIndex;
    });
  }

  onTap(int pageIndex) {
    pageController.animateToPage(pageIndex,
        duration: Duration(milliseconds: 500), curve: Curves.easeInOut);
//    persistentTabController.animateToPage(pageIndex,
//        duration: Duration(milliseconds: 500), curve: Curves.easeInOut);
  }

  SafeArea buildAuthScreen() {
    /*return RaisedButton(
      onPressed: logout,
      child: Text('Logout'),
    );*/
    return SafeArea(
      child: Scaffold(
        key: _scaffoldKey,
        body: PageView(
          children: [
            Timeline(currentUser: currentUser),
            Search(),
            Upload(currentUser: currentUser),
            ActivityFeed(),
            Profile(profileId: currentUser?.id),
          ],
          controller: pageController,
          onPageChanged: onPageChanged,
          physics: NeverScrollableScrollPhysics(),
        ),
        bottomNavigationBar: PersistentTabView(
          popAllScreensOnTapOfSelectedTab: true,
          onItemSelected: onTap,
          confineInSafeArea: true,
          stateManagement: false,
          backgroundColor: Colors.white,
          handleAndroidBackButtonPress: true,
          hideNavigationBarWhenKeyboardShows: true,
          resizeToAvoidBottomInset: false,
          itemAnimationProperties: ItemAnimationProperties(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          ),
          screenTransitionAnimation: ScreenTransitionAnimation(
            animateTabTransition: true,
            curve: Curves.easeInOut,
            duration: Duration(milliseconds: 200),
          ),
          navBarStyle: NavBarStyle.style12,
          items: [
            PersistentBottomNavBarItem(
              icon: Icon(
                Icons.home,
              ),
              title: ("Home"),
              activeColor: Theme.of(context).primaryColor,
              inactiveColor: Colors.grey,
            ),
            PersistentBottomNavBarItem(
              icon: Icon(
                Icons.search,
              ),
              title: ("Search"),
              activeColor: Theme.of(context).primaryColor,
              inactiveColor: Colors.grey,
            ),
            PersistentBottomNavBarItem(
              icon: Icon(
                Icons.add,
                size: 30.0,
              ),
              title: ("Upload"),
              activeColor: Theme.of(context).primaryColor,
              inactiveColor: Colors.black,
            ),
            PersistentBottomNavBarItem(
              icon: Icon(
                Icons.favorite_border,
              ),
              title: ("Notifications"),
              activeColor: Theme.of(context).primaryColor,
              inactiveColor: Colors.grey,
            ),
            PersistentBottomNavBarItem(
              icon: Icon(
                Icons.person_outline,
              ),
              title: ("Profile"),
              activeColor: Theme.of(context).primaryColor,
              inactiveColor: Colors.grey,
            ),
          ],
          screens: [
            Timeline(currentUser: currentUser),
            Search(),
            Upload(currentUser: currentUser),
            ActivityFeed(),
            Profile(profileId: currentUser?.id),
          ],
        ),
      ),
    );
  }

  Scaffold buildUnAuthScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.95),
              Theme.of(context).accentColor.withOpacity(0.95),
            ],
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Animator(
              duration: Duration(
                milliseconds: 1000,
              ),
              tween: Tween(
                begin: 0.1,
                end: 1.0,
              ),
              curve: Curves.elasticOut,
              cycles: 0,
              builder: (context, animatorState, child) => Transform.scale(
                scale: animatorState.value,
                child: FittedBox(
                  child: Text(
                    'Instasend.',
                    style: TextStyle(
                      fontFamily: 'GreatVibes',
                      fontSize: 70.0,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 20.0,
            ),
            GestureDetector(
              onTap: login,
              child: Container(
                width: 250.0,
                height: 70.0,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/google_signin_button.png'),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isAuth ? buildAuthScreen() : buildUnAuthScreen();
  }
}
