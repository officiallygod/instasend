import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:instasend/models/user.dart';
import 'package:instasend/pages/activity_feed.dart';
import 'package:instasend/pages/home.dart';
import 'package:instasend/widgets/progress.dart';

class Search extends StatefulWidget {
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search>
    with AutomaticKeepAliveClientMixin<Search> {
  TextEditingController searchController = TextEditingController();
  Future<QuerySnapshot> searchResultsFuture;

  handleSearch(String query) {
    Future<QuerySnapshot> users = usersRef
        .where('username', isGreaterThanOrEqualTo: query)
        .getDocuments();

    setState(
      () {
        searchResultsFuture = users;
      },
    );
  }

  AppBar buildSearchField() {
    return AppBar(
      backgroundColor: Colors.white,
      title: TextFormField(
        autofocus: false,
        keyboardAppearance: Brightness.dark,
        keyboardType: TextInputType.text,
        controller: searchController,
        style: TextStyle(
          fontFamily: 'Caveat',
          fontSize: 24.0,
          letterSpacing: 1,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Search Someone...',
          prefixIcon: Icon(Icons.search),
          suffixIcon: IconButton(
            icon: Icon(Icons.clear),
            onPressed: clearSearch,
          ),
        ),
        onFieldSubmitted: handleSearch,
      ),
    );
  }

  clearSearch() {
    searchController.clear();
    searchResultsFuture = null;
    FocusScope.of(context).unfocus();
  }

  Container buildNoContent() {
    final Orientation orientation = MediaQuery.of(context).orientation;
    return Container(
      color: Colors.white,
      child: Center(
        child: ListView(
          shrinkWrap: true,
          children: [
            SvgPicture.asset(
              'assets/images/search.svg',
              height: orientation == Orientation.portrait ? 300.0 : 200.0,
            ),
          ],
        ),
      ),
    );
  }

  buildSearchResults() {
    return FutureBuilder(
      future: searchResultsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        List<UserResult> searchResults = [];
        snapshot.data.documents.forEach((doc) {
          User user = User.fromDocument(doc);
          if (user.username.startsWith(searchController.text.substring(0, 1))) {
            UserResult searchResult = UserResult(
              user: user,
            );
            searchResults.add(searchResult);
          }
        });
        return ListView(
          children: searchResults,
        );
      },
    );
  }

  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: buildSearchField(),
      body:
          searchResultsFuture == null ? buildNoContent() : buildSearchResults(),
    );
  }
}

class UserResult extends StatelessWidget {
  final User user;

  UserResult({this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withOpacity(0.6),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => showProfile(context, profileId: user.id),
            child: ListTile(
              leading: CircleAvatar(
                maxRadius: 22,
                backgroundColor: Theme.of(context).primaryColor,
                child: Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.grey,
                    backgroundImage: CachedNetworkImageProvider(user.photoUrl),
                  ),
                ),
              ),
              title: Text(
                user.displayName,
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 20.0,
                  letterSpacing: 1,
                  fontFamily: 'Comfortaa',
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                user.username,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 15.0,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  fontFamily: 'Satisfy',
                ),
              ),
            ),
          ),
          Divider(
            height: 2.0,
            color: Colors.white54,
          ),
        ],
      ),
    );
  }
}
