import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:wo/models/global_user_data.dart';
import 'package:wo/reply_frame.dart';
import 'package:wo/services/firestore.dart';
import 'package:wo/services/global_functions.dart';

class CommentFrame extends StatefulWidget {
  final GlobalUserData globalUserData;
  final Map<String, dynamic> commentData;
  final Function commentsSetStateFunction;
  final Function postsSetStateFunction;
  final Function changeIsSelectedFunction;
  final String postMode;
  final int index;
  final FocusNode focusNode;
  final TextEditingController commentController;
  final DocumentReference<Map<String, dynamic>> postReference;
  final Map<String, Map<String, dynamic>> localPostsData;
  const CommentFrame(
      {Key? key,
      required this.globalUserData,
      required this.commentData,
      required this.commentsSetStateFunction,
      required this.postsSetStateFunction,
      required this.changeIsSelectedFunction,
      required this.postMode,
      required this.index,
      required this.focusNode,
      required this.commentController,
      required this.postReference,
      required this.localPostsData});

  @override
  State<CommentFrame> createState() => _CommentFrameState();
}

class _CommentFrameState extends State<CommentFrame> with TickerProviderStateMixin {
  late GlobalUserData globalUserData;
  late Map<String, Map<String, dynamic>> localPostsData;
  late Function commentsSetStateFunction;
  late Function postsSetStateFunction;
  late Function changeIsSelectedFunction;
  late String postMode;
  late int index;
  late FocusNode focusNode;
  late TextEditingController commentController;
  late DocumentReference<Map<String, dynamic>> postReference;

  late AnimationController _likeAnimationController;
  late Animation<double> _likeScaleAnimation;
  late Animation<double> _likeOpacityAnimation;

  bool likeOperation = false;
  bool likeReplyOperation = false;
  bool userSelectOperation = false;
  bool initialRepliesLoaded = false;

  Future<void> likeComment({required DocumentReference<Map<String, dynamic>> postReference, required String commentId}) async {
    if (likeOperation == false) {
      likeOperation = true;
      try {
        String postId = postReference.id;
        bool liked = localPostsData[postId]!["comments"][index]["liked"];
        if (mounted) {
          setState(() {
            localPostsData[postId]!["comments"][index]["liked"] = !liked;
            localPostsData[postId]!["comments"][index]["likeCount"] = (liked == true)
                ? localPostsData[postId]!["comments"][index]["likeCount"] - 1
                : localPostsData[postId]!["comments"][index]["likeCount"] + 1;
          });
          commentsSetStateFunction();
        }
        await Firestore().likeOrUnlikeComment(userId: globalUserData.uid, postReference: postReference, commentId: commentId);
      } catch (e) {
        print("ERROR: $e");
      }
      likeOperation = false;
    }
  }

  Future<void> likeReply(
      {required DocumentReference<Map<String, dynamic>> postReference,
      required String commentId,
      required String replyId,
      required int replyIndex}) async {
    if (likeReplyOperation == false) {
      likeReplyOperation = true;
      try {
        String postId = postReference.id;
        bool liked = localPostsData[postId]!["comments"][index]["replies"][replyIndex]["liked"];
        if (mounted) {
          setState(() {
            localPostsData[postId]!["comments"][index]["replies"][replyIndex]["liked"] = !liked;
            localPostsData[postId]!["comments"][index]["replies"][replyIndex]["likeCount"] = (liked == true)
                ? localPostsData[postId]!["comments"][index]["replies"][replyIndex]["likeCount"] - 1
                : localPostsData[postId]!["comments"][index]["replies"][replyIndex]["likeCount"] + 1;
          });
          commentsSetStateFunction();
        }
        await Firestore().likeOrUnlikeReply(userId: globalUserData.uid, postReference: postReference, commentId: commentId, replyId: replyId);
      } catch (e) {
        print("ERROR: $e");
      }
      likeReplyOperation = false;
    }
  }

  Future<void> deleteComment({required DocumentReference<Map<String, dynamic>> postReference, required String commentId, required int index}) async {
    try {
      String postId = postReference.id;
      if (mounted) {
        setState(() {
          localPostsData[postId]!["commentCount"] = localPostsData[postId]!["commentCount"] - 1;
          localPostsData[postId]!["comments"].removeAt(index);
        });
        commentsSetStateFunction();
        postsSetStateFunction();
      }
      await Firestore().deleteCommentFromPostReference(postReference: postReference, commentId: commentId);
    } catch (e) {
      print("ERROR: $e");
    }
  }

  Future<void> deleteReply(
      {required DocumentReference<Map<String, dynamic>> postReference,
      required String commentId,
      required String replyId,
      required int replyIndex}) async {
    try {
      String postId = postReference.id;
      if (mounted) {
        setState(() {
          localPostsData[postId]!["comments"][index]["replyCount"] = localPostsData[postId]!["comments"][index]["replyCount"] - 1;
          localPostsData[postId]!["comments"][index]["replies"].removeAt(replyIndex);
        });
        commentsSetStateFunction();
        postsSetStateFunction();
      }
      await Firestore().deleteReplyFromPostReference(postReference: postReference, commentId: commentId, replyId: replyId);
    } catch (e) {
      print("ERROR: $e");
    }
  }

  void onUserSelect(Map<String, dynamic> commentData) async {
    if (userSelectOperation == false) {
      userSelectOperation = true;
      String userId = commentData["userId"];
      final userData = await Firestore().getUserData(uid: userId);
      if (focusNode.hasFocus) {
        FocusScope.of(context).unfocus();
        await Future.delayed(Duration(seconds: 1));
      }
      Navigator.pop(context); // BUGLU BURASI YUKLENIRKEN EGER WIDGET KAPATILIRSA PATLIYOR.
      if (userData.isNotEmpty) {
        GlobalUserData selectedUserData = GlobalUserData(userId, userData);
        globalUserData.AddSelectedUserData(selectedUserData);
        globalUserData.AddLastPage(postMode);
        changeIsSelectedFunction("SearchProfile");
      }
      if (mounted) {
        setState(() {});
      }
    }
  }

  void setInitialReplies(String commentId) async {
    localPostsData[postReference.id]!["comments"][index]["replies"] = [];
    List<Map<String, dynamic>> repliesData = await Firestore().getRepliesWithUserDetails(
        postReference: postReference, commentId: commentId, userId: globalUserData.uid, lastReplyDate: Timestamp.fromDate(DateTime(2100)));
    localPostsData[postReference.id]!["comments"][index]["replies"].addAll(repliesData);
    initialRepliesLoaded = true;

    if (mounted) {
      setState(() {});
    }
  }

  void chooseCommentToReply(String commentId, String commenterUsername) {
    if (globalUserData.selectedReplyId != commentId || globalUserData.selectedReplyUsername != commenterUsername) {
      FocusScope.of(context).requestFocus(focusNode);
      commentController.text = "@$commenterUsername ";
      globalUserData.SetSelectedReplyId(index, commentId, commenterUsername, commentsSetStateFunction);
      commentsSetStateFunction();
    }
    if (mounted) {
      setState(() {});
    }
  }

  void commentSetState() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _likeAnimationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    index = widget.index;
    postMode = widget.postMode;
    focusNode = widget.focusNode;
    commentController = widget.commentController;
    postReference = widget.postReference;
    commentsSetStateFunction = widget.commentsSetStateFunction;
    postsSetStateFunction = widget.postsSetStateFunction;
    changeIsSelectedFunction = widget.changeIsSelectedFunction;
    localPostsData = widget.localPostsData;
    globalUserData = widget.globalUserData;

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
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          const Divider(
            color: Colors.black26,
            thickness: 0.3,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  onUserSelect(widget.commentData);
                },
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 20,
                  child: ClipOval(
                      child: (widget.commentData["profilePhotoUrl"] != null)
                          ? Image.network(
                              widget.commentData["profilePhotoUrl"],
                              width: 150,
                              height: 150,
                              fit: BoxFit.cover,
                            )
                          : Icon(
                              Icons.account_circle,
                              size: 40,
                              color: Colors.grey[300],
                            )),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text("@${widget.commentData["username"]}",
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              decoration: TextDecoration.none,
                              fontWeight: FontWeight.w900,
                              fontFamily: "Arial",
                              letterSpacing: 0,
                              overflow: TextOverflow.ellipsis,
                            )),
                        Expanded(
                          child: Text(" ${GlobalFunctions().formatTimeDifference(widget.commentData["commentDate"])}",
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 14,
                                decoration: TextDecoration.none,
                                fontWeight: FontWeight.w500,
                                fontFamily: "Arial",
                                letterSpacing: 0,
                                overflow: TextOverflow.ellipsis,
                              )),
                        ),
                        Padding(
                          padding: EdgeInsets.only(right: 5),
                          child: GestureDetector(
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
                                        children: (widget.commentData["username"] == globalUserData.userData["username"])
                                            ? [
                                                _buildMenuItem(Icons.edit, 'Edit', "Comment", widget.commentData, index),
                                                const Divider(
                                                  color: Colors.black26,
                                                  thickness: 0.75,
                                                  height: 0,
                                                ),
                                                _buildMenuItem(Icons.delete, 'Delete', "Comment", widget.commentData, index),
                                              ]
                                            : [
                                                _buildMenuItem(Icons.report, 'Report', "Comment", widget.commentData, index),
                                              ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            child: const Icon(Icons.more_horiz, size: 18),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.commentData["comment"],
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        decoration: TextDecoration.none,
                        fontWeight: FontWeight.w500,
                        fontFamily: "Arial",
                        letterSpacing: 0,
                        overflow: TextOverflow.clip,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
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
                                    child: localPostsData[postReference.id]!["comments"][index]["liked"] == true
                                        ? const Icon(Icons.favorite, color: Colors.red, size: 16)
                                        : Icon(Icons.favorite_border, size: 16),
                                  ),
                                );
                              },
                            ),
                            GestureDetector(
                              onTap: () {
                                likeComment(postReference: postReference, commentId: widget.commentData["commentId"]);
                                _likeAnimationController.forward(from: 0);
                                setState(() {});
                              },
                              child: localPostsData[postReference.id]!["comments"][index]["liked"] == true
                                  ? const Icon(Icons.favorite, color: Colors.red, size: 16)
                                  : Icon(Icons.favorite_border, size: 16),
                            ),
                          ],
                        ),
                        const SizedBox(width: 3),
                        Text(
                          localPostsData[postReference.id]!["comments"][index]["likeCount"].toString(),
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                            decoration: TextDecoration.none,
                            fontWeight: FontWeight.w500,
                            fontFamily: "Arial",
                            letterSpacing: 0,
                          ),
                        ),
                        SizedBox(width: 20),
                        GestureDetector(
                          onTap: () {
                            setInitialReplies(widget.commentData["commentId"]);
                            chooseCommentToReply(widget.commentData["commentId"], widget.commentData["username"]);
                          },
                          child: const Icon(Icons.chat_bubble_outline, size: 16),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          localPostsData[postReference.id]!["comments"][index]["replyCount"].toString(),
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                            decoration: TextDecoration.none,
                            fontWeight: FontWeight.w500,
                            fontFamily: "Arial",
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                    globalUserData.selectedReplyId == widget.commentData["commentId"] ? const SizedBox(height: 10) : const SizedBox(height: 0),
                    (globalUserData.selectedReplyId == widget.commentData["commentId"] && initialRepliesLoaded == true)
                        ? ListView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: localPostsData[postReference.id]!["comments"][index]["replies"].length,
                            itemBuilder: (context, replyIndex) {
                              final Map<String, dynamic> replyData = localPostsData[postReference.id]!["comments"][index]["replies"][replyIndex];
                              return ReplyFrame(
                                  commentsSetStateFunction: commentsSetStateFunction,
                                  onUserSelectFunction: onUserSelect,
                                  globalUserData: globalUserData,
                                  localPostsData: localPostsData,
                                  postReference: postReference,
                                  index: index,
                                  commentData: widget.commentData,
                                  replyData: replyData,
                                  commentController: commentController,
                                  replyIndex: replyIndex,
                                  focusNode: focusNode,
                                  postMode: postMode,
                                  changeIsSelectedFunction: changeIsSelectedFunction,
                                  postsSetStateFunction: postsSetStateFunction);
                            },
                          )
                        : const SizedBox(height: 0),
                    globalUserData.selectedReplyId == widget.commentData["commentId"] ? const SizedBox(height: 10) : const SizedBox(height: 0),
                    globalUserData.selectedReplyId == widget.commentData["commentId"]
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(width: 10),
                              (globalUserData.userData["profilePhotoUrl"] != null)
                                  ? CircleAvatar(
                                      backgroundColor: Colors.white,
                                      radius: 16,
                                      child: ClipOval(
                                          child: Image.network(
                                        globalUserData.userData["profilePhotoUrl"],
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
                              const SizedBox(width: 10),
                              Expanded(
                                // Comment ise
                                child: RichText(
                                  maxLines: null,
                                  text: TextSpan(
                                    text: "${globalUserData.userData["username"]}: ",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    children: [
                                      TextSpan(
                                          text: commentController.text, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black)),
                                    ],
                                  ),
                                ),
                              )
                            ],
                          )
                        : const SizedBox(height: 0)
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String text, String mode, Map<String, dynamic> replyData, int replyIndex) {
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
          if (mode == "Comment") {
            deleteComment(postReference: postReference, commentId: widget.commentData["commentId"], index: index);
          } else if (mode == "Reply") {
            deleteReply(
                postReference: postReference, commentId: widget.commentData["commentId"], replyId: replyData["replyId"], replyIndex: replyIndex);
          }
        } else if (text == "Report") {
          print("Coming SOON");
        }
        Navigator.pop(context); // Close the modal after selection
      },
    );
  }
}
