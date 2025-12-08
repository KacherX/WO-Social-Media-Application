import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:wo/models/global_user_data.dart';
import 'package:wo/services/firestore.dart';
import 'package:wo/services/global_functions.dart';

class NotificationsScreen extends StatefulWidget {
  final GlobalUserData globalUserData;
  final Function changeIsSelectedFunction;
  const NotificationsScreen({Key? key, required this.globalUserData, required this.changeIsSelectedFunction});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with TickerProviderStateMixin {
  late GlobalUserData globalUserData;
  late Function changeIsSelectedFunction;
  Map<String, Map<String, dynamic>> localNotificationsData = {};

  late AnimationController _loadingAnimationController;
  final _notificationsScrollController = ScrollController();

  bool loadNotificationsOperation = false;
  bool allNotificationsLoaded = false;
  bool notificationsLoading = false;

  late int notificationsLength;
  int countType1 = 0;
  int countType2 = 0;

  void acceptFriendRequest(int index, String senderUid) async {
    try {
      setState(() {
        notificationsLength -= 1;
        countType1 -= 1;
        globalUserData.notificationsData.removeAt(index);
      });
      await Firestore().acceptFriendRequest(userUid: globalUserData.uid, senderUid: senderUid);
    } catch (e) {
      print("ERROR: $e");
    }
  }

  void rejectFriendRequest(int index, String senderUid) async {
    try {
      setState(() {
        notificationsLength -= 1;
        countType1 -= 1;
        globalUserData.notificationsData.removeAt(index);
      });
      await Firestore().takeFriendRequestBack(getterUid: globalUserData.uid, senderUid: senderUid);
    } catch (e) {
      print("ERROR: $e");
    }
  }

  void onUserSelect(Map<String, dynamic> userData) {
    GlobalUserData selectedUserData = GlobalUserData(userData["id"], userData);
    globalUserData.AddSelectedUserData(selectedUserData);
    globalUserData.AddLastPage("Notifications");
    changeIsSelectedFunction("SearchProfile");
    if (mounted) {
      setState(() {});
    }
  }

  void onPostSelect(Map<String, dynamic> userData, String postId) async {
    final userPosts = await Firestore().getUserPosts(uid: globalUserData.uid, lastPostDate: Timestamp.fromDate(DateTime(2100)));
    GlobalUserData selectedUserData = GlobalUserData(globalUserData.uid, userData);
    selectedUserData.SetSelectedPostId(postId);
    selectedUserData.ChangePostsData(userPosts.docs);

    globalUserData.AddSelectedUserData(selectedUserData);
    globalUserData.AddLastPage("Notifications");
    changeIsSelectedFunction("SearchPosts"); // Force to show posts
    if (mounted) {
      setState(() {});
    }
  }

  void setNotificationData(String notificationId, Map<String, dynamic> data) async {
    Map<String, dynamic> emptyData = {};
    localNotificationsData[notificationId] = emptyData;
    try {
      List<Future> futures = [];

      futures.add(Firestore().getUserData(uid: data["userId"]));
      if (data["type"] == 2) {
        futures.add(Firestore().getPostData(uid: globalUserData.uid, postId: data["postId"]));
      }

      List<dynamic> results = await Future.wait(futures);

      if (results[0].isEmpty || (data["type"] == 2 && results[1].isEmpty)) {
        await Firestore().deleteNotification(userId: globalUserData.uid, notificationId: notificationId);
        int index = globalUserData.notificationsData.indexWhere((post) => post.id == notificationId);
        if (index != -1) {
          globalUserData.notificationsData.removeAt(index);
        }
        notificationsLength = globalUserData.notificationsData.length;
        countElements();
      } else {
        localNotificationsData[notificationId]!["userData"] = results[0];
        localNotificationsData[notificationId]!["userData"]["id"] = data["userId"];
        if (data["type"] == 2) {
          localNotificationsData[notificationId]!["postData"] = results[1];
        }
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print("ERROR: $e");
    }
  }

  void countElements() {
    countType1 = globalUserData.notificationsData.where((doc) => doc.data()["type"] == 1).length;
    countType2 = globalUserData.notificationsData.where((doc) => doc.data()["type"] == 2).length;
  }

  void setInitialNotifications() async {
    final notificationsData =
        await Firestore().getUserNotifications(uid: globalUserData.uid, lastType: 1, lastNotificationDate: Timestamp.fromDate(DateTime(2100)));
    globalUserData.ChangeNotificationsData(notificationsData.docs);
    notificationsLength = globalUserData.notificationsData.length;
    countElements();

    if (notificationsLength > 0 && localNotificationsData.isEmpty) {
      Map<String, dynamic> data = globalUserData.notificationsData[0].data();
      setNotificationData(globalUserData.notificationsData[0].id, data);
    }

    notificationsLoading = false;
    if (mounted) {
      setState(() {});
    }
  }

  void loadMoreNotifications() async {
    if (loadNotificationsOperation == false && allNotificationsLoaded == false && globalUserData.notificationsData != []) {
      loadNotificationsOperation = true;
      setState(() {});

      final notificationsData = await Firestore().getUserNotifications(
          uid: globalUserData.uid,
          lastType: globalUserData.notificationsData.last["type"],
          lastNotificationDate: globalUserData.notificationsData.last["notificationDate"]);
      if (notificationsData.docs.length < 30) {
        allNotificationsLoaded = true;
      }
      if (notificationsData.docs.isNotEmpty) {
        globalUserData.AddNotificationsData(notificationsData.docs);
        notificationsLength = globalUserData.notificationsData.length;
        countElements();
      }

      loadNotificationsOperation = false;
      setState(() {});
    }
  }

  void checkLastOfScroll() {
    _notificationsScrollController.addListener(() {
      if (_notificationsScrollController.position.pixels == _notificationsScrollController.position.maxScrollExtent) {
        loadMoreNotifications();
      }
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose

    _loadingAnimationController.dispose();
    _notificationsScrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    globalUserData = widget.globalUserData;
    changeIsSelectedFunction = widget.changeIsSelectedFunction;

    setInitialNotifications();
    checkLastOfScroll();

    _loadingAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
              child: notificationsLoading == false
                  ? globalUserData.notificationsData.isNotEmpty
                      ? (localNotificationsData[globalUserData.notificationsData[0].id] != null &&
                              localNotificationsData[globalUserData.notificationsData[0].id]!["userData"] != null) // First notification loading
                          ? ListView.builder(
                              controller: _notificationsScrollController,
                              padding: EdgeInsets.zero,
                              itemCount: notificationsLength + 1,
                              shrinkWrap: true,
                              itemBuilder: (context, index) {
                                if (index == notificationsLength) {
                                  if (loadNotificationsOperation) {
                                    return miniLoadingAnimation();
                                  } else {
                                    return SizedBox(height: 0);
                                  }
                                } else {
                                  final doc = globalUserData.notificationsData[index];
                                  Map<String, dynamic> data = doc.data();
                                  String notificationId = doc.id;

                                  if (localNotificationsData[notificationId] == null) {
                                    setNotificationData(notificationId, data);
                                  }

                                  if (index == 0 && countType1 != 0) {
                                    return FriendRequestFrame(data, notificationId, index, true);
                                  } else if (index == countType1 && countType2 != 0) {
                                    return PostActivityFrame(data, notificationId, index, true);
                                  } else if (data["type"] == 1) {
                                    return FriendRequestFrame(data, notificationId, index, false);
                                  } else {
                                    return PostActivityFrame(data, notificationId, index, false);
                                  }
                                }
                              },
                            )
                          : NotificationsLoadingAnimation()
                      : NoNotificationsTabBar()
                  : NotificationsLoadingAnimation()),
        ],
      ),
    );
  }

  Widget FriendRequestHeader() {
    return HeaderText("Friend requests");
  }

  Widget PostActivitiesHeader() {
    return HeaderText("Post activities");
  }

  Widget FriendRequestFrame(Map<String, dynamic> data, String notificationId, int index, bool isFirst) {
    return (localNotificationsData[notificationId] != null && localNotificationsData[notificationId]!["userData"] != null)
        ? Padding(
            padding: EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                isFirst ? FriendRequestHeader() : SizedBox(height: 0),
                GestureDetector(
                  onTap: () {
                    onUserSelect(localNotificationsData[notificationId]!["userData"]);
                  },
                  child: Row(
                    children: [
                      (localNotificationsData[notificationId]!["userData"]["profilePhotoUrl"] != null)
                          ? CircleAvatar(
                              backgroundColor: Colors.white,
                              radius: 24,
                              child: ClipOval(
                                  child: Image.network(
                                localNotificationsData[notificationId]!["userData"]["profilePhotoUrl"],
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
                      SizedBox(width: 7.5),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              maxLines: 3,
                              text: TextSpan(
                                text: "@${localNotificationsData[notificationId]!["userData"]["username"]}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                children: [
                                  TextSpan(
                                      text: " wants to be friends with you.",
                                      style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black)),
                                  TextSpan(
                                      text: " ${GlobalFunctions().formatTimeDifference(data["notificationDate"])}",
                                      style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black54)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Align(
                        alignment: Alignment(1, 0),
                        child: Row(
                          children: [
                            SizedBox(width: 10),
                            GestureDetector(
                              onTap: () {
                                acceptFriendRequest(index, localNotificationsData[notificationId]!["userData"]["id"]);
                              },
                              child: Icon(
                                Icons.check,
                                size: 24,
                                color: Colors.green[800],
                              ),
                            ),
                            SizedBox(width: 5),
                            GestureDetector(
                              onTap: () {
                                rejectFriendRequest(index, localNotificationsData[notificationId]!["userData"]["id"]);
                              },
                              child: Icon(
                                Icons.close,
                                size: 24,
                                color: Colors.red[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        : const SizedBox(height: 0);
  }

  Widget PostActivityFrame(Map<String, dynamic> data, String notificationId, int index, bool isFirst) {
    return (localNotificationsData[notificationId] != null && localNotificationsData[notificationId]!["userData"] != null)
        ? Padding(
            padding: EdgeInsets.only(left: 10, right: 10, top: (isFirst && index != 0) ? 40 : 5, bottom: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                isFirst ? PostActivitiesHeader() : SizedBox(height: 0),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        onPostSelect(globalUserData.userData, data["postId"]);
                      },
                      child: (localNotificationsData[notificationId]!["postData"]["postPhotoUrl"] != null)
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10), // Adjust for rounded corners
                              child: Image.network(
                                localNotificationsData[notificationId]!["postData"]["postPhotoUrl"],
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(
                              Icons.account_circle,
                              size: 48,
                              color: Colors.grey[300],
                            ),
                    ),
                    SizedBox(width: 7.5),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              text: "@${localNotificationsData[notificationId]!["userData"]["username"]}",
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                                overflow: TextOverflow.ellipsis,
                              ),
                              children: [
                                TextSpan(
                                    text: data["action"] == 1 ? " liked your post." : " commented your post.",
                                    style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black)),
                                TextSpan(
                                    text: " ${GlobalFunctions().formatTimeDifference(data["notificationDate"])}",
                                    style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black54)),
                              ],
                            ),
                          ),
                          SizedBox(height: 5),
                          GestureDetector(
                            onTap: () {
                              onUserSelect(localNotificationsData[notificationId]!["userData"]);
                            },
                            child: Row(
                              crossAxisAlignment: data["action"] == 1 ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                              children: [
                                (localNotificationsData[notificationId]!["userData"]["profilePhotoUrl"] != null)
                                    ? CircleAvatar(
                                        backgroundColor: Colors.white,
                                        radius: 16,
                                        child: ClipOval(
                                            child: Image.network(
                                          localNotificationsData[notificationId]!["userData"]["profilePhotoUrl"],
                                          width: 150,
                                          height: 150,
                                          fit: BoxFit.cover,
                                        )),
                                      )
                                    : Icon(
                                        Icons.account_circle,
                                        size: 32,
                                        color: Colors.grey[300],
                                      ),
                                SizedBox(width: 5),
                                data["action"] == 1 // Like ise
                                    ? Icon(Icons.favorite, color: Colors.red)
                                    : Expanded(
                                        // Comment ise
                                        child: RichText(
                                          maxLines: 3,
                                          text: TextSpan(
                                            text: "${localNotificationsData[notificationId]!["userData"]["username"]}: ",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              color: Colors.black,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            children: [
                                              TextSpan(
                                                  text: data["comment"], style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black)),
                                            ],
                                          ),
                                        ),
                                      )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        : const SizedBox(height: 0);
  }

  Widget HeaderText(String txt) {
    return Padding(
      padding: EdgeInsets.only(left: 10, bottom: 10),
      child: Text(
        txt,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
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

  Center NotificationsLoadingAnimation() {
    return Center(
        child: Column(
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
          "Notifications loading",
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

  Center NoNotificationsTabBar() {
    return const Center(
      child: Column(
        children: [
          SizedBox(
            height: 75,
          ),
          Icon(
            Icons.notifications,
            size: 60,
          ),
          Text(
            "No notifications",
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
      ),
    );
  }
}
