import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:wo/models/global_user_data.dart';
import 'package:wo/services/firestore.dart';

class FriendsScreen extends StatefulWidget {
  final GlobalUserData globalUserData;
  final Function changeIsSelectedFunction;
  final String viewMode;
  const FriendsScreen({Key? key, required this.globalUserData, required this.changeIsSelectedFunction, required this.viewMode}) : super(key: key);

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with TickerProviderStateMixin {
  late GlobalUserData globalUserData;
  late GlobalUserData selectedUserData;
  late String viewMode;
  late Function changeIsSelectedFunction;

  List<Map<String, dynamic>> friendsData = [];
  List<Map<String, dynamic>> searchUserDatas = [];

  List<Map<String, dynamic>> blockedAccountsData = [];
  List<Map<String, dynamic>> searchBlockedAccountDatas = [];

  final _friendsScrollController = ScrollController();
  final _searchController = TextEditingController();

  late AnimationController _loadingAnimationController;

  bool _searchingDone = true;
  bool _initialSet = false;
  bool loadFriendsOperation = false;
  bool allFriendsLoaded = false;
  bool loadBlockedsOperation = false;
  bool allBlockedsLoaded = false;

  int _selectedTabIndex = 0;
  void onTabTapped(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
  }

  void unFriendUser(int index, String friendUid) async {
    try {
      friendsData.removeAt(index);
      if (_searchController.text.trim().isNotEmpty) {
        // Eger arama yapilirken silmisse
        searchUserDatas.removeAt(index);
      }
      if (mounted) {
        setState(() {});
      }
      await Firestore().unFriendUser(userUid: friendUid, senderUid: globalUserData.uid);
    } catch (e) {
      print("ERROR: $e");
    }
  }

  void unblockUser(int index, String accountUid) async {
    try {
      blockedAccountsData.removeAt(index);
      if (_searchController.text.trim().isNotEmpty) {
        // Eger arama yapilirken silmisse
        searchBlockedAccountDatas.removeAt(index);
      }
      if (mounted) {
        setState(() {});
      }
      await Firestore().unblockUser(userUid: globalUserData.uid, blockedUserId: accountUid);
    } catch (e) {
      print("ERROR: $e");
    }
  }

  void searchOnChanged(String txt) async {
    String trimtxt = txt.trim();
    if (trimtxt.isNotEmpty) {
      _searchingDone = false;
      if (mounted) {
        setState(() {});
      }
      if (_selectedTabIndex == 0) {
        final result = await Firestore().getFriendsStartingWith(uid: selectedUserData.uid, input: trimtxt);
        if (trimtxt == _searchController.text.trim()) {
          searchUserDatas = result;
        }
      } else if (_selectedTabIndex == 1) {
        final result = await Firestore().getBlockedAccountsStartingWith(uid: selectedUserData.uid, input: trimtxt);
        if (trimtxt == _searchController.text.trim()) {
          searchBlockedAccountDatas = result;
        }
      }
      _searchingDone = true;
    } else {
      searchUserDatas = [];
      searchBlockedAccountDatas = [];
    }
    if (mounted) {
      setState(() {});
    }
  }

  void onUserSelect(Map<String, dynamic> userData) {
    GlobalUserData selectedUserData = GlobalUserData(userData["id"], userData);
    globalUserData.AddSelectedUserData(selectedUserData);
    if (viewMode == "SearchFriends") {
      globalUserData.AddLastPage("SearchFriends");
    } else {
      globalUserData.AddLastPage("Friends");
    }
    changeIsSelectedFunction("SearchProfile");
    if (mounted) {
      setState(() {});
    }
  }

  void loadMoreFriends() async {
    if (loadFriendsOperation == false && allFriendsLoaded == false && friendsData != []) {
      loadFriendsOperation = true;
      if (mounted) {
        setState(() {});
      }

      final data = await Firestore().getFriendsWithUserData(uid: selectedUserData.uid, lastFriendDate: friendsData.last["friendDate"], limit: 30);
      if (data.length < 30) {
        allFriendsLoaded = true;
      }
      if (data.isNotEmpty) {
        friendsData.addAll(data);
      }

      loadFriendsOperation = false;
      if (mounted) {
        setState(() {});
      }
    }
  }

  void loadMoreBlockeds() async {
    if (loadBlockedsOperation == false && allBlockedsLoaded == false && blockedAccountsData != []) {
      loadBlockedsOperation = true;
      if (mounted) {
        setState(() {});
      }

      final data = await Firestore().getBlockedAccountsWithUserData(uid: selectedUserData.uid, lastBlockDate: blockedAccountsData.last["blockDate"]);
      if (data.length < 30) {
        allBlockedsLoaded = true;
      }
      if (data.isNotEmpty) {
        blockedAccountsData.addAll(data);
      }

      loadBlockedsOperation = false;
      if (mounted) {
        setState(() {});
      }
    }
  }

  void setInitialFriends() async {
    List<Future<dynamic>> futures = [
      Firestore().getFriendsWithUserData(uid: selectedUserData.uid, lastFriendDate: Timestamp.fromDate(DateTime(2100)), limit: 30),
      Firestore().getBlockedAccountsWithUserData(uid: selectedUserData.uid, lastBlockDate: Timestamp.fromDate(DateTime(2100))),
    ];

    List<dynamic> results = await Future.wait(futures);
    friendsData = results[0];
    blockedAccountsData = results[1];

    _initialSet = true;
    if (mounted) {
      setState(() {});
    }
  }

  void checkLastOfScroll() {
    _friendsScrollController.addListener(() {
      if (_friendsScrollController.position.pixels == _friendsScrollController.position.maxScrollExtent && _searchController.text.trim().isEmpty) {
        if (_selectedTabIndex == 0) {
          loadMoreFriends();
        } else if (_selectedTabIndex == 1) {
          loadMoreBlockeds();
        }
      }
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose

    _friendsScrollController.dispose();
    _searchController.dispose();
    _loadingAnimationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    viewMode = widget.viewMode;
    globalUserData = widget.globalUserData;
    changeIsSelectedFunction = widget.changeIsSelectedFunction;

    if (viewMode == "SearchFriends") {
      selectedUserData = globalUserData.selectedUserData.last!;
    } else {
      // Zaten baska mod yok UserFriends var bir de
      selectedUserData = globalUserData;
    }

    setInitialFriends();

    _loadingAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _friendsScrollController,
      child: Column(
        children: [
          DefaultTabController(
            length: viewMode == "SearchFriends" ? 1 : 2,
            child: TabBar(
              onTap: onTabTapped,
              indicatorColor: Colors.deepPurple,
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.black, // Color of selected tab text
              unselectedLabelColor: Colors.grey, // Color of unselected tab text
              labelStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              tabs: viewMode == "SearchFriends"
                  ? const [
                      Tab(
                        text: "Friends",
                      ),
                    ]
                  : const [
                      Tab(
                        text: "Friends",
                      ),
                      Tab(
                        text: "Blocked accounts",
                      ),
                    ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 7),
            child: Material(
              color: Colors.transparent,
              child: TextField(
                controller: _searchController,
                maxLines: 1, // Allow multiline input
                onChanged: (String txt) {
                  searchOnChanged(txt);
                },
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: "Search by username.",
                  hintStyle: const TextStyle(color: Colors.grey),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
          const Divider(
            color: Colors.black26,
            thickness: 0.5,
            height: 10,
          ),
          _selectedTabIndex == 0
              ? _initialSet
                  ? friendsData.isNotEmpty
                      ? _searchingDone
                          ? _searchController.text.trim().isEmpty
                              ? ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: friendsData.length + 1,
                                  itemBuilder: (context, index) {
                                    if (index == friendsData.length) {
                                      if (loadFriendsOperation) {
                                        return miniLoadingAnimation();
                                      } else {
                                        return SizedBox(height: 0);
                                      }
                                    } else {
                                      final userData = friendsData[index];
                                      return GestureDetector(
                                        onTap: () {
                                          onUserSelect(userData);
                                        },
                                        child: UserContainer(index, userData, true),
                                      );
                                    }
                                  })
                              : searchUserDatas.isNotEmpty
                                  ? ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: searchUserDatas.length + 1,
                                      itemBuilder: (context, index) {
                                        if (index == searchUserDatas.length) {
                                          if (loadFriendsOperation) {
                                            return miniLoadingAnimation();
                                          } else {
                                            return SizedBox(height: 0);
                                          }
                                        } else {
                                          final userData = searchUserDatas[index];
                                          return GestureDetector(
                                            onTap: () {
                                              onUserSelect(userData);
                                            },
                                            child: UserContainer(index, userData, true),
                                          );
                                        }
                                      })
                                  : NoUsersTabBar("No friends found")
                          : UsersLoadingAnimation("Friends loading")
                      : NoUsersTabBar("No friends found")
                  : UsersLoadingAnimation("Friends loading")
              : _initialSet
                  ? blockedAccountsData.isNotEmpty
                      ? _searchingDone
                          ? _searchController.text.trim().isEmpty
                              ? ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: blockedAccountsData.length + 1,
                                  itemBuilder: (context, index) {
                                    if (index == blockedAccountsData.length) {
                                      if (loadFriendsOperation) {
                                        return miniLoadingAnimation();
                                      } else {
                                        return SizedBox(height: 0);
                                      }
                                    } else {
                                      final userData = blockedAccountsData[index];
                                      return GestureDetector(
                                        onTap: () {
                                          onUserSelect(userData);
                                        },
                                        child: UserContainer(index, userData, false),
                                      );
                                    }
                                  })
                              : searchBlockedAccountDatas.isNotEmpty
                                  ? ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: searchBlockedAccountDatas.length + 1,
                                      itemBuilder: (context, index) {
                                        if (index == searchBlockedAccountDatas.length) {
                                          if (loadFriendsOperation) {
                                            return miniLoadingAnimation();
                                          } else {
                                            return SizedBox(height: 0);
                                          }
                                        } else {
                                          final userData = searchBlockedAccountDatas[index];
                                          return GestureDetector(
                                            onTap: () {
                                              onUserSelect(userData);
                                            },
                                            child: UserContainer(index, userData, false),
                                          );
                                        }
                                      })
                                  : NoUsersTabBar("No accounts found")
                          : UsersLoadingAnimation("Accounts loading")
                      : NoUsersTabBar("No accounts found")
                  : UsersLoadingAnimation("Accounts loading")
        ],
      ),
    );
  }

  Widget UserContainer(int index, Map<String, dynamic> userData, bool isFriendFrame) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
      child: Row(
        children: [
          (userData["profilePhotoUrl"] != null)
              ? CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 24,
                  child: ClipOval(
                      child: Image.network(
                    userData["profilePhotoUrl"],
                    width: 150,
                    height: 150,
                    fit: BoxFit.cover,
                  )),
                )
              : Icon(
                  Icons.account_circle,
                  size: 48,
                  color: Colors.grey[300],
                ),
          const SizedBox(width: 7.5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  " @${userData["username"]}",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _selectedTabIndex == 0
                    ? userData["id"] == globalUserData.uid
                        ? const Row(
                            children: [
                              Icon(
                                Icons.person,
                                size: 20,
                                color: Colors.deepPurple,
                              ),
                              Expanded(
                                child: Text(
                                  "You",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : userData["isOnline"] == true
                            ? const Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: 20,
                                    color: Colors.green,
                                  ),
                                  Expanded(
                                    child: Text(
                                      "Online",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : const Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: 20,
                                  ),
                                  Expanded(
                                    child: Text(
                                      "Offline",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                    : SizedBox(height: 0),
              ],
            ),
          ),
          Align(
            alignment: Alignment(1, 0),
            child: Row(
              children: [
                SizedBox(width: 10),
                viewMode == "SearchFriends"
                    ? const SizedBox(width: 0)
                    : isFriendFrame
                        ? ElevatedButton(
                            onPressed: () {
                              unFriendUser(index, userData["id"]);
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              "Unfriend",
                              style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
                            ),
                          )
                        : ElevatedButton(
                            onPressed: () {
                              unblockUser(index, userData["id"]);
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              "Unblock",
                              style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
                            ),
                          ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Container miniLoadingAnimation() {
    return Container(
      child: RotationTransition(
        turns: _loadingAnimationController,
        child: const Icon(
          Icons.refresh,
          size: 25,
        ),
      ),
    );
  }

  Center UsersLoadingAnimation(String txt) {
    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          height: 75,
        ),
        RotationTransition(
          turns: _loadingAnimationController,
          child: const Icon(
            Icons.refresh,
            size: 60,
          ),
        ),
        Text(
          txt,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            decoration: TextDecoration.none,
            fontWeight: FontWeight.w600,
            fontFamily: "Arial",
            letterSpacing: 0,
          ),
        ),
      ],
    ));
  }

  Center NoUsersTabBar(String txt) {
    return Center(
      child: Column(
        children: [
          const SizedBox(
            height: 75,
          ),
          const Icon(
            Icons.people,
            size: 60,
          ),
          Text(
            txt,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              decoration: TextDecoration.none,
              fontWeight: FontWeight.w600,
              fontFamily: "Arial",
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
