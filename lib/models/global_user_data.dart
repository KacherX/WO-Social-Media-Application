import 'package:cloud_firestore/cloud_firestore.dart';

void doNothing() {}

class GlobalUserData {
  late String uid;
  late Map<String, dynamic> userData;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> postsData = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> savesData = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> notificationsData = [];

  List<GlobalUserData?> selectedUserData = [];
  List<String> lastPage = [];

  late Function selectedCommentSetState;
  int selectedReplyIndex = 0;
  String selectedReplyUsername = "";
  String selectedReplyId = "";
  String selectedPostId = "";

  int friendsCount = 0;
  int onlineFriendsCount = 0;

  void ClearLists() {
    lastPage = [];
    selectedUserData = [];
  }

  void SetFriendsCount(int Count) {
    friendsCount = Count;
  }

  void SetOnlineFriendsCount(int Count) {
    onlineFriendsCount = Count;
  }

  void SetSelectedPostId(String postId) {
    selectedPostId = postId;
  }

  void SetSelectedReplyId(int index, String replyId, String username, Function setStateFunction) {
    selectedReplyIndex = index;
    selectedReplyId = replyId;
    selectedReplyUsername = username;
    selectedCommentSetState = setStateFunction;
  }

  void SetLastPage(String page) {
    lastPage = [page];
  }

  void AddLastPage(String page) {
    lastPage.add(page);
  }

  String PopLastPage() {
    return lastPage.removeLast();
  }

  void SetSelectedUserData(GlobalUserData? data) {
    selectedUserData = [data];
  }

  void AddSelectedUserData(GlobalUserData? data) {
    selectedUserData.add(data);
  }

  GlobalUserData? PopSelectedUserData() {
    return selectedUserData.removeLast();
  }

  void ChangeUserData(Map<String, dynamic> newUserData) {
    userData = newUserData;
  }

  void ChangePostsData(List<QueryDocumentSnapshot<Map<String, dynamic>>> newPostsData) {
    postsData = newPostsData;
  }

  void AddPostsData(List<QueryDocumentSnapshot<Map<String, dynamic>>> newPostsData) {
    postsData.addAll(newPostsData);
  }

  void ChangeSavesData(List<QueryDocumentSnapshot<Map<String, dynamic>>> newSavesData) {
    savesData = newSavesData;
  }

  void AddSavesData(List<QueryDocumentSnapshot<Map<String, dynamic>>> newSavesData) {
    savesData.addAll(newSavesData);
  }

  void ChangeNotificationsData(List<QueryDocumentSnapshot<Map<String, dynamic>>> newNotificationsData) {
    notificationsData = newNotificationsData;
  }

  void AddNotificationsData(List<QueryDocumentSnapshot<Map<String, dynamic>>> newNotificationsData) {
    notificationsData.addAll(newNotificationsData);
  }

  GlobalUserData(this.uid, this.userData);
}
