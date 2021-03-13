import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

/*Container circularProgress() {
  return Container(
    alignment: Alignment.center,
    padding: EdgeInsets.only(top: 10.0),
    child: CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation(
        Color(0xFFFF512F),
      ),
    ),
  );
}*/

Container circularProgress() {
  return Container(
    alignment: Alignment.center,
    padding: EdgeInsets.only(top: 10.0),
    child: SpinKitChasingDots(
      color: Color(0xFFDD2476),
      size: 100.0,
    ),
  );
}

Container circularProgress2() {
  return Container(
    alignment: Alignment.center,
    padding: EdgeInsets.only(top: 10.0),
    child: SpinKitThreeBounce(
      color: Colors.white,
      size: 30.0,
    ),
  );
}

linearProgress() {
  return Container(
    padding: EdgeInsets.only(bottom: 10.0),
    child: LinearProgressIndicator(
      valueColor: AlwaysStoppedAnimation(
        Color(0xFFFF512F),
      ),
    ),
  );
}
