import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:wo/models/global_place_data.dart';
import 'package:wo/models/global_user_data.dart';
import 'package:wo/services/firestore.dart';

class MainMapScreen extends StatefulWidget {
  final GlobalUserData globalUserData;
  final GlobalPlaceData globalPlaceData;
  const MainMapScreen({Key? key, required this.globalUserData, required this.globalPlaceData}) : super(key: key);

  @override
  State<MainMapScreen> createState() => _MainMapScreenState();
}

class _MainMapScreenState extends State<MainMapScreen> {
  late GlobalUserData globalUserData;
  late GlobalPlaceData globalPlaceData;

  MapController mapController = MapController();

  List<Map<String, dynamic>> friendsData = [];
  bool friendsSet = false;

  void setInitialFriends() async {
    List<Future<dynamic>> futures = [
      Firestore().getFriendsWithUserData(uid: globalUserData.uid, lastFriendDate: Timestamp.fromDate(DateTime(2100)), limit: 100), // Max 100
    ];

    List<dynamic> results = await Future.wait(futures);
    friendsData = results[0];

    friendsSet = true;

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    globalUserData = widget.globalUserData;
    globalPlaceData = widget.globalPlaceData;

    setInitialFriends();
  }

  @override
  Widget build(BuildContext context) {
    return friendsSet
        ? Stack(children: [
            FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: LatLng(globalPlaceData.userPosition!.latitude, globalPlaceData.userPosition!.longitude),
                initialZoom: 15.5,
                minZoom: 2.0, // Minimum zoom seviyesi
                maxZoom: 20.0, // Maksimum zoom seviyesi
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(globalPlaceData.userPosition!.latitude, globalPlaceData.userPosition!.longitude),
                      width: 50,
                      height: 50,
                      child: globalUserData.userData["profilePhotoUrl"] != null
                          ? CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.deepPurple,
                              child: Padding(
                                padding: EdgeInsets.all(2.5), // Border radius
                                child: ClipOval(
                                    child: Image.network(
                                  globalUserData.userData["profilePhotoUrl"],
                                  width: 43,
                                  height: 43,
                                  fit: BoxFit.cover,
                                )),
                              ),
                            )
                          : CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.deepPurple,
                              child: Padding(
                                padding: EdgeInsets.all(0), // Border radius
                                child: Icon(
                                  Icons.account_circle,
                                  size: 50,
                                  color: Colors.grey[300],
                                ),
                              ),
                            ),
                    ),
                    for (var friendData in friendsData)
                      if (friendData["lat"] != null && friendData["lon"] != null) friendMarker(friendData),
                  ],
                ),
              ],
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Column(
                children: [
                  FloatingActionButton(
                    mini: true,
                    onPressed: () {
                      mapController.move(mapController.camera.center, mapController.camera.zoom + 0.5); // ✅ Zoom In
                    },
                    child: Icon(Icons.add),
                  ),
                  SizedBox(height: 10),
                  FloatingActionButton(
                    mini: true,
                    onPressed: () {
                      mapController.move(mapController.camera.center, mapController.camera.zoom - 0.5); // ✅ Zoom Out
                    },
                    child: Icon(Icons.remove),
                  ),
                ],
              ),
            ),
          ])
        : const SizedBox(height: 0);
  }

  Marker friendMarker(Map<String, dynamic> friendData) {
    return Marker(
        point: LatLng(friendData["lat"], friendData["lon"]),
        width: 50,
        height: 50,
        child: friendData["profilePhotoUrl"] != null
            ? CircleAvatar(
                radius: 20,
                backgroundColor: Colors.deepPurple,
                child: Padding(
                  padding: EdgeInsets.all(2.5), // Border radius
                  child: ClipOval(
                      child: Image.network(
                    friendData["profilePhotoUrl"],
                    width: 43,
                    height: 43,
                    fit: BoxFit.cover,
                  )),
                ),
              )
            : CircleAvatar(
                radius: 20,
                backgroundColor: Colors.deepPurple,
                child: Padding(
                  padding: EdgeInsets.all(0), // Border radius
                  child: Icon(
                    Icons.account_circle,
                    size: 50,
                    color: Colors.grey[300],
                  ),
                ),
              ));
  }
}
