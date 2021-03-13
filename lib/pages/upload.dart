import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as im;
import 'package:image_picker/image_picker.dart';
import 'package:instasend/models/user.dart';
import 'package:instasend/pages/home.dart';
import 'package:instasend/widgets/progress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

final _picker = ImagePicker();

class Upload extends StatefulWidget {
  final User currentUser;

  Upload({this.currentUser});

  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload>
    with AutomaticKeepAliveClientMixin<Upload> {
  File file;
  bool isUploading = false;
  String postId = Uuid().v4();
  TextEditingController locationController = TextEditingController();
  TextEditingController captionController = TextEditingController();
  BuildContext dialogContext;

  handleTakePhoto() async {
    Navigator.pop(dialogContext);
    PickedFile image = await _picker.getImage(
      source: ImageSource.camera,
      maxHeight: 675,
      maxWidth: 960,
    );

    setState(() {
      this.file = File(image.path);
    });
  }

  handleChooseFromGallery() async {
    Navigator.pop(dialogContext);
    PickedFile image = await _picker.getImage(
      source: ImageSource.gallery,
    );
    setState(() {
      this.file = File(image.path);
    });
  }

  selectImage(parentContext) {
    return showDialog(
      context: parentContext,
      builder: (context) {
        dialogContext = context;
        return SimpleDialog(
          titlePadding: EdgeInsets.only(top: 15.0, bottom: 5.0),
          elevation: 6.0,
          backgroundColor: Colors.white,
          title: Text(
            'Create Post !',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 36.0,
              fontWeight: FontWeight.bold,
              fontFamily: 'Caveat',
            ),
          ),
          children: [
            SimpleDialogOption(
              child: Text(
                'Picture with Camera',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.0,
                  fontFamily: 'Comfortaa',
                ),
              ),
              onPressed: handleTakePhoto,
            ),
            SimpleDialogOption(
              child: Text(
                'Image with Gallery',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.0,
                  fontFamily: 'Comfortaa',
                ),
              ),
              onPressed: handleChooseFromGallery,
            ),
            SimpleDialogOption(
              child: Text(
                'Cancel',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.0,
                  fontFamily: 'Comfortaa',
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  Scaffold buildSplashScreen() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Text(
          'Upload',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        color: Colors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/images/upload.svg',
              height: 260.0,
            ),
            SizedBox(
              height: 20.0,
            ),
            GestureDetector(
              onTap: () => selectImage(context),
              child: Container(
                height: 60.0,
                width: 200.0,
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
                child: Center(
                  child: Text(
                    'Upload Something',
                    style: TextStyle(
                        fontSize: 16.0,
                        fontFamily: 'Comfortaa',
                        fontWeight: FontWeight.w500,
                        color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  clearImage() {
    setState(() {
      file = null;
    });
  }

  compressImage() async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    im.Image imageFile = im.decodeImage(file.readAsBytesSync());
    final compressedImageFile = File('$path/img_$postId.jpg')
      ..writeAsBytesSync(
        im.encodeJpg(imageFile, quality: 80),
      );
    setState(() {
      file = compressedImageFile;
    });
  }

  Future<String> uploadImage(imageFile) async {
    StorageUploadTask uploadTask = storageRef
        .child('posts')
        .child(currentUser.id)
        .child('post_$postId.jpg')
        .putFile(imageFile);
    StorageTaskSnapshot storageSnap = await uploadTask.onComplete;
    String downloadUrl = await storageSnap.ref.getDownloadURL();
    return downloadUrl;
  }

  createPostInFirestore({
    String mediaUrl,
    String location,
    String description,
  }) {
    postsRef
        .document(widget.currentUser.id)
        .collection('userPosts')
        .document(postId)
        .setData(
      {
        "postId": postId,
        'ownerId': widget.currentUser.id,
        'username': widget.currentUser.username,
        'mediaUrl': mediaUrl,
        'description': description,
        'location': location,
        'timestamp': timestamp,
        'likes': {},
      },
    );
  }

  handleSubmit() async {
    setState(() {
      isUploading = true;
    });
    await compressImage();
    String mediaUrl = await uploadImage(file);
    createPostInFirestore(
      mediaUrl: mediaUrl,
      location: locationController.text,
      description: captionController.text,
    );
    captionController.clear();
    locationController.clear();
    setState(() {
      file = null;
      isUploading = false;
      postId = Uuid().v4();
    });
  }

  Scaffold buildUploadForm() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: clearImage,
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black54,
          ),
        ),
        title: Text(
          'New Post',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        actions: [
          FlatButton(
            onPressed: isUploading ? null : () => handleSubmit(),
            child: Text(
              'Post',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 20.0,
                color: Theme.of(context).accentColor,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          isUploading ? linearProgress() : Text(''),
          Container(
            height: 230.0,
            width: MediaQuery.of(context).size.width * 0.8,
            child: Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: FileImage(file),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 10.0),
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).accentColor,
              child: Padding(
                padding: const EdgeInsets.all(1.0),
                child: CircleAvatar(
                  backgroundImage:
                      CachedNetworkImageProvider(widget.currentUser.photoUrl),
                ),
              ),
            ),
            title: Container(
              width: 250.0,
              child: TextField(
                controller: captionController,
                style: TextStyle(
                  fontFamily: 'Caveat',
                  fontSize: 23.0,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  hintText: 'Write you Story...',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(
              Icons.pin_drop,
              color: Colors.red,
              size: 35.0,
            ),
            title: Container(
              width: 250.0,
              child: TextField(
                controller: locationController,
                style: TextStyle(
                  fontFamily: 'Caveat',
                  fontSize: 21.0,
                  letterSpacing: 1,
                  color: Colors.black54,
                ),
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  hintText: 'Where was this memory made?',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Container(
            width: 200.0,
            height: 100.0,
            alignment: Alignment.center,
            child: RaisedButton.icon(
              padding: EdgeInsets.all(8.0),
              onPressed: getUserLocation,
              icon: Icon(
                Icons.my_location,
                color: Colors.white,
              ),
              label: Text(
                'Current Location',
                style: TextStyle(
                  fontSize: 16.0,
                  fontFamily: 'Mukta',
                  color: Colors.white,
                ),
              ),
              elevation: 3.0,
              highlightColor: Theme.of(context).accentColor,
              highlightElevation: 6.0,
              color: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  getUserLocation() async {
    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placemarks = await Geolocator()
        .placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark placemark = placemarks[0];

    String formattedAddress = '${placemark.locality}, ${placemark.country}';
    locationController.text = formattedAddress;
  }

  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return file == null ? buildSplashScreen() : buildUploadForm();
  }
}
