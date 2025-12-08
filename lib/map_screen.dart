import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:wo/models/global_place_data.dart';
import 'package:wo/models/global_user_data.dart';
import 'package:wo/models/place_model.dart';
import 'package:wo/services/place_fetcher.dart';

class MapScreen extends StatefulWidget {
  final GlobalUserData globalUserData;
  final GlobalPlaceData globalPlaceData;
  const MapScreen({Key? key, required this.globalUserData, required this.globalPlaceData}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GlobalUserData globalUserData;
  late GlobalPlaceData globalPlaceData;

  MapController mapController = MapController();

  late Place selectedPlace;
  late List<LatLng> routePoints;

  bool routePointsSet = false;

  void SetRoute() async {
    routePoints = await PlaceFetcher()
        .fetchRoute(globalPlaceData.userPosition!.latitude, globalPlaceData.userPosition!.longitude, selectedPlace.lat, selectedPlace.lon);
    routePointsSet = true;

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
    selectedPlace = globalPlaceData.selctedPlace!;

    SetRoute();
  }

  @override
  Widget build(BuildContext context) {
    return routePointsSet
        ? Stack(children: [
            FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: LatLng(globalPlaceData.userPosition!.latitude, globalPlaceData.userPosition!.longitude),
                initialZoom: 16.5,
                minZoom: 2.0, // Minimum zoom seviyesi
                maxZoom: 20.0, // Maksimum zoom seviyesi
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                ),
                if (routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: routePoints,
                        color: Colors.blue,
                        strokeWidth: 5.0,
                      ),
                    ],
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
                    Marker(
                      point: LatLng(selectedPlace.lat, selectedPlace.lon),
                      width: 160,
                      height: 60,
                      child: Column(
                        children: [
                          StrokedText(selectedPlace.name),
                          Icon(Icons.location_on, color: Colors.red, size: 30), // ✅ Marker Icon
                        ],
                      ),
                    ),
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

  Widget StrokedText(String txt) {
    return Stack(
      children: [
        // Stroke (Outline)
        Text(
          txt,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            overflow: TextOverflow.ellipsis,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..color = Colors.black, // Outline Color
          ),
        ),
        // Fill Text
        Text(
          txt,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            overflow: TextOverflow.ellipsis,
            color: Colors.white, // Fill Color
          ),
        ),
      ],
    );
  }
}
