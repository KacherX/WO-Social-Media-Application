import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:wo/comment_frame.dart';
import 'package:wo/models/global_user_data.dart';
import 'package:wo/services/firestore.dart';
import 'package:wo/services/global_functions.dart';
import 'package:wo/services/storage.dart';

class PostScreen extends StatefulWidget {
  final GlobalUserData globalUserData;
  final String postMode;
  final Function changeIsSelectedFunction;
  const PostScreen({Key? key, required this.globalUserData, required this.postMode, required this.changeIsSelectedFunction}) : super(key: key);

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> with TickerProviderStateMixin {
  late GlobalUserData globalUserData;
  late GlobalUserData selectedUserData;
  late Function changeIsSelectedFunction;
  late String postMode;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> postsData = [];
  Map<String, Map<String, dynamic>> localPostsData = {};
  Map<String, Map<String, dynamic>> localSavesData = {};
  List<Map<String, dynamic>> postCommentsData = [];

  final _postsScrollController = ScrollController();
  final _commentsScrollController = ScrollController();
  final _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late AnimationController _likeAnimationController;
  late Animation<double> _likeScaleAnimation;
  late Animation<double> _likeOpacityAnimation;
  late AnimationController _saveAnimationController;
  late Animation<double> _saveScaleAnimation;
  late Animation<double> _saveOpacityAnimation;
  late AnimationController _loadingAnimationController;

  DocumentReference<Map<String, dynamic>>? commentsViewPostReference;
  Function? currentCallCommentsScreenSetState;

  late String selectedPostId;

  bool selectedPostIsLast = false;

  bool initialPostsLoading = true;

  bool likeOperation = false;
  bool saveOperation = false;
  bool commentOperation = false;
  bool loadCommentsOperation = false;
  bool loadPostsOperation = false;
  bool allPostsLoaded = false;

  bool loadNewComments = false;

  Future<void> deletePost({required DocumentReference<Map<String, dynamic>> postReference}) async {
    try {
      int index = postsData.indexWhere((post) => post.id == postReference.id);
      if (index != -1) {
        postsData.removeAt(index);
      }
      if (mounted) {
        setState(() {});
      }
      await Firestore().deletePostFromPostReference(postReference: postReference);
      await Storage().deletePost(userId: globalUserData.uid, postId: postReference.id);
    } catch (e) {
      print("ERROR: $e");
    }
  }

  Future<void> likePost({required DocumentReference<Map<String, dynamic>> postReference}) async {
    if (likeOperation == false) {
      likeOperation = true;
      try {
        bool liked = localPostsData[postReference.id]!["liked"];
        if (mounted) {
          setState(() {
            localPostsData[postReference.id]!["liked"] = !liked;
            localPostsData[postReference.id]!["likeCount"] =
                (liked == true) ? localPostsData[postReference.id]!["likeCount"] - 1 : localPostsData[postReference.id]!["likeCount"] + 1;
          });
        }
        await Firestore().likeOrUnlikePostFromPostReference(userId: globalUserData.uid, postReference: postReference);
      } catch (e) {
        print("ERROR: $e");
      }
      likeOperation = false;
    }
  }

  Future<void> savePost({required DocumentReference<Map<String, dynamic>> postReference}) async {
    if (saveOperation == false) {
      saveOperation = true;
      try {
        bool saved = localPostsData[postReference.id]!["saved"];
        if (mounted) {
          setState(() {
            localPostsData[postReference.id]!["saved"] = !saved;
            localPostsData[postReference.id]!["saveCount"] =
                (saved == true) ? localPostsData[postReference.id]!["saveCount"] - 1 : localPostsData[postReference.id]!["saveCount"] + 1;
          });
        }
        await Firestore().saveOrUnsavePostFromPostReference(userId: globalUserData.uid, postReference: postReference);
      } catch (e) {
        print("ERROR: $e");
      }
      saveOperation = false;
    }
  }

  Future<void> commentPost({required DocumentReference<Map<String, dynamic>> postReference}) async {
    if (commentOperation == false) {
      commentOperation = true;
      try {
        String trimTxt = _commentController.text.trim();
        if (trimTxt.isNotEmpty && _commentController.text.length < 300) {
          String selectedReplyId = globalUserData.selectedReplyId;
          if (selectedReplyId == "") {
            String randomCommentId = Firestore().getRandomCommentId(postReference: postReference);
            Map<String, dynamic> newComment = {
              "comment": trimTxt,
              "commentId": randomCommentId,
              "commentDate": Timestamp.fromDate(DateTime.now()),
              "userId": globalUserData.uid,
              "username": globalUserData.userData["username"],
              "profilePhotoUrl": globalUserData.userData["profilePhotoUrl"],
              "liked": false,
              "likeCount": 0,
              "replyCount": 0,
            };

            _commentController.text = "";
            localPostsData[postReference.id]!["commentCount"] = localPostsData[postReference.id]!["commentCount"] + 1;
            localPostsData[postReference.id]!["comments"].insert(0, newComment);

            if (mounted) {
              setState(() {});
            }

            await Firestore()
                .makeCommentFromPostReference(userId: globalUserData.uid, commentId: randomCommentId, postReference: postReference, comment: trimTxt);
          } else {
            if (trimTxt != "@${globalUserData.selectedReplyUsername}") {
              String randomReplyId = Firestore().getRandomReplyId(postReference: postReference, commentId: selectedReplyId);

              Map<String, dynamic> newReply = {
                "reply": trimTxt,
                "replyId": randomReplyId,
                "replyDate": Timestamp.fromDate(DateTime.now()),
                "username": globalUserData.userData["username"],
                "userId": globalUserData.uid,
                "profilePhotoUrl": globalUserData.userData["profilePhotoUrl"],
                "liked": false,
                "likeCount": 0,
              };

              _commentController.text = "@${globalUserData.selectedReplyUsername} ";
              localPostsData[postReference.id]!["comments"][globalUserData.selectedReplyIndex]["replyCount"] =
                  localPostsData[postReference.id]!["comments"][globalUserData.selectedReplyIndex]["replyCount"] + 1;
              localPostsData[postReference.id]!["comments"][globalUserData.selectedReplyIndex]["replies"].add(newReply);

              if (mounted) {
                setState(() {});
              }

              await Firestore().makeReplyToCommentFromPostReference(
                  userId: globalUserData.uid, commentId: selectedReplyId, postReference: postReference, reply: trimTxt, replyId: randomReplyId);
            }
          }
        }
      } catch (e) {
        print("ERROR: $e");
      }
      commentOperation = false;
    }
  }

  void onUserSelect(Map<String, dynamic> userData) {
    GlobalUserData newUserData = GlobalUserData(userData["id"], userData);
    globalUserData.AddSelectedUserData(newUserData);
    globalUserData.AddLastPage(postMode);
    changeIsSelectedFunction("SearchProfile");
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> loadComments({required DocumentReference<Map<String, dynamic>> postReference, required Function callCommentsScreenSetState}) async {
    if (loadCommentsOperation == false && (localPostsData[postReference.id]!["comments"] == null || loadNewComments)) {
      loadCommentsOperation = true;
      callCommentsScreenSetState();
      try {
        List<Map<String, dynamic>> commentsData = await Firestore().getCommentsWithUserDetails(
            postReference: postReference, userId: globalUserData.uid, lastCommentDate: localPostsData[postReference.id]!["lastCommentDate"]);
        if (commentsData.length < 20) {
          localPostsData[postReference.id]!["allCommentsLoaded"] = true;
        }
        if (commentsData.isNotEmpty) {
          if (mounted) {
            setState(() {
              localPostsData[postReference.id]!["lastCommentDate"] = commentsData.last["commentDate"];
              if (localPostsData[postReference.id]!["comments"] == null) {
                localPostsData[postReference.id]!["comments"] = commentsData;
              } else {
                localPostsData[postReference.id]!["comments"].addAll(commentsData);
              }
            });
          }
        } else if (localPostsData[postReference.id]!["comments"] == null) {
          setState(() {
            localPostsData[postReference.id]!["comments"] = [];
          });
        }
      } catch (e) {
        print("ERROR: $e");
      }

      loadCommentsOperation = false;
      loadNewComments = false;
      callCommentsScreenSetState();
    }
  }

  Future<void> setPostStatus(DocumentReference<Map<String, dynamic>> postReference) async {
    Map<String, dynamic> emptyData = {};
    localPostsData[postReference.id] = emptyData;
    try {
      List<Future<dynamic>> futures = [
        Firestore().getCommentsCountFromPostReference(postReference: postReference),
        Firestore().getLikesCountFromPostReference(postReference: postReference),
        Firestore().getSavesCountFromPostReference(postReference: postReference),
        Firestore().hasUserLikedPost(userId: globalUserData.uid, postReference: postReference),
        Firestore().hasUserSavedPost(userId: globalUserData.uid, postReference: postReference),
        postReference.get(),
        Firestore().getPlaceNameById(postReference: postReference),
      ];

      List<dynamic> results = await Future.wait(futures);

      if (results[5].exists) {
        String postOwnerId = results[5].data()["userId"];
        Map<String, dynamic> postOwnerData = await Firestore().getUserData(uid: postOwnerId);

        Map<String, dynamic> localPostData = {};
        localPostData["placeName"] = results[6] as String;
        localPostData["saved"] = results[4] as bool;
        localPostData["liked"] = results[3] as bool;
        localPostData["commentCount"] = results[0] as int;
        localPostData["likeCount"] = results[1] as int;
        localPostData["saveCount"] = results[2] as int;
        localPostData["allCommentsLoaded"] = false;
        localPostData["lastCommentDate"] = Timestamp.fromDate(DateTime(2100));
        localPostData["postOwnerData"] = postOwnerData;
        localPostData["postOwnerData"]["id"] = postOwnerId;
        localPostsData[postReference.id] = localPostData;
      } else {
        int index = postsData.indexWhere((post) => post.id == postReference.id);
        if (index != -1) {
          postsData.removeAt(index);
          localPostsData.remove(postReference.id);
          if (index == 0) {
            selectedUserData.SetSelectedPostId(postsData[0].id);
            selectedPostId = selectedUserData.selectedPostId;
          }
        }
      }
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print("ERROR: $e");
    }
  }

  void setPostsDataAndMoveTop() async {
    if (postMode == "SavedPosts") {
      postsData = List.from(selectedUserData.savesData);
    } else if (postMode == "Timeline") {
      postsData = await Firestore().getFriendsPosts(uid: globalUserData.uid, lastPostDate: Timestamp.fromDate(DateTime(2100)));
      if (postsData.isNotEmpty) {
        selectedPostId = postsData[0].id;
      }
    } else {
      postsData = List.from(selectedUserData.postsData);
    }

    initialPostsLoading = false;

    if (mounted) {
      setState(() {});
    }

    var selectedPost;
    if (selectedPostId != "" && postsData.isNotEmpty) {
      int index = postsData.indexWhere((post) => post.id == selectedPostId);

      if (index != -1) {
        if (index == postsData.length - 1) {
          selectedPostIsLast = true;
        }
        selectedPost = postsData.removeAt(index);
        postsData.insert(0, selectedPost);

        if (postMode == "SavedPosts") {
          localSavesData = await Firestore().getPostsWithDataFromSaves(savesData: globalUserData.savesData);
          setPostStatus(postsData[0].data()["postReference"]);
        } else {
          setPostStatus(selectedPost.reference);
        }
      }
    }
  }

  void loadMoreSaves() async {
    if (loadPostsOperation == false && allPostsLoaded == false && globalUserData.savesData != []) {
      loadPostsOperation = true;
      setState(() {});

      final Timestamp lastPostCreateDate;
      if (selectedPostIsLast) {
        lastPostCreateDate = postsData.first["postSaveDate"];
      } else {
        lastPostCreateDate = postsData.last["postSaveDate"];
      }

      final newPostsData = await Firestore().getUserSaves(uid: selectedUserData.uid, lastSaveDate: lastPostCreateDate);
      if (newPostsData.docs.length < 30) {
        allPostsLoaded = true;
      }
      if (newPostsData.docs.isNotEmpty) {
        postsData.addAll(newPostsData.docs);
      }
      loadPostsOperation = false;
      setState(() {});
    }
  }

  void loadMorePosts() async {
    if (loadPostsOperation == false && allPostsLoaded == false && globalUserData.postsData != []) {
      loadPostsOperation = true;
      setState(() {});

      final Timestamp lastPostCreateDate;
      if (selectedPostIsLast) {
        lastPostCreateDate = postsData.first["postCreateDate"];
      } else {
        lastPostCreateDate = postsData.last["postCreateDate"];
      }

      final newPostsData = await Firestore().getUserPosts(uid: selectedUserData.uid, lastPostDate: lastPostCreateDate);
      if (newPostsData.docs.length < 30) {
        allPostsLoaded = true;
      }
      if (newPostsData.docs.isNotEmpty) {
        postsData.addAll(newPostsData.docs);
      }
      loadPostsOperation = false;
      setState(() {});
    }
  }

  void loadMoreTimeline() async {
    if (loadPostsOperation == false && allPostsLoaded == false && globalUserData.postsData != []) {
      loadPostsOperation = true;
      setState(() {});

      final Timestamp lastPostCreateDate;
      if (selectedPostIsLast) {
        lastPostCreateDate = postsData.first["postCreateDate"];
      } else {
        lastPostCreateDate = postsData.last["postCreateDate"];
      }

      final newPostsData = await Firestore().getFriendsPosts(uid: globalUserData.uid, lastPostDate: lastPostCreateDate);
      if (newPostsData.length < 30) {
        allPostsLoaded = true;
      }
      if (newPostsData.isNotEmpty) {
        postsData.addAll(newPostsData);
      }
      loadPostsOperation = false;
      setState(() {});
    }
  }

  void checkPostsLastOfScroll() {
    _postsScrollController.addListener(() {
      if (_postsScrollController.position.pixels == _postsScrollController.position.maxScrollExtent) {
        if (postMode == "SavedPosts") {
          loadMoreSaves();
        } else if (postMode == "Timeline") {
          loadMoreTimeline();
        } else {
          loadMorePosts();
        }
      }
    });
  }

  void checkCommentsLastOfScroll() {
    _commentsScrollController.addListener(() {
      if (_commentsScrollController.position.pixels == _commentsScrollController.position.maxScrollExtent) {
        if (currentCallCommentsScreenSetState != null &&
            commentsViewPostReference != null &&
            localPostsData[commentsViewPostReference!.id]!["allCommentsLoaded"] == false) {
          loadNewComments = true;
          loadComments(postReference: commentsViewPostReference!, callCommentsScreenSetState: currentCallCommentsScreenSetState!);
        }
      }
    });
  }

  void commentControllerTextChanged(String txt) {
    if (globalUserData.selectedReplyId != "") {
      String replyUsername = globalUserData.selectedReplyUsername;
      if (txt.startsWith("@$replyUsername ") == false) {
        _commentController.text = "";
        globalUserData.selectedCommentSetState();
        clearSelectedReplyId();
      } else {
        globalUserData.selectedCommentSetState();
      }
    }
  }

  void clearSelectedReplyId() {
    globalUserData.SetSelectedReplyId(0, "", "", callPostScreenSetState);
    if (mounted) {
      setState(() {});
    }
  }

  void callPostScreenSetState() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _commentController.dispose();
    _commentsScrollController.dispose();
    _postsScrollController.dispose();
    _focusNode.dispose();
    _likeAnimationController.dispose();
    _saveAnimationController.dispose();
    _loadingAnimationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    postMode = widget.postMode;
    globalUserData = widget.globalUserData;
    changeIsSelectedFunction = widget.changeIsSelectedFunction;
    if (postMode == "SearchPosts") {
      selectedUserData = globalUserData.selectedUserData.last!;
    } else {
      selectedUserData = globalUserData;
    }

    selectedPostId = selectedUserData.selectedPostId;

    setPostsDataAndMoveTop();

    checkCommentsLastOfScroll();
    checkPostsLastOfScroll();

    _likeAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _likeScaleAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _likeAnimationController, curve: Curves.easeOut),
    );
    _likeOpacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _likeAnimationController, curve: Curves.easeOut),
    );
    _saveAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _saveScaleAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _saveAnimationController, curve: Curves.easeOut),
    );
    _saveOpacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _saveAnimationController, curve: Curves.easeOut),
    );

    _loadingAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return initialPostsLoading == false
        ? postsData.isNotEmpty
            ? (localPostsData[selectedPostId] != null && localPostsData[selectedPostId]!["saved"] != null)
                ? ListView.builder(
                    controller: _postsScrollController,
                    itemCount: postsData.length + 1,
                    itemBuilder: (context, index) {
                      if (index == postsData.length) {
                        if (loadPostsOperation) {
                          return miniLoadingAnimation();
                        } else {
                          return SizedBox(height: 0);
                        }
                      } else {
                        QueryDocumentSnapshot<Map<String, dynamic>> postDocument = postsData[index];
                        String postId = postDocument.id;
                        DocumentReference<Map<String, dynamic>> postReference;
                        Map<String, dynamic> data;
                        if (postMode == "SavedPosts") {
                          postReference = postDocument.data()["postReference"];
                          data = localSavesData[postId]!;
                        } else {
                          postReference = postDocument.reference;
                          data = postDocument.data();
                        }

                        if (localPostsData[postId] == null) {
                          setPostStatus(postReference);
                        }
                        return PostFrame(data, postId, postReference);
                      }
                    })
                : FirstPostLoadingAnimation(postMode)
            : NoPostsTabBar()
        : FirstPostLoadingAnimation(postMode);
  }

  Container PostFrame(Map<String, dynamic> postData, String postId, DocumentReference<Map<String, dynamic>> postReference) {
    return (localPostsData[postId] != null && localPostsData[postId]!["saved"] != null)
        ? Container(
            child: Column(
              children: [
                SizedBox(height: 10),
                Row(
                  children: [
                    SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        onUserSelect(localPostsData[postId]!["postOwnerData"]);
                      },
                      child: (localPostsData[postId]!["postOwnerData"]["profilePhotoUrl"] != null)
                          ? CircleAvatar(
                              backgroundColor: Colors.white,
                              radius: 20,
                              child: ClipOval(
                                  child: Image.network(
                                localPostsData[postId]!["postOwnerData"]["profilePhotoUrl"],
                                width: 150,
                                height: 150,
                                fit: BoxFit.cover,
                              )),
                            )
                          : Icon(
                              Icons.account_circle,
                              size: 40,
                              color: Colors.grey[300],
                            ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              onUserSelect(localPostsData[postId]!["postOwnerData"]);
                            },
                            child: Text(
                              " @ ${localPostsData[postId]!["postOwnerData"]["username"]}",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 20,
                              ),
                              Expanded(
                                child: Text(
                                  localPostsData[postId]!["placeName"],
                                  style: TextStyle(fontWeight: FontWeight.w600, overflow: TextOverflow.ellipsis),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 10,
                ),
                Image.network(
                  postData["postPhotoUrl"],
                  height: MediaQuery.of(context).size.width * 1.1,
                  width: MediaQuery.of(context).size.width,
                  fit: BoxFit.cover,
                ),
                Padding(
                  padding: EdgeInsets.only(left: 10, top: 10, right: 10),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          AnimatedBuilder(
                            animation: _likeAnimationController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _likeScaleAnimation.value,
                                child: Opacity(
                                  opacity: _likeOpacityAnimation.value,
                                  child: localPostsData[postId]!["liked"] ? Icon(Icons.favorite, color: Colors.red) : Icon(Icons.favorite_border),
                                ),
                              );
                            },
                          ),
                          GestureDetector(
                            onTap: () {
                              likePost(postReference: postReference);
                              _likeAnimationController.forward(from: 0);
                            },
                            child: localPostsData[postId]!["liked"] ? Icon(Icons.favorite, color: Colors.red) : Icon(Icons.favorite_border),
                          ),
                        ],
                      ),
                      SizedBox(width: 5),
                      Text(
                        localPostsData[postId]!["likeCount"].toString(),
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      SizedBox(width: 20),
                      GestureDetector(
                        onTap: () {
                          _commentController.text = "";
                          commentsViewPostReference = postReference;
                          clearSelectedReplyId();
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                            builder: (context) {
                              return StatefulBuilder(builder: (context, setState) {
                                void callCommentsScreenSetState() {
                                  if (mounted) {
                                    setState(() {});
                                  }
                                }

                                if (currentCallCommentsScreenSetState != callCommentsScreenSetState) {
                                  currentCallCommentsScreenSetState = callCommentsScreenSetState;
                                }
                                if (loadCommentsOperation == false && localPostsData[postReference.id]!["comments"] == null) {
                                  loadComments(postReference: postReference, callCommentsScreenSetState: callCommentsScreenSetState);
                                }

                                return Container(
                                  height: _focusNode.hasFocus ? MediaQuery.of(context).size.height * 0.95 : MediaQuery.of(context).size.height * 0.65,
                                  child: Column(
                                    children: [
                                      Stack(
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.only(left: 5),
                                            child: IconButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              icon: Icon(Icons.arrow_back),
                                            ),
                                          ),
                                          const Center(
                                            child: Padding(
                                              padding: EdgeInsets.only(top: 12),
                                              child: Text(
                                                "Comments",
                                                style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 20,
                                                    fontFamily: "Arial",
                                                    fontWeight: FontWeight.w600,
                                                    decoration: TextDecoration.none,
                                                    letterSpacing: 0),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Expanded(
                                          child: localPostsData[postId]!["comments"] != null
                                              ? localPostsData[postId]!["comments"].isEmpty
                                                  ? NoCommentsTabBar()
                                                  : ListView.builder(
                                                      padding: EdgeInsets.zero,
                                                      controller: _commentsScrollController,
                                                      itemCount: localPostsData[postId]!["comments"].length + 1,
                                                      itemBuilder: (context, index) {
                                                        if (index == localPostsData[postId]!["comments"].length) {
                                                          if (loadCommentsOperation) {
                                                            return Container(
                                                              child: RotationTransition(
                                                                turns: _loadingAnimationController,
                                                                child: const Icon(
                                                                  Icons.refresh,
                                                                  size: 25,
                                                                ),
                                                              ),
                                                            );
                                                          } else {
                                                            return SizedBox(height: 0);
                                                          }
                                                        } else {
                                                          final Map<String, dynamic> commentData = localPostsData[postId]!["comments"][index];
                                                          return CommentFrame(
                                                              globalUserData: globalUserData,
                                                              commentData: commentData,
                                                              commentsSetStateFunction: callCommentsScreenSetState,
                                                              postsSetStateFunction: callPostScreenSetState,
                                                              changeIsSelectedFunction: changeIsSelectedFunction,
                                                              postMode: postMode,
                                                              index: index,
                                                              focusNode: _focusNode,
                                                              commentController: _commentController,
                                                              postReference: postReference,
                                                              localPostsData: localPostsData);
                                                        }
                                                      },
                                                    )
                                              : CommentsLoadingAnimation()),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Material(
                                              color: Colors.transparent,
                                              child: TextField(
                                                focusNode: _focusNode,
                                                controller: _commentController,
                                                onChanged: commentControllerTextChanged,
                                                maxLines: 5,
                                                minLines: 1, // Allow multiline input
                                                decoration: InputDecoration(
                                                  prefixIcon: Icon(Icons.chat_bubble_outline),
                                                  hintText: "Post your comment.",
                                                  hintStyle: TextStyle(color: Colors.grey),
                                                  contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                                  filled: true,
                                                  fillColor: Colors.grey[200],
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(25),
                                                    borderSide: BorderSide.none,
                                                  ),
                                                ),
                                                style: TextStyle(fontSize: 14),
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                              onPressed: () {
                                                commentPost(postReference: postReference);
                                                setState(() {});
                                              },
                                              icon: Icon(Icons.send)),
                                        ],
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(
                                          bottom: MediaQuery.of(context).viewInsets.bottom, // Adjust for keyboard
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              });
                            },
                          );
                        },
                        child: Icon(Icons.chat_bubble_outline),
                      ),
                      SizedBox(width: 5),
                      Text(
                        localPostsData[postId]!["commentCount"].toString(),
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      SizedBox(width: 20),
                      Stack(
                        children: [
                          AnimatedBuilder(
                            animation: _saveAnimationController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _saveScaleAnimation.value,
                                child: Opacity(
                                  opacity: _saveOpacityAnimation.value,
                                  child: localPostsData[postId]!["saved"]
                                      ? Icon(Icons.cloud_download, color: Colors.deepPurple)
                                      : Icon(Icons.cloud_download_outlined),
                                ),
                              );
                            },
                          ),
                          GestureDetector(
                            onTap: () {
                              savePost(postReference: postReference);
                              _saveAnimationController.forward(from: 0);
                            },
                            child: localPostsData[postId]!["saved"]
                                ? Icon(Icons.cloud_download, color: Colors.deepPurple)
                                : Icon(Icons.cloud_download_outlined),
                          ),
                        ],
                      ),
                      SizedBox(width: 5),
                      Text(
                        localPostsData[postId]!["saveCount"].toString(),
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      Spacer(),
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
                                    children: (postData["userId"] == globalUserData.uid)
                                        ? [
                                            _buildMenuItem(Icons.edit, 'Edit', postReference),
                                            const Divider(
                                              color: Colors.black26,
                                              thickness: 0.75,
                                              height: 0,
                                            ),
                                            _buildMenuItem(Icons.delete, 'Delete', postReference)
                                          ]
                                        : [_buildMenuItem(Icons.report, 'Report', postReference)],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        child: Icon(Icons.more_horiz),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 10, right: 10, top: 5),
                  child: Align(
                    alignment: Alignment(-1, 0),
                    child: postData["caption"] == ""
                        ? SizedBox(height: 0)
                        : GestureDetector(
                            onTap: () {
                              onUserSelect(localPostsData[postId]!["postOwnerData"]);
                            },
                            child: RichText(
                              text: TextSpan(
                                text: localPostsData[postId]!["postOwnerData"]["username"],
                                style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black),
                                children: [
                                  TextSpan(
                                      text: ": ${postData["caption"]}", style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black)),
                                ],
                              ),
                            ),
                          ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 10, right: 10, top: 5),
                  child: Align(
                    alignment: Alignment(-1, 0),
                    child: Text(
                      GlobalFunctions().formatTimeDifference(postData["postCreateDate"]),
                      style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                const Divider(
                  color: Colors.black26,
                  thickness: 0.3,
                ),
              ],
            ),
          )
        : miniLoadingAnimation();
  }

  Widget _buildMenuItem(IconData icon, String text, DocumentReference<Map<String, dynamic>> postReference) {
    return ListTile(
      leading: Icon(icon, color: (text == "Delete" || text == "Report") ? Colors.red : Colors.black87),
      title: Text(
        text,
        style: TextStyle(
          color: (text == "Delete" || text == "Report") ? Colors.red : Colors.black87,
          fontSize: 16,
        ),
      ),
      onTap: () {
        if (text == "Delete") {
          deletePost(postReference: postReference);
        } else if (text == "Report") {
          print("Coming SOON");
        }
        Navigator.pop(context); // Close the modal after selection
      },
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

  Center CommentsLoadingAnimation() {
    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        RotationTransition(
          turns: _loadingAnimationController,
          child: const Icon(
            Icons.refresh,
            size: 60,
          ),
        ),
        const Text(
          "Comments loading",
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

  Center FirstPostLoadingAnimation(String postMode) {
    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        RotationTransition(
          turns: _loadingAnimationController,
          child: const Icon(
            Icons.refresh,
            size: 60,
          ),
        ),
        Text(
          (postMode == "SavedPosts") ? "Saves loading" : "Posts loading",
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

  Center NoCommentsTabBar() {
    return const Center(
      child: Column(
        children: [
          SizedBox(
            height: 75,
          ),
          Icon(
            Icons.comment_outlined,
            size: 60,
          ),
          Text(
            "No comments",
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
            "No posts found",
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
