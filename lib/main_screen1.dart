import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:wo/app_bars.dart';
import 'package:wo/favourites_screen.dart';
import 'package:wo/friends_screen.dart';
import 'package:wo/home_screen.dart';
import 'package:wo/login_screen.dart';
import 'package:wo/main_map_screen.dart';
import 'package:wo/map_screen.dart';
import 'package:wo/models/global_place_data.dart';
import 'package:wo/models/global_user_data.dart';
import 'package:wo/notifications_screen.dart';
import 'package:wo/post_screen.dart';
import 'package:wo/profile_screen.dart';
import 'package:wo/search_screen.dart';
import 'package:wo/services/auth.dart';
import 'package:wo/services/firestore.dart';
import 'package:wo/settings_screen.dart';
import 'package:wo/user_search_profile_screen.dart';

class MainScreen1 extends StatefulWidget {
  final GlobalUserData globalUserData;
  final GlobalPlaceData globalPlaceData;
  final Function changeScreenFunction;
  const MainScreen1({Key? key, required this.globalUserData, required this.globalPlaceData, required this.changeScreenFunction}) : super(key: key);

  @override
  State<MainScreen1> createState() => _MainScreen1State();
}

class _MainScreen1State extends State<MainScreen1> with WidgetsBindingObserver {
  late GlobalUserData globalUserData;
  late GlobalPlaceData globalPlaceData;
  late Function changeScreenFunction;
  late String uid;

  final PageController _controller = PageController(initialPage: 0);

  late StreamSubscription<DocumentSnapshot> _userDataListener;

  bool onLogout = false;

  int _selectedIndex = 0;
  String _isViewingHome = "";
  String _isViewingProfilePost = "";
  String _isUserSelected = "";
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _controller.jumpToPage(_selectedIndex);

      if (index != 1) {
        _isUserSelected = "";
        globalUserData.ClearLists();
      }
    });
  }

  void _onMapView(String s) {
    _isViewingHome = s;
    if (s == "") {
      globalPlaceData.selctedPlace = null;
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _changeViewProfilePostFlag(String s) {
    setState(() {
      _isViewingProfilePost = s;
      if (_isViewingProfilePost != "UserPosts" && _isViewingProfilePost != "SavedPosts") {
        globalUserData.SetSelectedPostId("");
      }
    });
  }

  void _changeSearchUserFlag(String s) {
    if (s == "" && _isUserSelected != "SearchProfile") {
      _isUserSelected = "SearchProfile";
      globalUserData.selectedUserData.last!.SetSelectedPostId("");
    } else {
      _isUserSelected = s;
      if (s == "") {
        globalUserData.PopSelectedUserData()!.userData["username"];
        String lastPage = globalUserData.PopLastPage();
        if (lastPage == "Friends" || lastPage == "UserPosts" || lastPage == "SavedPosts") {
          _onItemTapped(2);
        } else if (lastPage == "Notifications") {
          _onItemTapped(4);
        } else if (lastPage == "SearchPosts") {
          _isUserSelected = "SearchPosts";
        } else if (lastPage == "SearchFriends") {
          _isUserSelected = "SearchFriends";
        } else if (lastPage == "Timeline") {
          _onItemTapped(3);
        }
      } else {
        _onItemTapped(1);
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _drawerOnTap(String drawerName) async {
    Navigator.pop(context);
    switch (drawerName) {
      case "Home":
        _onItemTapped(0);
      case "Search":
        _onItemTapped(1);
      case "Profile":
        _onItemTapped(2);
      case "Timeline":
        _onItemTapped(3);
      case "Notifications":
        _onItemTapped(4);
      case "My Location":
        _onItemTapped(5);
      case "Favourites":
        _isViewingHome = "Favourites";
        _onItemTapped(0);
      case "Settings":
        _isViewingHome = "Settings";
        _onItemTapped(0);
      case "Logout":
        onLogout = true;
        changeScreenFunction(LoginScreen(changeScreenFunction: changeScreenFunction, globalPlaceData: globalPlaceData));
        await Firestore().setUserOnlineOffline(uid: uid, isOnline: false);
        await Auth().logout();
    }
  }

  void userSnapshotEvent() {
    _userDataListener = Firestore().getUserSnapshots(uid: uid).listen((event) {
      if (mounted) {
        setState(() {
          globalUserData.ChangeUserData(event.data()!);
        });
      }
    }, onError: (error) => print("Listen failed: $error"));
  }

  void loginControlsAndOperations() async {
    List<Future<dynamic>> futures = [
      Firestore().getFriendsCount(uid: uid),
      Firestore().getOnlineFriendsCount(uid: uid),
      Firestore().checkAndDeleteOldNotifications(userId: globalUserData.uid),
      Firestore().setUserPosition(uid: uid, position: globalPlaceData.userPosition),
    ];

    List<dynamic> results = await Future.wait(futures);

    globalUserData.SetFriendsCount(results[0]);
    globalUserData.SetOnlineFriendsCount(results[1]);

    if (mounted) {
      setState(() {});
    }
  }

  void setUserOnlineOfflineStatus(bool isOnline) async {
    if (onLogout == false) {
      await Firestore().setUserOnlineOffline(uid: uid, isOnline: isOnline);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      setUserOnlineOfflineStatus(false);
    } else if (state == AppLifecycleState.resumed) {
      setUserOnlineOfflineStatus(true);
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    setUserOnlineOfflineStatus(false);
    _controller.dispose();
    _userDataListener.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    globalUserData = widget.globalUserData;
    globalPlaceData = widget.globalPlaceData;
    changeScreenFunction = widget.changeScreenFunction;
    uid = globalUserData.uid;

    userSnapshotEvent();
    loginControlsAndOperations();
    setUserOnlineOfflineStatus(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawerScrimColor: Colors.transparent.withOpacity(0.25),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(top: 40, left: 10, right: 10, bottom: 5),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          _changeViewProfilePostFlag("");
                          _drawerOnTap("Profile");
                        },
                        child: globalUserData.userData["profilePhotoUrl"] != null
                            ? CircleAvatar(
                                radius: 30,
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
                                radius: 30,
                                backgroundColor: Colors.white,
                                child: Padding(
                                  padding: EdgeInsets.all(0), // Border radius
                                  child: Icon(
                                    Icons.account_circle,
                                    size: 60,
                                    color: Colors.grey[300],
                                  ),
                                ),
                              ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              globalUserData.userData["name"],
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              "@${globalUserData.userData["username"]}",
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      _changeViewProfilePostFlag("Friends");
                      _drawerOnTap("Profile");
                    },
                    child: Row(
                      children: [
                        SizedBox(width: 5),
                        Icon(Icons.people, size: 20, color: Colors.green),
                        SizedBox(width: 5),
                        Text("${globalUserData.onlineFriendsCount}", style: TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                          " Online",
                          style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(width: 10),
                        Icon(Icons.people, size: 20),
                        SizedBox(width: 5),
                        Text("${globalUserData.friendsCount - globalUserData.onlineFriendsCount}", style: TextStyle(fontWeight: FontWeight.w600)),
                        Expanded(
                          child: Text(
                            " Offline",
                            style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12.5),
                  const Divider(
                    color: Colors.black26,
                    thickness: 0.75,
                    height: 0,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: [
                  _DrawerItem(Icon(Icons.home), "Home"),
                  _DrawerItem(Icon(Icons.search), "Search"),
                  _DrawerItem(Icon(Icons.person), "Profile"),
                  _DrawerItem(Icon(Icons.people), "Timeline"),
                  _DrawerItem(Icon(Icons.notifications), "Notifications"),
                  _DrawerItem(Icon(Icons.favorite), "Favourites"),
                  _DrawerItem(Icon(Icons.location_on), "My Location"),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Divider(
                      color: Colors.black26,
                      thickness: 0.75,
                      height: 32,
                    ),
                  ),
                  _DrawerItem(Icon(Icons.settings), "Settings"),
                  _DrawerItem(Icon(Icons.logout), "Logout"),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        onTap: _onItemTapped,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home_outlined,
            ),
            activeIcon: Icon(Icons.home),
            label: "",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: "",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: "",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: "",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            activeIcon: Icon(Icons.notifications),
            label: "",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on_outlined),
            activeIcon: Icon(Icons.location_on),
            label: "",
          ),
        ],
      ),
      appBar: (_selectedIndex == 0 && _isViewingHome == "Map")
          ? MapAppBar(_onMapView)
          : (_selectedIndex == 0 && _isViewingHome == "Favourites")
              ? FavouritesAppBar(globalUserData, _onMapView)
              : (_selectedIndex == 0 && _isViewingHome == "Settings")
                  ? SettingsAppBar(globalUserData, _onMapView)
                  : (_selectedIndex == 1 && _isUserSelected != "")
                      ? SelectedUserAppBar(globalUserData.selectedUserData.last!.userData["username"], _changeSearchUserFlag)
                      : (_selectedIndex == 2)
                          ? (_isViewingProfilePost == "")
                              ? ProfileAppBar(globalUserData, globalPlaceData, context)
                              : (_isViewingProfilePost == "Friends")
                                  ? FriendsAppBar(globalUserData, _changeViewProfilePostFlag)
                                  : (_isViewingProfilePost == "UserPosts")
                                      ? PostsAppBar(_changeViewProfilePostFlag)
                                      : SavedPostsAppBar(_changeViewProfilePostFlag)
                          : (_selectedIndex == 3)
                              ? AppBarWithTitleTxt("Timeline")
                              : (_selectedIndex == 4)
                                  ? AppBarWithTitleTxt("Notifications")
                                  : MainAppBar(),
      body: PageView(
        controller: _controller,
        onPageChanged: _onPageChanged,
        children: [
          (_isViewingHome == "")
              ? HomeScreen(globalUserData: globalUserData, globalPlaceData: globalPlaceData, onMapViewFunction: _onMapView)
              : (_isViewingHome == "Map")
                  ? MapScreen(globalUserData: globalUserData, globalPlaceData: globalPlaceData)
                  : (_isViewingHome == "Favourites")
                      ? FavouritesScreen(globalUserData: globalUserData, globalPlaceData: globalPlaceData, onMapViewFunction: _onMapView)
                      : SettingsScreen(globalUserData: globalUserData, globalPlaceData: globalPlaceData, onMapViewFunction: _onMapView),
          (_isUserSelected == "")
              ? SearchScreen(globalUserData: globalUserData, changeIsSelectedFunction: _changeSearchUserFlag)
              : (_isUserSelected == "SearchProfile")
                  ? UserSearchProfileScreen(globalUserData: globalUserData, changeIsSelectedFunction: _changeSearchUserFlag)
                  : (_isUserSelected == "SearchFriends")
                      ? FriendsScreen(globalUserData: globalUserData, changeIsSelectedFunction: _changeSearchUserFlag, viewMode: "SearchFriends")
                      : PostScreen(globalUserData: globalUserData, postMode: "SearchPosts", changeIsSelectedFunction: _changeSearchUserFlag),
          (_isViewingProfilePost == "")
              ? ProfileScreen(globalUserData: globalUserData, changeFlagFunction: _changeViewProfilePostFlag)
              : (_isViewingProfilePost == "Friends")
                  ? FriendsScreen(globalUserData: globalUserData, changeIsSelectedFunction: _changeSearchUserFlag, viewMode: "UserFriends")
                  : PostScreen(globalUserData: globalUserData, postMode: _isViewingProfilePost, changeIsSelectedFunction: _changeSearchUserFlag),
          PostScreen(globalUserData: globalUserData, postMode: "Timeline", changeIsSelectedFunction: _changeSearchUserFlag),
          NotificationsScreen(globalUserData: globalUserData, changeIsSelectedFunction: _changeSearchUserFlag),
          MainMapScreen(globalUserData: globalUserData, globalPlaceData: globalPlaceData),
        ],
      ),
    );
  }

  ListTile _DrawerItem(Icon icon, String txt) {
    return ListTile(
      dense: true,
      leading: icon,
      title: Text(
        txt,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ),
      onTap: () {
        _drawerOnTap(txt);
      },
    );
  }
}
