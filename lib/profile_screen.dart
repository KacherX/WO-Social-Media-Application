import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wo/edit_profile_frame.dart';
import 'package:wo/models/global_user_data.dart';
import 'package:wo/services/firestore.dart';
import 'package:wo/services/place_fetcher.dart';

List<String> indexMonths = [
  "January",
  "February",
  "March",
  "April",
  "May",
  "June",
  "July",
  "August",
  "September",
  "October",
  "November",
  "December",
];

class ProfileScreen extends StatefulWidget {
  final GlobalUserData globalUserData;
  final Function changeFlagFunction;
  const ProfileScreen({Key? key, required this.globalUserData, required this.changeFlagFunction}) : super(key: key);

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  late GlobalUserData globalUserData;
  late Function changeFlagFunction;
  late String uid;

  final _postsScrollController = ScrollController();
  late AnimationController _loadingAnimationController;

  late StreamSubscription<QuerySnapshot> _postListener;
  late StreamSubscription<QuerySnapshot> _saveListener;
  Map<String, Map<String, dynamic>> localSavedPostsData = {};

  bool loadPostsOperation = false;
  bool loadSavesOperation = false;
  bool allPostsLoaded = false;
  bool allSavesLoaded = false;

  int _selectedTabIndex = 0;
  void onTabTapped(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
  }

  void setLocalSavedPostsData() async {
    localSavedPostsData = await Firestore().getPostsWithDataFromSaves(savesData: globalUserData.savesData);
  }

  void setUserStatus() async {
    List<Future<dynamic>> futures = [
      Firestore().getFriendsCount(uid: uid),
    ];

    List<dynamic> results = await Future.wait(futures);

    globalUserData.SetFriendsCount(results[0]);

    if (mounted) {
      setState(() {});
    }
  }

  void postAddedEvent() {
    _postListener = Firestore().getPostsSnapshots(uid: uid, lastPostDate: Timestamp.fromDate(DateTime(2100))).listen((event) {
      if (mounted) {
        setState(() {
          globalUserData.ChangePostsData(event.docs);
          allPostsLoaded = false;
        });
      }
    }, onError: (error) => print("Listen failed: $error"));
  }

  void saveAddedEvent() {
    _saveListener = Firestore().getSavedPostsSnapshots(uid: uid, lastSaveDate: Timestamp.fromDate(DateTime(2100))).listen((event) {
      if (mounted) {
        setState(() {
          globalUserData.ChangeSavesData(event.docs);
        });
        setLocalSavedPostsData();
      }
    }, onError: (error) => print("Listen failed: $error"));
  }

  void loadMorePosts() async {
    if (loadPostsOperation == false && allPostsLoaded == false && globalUserData.postsData != []) {
      loadPostsOperation = true;
      if (mounted) {
        setState(() {});
      }

      final postsData = await Firestore().getUserPosts(uid: uid, lastPostDate: globalUserData.postsData.last["postCreateDate"]);
      if (postsData.docs.length < 30) {
        allPostsLoaded = true;
      }
      if (postsData.docs.isNotEmpty) {
        globalUserData.AddPostsData(postsData.docs);
      }

      loadPostsOperation = false;
      if (mounted) {
        setState(() {});
      }
    }
  }

  void loadMoreSaves() async {
    if (loadSavesOperation == false && allSavesLoaded == false && globalUserData.savesData != []) {
      loadSavesOperation = true;
      if (mounted) {
        setState(() {});
      }

      final savesData = await Firestore().getUserSaves(uid: uid, lastSaveDate: globalUserData.savesData.last["postSaveDate"]);
      if (savesData.docs.length < 30) {
        allSavesLoaded = true;
      }
      if (savesData.docs.isNotEmpty) {
        globalUserData.AddSavesData(savesData.docs);
        setLocalSavedPostsData();
      }

      loadSavesOperation = false;
      if (mounted) {
        setState(() {});
      }
    }
  }

  void checkLastOfScroll() {
    _postsScrollController.addListener(() {
      if (_postsScrollController.position.pixels == _postsScrollController.position.maxScrollExtent) {
        if (_selectedTabIndex == 0) {
          loadMorePosts();
        } else if (_selectedTabIndex == 1) {
          loadMoreSaves();
        }
      }
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _postListener.cancel();
    _saveListener.cancel();
    _postsScrollController.dispose();
    _loadingAnimationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    globalUserData = widget.globalUserData;
    changeFlagFunction = widget.changeFlagFunction;
    uid = globalUserData.uid;
    postAddedEvent();
    saveAddedEvent();

    setUserStatus();
    checkLastOfScroll();

    _loadingAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _postsScrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Image
          Stack(
            children: [
              globalUserData.userData["profileCoverPhotoUrl"] != null
                  ? Image.network(
                      globalUserData.userData["profileCoverPhotoUrl"],
                      width: 5000,
                      height: 100,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      height: 100,
                      width: 5000,
                      color: Colors.grey[300],
                    ),
              Padding(
                  padding: EdgeInsets.only(top: 65, left: 25),
                  child: globalUserData.userData["profilePhotoUrl"] != null
                      ? CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.white,
                          child: Padding(
                            padding: EdgeInsets.all(2.5), // Border radius
                            child: ClipOval(
                                child: Image.network(
                              globalUserData.userData["profilePhotoUrl"],
                              width: 150,
                              height: 150,
                              fit: BoxFit.cover,
                            )),
                          ),
                        )
                      : CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.white,
                          child: Padding(
                            padding: EdgeInsets.all(0), // Border radius
                            child: Icon(
                              Icons.account_circle,
                              size: 70,
                              color: Colors.grey[300],
                            ),
                          ),
                        )),
              Padding(
                padding: EdgeInsets.only(top: 105, right: 5),
                child: Align(
                  alignment: Alignment(1, 0),
                  child: Container(
                    height: 30,
                    child: ElevatedButton(
                      onPressed: () {
                        showCupertinoModalPopup(
                          context: context,
                          builder: (context) => EditProfileFrame(globalUserData: globalUserData),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        "Edit Profile",
                        style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),
              (globalUserData.userData["name"] == "")
                  ? SizedBox(height: 0)
                  : Padding(
                      padding: EdgeInsets.only(top: 140, left: 10),
                      child: Text(
                        globalUserData.userData["name"],
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                      ),
                    ),
            ],
          ),
          // Followers and Following Section
          (globalUserData.userData["bio"] == "")
              ? SizedBox(height: 0)
              : Padding(
                  padding: EdgeInsets.only(left: 10),
                  child: Text(
                    globalUserData.userData["bio"],
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
          Padding(
            padding: EdgeInsets.only(top: 10, left: 10),
            child: GestureDetector(
              onTap: () {
                changeFlagFunction("Friends");
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(Icons.people, size: 20),
                  SizedBox(width: 5),
                  Text(globalUserData.friendsCount.toString(), style: TextStyle(fontWeight: FontWeight.w600)),
                  const Text(
                    " Friends",
                    style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 10),
            child: Text(
              "Joined in " +
                  indexMonths[globalUserData.userData["joinDate"].toDate().month - 1] +
                  " " +
                  globalUserData.userData["joinDate"].toDate().year.toString(),
              style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 10),
            child: DefaultTabController(
              length: 2,
              child: TabBar(
                onTap: onTabTapped,
                indicatorColor: Colors.deepPurple,
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.black, // Color of selected tab text
                unselectedLabelColor: Colors.grey, // Color of unselected tab text
                tabs: const <Widget>[
                  Tab(
                    icon: Icon(Icons.photo),
                  ),
                  Tab(
                    icon: Icon(Icons.collections),
                  ),
                ],
              ),
            ),
          ),
          //_TabBars.elementAt(_selectedTabIndex),
          _selectedTabIndex == 0
              ? (globalUserData.postsData.isEmpty
                  ? NoPostsTabBar()
                  : GridView.builder(
                      primary: false,
                      shrinkWrap: true,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3, // Number of columns
                      ),
                      itemCount: globalUserData.postsData.length, // Total number of posts
                      itemBuilder: (context, index) {
                        final doc = globalUserData.postsData[index]; // Access the post by index
                        Map<String, dynamic> data = doc.data();

                        return ProfilePost(data, doc.id); // Return the grid item
                      },
                    ))
              : (globalUserData.savesData.isEmpty)
                  ? NoSavesTabBar()
                  : GridView.builder(
                      primary: false,
                      shrinkWrap: true,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3, // Number of columns
                      ),
                      itemCount: globalUserData.savesData.length, // Total items
                      itemBuilder: (context, index) {
                        final doc = globalUserData.savesData[index];

                        return SavesPost(doc.id); // Return the grid item
                      },
                    ),
          (loadPostsOperation || loadSavesOperation) ? miniLoadingAnimation() : const SizedBox(height: 0),
        ],
      ),
    );
  }

  GestureDetector ProfilePost(Map<String, dynamic> postData, String postId) {
    return GestureDetector(
      onTap: () {
        globalUserData.SetSelectedPostId(postId);
        changeFlagFunction("UserPosts");
      },
      child: Image.network(
        postData["postPhotoUrl"],
        fit: BoxFit.cover,
      ),
    );
  }

  GestureDetector SavesPost(String postId) {
    return GestureDetector(
      onTap: () {
        globalUserData.SetSelectedPostId(postId);
        changeFlagFunction("SavedPosts");
      },
      child: localSavedPostsData[postId] == null
          ? Container()
          : Image.network(
              localSavedPostsData[postId]!["postPhotoUrl"],
              fit: BoxFit.cover,
            ),
    );
  }

  Center miniLoadingAnimation() {
    return Center(
      child: Container(
        child: RotationTransition(
          turns: _loadingAnimationController,
          child: const Icon(
            Icons.refresh,
            size: 25,
          ),
        ),
      ),
    );
  }

  Center NoPostsTabBar() {
    return const Center(
      child: Column(
        children: [
          SizedBox(
            height: 75,
          ),
          Icon(
            Icons.photo_outlined,
            size: 60,
          ),
          Text(
            "Empty",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Center NoSavesTabBar() {
    return const Center(
      child: Column(
        children: [
          SizedBox(
            height: 75,
          ),
          Icon(
            Icons.collections_outlined,
            size: 60,
          ),
          Text(
            "Empty",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Center FavouritesTabBar() {
    return Center(
      child: Text("Favourites"),
    );
  }
}
