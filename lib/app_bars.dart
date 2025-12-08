import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wo/add_post_frame.dart';
import 'package:wo/models/global_place_data.dart';
import 'package:wo/models/global_user_data.dart';

AppBar MainAppBar() {
  return AppBar(
    backgroundColor: Colors.grey[100],
    centerTitle: true,
    scrolledUnderElevation: 0,
    title: const Text("WO", style: TextStyle(fontFamily: "Pacifico", fontWeight: FontWeight.bold)),
  );
}

AppBar MapAppBar(Function changeFlagFunction) {
  return AppBar(
    backgroundColor: Colors.grey[100],
    centerTitle: true,
    scrolledUnderElevation: 0,
    title: const Text("WO", style: TextStyle(fontFamily: "Pacifico", fontWeight: FontWeight.bold)),
    actions: [
      IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          changeFlagFunction("");
        },
      ),
    ],
  );
}

AppBar AppBarWithTitleTxt(String titletxt) {
  return AppBar(
    backgroundColor: Colors.grey[100],
    centerTitle: true,
    scrolledUnderElevation: 0,
    title: Text(titletxt, style: TextStyle(fontWeight: FontWeight.bold)),
  );
}

AppBar ProfileAppBar(GlobalUserData globalUserData, GlobalPlaceData globalPlaceData, BuildContext context) {
  return AppBar(
    backgroundColor: Colors.grey[100],
    centerTitle: true,
    scrolledUnderElevation: 0,
    title: Text(
      globalUserData.userData["username"],
      style: const TextStyle(fontWeight: FontWeight.bold),
    ),
    actions: [
      IconButton(
        icon: const Icon(Icons.add_photo_alternate),
        onPressed: () {
          if (globalPlaceData.finalPlaces.isNotEmpty) {
            showCupertinoModalPopup(
              context: context,
              builder: (context) => AddPostFrame(globalUserData: globalUserData, globalPlaceData: globalPlaceData),
            );
          }
        },
      ),
    ],
  );
}

AppBar FavouritesAppBar(GlobalUserData globalUserData, Function changeFlagFunction) {
  return AppBar(
    backgroundColor: Colors.grey[100],
    centerTitle: true,
    scrolledUnderElevation: 0,
    title: Text(
      "Favourites",
      style: const TextStyle(fontWeight: FontWeight.bold),
    ),
    actions: [
      IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          changeFlagFunction("");
        },
      ),
    ],
  );
}

AppBar SettingsAppBar(GlobalUserData globalUserData, Function changeFlagFunction) {
  return AppBar(
    backgroundColor: Colors.grey[100],
    centerTitle: true,
    scrolledUnderElevation: 0,
    title: Text(
      "Settings",
      style: const TextStyle(fontWeight: FontWeight.bold),
    ),
    actions: [
      IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          changeFlagFunction("");
        },
      ),
    ],
  );
}

AppBar FriendsAppBar(GlobalUserData globalUserData, Function changeFlagFunction) {
  return AppBar(
    backgroundColor: Colors.grey[100],
    centerTitle: true,
    scrolledUnderElevation: 0,
    title: Text(
      globalUserData.userData["username"],
      style: const TextStyle(fontWeight: FontWeight.bold),
    ),
    actions: [
      IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          changeFlagFunction("");
        },
      ),
    ],
  );
}

AppBar SelectedUserAppBar(String username, Function changeFlagFunction) {
  return AppBar(
    backgroundColor: Colors.grey[100],
    centerTitle: true,
    scrolledUnderElevation: 0,
    title: Text(
      username,
      style: const TextStyle(fontWeight: FontWeight.bold),
    ),
    actions: [
      IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          changeFlagFunction("");
        },
      ),
    ],
  );
}

AppBar PostsAppBar(Function changeFlagFunction) {
  return AppBar(
    backgroundColor: Colors.grey[100],
    centerTitle: true,
    scrolledUnderElevation: 0,
    title: const Text(
      "Posts",
      style: TextStyle(fontWeight: FontWeight.bold),
    ),
    actions: [
      IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          changeFlagFunction("");
        },
      ),
    ],
  );
}

AppBar SavedPostsAppBar(Function changeFlagFunction) {
  return AppBar(
    backgroundColor: Colors.grey[100],
    centerTitle: true,
    scrolledUnderElevation: 0,
    title: const Text(
      "Saves",
      style: TextStyle(fontWeight: FontWeight.bold),
    ),
    actions: [
      IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          changeFlagFunction("");
        },
      ),
    ],
  );
}
