import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:wo/models/global_user_data.dart';
import 'package:wo/services/firestore.dart';
import 'package:wo/services/global_functions.dart';

class ReplyFrame extends StatefulWidget {
  final GlobalUserData globalUserData;
  final DocumentReference<Map<String, dynamic>> postReference;
  final Map<String, Map<String, dynamic>> localPostsData;
  final Map<String, dynamic> commentData;
  final Map<String, dynamic> replyData;
  final TextEditingController commentController;
  final Function commentsSetStateFunction;
  final Function onUserSelectFunction;
  final Function postsSetStateFunction;
  final Function changeIsSelectedFunction;
  final String postMode;
  final FocusNode focusNode;
  final int index;
  final int replyIndex;
  const ReplyFrame(
      {Key? key,
      required this.commentsSetStateFunction,
      required this.globalUserData,
      required this.onUserSelectFunction,
      required this.localPostsData,
      required this.postReference,
      required this.index,
      required this.commentData,
      required this.replyData,
      required this.commentController,
      required this.replyIndex,
      required this.focusNode,
      required this.postMode,
      required this.changeIsSelectedFunction,
      required this.postsSetStateFunction});

  @override
  State<ReplyFrame> createState() => _ReplyFrameState();
}

class _ReplyFrameState extends State<ReplyFrame> with TickerProviderStateMixin {
  late GlobalUserData globalUserData;
  late DocumentReference<Map<String, dynamic>> postReference;
  late Map<String, Map<String, dynamic>> localPostsData;
  late Function commentsSetStateFunction;
  late Function onUserSelectFunction;
  late TextEditingController commentController;
  late int index;
  late int replyIndex;
  late Function postsSetStateFunction;
  late Function changeIsSelectedFunction;
  late String postMode;
  late FocusNode focusNode;

  late AnimationController _likeAnimationController;
  late Animation<double> _likeScaleAnimation;
  late Animation<double> _likeOpacityAnimation;

  bool likeOperation = false;
  bool likeReplyOperation = false;
  bool userSelectOperation = false;

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
    globalUserData = widget.globalUserData;
    postMode = widget.postMode;
    onUserSelectFunction = widget.onUserSelectFunction;
    focusNode = widget.focusNode;
    postReference = widget.postReference;
    index = widget.index;
    commentController = widget.commentController;
    replyIndex = widget.replyIndex;
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
                  onUserSelectFunction(widget.replyData);
                },
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 16,
                  child: ClipOval(
                      child: (widget.replyData["profilePhotoUrl"] != null)
                          ? Image.network(
                              widget.replyData["profilePhotoUrl"],
                              width: 150,
                              height: 150,
                              fit: BoxFit.cover,
                            )
                          : Icon(
                              Icons.account_circle,
                              size: 32,
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
                        Text("@${widget.replyData["username"]}",
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
                          child: Text(" ${GlobalFunctions().formatTimeDifference(widget.replyData["replyDate"])}",
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
                                        children: (widget.replyData["username"] == globalUserData.userData["username"])
                                            ? [
                                                _buildMenuItem(Icons.edit, 'Edit', widget.replyData, replyIndex),
                                                const Divider(
                                                  color: Colors.black26,
                                                  thickness: 0.75,
                                                  height: 0,
                                                ),
                                                _buildMenuItem(Icons.delete, 'Delete', widget.replyData, replyIndex),
                                              ]
                                            : [
                                                _buildMenuItem(Icons.report, 'Report', widget.replyData, replyIndex),
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
                      widget.replyData["reply"],
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
                                    child: widget.replyData["liked"] == true
                                        ? const Icon(Icons.favorite, color: Colors.red, size: 16)
                                        : Icon(Icons.favorite_border, size: 16),
                                  ),
                                );
                              },
                            ),
                            GestureDetector(
                              onTap: () {
                                likeReply(
                                    postReference: postReference,
                                    commentId: widget.commentData["commentId"],
                                    replyId: widget.replyData["replyId"],
                                    replyIndex: replyIndex);
                                _likeAnimationController.forward(from: 0);
                                setState(() {});
                              },
                              child: widget.replyData["liked"] == true
                                  ? const Icon(Icons.favorite, color: Colors.red, size: 16)
                                  : Icon(Icons.favorite_border, size: 16),
                            ),
                          ],
                        ),
                        const SizedBox(width: 3),
                        Text(
                          widget.replyData["likeCount"].toString(),
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
                            chooseCommentToReply(widget.commentData["commentId"], widget.replyData["username"]);
                          },
                          child: const Icon(Icons.chat_bubble_outline, size: 16),
                        ),
                        const SizedBox(width: 3),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String text, Map<String, dynamic> replyData, int replyIndex) {
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
          deleteReply(
              postReference: postReference, commentId: widget.commentData["commentId"], replyId: replyData["replyId"], replyIndex: replyIndex);
        } else if (text == "Report") {
          print("Coming SOON");
        }
        Navigator.pop(context); // Close the modal after selection
      },
    );
  }
}
