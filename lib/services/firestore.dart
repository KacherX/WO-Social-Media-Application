import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wo/models/place_model.dart';

class Firestore {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  // Write operation
  //Her zaman set() kullan add()'i sadece uid yoksa kullan.
  Future<void> setUser({required String uid, required String username}) async {
    try {
      await _firebaseFirestore.collection("users").doc(uid).set({'username': username, 'joinDate': FieldValue.serverTimestamp()});
      await _firebaseFirestore.collection("userposts").doc(uid).set({'username': username});
    } catch (e) {
      print(e);
    }
  }

  // Write operation
  Future<void> updateUserAfterFirstJoin({required String uid, required String name, required String phoneNumber, required DateTime birthday}) async {
    try {
      await _firebaseFirestore.collection("users").doc(uid).update({
        'name': name,
        'birthday': birthday,
        "phoneNumber": phoneNumber,
        "bio": "",
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> setUserOnlineOffline({required String uid, required bool isOnline}) async {
    try {
      await _firebaseFirestore.collection("users").doc(uid).update({'isOnline': isOnline, 'lastSeen': FieldValue.serverTimestamp()});
    } catch (e) {
      print(e);
    }
  }

  Future<void> setUserPosition({required String uid, required Position? position}) async {
    try {
      if (position != null) {
        await _firebaseFirestore.collection("users").doc(uid).update({'lat': position.latitude, 'lon': position.longitude});
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> editProfile(
      {required String uid,
      required String name,
      required String bio,
      required String? profilePhotoUrl,
      required String? profileCoverPhotoUrl}) async {
    try {
      await _firebaseFirestore.collection("users").doc(uid).update({
        'name': name,
        "bio": bio,
        "previousEditDate": FieldValue.serverTimestamp(),
        "profilePhotoUrl": profilePhotoUrl,
        "profileCoverPhotoUrl": profileCoverPhotoUrl,
      });
    } catch (e) {
      print(e);
    }
  }

  String getRandomPostId({required String uid}) {
    DocumentReference docRef = _firebaseFirestore.collection("userposts").doc(uid).collection("posts").doc();
    return docRef.id;
  }

  String getRandomCommentId({required DocumentReference<Map<String, dynamic>> postReference}) {
    DocumentReference docRef = postReference.collection("comments").doc();
    return docRef.id;
  }

  String getRandomReplyId({required DocumentReference<Map<String, dynamic>> postReference, required String commentId}) {
    DocumentReference docRef = postReference.collection("comments").doc(commentId).collection("replies").doc();
    return docRef.id;
  }

  Future<void> addPost(
      {required String uid,
      required String postid,
      required String photoUrl,
      required String caption,
      required Place selectedPlace,
      required int star,
      required String placeComment}) async {
    try {
      List<Future> futures = [];
      futures.add(_firebaseFirestore.collection("userposts").doc(uid).collection("posts").doc(postid).set({
        "postCreateDate": FieldValue.serverTimestamp(),
        "postPhotoUrl": photoUrl,
        "caption": caption,
        "userId": uid,
        "placeId": "${selectedPlace.id}",
      }));
      await _firebaseFirestore.collection("places").doc("${selectedPlace.id}").get().then((doc) async {
        if (doc.exists) {
          await _firebaseFirestore
              .collection("places")
              .doc("${selectedPlace.id}")
              .collection("placeComments")
              .doc(uid)
              .get()
              .then((docSnapshot) async {
            if (!docSnapshot.exists) {
              // kullanici daha once yorum yapmamissa
              futures.add(_firebaseFirestore
                  .collection("places")
                  .doc("${selectedPlace.id}")
                  .update({"totalVotes": doc.data()!["totalVotes"] + 1, "totalStars": doc.data()!["totalStars"] + star}));
            } else {
              // kullanici daha once yorum yapmissa yorumunu guncelle
              num finalStar = star - docSnapshot.data()!["star"];
              futures.add(
                  _firebaseFirestore.collection("places").doc("${selectedPlace.id}").update({"totalStars": doc.data()!["totalStars"] + finalStar}));
            }
            futures.add(_firebaseFirestore
                .collection("places")
                .doc("${selectedPlace.id}")
                .collection("placeComments")
                .doc(uid)
                .set({"star": star, "placeComment": placeComment, "commentDate": FieldValue.serverTimestamp()})); // Latest comment only visible
          });
        }
      });

      await Future.wait(futures);
    } catch (e) {
      print(e);
    }
  }

  Future<void> blockUser({required String userUid, required String blockedUserId}) async {
    try {
      List<Future> futures = [];

      futures.add(unFriendUser(userUid: userUid, senderUid: blockedUserId));
      futures.add(takeFriendRequestBack(getterUid: userUid, senderUid: blockedUserId));
      futures.add(takeFriendRequestBack(getterUid: blockedUserId, senderUid: userUid));
      futures.add(_firebaseFirestore
          .collection("users")
          .doc(userUid)
          .collection("blocked_accounts")
          .doc(blockedUserId)
          .set({"blockDate": FieldValue.serverTimestamp()}));

      await Future.wait(futures);
    } catch (e) {
      print(e);
    }
  }

  Future<void> unblockUser({required String userUid, required String blockedUserId}) async {
    try {
      await _firebaseFirestore.collection("users").doc(userUid).collection("blocked_accounts").doc(blockedUserId).delete();
    } catch (e) {
      print(e);
    }
  }

  Future<bool> userIsBlocked({required String userUid, required String checkUserUid}) async {
    try {
      final countQuery = await _firebaseFirestore.collection("users").doc(userUid).collection("blocked_accounts").doc(checkUserUid).get();
      if (countQuery.exists) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print(e);
      return false;
    }
  }

  // Subcollection write operation
  Future<void> acceptFriendRequest({required String userUid, required String senderUid}) async {
    try {
      List<Future> futures = [];

      futures.add(takeFriendRequestBack(getterUid: userUid, senderUid: senderUid));
      futures.add(
          _firebaseFirestore.collection("users").doc(senderUid).collection("friends").doc(userUid).set({"friendDate": FieldValue.serverTimestamp()}));
      futures.add(
          _firebaseFirestore.collection("users").doc(userUid).collection("friends").doc(senderUid).set({"friendDate": FieldValue.serverTimestamp()}));

      await Future.wait(futures);
    } catch (e) {
      print(e);
    }
  }

  Future<void> sendFriendRequest({required String getterUid, required String senderUid}) async {
    try {
      await _firebaseFirestore
          .collection("users")
          .doc(getterUid)
          .collection("notifications")
          .doc()
          .set({"notificationDate": FieldValue.serverTimestamp(), "type": 1, "userId": senderUid});
    } catch (e) {
      print(e);
    }
  }

  Future<void> takeFriendRequestBack({required String getterUid, required String senderUid}) async {
    try {
      QuerySnapshot querySnapshot = await _firebaseFirestore
          .collection("users")
          .doc(getterUid)
          .collection("notifications")
          .where("userId", isEqualTo: senderUid)
          .where("type", isEqualTo: 1)
          .get();
      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        doc.reference.delete();
      }
    } catch (e) {
      print(e);
    }
  }

  Future<bool> userHasFriendRequest({required String getterUid, required String senderUid}) async {
    bool hasFriendRequest = false;
    try {
      QuerySnapshot querySnapshot = await _firebaseFirestore
          .collection("users")
          .doc(getterUid)
          .collection("notifications")
          .where("userId", isEqualTo: senderUid)
          .where("type", isEqualTo: 1)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        hasFriendRequest = true;
      }
    } catch (e) {
      print(e);
    }
    return hasFriendRequest;
  }

  // Subcollection write operation
  Future<void> unFriendUser({required String userUid, required String senderUid}) async {
    try {
      List<Future> futures = [];

      futures.add(_firebaseFirestore.collection("users").doc(userUid).collection("friends").doc(senderUid).delete());
      futures.add(_firebaseFirestore.collection("users").doc(senderUid).collection("friends").doc(userUid).delete());

      await Future.wait(futures);
    } catch (e) {
      print(e);
    }
  }

  // Read operation
  Future<int> getFriendsCount({required String uid}) async {
    try {
      final countQuery = await _firebaseFirestore.collection("users").doc(uid).collection("friends").count().get();
      return countQuery.count!;
    } catch (e) {
      print(e);
      return 0;
    }
  }

  Future<int> getOnlineFriendsCount({required String uid}) async {
    try {
      final CollectionReference<Map<String, dynamic>> usersCollection = _firebaseFirestore.collection("users");

      // Step 1: Fetch the friend IDs
      final friendsSnapshot = await usersCollection.doc(uid).collection("friends").get();
      List<String> friendIds = friendsSnapshot.docs.map((doc) => doc.id).toList();

      if (friendIds.isEmpty) return 0; // No friends, return 0

      // Step 2: Fetch only friends who are online
      final onlineFriendsQuery = await usersCollection
          .where(FieldPath.documentId, whereIn: friendIds) // Filter only friends
          .where("isOnline", isEqualTo: true) // Check if they are online
          .count()
          .get();

      return onlineFriendsQuery.count ?? 0;
    } catch (e) {
      print("Error fetching online friends count: $e");
      return 0;
    }
  }

  Future<bool> userIsFriend({required String userUid, required String checkUserUid}) async {
    try {
      final countQuery = await _firebaseFirestore.collection("users").doc(userUid).collection("friends").doc(checkUserUid).get();
      if (countQuery.exists) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<int> getCommentsCountFromPostReference({required DocumentReference<Map<String, dynamic>> postReference}) async {
    try {
      final countQuery = await postReference.collection("comments").count().get();
      if (countQuery.count == null) {
        return 0;
      } else {
        return countQuery.count!;
      }
    } catch (e) {
      print(e);
      return 0;
    }
  }

  Future<int> getSavesCountFromPostReference({required DocumentReference<Map<String, dynamic>> postReference}) async {
    try {
      final countQuery = await postReference.collection("saves").count().get();
      if (countQuery.count == null) {
        return 0;
      } else {
        return countQuery.count!;
      }
    } catch (e) {
      print(e);
      return 0;
    }
  }

  Future<int> getLikesCountFromPostReference({required DocumentReference<Map<String, dynamic>> postReference}) async {
    try {
      final countQuery = await postReference.collection("likes").count().get();
      if (countQuery.count == null) {
        return 0;
      } else {
        return countQuery.count!;
      }
    } catch (e) {
      print(e);
      return 0;
    }
  }

  Future<void> deleteNotification({required String userId, required String notificationId}) async {
    DocumentSnapshot documentSnapshot =
        await _firebaseFirestore.collection("users").doc(userId).collection("notifications").doc(notificationId).get();
    if (documentSnapshot.exists) {
      await documentSnapshot.reference.delete();
    }
  }

  Future<void> checkAndDeleteOldNotifications({required String userId}) async {
    final DateTime cutoffDate = DateTime.now().subtract(Duration(days: 30));
    QuerySnapshot querySnapshot = await _firebaseFirestore
        .collection("users")
        .doc(userId)
        .collection("notifications")
        .where("type", isNotEqualTo: 1)
        .where("notificationDate", isLessThan: Timestamp.fromDate(cutoffDate))
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      List<Future> batchFutures = [];
      WriteBatch batch = _firebaseFirestore.batch();
      int batchCount = 0;

      void singleDeleteOperation(DocumentReference ref) {
        batch.delete(ref);
        batchCount += 1;
        if (batchCount >= 500) {
          batchCount = 0;
          batchFutures.add(batch.commit());
          batch = _firebaseFirestore.batch();
        }
      }

      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        singleDeleteOperation(doc.reference);
      }

      if (batchCount > 0) {
        batchFutures.add(batch.commit());
      }
      await Future.wait(batchFutures);
    }
  }

  Future<List<Map<String, dynamic>>> getCommentsWithUserDetails(
      {required DocumentReference<Map<String, dynamic>> postReference, required String userId, required Timestamp lastCommentDate}) async {
    try {
      // Fetch the "comments" subcollection from the post
      QuerySnapshot<Map<String, dynamic>> commentsSnapshot = await postReference
          .collection("comments")
          .orderBy("commentDate", descending: true)
          .startAfter([lastCommentDate])
          .limit(20) // Latest comments first
          .get();

      List<Future<Map<String, dynamic>>> userFetchFutures = [];

      for (var commentDoc in commentsSnapshot.docs) {
        Map<String, dynamic> commentData = commentDoc.data();

        // Add the user data fetching task to the list of futures
        userFetchFutures.add(
          _firebaseFirestore.collection("users").doc(commentData["userId"]).get().then((userDoc) {
            if (userDoc.exists) {
              Map<String, dynamic> userData = userDoc.data() ?? {};

              // Return a combined map of comment data + user data
              return {
                "userId": commentData["userId"],
                "commentId": commentDoc.id,
                "comment": commentData["comment"],
                "commentDate": commentData["commentDate"],
                "username": userData["username"],
                "profilePhotoUrl": userData["profilePhotoUrl"],
              };
            } else {
              // Handle case where user document doesn't exist
              return {
                "userId": "Unknown",
                "commentId": commentDoc.id,
                "comment": commentData["comment"],
                "commentDate": commentData["commentDate"],
                "username": "Unknown",
                "profilePhotoUrl": null, // Empty photo URL
              };
            }
          }),
        );
      }

      List<Map<String, dynamic>> commentsWithUserData = await Future.wait(userFetchFutures);

      // Now fetch likes and replies for all comments concurrently
      List<Future<Map<String, dynamic>>> likeAndReplyFutures = [];

      for (var commentData in commentsWithUserData) {
        String commentDocId = commentData["commentId"];

        // Fetch like count
        var likeCountFuture = postReference.collection("comments").doc(commentDocId).collection("likes").get().then((likesSnapshot) {
          return {"likeCount": likesSnapshot.docs.length};
        });

        // Fetch reply count
        var replyCountFuture = postReference.collection("comments").doc(commentDocId).collection("replies").get().then((repliesSnapshot) {
          return {"replyCount": repliesSnapshot.docs.length};
        });

        // Fetch whether the current user has liked the post
        var userLikedPostFuture = postReference
            .collection("comments")
            .doc(commentDocId)
            .collection("likes") // Assuming "likes" is the subcollection under the post
            .doc(userId)
            .get()
            .then((userLikeDoc) {
          return {"liked": userLikeDoc.exists}; // Returns whether the user liked the post
        });

        // Add the like, reply, and user like status futures to the list
        likeAndReplyFutures.add(
          Future.wait([likeCountFuture, replyCountFuture, userLikedPostFuture]).then((results) {
            var likeCount = results[0]["likeCount"];
            var replyCount = results[1]["replyCount"];
            var userLikedPost = results[2]["liked"];

            // Combine the comment data, user data, like/reply counts, and liked status
            return {
              ...commentData, // Spread the original comment data
              "likeCount": likeCount,
              "replyCount": replyCount,
              "liked": userLikedPost, // Whether the user liked the post
            };
          }),
        );
      }

      // Wait for all like, reply, and user like status futures to complete
      List<Map<String, dynamic>> finalCommentsWithDetails = await Future.wait(likeAndReplyFutures);

      return finalCommentsWithDetails;
    } catch (e) {
      print("Error fetching comments with user details: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getRepliesWithUserDetails(
      {required DocumentReference<Map<String, dynamic>> postReference,
      required String commentId,
      required String userId,
      required Timestamp lastReplyDate}) async {
    try {
      // Fetch the "comments" subcollection from the post
      QuerySnapshot<Map<String, dynamic>> repliesSnapshot = await postReference
          .collection("comments")
          .doc(commentId)
          .collection("replies")
          .orderBy("replyDate", descending: true)
          .startAfter([lastReplyDate])
          .limit(20) // Latest comments first
          .get();

      List<Future<Map<String, dynamic>>> userFetchFutures = [];

      for (var replyDoc in repliesSnapshot.docs.reversed) {
        Map<String, dynamic> replyData = replyDoc.data();

        // Add the user data fetching task to the list of futures
        userFetchFutures.add(
          _firebaseFirestore.collection("users").doc(replyData["userId"]).get().then((userDoc) {
            if (userDoc.exists) {
              Map<String, dynamic> userData = userDoc.data() ?? {};

              // Return a combined map of comment data + user data
              return {
                "userId": replyData["userId"],
                "replyId": replyDoc.id,
                "reply": replyData["reply"],
                "replyDate": replyData["replyDate"],
                "username": userData["username"],
                "profilePhotoUrl": userData["profilePhotoUrl"],
              };
            } else {
              // Handle case where user document doesn't exist
              return {
                "userId": "Unknown",
                "replyId": replyDoc.id,
                "reply": replyData["reply"],
                "replyDate": replyData["replyDate"],
                "username": "Unknown",
                "profilePhotoUrl": null, // Empty photo URL
              };
            }
          }),
        );
      }

      List<Map<String, dynamic>> repliesWithUserData = await Future.wait(userFetchFutures);

      // Now fetch likes and replies for all comments concurrently
      List<Future<Map<String, dynamic>>> likeFutures = [];

      for (var replyData in repliesWithUserData) {
        String replyDocId = replyData["replyId"];

        // Fetch like count
        var likeCountFuture =
            postReference.collection("comments").doc(commentId).collection("replies").doc(replyDocId).collection("likes").get().then((likesSnapshot) {
          return {"likeCount": likesSnapshot.docs.length};
        });

        // Fetch whether the current user has liked the post
        var userLikedPostFuture = postReference
            .collection("comments")
            .doc(commentId)
            .collection("replies")
            .doc(replyDocId)
            .collection("likes") // Assuming "likes" is the subcollection under the post
            .doc(userId)
            .get()
            .then((userLikeDoc) {
          return {"liked": userLikeDoc.exists}; // Returns whether the user liked the post
        });

        // Add the like, reply, and user like status futures to the list
        likeFutures.add(
          Future.wait([likeCountFuture, userLikedPostFuture]).then((results) {
            var likeCount = results[0]["likeCount"];
            var userLikedPost = results[1]["liked"];

            // Combine the comment data, user data, like/reply counts, and liked status
            return {
              ...replyData, // Spread the original comment data
              "likeCount": likeCount,
              "liked": userLikedPost, // Whether the user liked the post
            };
          }),
        );
      }

      // Wait for all like, reply, and user like status futures to complete
      List<Map<String, dynamic>> finalRepliesWithDetails = await Future.wait(likeFutures);

      return finalRepliesWithDetails;
    } catch (e) {
      print("Error fetching comments with user details: $e");
      return [];
    }
  }

  Future<void> makeCommentFromPostReference(
      {required String userId,
      required DocumentReference<Map<String, dynamic>> postReference,
      required String comment,
      required String commentId}) async {
    try {
      await postReference
          .collection("comments")
          .doc(commentId)
          .set({"userId": userId, "comment": comment, "commentDate": FieldValue.serverTimestamp()});
      DocumentSnapshot<Map<String, dynamic>> snapshot = await postReference.get();
      if (snapshot.exists) {
        String postOwnerId = snapshot.data()!["userId"];
        if (postOwnerId != userId) {
          // Kendi kendine bildirim gondermesin.
          QuerySnapshot querySnapshot = await _firebaseFirestore
              .collection("users")
              .doc(postOwnerId)
              .collection("notifications")
              .where("userId", isEqualTo: userId)
              .where("postId", isEqualTo: postReference.id)
              .where("comment", isEqualTo: comment)
              .get();
          if (querySnapshot.docs.isEmpty) {
            await _firebaseFirestore.collection("users").doc(postOwnerId).collection("notifications").doc().set({
              "notificationDate": FieldValue.serverTimestamp(),
              "type": 2,
              "action": 2,
              "userId": userId,
              "postId": postReference.id,
              "comment": comment,
            });
          }
        }
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> makeReplyToCommentFromPostReference(
      {required String userId,
      required DocumentReference<Map<String, dynamic>> postReference,
      required String reply,
      required String commentId,
      required String replyId}) async {
    try {
      await postReference
          .collection("comments")
          .doc(commentId)
          .collection("replies")
          .doc(replyId)
          .set({"userId": userId, "reply": reply, "replyDate": FieldValue.serverTimestamp()});
      DocumentSnapshot<Map<String, dynamic>> snapshot = await postReference.get();
      if (snapshot.exists) {
        String postOwnerId = snapshot.data()!["userId"];
        if (postOwnerId != userId) {
          // Kendi kendine bildirim gondermesin.
          QuerySnapshot querySnapshot = await _firebaseFirestore
              .collection("users")
              .doc(postOwnerId)
              .collection("notifications")
              .where("userId", isEqualTo: userId)
              .where("postId", isEqualTo: postReference.id)
              .where("comment", isEqualTo: reply)
              .get();
          if (querySnapshot.docs.isEmpty) {
            await _firebaseFirestore.collection("users").doc(postOwnerId).collection("notifications").doc().set({
              "notificationDate": FieldValue.serverTimestamp(),
              "type": 2,
              "action": 2,
              "userId": userId,
              "postId": postReference.id,
              "comment": reply,
            });
          }
        }
        DocumentSnapshot<Map<String, dynamic>> commentSnapshot = await postReference.collection("comments").doc(commentId).get();
        if (commentSnapshot.exists) {
          String commentOwnerId = commentSnapshot.data()!["userId"];
          if (commentOwnerId != userId) {
            // Kendi commentine yorum yaptiginda bildirim gitmesin
            print("SET NOTIFICATION LOGIC HERE!!");
          }
        }
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> deletePostFromPostReference(
      // AWAIT COMPLEXITY: O(6) // belki hierarchiyi degistirerek optimize edilebilir.
      {required DocumentReference<Map<String, dynamic>> postReference}) async {
    try {
      CollectionReference<Map<String, dynamic>> userPosts = _firebaseFirestore.collection("userposts");

      List<Future> batchFutures = [];
      List<Future> futures = [];
      List<Future> futures2 = [];

      WriteBatch batch = _firebaseFirestore.batch();
      int batchCount = 0;

      void singleDeleteOperation(DocumentReference ref) {
        batch.delete(ref);
        batchCount += 1;
        if (batchCount >= 500) {
          batchCount = 0;
          batchFutures.add(batch.commit());
          batch = _firebaseFirestore.batch();
        }
      }

      // Delete the "likes" subcollection concurrently
      QuerySnapshot<Map<String, dynamic>> likesSnapshot = await postReference.collection("likes").get();
      for (var likeDoc in likesSnapshot.docs) {
        singleDeleteOperation(likeDoc.reference);
      }

      QuerySnapshot<Map<String, dynamic>> savesSnapshot = await postReference.collection("saves").get();
      for (var saveDoc in savesSnapshot.docs) {
        final savedPost = userPosts.doc(saveDoc.id).collection("saved_posts").doc(postReference.id);
        singleDeleteOperation(savedPost);
        singleDeleteOperation(saveDoc.reference);
      }

      QuerySnapshot<Map<String, dynamic>> commentsSnapshot = await postReference.collection("comments").get();
      for (var commentDoc in commentsSnapshot.docs) {
        // Collect "likes" for each comment
        futures.add(commentDoc.reference.collection("likes").get().then((commentLikesSnapshot) {
          for (var commentLikeDoc in commentLikesSnapshot.docs) {
            singleDeleteOperation(commentLikeDoc.reference);
          }
        }));

        // Collect "replies" for each comment
        futures.add(commentDoc.reference.collection("replies").get().then((commentRepliesSnapshot) {
          for (var commentReplyDoc in commentRepliesSnapshot.docs) {
            futures2.add(commentReplyDoc.reference.collection("likes").get().then((replyLikesSnapshot) {
              for (var replyLikeDoc in replyLikesSnapshot.docs) {
                singleDeleteOperation(replyLikeDoc.reference);
              }
            }));

            singleDeleteOperation(commentReplyDoc.reference);
          }
        }));

        singleDeleteOperation(commentDoc.reference);
      }

      await Future.wait(futures);
      await Future.wait(futures2);
      if (batchCount > 0) {
        batchFutures.add(batch.commit());
      }
      await Future.wait(batchFutures);
      await postReference.delete();
    } catch (e) {
      print("Error deleting post: $e");
    }
  }

  Future<void> deleteReplyFromPostReference(
      // AWAIT COMPLEXITY: O(4)
      {required DocumentReference<Map<String, dynamic>> postReference,
      required String commentId,
      required String replyId}) async {
    try {
      // Reference to the comment document
      DocumentReference<Map<String, dynamic>> replyDoc = postReference.collection("comments").doc(commentId).collection("replies").doc(replyId);

      List<Future> batchFutures = [];
      WriteBatch batch = _firebaseFirestore.batch();
      int batchCount = 0;

      void singleDeleteOperation(DocumentReference ref) {
        batch.delete(ref);
        batchCount += 1;
        if (batchCount >= 500) {
          batchCount = 0;
          batchFutures.add(batch.commit());
          batch = _firebaseFirestore.batch();
        }
      }

      // Delete the "likes" subcollection concurrently
      QuerySnapshot<Map<String, dynamic>> likesSnapshot = await replyDoc.collection("likes").get();
      for (var likeDoc in likesSnapshot.docs) {
        singleDeleteOperation(likeDoc.reference);
      }

      if (batchCount > 0) {
        batchFutures.add(batch.commit());
      }
      await Future.wait(batchFutures);
      await replyDoc.delete();
    } catch (e) {
      print("Error deleting comment and its subcollections: $e");
    }
  }

  Future<void> deleteCommentFromPostReference(
      // AWAIT COMPLEXITY: O(4)
      {required DocumentReference<Map<String, dynamic>> postReference,
      required String commentId}) async {
    try {
      // Reference to the comment document
      DocumentReference<Map<String, dynamic>> commentDoc = postReference.collection("comments").doc(commentId);

      List<Future> futures = [];
      List<Future> batchFutures = [];
      WriteBatch batch = _firebaseFirestore.batch();
      int batchCount = 0;

      void singleDeleteOperation(DocumentReference ref) {
        batch.delete(ref);
        batchCount += 1;
        if (batchCount >= 500) {
          batchCount = 0;
          batchFutures.add(batch.commit());
          batch = _firebaseFirestore.batch();
        }
      }

      // Delete the "likes" subcollection concurrently
      QuerySnapshot<Map<String, dynamic>> likesSnapshot = await commentDoc.collection("likes").get();
      for (var likeDoc in likesSnapshot.docs) {
        singleDeleteOperation(likeDoc.reference);
      }
      // Delete the "replies" subcollection concurrently
      QuerySnapshot<Map<String, dynamic>> repliesSnapshot = await commentDoc.collection("replies").get();
      for (var replyDoc in repliesSnapshot.docs) {
        futures.add(replyDoc.reference.collection("likes").get().then((replyLikesSnapshot) {
          for (var replyLikeDoc in replyLikesSnapshot.docs) {
            singleDeleteOperation(replyLikeDoc.reference);
          }
        }));

        singleDeleteOperation(replyDoc.reference);
      }

      await Future.wait(futures);
      if (batchCount > 0) {
        batchFutures.add(batch.commit());
      }
      await Future.wait(batchFutures);
      await commentDoc.delete();
    } catch (e) {
      print("Error deleting comment and its subcollections: $e");
    }
  }

  Future<void> likeOrUnlikeReply(
      // AWAIT COMPLEXITY: O(2)
      {required String userId,
      required DocumentReference<Map<String, dynamic>> postReference,
      required String commentId,
      required String replyId}) async {
    try {
      final likeDoc =
          await postReference.collection("comments").doc(commentId).collection("replies").doc(replyId).collection("likes").doc(userId).get();
      if (likeDoc.exists) {
        // Unlike
        await postReference.collection("comments").doc(commentId).collection("replies").doc(replyId).collection("likes").doc(userId).delete();
      } else {
        // Like
        await postReference
            .collection("comments")
            .doc(commentId)
            .collection("replies")
            .doc(replyId)
            .collection("likes")
            .doc(userId)
            .set({"likeDate": FieldValue.serverTimestamp()});
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> likeOrUnlikeComment(
      // AWAIT COMPLEXITY: O(2)
      {required String userId,
      required DocumentReference<Map<String, dynamic>> postReference,
      required String commentId}) async {
    try {
      final likeDoc = await postReference.collection("comments").doc(commentId).collection("likes").doc(userId).get();
      if (likeDoc.exists) {
        // Unlike
        await postReference.collection("comments").doc(commentId).collection("likes").doc(userId).delete();
      } else {
        // Like
        await postReference.collection("comments").doc(commentId).collection("likes").doc(userId).set({"likeDate": FieldValue.serverTimestamp()});
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> likeOrUnlikePostFromPostReference(
      // AWAIT COMPLEXITY: O(5)
      {required String userId,
      required DocumentReference<Map<String, dynamic>> postReference}) async {
    try {
      final likeDoc = await postReference.collection("likes").doc(userId).get();
      if (likeDoc.exists) {
        // Unlike
        await postReference.collection("likes").doc(userId).delete();
      } else {
        // Like
        await postReference.collection("likes").doc(userId).set({"likeDate": FieldValue.serverTimestamp()});
        DocumentSnapshot<Map<String, dynamic>> snapshot = await postReference.get();
        if (snapshot.exists) {
          String postOwnerId = snapshot.data()!["userId"];
          if (postOwnerId != userId) {
            QuerySnapshot querySnapshot = await _firebaseFirestore
                .collection("users")
                .doc(postOwnerId)
                .collection("notifications")
                .where("userId", isEqualTo: userId)
                .where("postId", isEqualTo: postReference.id)
                .where("action", isEqualTo: 1)
                .get();
            if (querySnapshot.docs.isEmpty) {
              await _firebaseFirestore.collection("users").doc(postOwnerId).collection("notifications").doc().set({
                "notificationDate": FieldValue.serverTimestamp(),
                "type": 2,
                "action": 1,
                "userId": userId,
                "postId": postReference.id,
              });
            }
          }
        }
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> saveOrUnsavePostFromPostReference({required String userId, required DocumentReference<Map<String, dynamic>> postReference}) async {
    // AWAIT COMPLEXITY: O(2)
    try {
      final saveDoc = await postReference.collection("saves").doc(userId).get();
      if (saveDoc.exists) {
        // Unsave
        await postReference.collection("saves").doc(userId).delete();
        await _firebaseFirestore.collection("userposts").doc(userId).collection("saved_posts").doc(postReference.id).delete();
      } else {
        // Save
        await postReference.collection("saves").doc(userId).set({"saveDate": FieldValue.serverTimestamp()});
        await _firebaseFirestore
            .collection("userposts")
            .doc(userId)
            .collection("saved_posts")
            .doc(postReference.id)
            .set({"postReference": postReference, "postSaveDate": FieldValue.serverTimestamp()});
      }
    } catch (e) {
      print(e);
    }
  }

  Future<Map<String, Map<String, dynamic>>> getPostsWithDataFromSaves({required List<QueryDocumentSnapshot<Map<String, dynamic>>> savesData}) async {
    Map<String, Map<String, dynamic>> localSavedPostsData = {};
    try {
      List<Future<MapEntry<String, Map<String, dynamic>>>> fetchTasks = [];

      for (var post in savesData) {
        DocumentReference<Map<String, dynamic>> postReference = post.data()["postReference"];

        fetchTasks.add(
          postReference.get().then((postDoc) {
            return MapEntry(postDoc.id, postDoc.data()!);
          }),
        );
      }

      List<MapEntry<String, Map<String, dynamic>>> fetchedPosts = await Future.wait(fetchTasks);

      for (var entry in fetchedPosts) {
        localSavedPostsData[entry.key] = entry.value;
      }
    } catch (e) {
      print(e);
    }
    return localSavedPostsData;
  }

  Future<bool> hasUserLikedPost({
    required String userId,
    required DocumentReference<Map<String, dynamic>> postReference,
  }) async {
    try {
      final likeDoc = await postReference.collection("likes").doc(userId).get();
      return likeDoc.exists;
    } catch (e) {
      print("Error checking like status: $e");
      return false; // Return false if there was an error (e.g., no connection to Firestore)
    }
  }

  Future<bool> hasUserSavedPost({
    required String userId,
    required DocumentReference<Map<String, dynamic>> postReference,
  }) async {
    try {
      final saveDoc = await postReference.collection("saves").doc(userId).get();
      return saveDoc.exists;
    } catch (e) {
      print("Error checking save status: $e");
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getFriendsStartingWith({
    required String uid,
    required String input,
  }) async {
    try {
      final CollectionReference<Map<String, dynamic>> usersCollection = _firebaseFirestore.collection('users');
      final friends = await usersCollection.doc(uid).collection("friends").get(); // Butun arkadaslar arasindan

      List<Future> futures = [];
      List<Map<String, dynamic>> friendUserDocs = [];

      for (var entry in friends.docs) {
        futures.add(usersCollection.doc(entry.id).get().then((friendUserDoc) {
          final userData = friendUserDoc.data();
          if (userData != null && userData["username"] != null && userData["username"].toLowerCase().startsWith(input.toLowerCase())) {
            friendUserDocs.add({
              "id": entry.id,
              "friendDate": entry.data()["friendDate"], // Include friend date
              ...userData, // Merge user data
            });
          }
        }));
      }

      await Future.wait(futures);

      return friendUserDocs;
    } catch (e) {
      print("Error: $e");
      return [];
    }
  }

  // Read operation
  Future<List<Map<String, dynamic>>> getFriendsWithUserData({required String uid, required Timestamp lastFriendDate, required int limit}) async {
    try {
      final CollectionReference<Map<String, dynamic>> usersCollection = _firebaseFirestore.collection('users');
      final friends = await usersCollection
          .doc(uid)
          .collection("friends")
          .orderBy("friendDate", descending: true)
          .startAfter([lastFriendDate])
          .limit(limit)
          .get();

      List<Future> futures = [];
      List<Map<String, dynamic>> friendUserDocs = [];

      int count = 0;
      for (var entry in friends.docs) {
        int innerCount = count;
        friendUserDocs.add({});
        count += 1;
        futures.add(usersCollection.doc(entry.id).get().then((friendUserDoc) {
          friendUserDocs[innerCount] = {
            "id": entry.id,
            "friendDate": entry.data()["friendDate"], // Include friend ID
            ...?friendUserDoc.data(), // Spread operator to merge document data
          };
        }));
      }

      await Future.wait(futures);

      return friendUserDocs;
    } catch (e) {
      print("Error: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getBlockedAccountsStartingWith({
    required String uid,
    required String input,
  }) async {
    try {
      final CollectionReference<Map<String, dynamic>> usersCollection = _firebaseFirestore.collection('users');
      final blockedAccounts = await usersCollection.doc(uid).collection("blocked_accounts").get(); // Butun arkadaslar arasindan

      List<Future> futures = [];
      List<Map<String, dynamic>> blockUserDocs = [];

      for (var entry in blockedAccounts.docs) {
        futures.add(usersCollection.doc(entry.id).get().then((blockUserDoc) {
          final userData = blockUserDoc.data();
          if (userData != null && userData["username"] != null && userData["username"].toLowerCase().startsWith(input.toLowerCase())) {
            blockUserDocs.add({
              "id": entry.id,
              "blockDate": entry.data()["blockDate"], // Include friend date
              ...userData, // Merge user data
            });
          }
        }));
      }

      await Future.wait(futures);

      return blockUserDocs;
    } catch (e) {
      print("Error: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getBlockedAccountsWithUserData({required String uid, required Timestamp lastBlockDate}) async {
    try {
      final CollectionReference<Map<String, dynamic>> usersCollection = _firebaseFirestore.collection('users');
      final blockedAccounts = await usersCollection
          .doc(uid)
          .collection("blocked_accounts")
          .orderBy("blockDate", descending: true)
          .startAfter([lastBlockDate])
          .limit(30)
          .get();

      List<Future> futures = [];
      List<Map<String, dynamic>> blockUserDocs = [];

      int count = 0;
      for (var entry in blockedAccounts.docs) {
        int innerCount = count;
        blockUserDocs.add({});
        count += 1;
        futures.add(usersCollection.doc(entry.id).get().then((blockUserDoc) {
          blockUserDocs[innerCount] = {
            "id": entry.id,
            "blockDate": entry.data()["blockDate"], // Include friend ID
            ...?blockUserDoc.data(), // Spread operator to merge document data
          };
        }));
      }

      await Future.wait(futures);

      return blockUserDocs;
    } catch (e) {
      print("Error: $e");
      return [];
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getNotificationSnapshots(
      {required String uid, required int lastType, required Timestamp lastNotificationDate}) {
    return _firebaseFirestore
        .collection("users")
        .doc(uid)
        .collection("notifications")
        .orderBy("type", descending: false)
        .orderBy("notificationDate", descending: true)
        .startAfter([lastType, lastNotificationDate])
        .limit(30)
        .snapshots();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getUserNotifications(
      {required String uid, required int lastType, required Timestamp lastNotificationDate}) async {
    return await _firebaseFirestore
        .collection("users")
        .doc(uid)
        .collection("notifications")
        .orderBy("type", descending: false)
        .orderBy("notificationDate", descending: true)
        .startAfter([lastType, lastNotificationDate])
        .limit(30)
        .get();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getPostsSnapshots({required String uid, required Timestamp lastPostDate}) {
    return _firebaseFirestore
        .collection("userposts")
        .doc(uid)
        .collection("posts")
        .orderBy("postCreateDate", descending: true)
        .startAfter([lastPostDate])
        .limit(30)
        .snapshots();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getUserPosts({required String uid, required Timestamp lastPostDate}) async {
    return await _firebaseFirestore
        .collection("userposts")
        .doc(uid)
        .collection("posts")
        .orderBy("postCreateDate", descending: true)
        .startAfter([lastPostDate])
        .limit(30)
        .get();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getUserSaves({required String uid, required Timestamp lastSaveDate}) async {
    return await _firebaseFirestore
        .collection("userposts")
        .doc(uid)
        .collection("saved_posts")
        .orderBy("postSaveDate", descending: true)
        .startAfter([lastSaveDate])
        .limit(30)
        .get();
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getFriendsPosts({required String uid, required Timestamp lastPostDate}) async {
    // Step 1: Fetch friend user IDs
    final friendsSnapshot = await _firebaseFirestore.collection('users').doc(uid).collection('friends').get();

    final friendIDs = friendsSnapshot.docs.map((doc) => doc.id).toList();

    if (friendIDs.isEmpty) return [];

    List<QueryDocumentSnapshot<Map<String, dynamic>>> allPosts = [];

    // Step 2: Batch in chunks of 10 for Firestore `whereIn` limit
    for (int i = 0; i < friendIDs.length; i += 10) {
      final batch = friendIDs.sublist(i, (i + 10).clamp(0, friendIDs.length));

      final querySnapshot = await _firebaseFirestore
          .collectionGroup('posts')
          .where('userId', whereIn: batch)
          .orderBy('postCreateDate', descending: true)
          .startAfter([lastPostDate])
          .limit(30)
          .get();

      allPosts.addAll(querySnapshot.docs);
    }

    // Step 3: Final sort across all batches by postDate (descending)
    allPosts.sort((a, b) {
      final aDate = a.data()['postCreateDate'] as Timestamp;
      final bDate = b.data()['postCreateDate'] as Timestamp;
      return bDate.compareTo(aDate); // descending
    });

    return allPosts;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getSavedPostsSnapshots({required String uid, required Timestamp lastSaveDate}) {
    return _firebaseFirestore
        .collection("userposts")
        .doc(uid)
        .collection("saved_posts")
        .orderBy("postSaveDate", descending: true)
        .startAfter([lastSaveDate])
        .limit(30)
        .snapshots();
  }

  // Read operation
  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserSnapshots({required String uid}) {
    return _firebaseFirestore.collection("users").doc(uid).snapshots();
  }

  Future<Map<String, dynamic>> getPostData({required String uid, required String postId}) async {
    Map<String, dynamic> data = {};
    try {
      await _firebaseFirestore.collection("userposts").doc(uid).collection("posts").doc(postId).get().then(
        (querySnapshot) {
          data = querySnapshot.data()!;
        },
        onError: (e) => print(e),
      );
    } catch (e) {
      print(e);
    }
    return data;
  }

  // Read operation
  Future<Map<String, dynamic>> getUserData({required String uid}) async {
    Map<String, dynamic> data = {};
    try {
      await _firebaseFirestore.collection("users").doc(uid).get().then(
        (querySnapshot) {
          data = querySnapshot.data()!;
        },
        onError: (e) => print(e),
      );
    } catch (e) {
      print(e);
    }
    return data;
  }

  // Read + Query operation
  Future<bool> usernameIsUnique({required String username}) async {
    bool docIsEmpty = false;
    try {
      await _firebaseFirestore.collection("users").where("username", isEqualTo: username).get().then(
        (querySnapshot) {
          docIsEmpty = querySnapshot.docs.isEmpty;
        },
        onError: (e) => print(e),
      );
    } catch (e) {
      print(e);
    }
    return docIsEmpty;
  }

  Future<List<Map<String, dynamic>>> getUsernamesStartingWith({required String input, required String uid}) async {
    try {
      // Reference to the "users" collection
      final CollectionReference<Map<String, dynamic>> usersCollection = _firebaseFirestore.collection('users');

      // Define the start and end range for the query
      String startAt = input;
      String endAt = input + '\uf8ff';

      QuerySnapshot<Map<String, dynamic>> querySnapshot = await usersCollection
          .where('username', isGreaterThanOrEqualTo: startAt)
          .where('username', isLessThanOrEqualTo: endAt)
          .orderBy('username')
          .limit(20)
          .get();

      QuerySnapshot<Map<String, dynamic>> friendsSnapshot = await usersCollection.doc(uid).collection('friends').get();
      Set<String> friendUids = friendsSnapshot.docs.map((doc) => doc.id).toSet();

      List<Map<String, dynamic>> userDataList = querySnapshot.docs
          .map((doc) => {
                "id": doc.id, // Include the document ID
                "isFriend": friendUids.contains(doc.id),
                ...doc.data(), // Spread all document fields
              })
          .toList();

      return userDataList;
    } catch (e) {
      print("Error fetching usernames: $e");
      return [];
    }
  }

  Future<String> getPlaceNameById({
    required DocumentReference<Map<String, dynamic>> postReference,
  }) async {
    try {
      String returnStr = "";
      final docRef = await postReference.get();
      if (docRef.exists) {
        String? placeId = docRef.data()!["placeId"];
        if (placeId != null) {
          await _firebaseFirestore.collection("places").doc(placeId).get().then((query) {
            if (query.exists && query.data()!["name"] != null) {
              returnStr = query.data()!["name"];
            }
          });
        }
      }
      return returnStr;
    } catch (e) {
      print("Error checking like status: $e");
      return "";
    }
  }

  Future<List<Map<String, dynamic>>> getPlaceCommentsWithUserDetails({required String placeId, required Timestamp lastCommentDate}) async {
    try {
      // Fetch the "comments" subcollection from the post
      QuerySnapshot<Map<String, dynamic>> commentsSnapshot = await _firebaseFirestore
          .collection("places")
          .doc(placeId)
          .collection("placeComments")
          .orderBy("commentDate", descending: true)
          .startAfter([lastCommentDate])
          .limit(20) // Latest comments first
          .get();

      List<Future<Map<String, dynamic>>> userFetchFutures = [];

      for (var commentDoc in commentsSnapshot.docs) {
        Map<String, dynamic> commentData = commentDoc.data();
        String userId = commentDoc.id;

        // Add the user data fetching task to the list of futures
        userFetchFutures.add(
          _firebaseFirestore.collection("users").doc(userId).get().then((userDoc) {
            if (userDoc.exists) {
              Map<String, dynamic> userData = userDoc.data() ?? {};

              // Return a combined map of comment data + user data
              return {
                "userId": userId,
                "comment": commentData["placeComment"],
                "commentDate": commentData["commentDate"],
                "star": commentData["star"],
                "username": userData["username"],
                "profilePhotoUrl": userData["profilePhotoUrl"],
              };
            } else {
              // Handle case where user document doesn't exist
              return {
                "userId": "Unknown",
                "comment": commentData["comment"],
                "commentDate": commentData["commentDate"],
                "star": commentData["star"],
                "username": "Unknown",
                "profilePhotoUrl": null, // Empty photo URL
              };
            }
          }),
        );
      }

      List<Map<String, dynamic>> commentsWithUserData = await Future.wait(userFetchFutures);

      return commentsWithUserData;
    } catch (e) {
      print("Error fetching comments with user details: $e");
      return [];
    }
  }

  Future<void> togglePlaceFavourite(String userID, String placeID) async {
    final favRef = _firebaseFirestore.collection('users').doc(userID).collection('favourites').doc(placeID);

    final favSnapshot = await favRef.get();

    if (favSnapshot.exists) {
      // Zaten favorideyse: kaldır
      await favRef.delete();
    } else {
      // Favori olarak ekle
      await favRef.set({'favouriteDate': FieldValue.serverTimestamp()});
    }
  }

  Future<List<String>> getUserFavouritePlaceIDs(String userID) async {
    final snapshot = await _firebaseFirestore.collection('users').doc(userID).collection('favourites').get();

    return snapshot.docs.map((doc) => doc.id).toList(); // placeIDs
  }

  Future<Map<String, dynamic>> checkAndCreatePlace({required Place place}) async {
    Map<String, dynamic> data = {};
    try {
      await _firebaseFirestore.collection("places").doc(place.id).get().then(
        (querySnapshot) async {
          if (querySnapshot.exists) {
            data = querySnapshot.data()!;
          } else {
            double latRounded = double.parse(place.lat.toStringAsFixed(3));
            double lonRounded = double.parse(place.lon.toStringAsFixed(3));

            await FirebaseFirestore.instance
                .collection("places")
                .where("name", isEqualTo: place.name)
                .where("latRounded", isEqualTo: latRounded)
                .where("lonRounded", isEqualTo: lonRounded)
                .get()
                .then((query) async {
              if (query.docs.isEmpty) {
                await _firebaseFirestore.collection("places").doc(place.id).set({
                  "name": place.name,
                  "lon": place.lon,
                  "lonRounded": lonRounded,
                  "lat": place.lat,
                  "latRounded": latRounded,
                  "totalStars": 0,
                  "totalVotes": 0
                });
                data = {"name": place.name, "lon": place.lon, "lat": place.lat, "totalStars": 0, "totalVotes": 0};
              } else {
                // ID Degismisse id yi tasima
                await _firebaseFirestore.collection("places").doc(place.id).set({
                  "name": place.name,
                  "lon": place.lon,
                  "lonRounded": lonRounded,
                  "lat": place.lat,
                  "latRounded": latRounded,
                  "totalStars": query.docs.first.data()["totalStars"],
                  "totalVotes": query.docs.first.data()["totalVotes"],
                });
                data = {
                  "name": place.name,
                  "lon": place.lon,
                  "lat": place.lat,
                  "totalStars": query.docs.first.data()["totalStars"],
                  "totalVotes": query.docs.first.data()["totalVotes"]
                };
                await query.docs.first.reference.delete();
              }
            });
          }
        },
        onError: (e) => print(e),
      );
    } catch (e) {
      print(e);
    }
    return data;
  }
}
