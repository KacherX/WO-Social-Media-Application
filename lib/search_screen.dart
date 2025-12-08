import 'package:flutter/material.dart';
import 'package:wo/models/global_user_data.dart';
import 'package:wo/services/firestore.dart';

class SearchScreen extends StatefulWidget {
  final GlobalUserData globalUserData;
  final Function changeIsSelectedFunction;
  const SearchScreen({Key? key, required this.globalUserData, required this.changeIsSelectedFunction}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with TickerProviderStateMixin {
  late GlobalUserData globalUserData;
  late Function changeIsSelectedFunction;

  List<Map<String, dynamic>> searchUserDatas = [];
  bool _searchingDone = true;

  final _searchController = TextEditingController();

  late AnimationController _loadingAnimationController;

  void searchOnChanged(String txt) async {
    String trimtxt = txt.trim();
    if (trimtxt.isNotEmpty) {
      _searchingDone = false;
      if (mounted) {
        setState(() {});
      }
      final result = await Firestore().getUsernamesStartingWith(input: trimtxt, uid: globalUserData.uid);
      if (trimtxt == _searchController.text.trim()) {
        searchUserDatas = result;
      }
      _searchingDone = true;
    } else {
      searchUserDatas = [];
    }
    if (mounted) {
      setState(() {});
    }
  }

  void onUserSelect(Map<String, dynamic> userData) {
    GlobalUserData selectedUserData = GlobalUserData(userData["id"], userData);
    globalUserData.SetSelectedUserData(selectedUserData);
    globalUserData.SetLastPage("Search");
    changeIsSelectedFunction("SearchProfile");
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _searchController.dispose();
    _loadingAnimationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    globalUserData = widget.globalUserData;
    changeIsSelectedFunction = widget.changeIsSelectedFunction;

    _loadingAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
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
                  hintText: "Search user by username.",
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
          _searchingDone
              ? searchUserDatas.isEmpty
                  ? NoUsersTabBar()
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: searchUserDatas.length,
                      itemBuilder: (context, index) {
                        final userData = searchUserDatas[index];
                        return GestureDetector(
                          onTap: () {
                            onUserSelect(userData);
                          },
                          child: UserContainer(userData),
                        );
                      })
              : UsersLoadingAnimation(),
        ],
      ),
    );
  }

  Widget UserContainer(Map<String, dynamic> userData) {
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
                userData["id"] == globalUserData.uid
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
                    : userData["isFriend"]
                        ? const Row(
                            children: [
                              Icon(
                                Icons.person,
                                size: 20,
                                color: Colors.green,
                              ),
                              Expanded(
                                child: Text(
                                  "Friend",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              const Icon(
                                Icons.person,
                                size: 20,
                              ),
                              Expanded(
                                child: Text(
                                  (userData["birthday"] != null) ? "User" : "New user",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Center UsersLoadingAnimation() {
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
        const Text(
          "Users loading",
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

  Center NoUsersTabBar() {
    return const Center(
      child: Column(
        children: [
          SizedBox(
            height: 75,
          ),
          Icon(
            Icons.people,
            size: 60,
          ),
          Text(
            "No users found",
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
