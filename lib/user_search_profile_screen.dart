import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:wo/models/global_user_data.dart';
import 'package:wo/services/firestore.dart';

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

class UserSearchProfileScreen extends StatefulWidget {
  final GlobalUserData globalUserData;
  final Function changeIsSelectedFunction;
  const UserSearchProfileScreen({Key? key, required this.globalUserData, required this.changeIsSelectedFunction}) : super(key: key);

  @override
  State<UserSearchProfileScreen> createState() => _UserSearchProfileScreenState();
}

class _UserSearchProfileScreenState extends State<UserSearchProfileScreen> with TickerProviderStateMixin {
  late Function changeIsSelectedFunction;
  late GlobalUserData globalUserData;
  late GlobalUserData selectedUserData;
  late String selectedUid;

  final _postsScrollController = ScrollController();
  late AnimationController _postsLoadingAnimationController;

  bool loadPostsOperation = false;
  bool allPostsLoaded = false;

  late AnimationController _loadingAnimationController;

  void acceptFriendRequest() async {
    try {
      if (selectedUserData.userData["hasFriendRequestBySelected"] == true) {
        setState(() {
          selectedUserData.userData["hasFriendRequestBySelected"] = false;
          selectedUserData.userData["isFriend"] = true;
          selectedUserData.SetFriendsCount(selectedUserData.friendsCount + 1);
        });
        await Firestore().acceptFriendRequest(userUid: globalUserData.uid, senderUid: selectedUid);
      }
    } catch (e) {
      print("ERROR: $e");
    }
  }

  void sendFriendRequest() async {
    try {
      if (selectedUserData.userData["hasFriendRequest"] == false) {
        setState(() {
          selectedUserData.userData["hasFriendRequest"] = true;
        });
        await Firestore().sendFriendRequest(getterUid: selectedUid, senderUid: globalUserData.uid);
      }
    } catch (e) {
      print("ERROR: $e");
    }
  }

  void unFriendUser() async {
    try {
      if (selectedUserData.userData["isFriend"] == true) {
        setState(() {
          selectedUserData.userData["isFriend"] = false;
          selectedUserData.SetFriendsCount(selectedUserData.friendsCount - 1);
        });
        await Firestore().unFriendUser(userUid: selectedUid, senderUid: globalUserData.uid);
      }
    } catch (e) {
      print("ERROR: $e");
    }
  }

  void blockUser() async {
    try {
      selectedUserData.userData["hasFriendRequest"] = false;
      selectedUserData.userData["isFriend"] = false;
      selectedUserData.userData["hasFriendRequestBySelected"] = false;
      selectedUserData.userData["isBlocked"] = true;
      if (mounted) {
        setState(() {});
      }
      await Firestore().blockUser(userUid: globalUserData.uid, blockedUserId: selectedUid);
    } catch (e) {
      print("ERROR: $e");
    }
    if (mounted) {
      setState(() {});
    }
  }

  void unblockUser() async {
    try {
      selectedUserData.userData["hasFriendRequest"] = false;
      selectedUserData.userData["isFriend"] = false;
      selectedUserData.userData["hasFriendRequestBySelected"] = false;
      selectedUserData.userData["isBlocked"] = false;
      if (mounted) {
        setState(() {});
      }
      await Firestore().unblockUser(userUid: globalUserData.uid, blockedUserId: selectedUid);
    } catch (e) {
      print("ERROR: $e");
    }
    if (mounted) {
      setState(() {});
    }
  }

  void setUserStatus() async {
    List<Future<dynamic>> futures = [
      Firestore().getFriendsCount(uid: selectedUid),
      Firestore().userHasFriendRequest(getterUid: selectedUid, senderUid: globalUserData.uid),
      Firestore().userIsFriend(userUid: selectedUid, checkUserUid: globalUserData.uid),
      Firestore().userHasFriendRequest(getterUid: globalUserData.uid, senderUid: selectedUid),
      Firestore().userIsBlocked(userUid: globalUserData.uid, checkUserUid: selectedUid),
      Firestore().userIsBlocked(userUid: selectedUid, checkUserUid: globalUserData.uid),
      Firestore().getUserPosts(uid: selectedUid, lastPostDate: Timestamp.fromDate(DateTime(2100))),
    ];

    List<dynamic> results = await Future.wait(futures);

    selectedUserData.SetFriendsCount(results[0]);
    selectedUserData.userData["hasFriendRequest"] = results[1];
    selectedUserData.userData["isFriend"] = results[2];
    selectedUserData.userData["hasFriendRequestBySelected"] = results[3];
    selectedUserData.userData["isBlocked"] = results[4];
    selectedUserData.userData["isBlockedBySelected"] = results[5];
    selectedUserData.ChangePostsData(results[6].docs);
    if (mounted) {
      setState(() {});
    }
  }

  void loadMorePosts() async {
    if (loadPostsOperation == false && allPostsLoaded == false && selectedUserData.postsData != []) {
      loadPostsOperation = true;
      setState(() {});

      final postsData = await Firestore().getUserPosts(uid: selectedUid, lastPostDate: selectedUserData.postsData.last["postCreateDate"]);
      if (postsData.docs.length < 30) {
        allPostsLoaded = true;
      }
      if (postsData.docs.isNotEmpty) {
        selectedUserData.AddPostsData(postsData.docs);
      }

      loadPostsOperation = false;
      setState(() {});
    }
  }

  void checkLastOfScroll() {
    _postsScrollController.addListener(() {
      if (_postsScrollController.position.pixels == _postsScrollController.position.maxScrollExtent) {
        loadMorePosts();
      }
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose

    _postsScrollController.dispose();
    _postsLoadingAnimationController.dispose();
    _loadingAnimationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    globalUserData = widget.globalUserData;
    selectedUserData = globalUserData.selectedUserData.last!;
    selectedUid = selectedUserData.uid;
    changeIsSelectedFunction = widget.changeIsSelectedFunction;

    setUserStatus();

    checkLastOfScroll();

    _loadingAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _postsLoadingAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return selectedUserData.userData["hasFriendRequest"] != null
        ? SingleChildScrollView(
            controller: _postsScrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Image
                Stack(
                  children: [
                    (selectedUserData.userData["profileCoverPhotoUrl"] != null &&
                            selectedUserData.userData["isBlocked"] == false &&
                            selectedUserData.userData["isBlockedBySelected"] == false)
                        ? Image.network(
                            selectedUserData.userData["profileCoverPhotoUrl"],
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
                        child: (selectedUserData.userData["profilePhotoUrl"] != null &&
                                selectedUserData.userData["isBlocked"] == false &&
                                selectedUserData.userData["isBlockedBySelected"] == false)
                            ? CircleAvatar(
                                radius: 35,
                                backgroundColor: Colors.white,
                                child: Padding(
                                  padding: EdgeInsets.all(2.5), // Border radius
                                  child: ClipOval(
                                      child: Image.network(
                                    selectedUserData.userData["profilePhotoUrl"],
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
                    selectedUid != globalUserData.uid
                        ? Padding(
                            padding: EdgeInsets.only(top: 105, right: 5),
                            child: Align(
                              alignment: Alignment(1, 0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      showModalBottomSheet(
                                        context: context,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(16),
                                          ),
                                        ),
                                        backgroundColor: Colors.transparent,
                                        builder: (BuildContext context) {
                                          return Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: ListView(
                                                shrinkWrap: true,
                                                children: selectedUserData.userData["isBlocked"]
                                                    ? [
                                                        _buildMenuItem(Icons.block, 'Unblock'),
                                                        const Divider(
                                                          color: Colors.black26,
                                                          thickness: 0.75,
                                                          height: 0,
                                                        ),
                                                        _buildMenuItem(Icons.report, 'Report'),
                                                      ]
                                                    : [
                                                        _buildMenuItem(Icons.block, 'Block'),
                                                        const Divider(
                                                          color: Colors.black26,
                                                          thickness: 0.75,
                                                          height: 0,
                                                        ),
                                                        _buildMenuItem(Icons.report, 'Report'),
                                                      ],
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                    child: const Icon(Icons.more_horiz),
                                  ),
                                  const SizedBox(width: 5),
                                  selectedUserData.userData["isBlocked"]
                                      ? Container(
                                          height: 30,
                                          child: ElevatedButton(
                                            onPressed: () {
                                              unblockUser();
                                            },
                                            style: ElevatedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                            child: Text(
                                              "Unblock",
                                              style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        )
                                      : selectedUserData.userData["isBlockedBySelected"]
                                          ? const SizedBox(height: 0)
                                          : selectedUserData.userData["isFriend"]
                                              ? Container(
                                                  height: 30,
                                                  child: ElevatedButton(
                                                    onPressed: () {
                                                      unFriendUser();
                                                    },
                                                    style: ElevatedButton.styleFrom(
                                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      "Unfriend",
                                                      style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
                                                    ),
                                                  ),
                                                )
                                              : selectedUserData.userData["hasFriendRequest"]
                                                  ? Container(
                                                      height: 30,
                                                      child: ElevatedButton(
                                                        onPressed: () {},
                                                        style: ElevatedButton.styleFrom(
                                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(10),
                                                          ),
                                                        ),
                                                        child: Text(
                                                          "Pending request",
                                                          style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
                                                        ),
                                                      ),
                                                    )
                                                  : selectedUserData.userData["hasFriendRequestBySelected"]
                                                      ? Container(
                                                          height: 30,
                                                          child: ElevatedButton(
                                                            onPressed: () {
                                                              acceptFriendRequest();
                                                            },
                                                            style: ElevatedButton.styleFrom(
                                                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(10),
                                                              ),
                                                            ),
                                                            child: Text(
                                                              "Accept Request",
                                                              style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
                                                            ),
                                                          ),
                                                        )
                                                      : Container(
                                                          height: 30,
                                                          child: ElevatedButton(
                                                            onPressed: () {
                                                              sendFriendRequest();
                                                            },
                                                            style: ElevatedButton.styleFrom(
                                                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(10),
                                                              ),
                                                            ),
                                                            child: Text(
                                                              "Add Friend",
                                                              style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
                                                            ),
                                                          ),
                                                        ),
                                ],
                              ),
                            ),
                          )
                        : const SizedBox(height: 0),
                    (selectedUserData.userData["name"] == null ||
                            selectedUserData.userData["name"].trim() == "" ||
                            selectedUserData.userData["isBlocked"] ||
                            selectedUserData.userData["isBlockedBySelected"])
                        ? SizedBox(height: 0)
                        : Padding(
                            padding: EdgeInsets.only(top: 140, left: 10),
                            child: Text(
                              selectedUserData.userData["name"],
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
                            ),
                          ),
                  ],
                ),
                // Followers and Following Section
                (selectedUserData.userData["bio"] == null ||
                        selectedUserData.userData["bio"].trim() == "" ||
                        selectedUserData.userData["isBlocked"] ||
                        selectedUserData.userData["isBlockedBySelected"])
                    ? SizedBox(height: 0)
                    : Padding(
                        padding: EdgeInsets.only(left: 10),
                        child: Text(
                          selectedUserData.userData["bio"],
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                Padding(
                  padding: EdgeInsets.only(top: 10, left: 10),
                  child: GestureDetector(
                    onTap: () {
                      if ((selectedUserData.userData["isBlocked"] || selectedUserData.userData["isBlockedBySelected"]) == false) {
                        changeIsSelectedFunction("SearchFriends");
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(Icons.people, size: 20),
                        SizedBox(width: 5),
                        Text(
                            (selectedUserData.userData["isBlocked"] || selectedUserData.userData["isBlockedBySelected"])
                                ? "0"
                                : selectedUserData.friendsCount.toString(),
                            style: TextStyle(fontWeight: FontWeight.w600)),
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
                        indexMonths[selectedUserData.userData["joinDate"].toDate().month - 1] +
                        " " +
                        selectedUserData.userData["joinDate"].toDate().year.toString(),
                    style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
                  ),
                ),
                ((selectedUid == globalUserData.uid || selectedUserData.userData["isFriend"]) &&
                        (selectedUserData.userData["isBlocked"] == false && selectedUserData.userData["isBlockedBySelected"] == false))
                    ? const Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: DefaultTabController(
                          length: 1,
                          child: TabBar(
                            indicatorColor: Colors.deepPurple,
                            indicatorSize: TabBarIndicatorSize.tab,
                            labelColor: Colors.black, // Color of selected tab text
                            unselectedLabelColor: Colors.grey, // Color of unselected tab text
                            tabs: const <Widget>[
                              Tab(
                                icon: Icon(Icons.photo),
                              ),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox(height: 0),
                ((selectedUid == globalUserData.uid || selectedUserData.userData["isFriend"]) &&
                        (selectedUserData.userData["isBlocked"] == false && selectedUserData.userData["isBlockedBySelected"] == false))
                    ? selectedUserData.postsData.isEmpty
                        ? NoPostsTabBar()
                        : GridView.builder(
                            primary: false,
                            shrinkWrap: true,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3, // Number of columns
                            ),
                            itemCount: selectedUserData.postsData.length, // Total number of posts
                            itemBuilder: (context, index) {
                              final doc = selectedUserData.postsData[index]; // Access the post by index
                              Map<String, dynamic> data = doc.data();

                              return ProfilePost(data, doc.id); // Return the grid item
                            },
                          )
                    : selectedUserData.userData["isBlocked"]
                        ? BlockedTabBar("Blocked profile.")
                        : selectedUserData.userData["isBlockedBySelected"]
                            ? BlockedTabBar("${selectedUserData.userData["username"]} blocked you.")
                            : NotFriendsTabBar(),
                loadPostsOperation ? miniLoadingAnimation() : const SizedBox(height: 0),
              ],
            ),
          )
        : UserLoadingAnimation();
  }

  GestureDetector ProfilePost(Map<String, dynamic> postData, String postId) {
    return GestureDetector(
      onTap: () {
        selectedUserData.SetSelectedPostId(postId);
        changeIsSelectedFunction("SearchPosts");
      },
      child: Image.network(
        postData["postPhotoUrl"],
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String text) {
    return ListTile(
      leading: Icon(icon, color: (text == "Block" || text == "Report") ? Colors.red : Colors.black87),
      title: Text(
        text,
        style: TextStyle(
          color: (text == "Block" || text == "Report") ? Colors.red : Colors.black87,
          fontSize: 16,
        ),
      ),
      onTap: () {
        Navigator.pop(context); // Close the modal after selection
        if (text == "Block") {
          blockUser();
        } else if (text == "Unblock") {
          unblockUser();
        }
      },
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

  Center UserLoadingAnimation() {
    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 75,
        ),
        RotationTransition(
          turns: _loadingAnimationController,
          child: const Icon(
            Icons.refresh,
            size: 60,
          ),
        ),
        const Text(
          "Profile loading",
          style: TextStyle(
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

  Center NotFriendsTabBar() {
    return const Center(
      child: Column(
        children: [
          SizedBox(
            height: 75,
          ),
          Icon(
            Icons.privacy_tip_outlined,
            size: 60,
          ),
          Text(
            "Private profile",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Center BlockedTabBar(String txt) {
    return Center(
      child: Column(
        children: [
          const SizedBox(
            height: 75,
          ),
          const Icon(
            Icons.block,
            size: 60,
          ),
          Text(
            txt,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
