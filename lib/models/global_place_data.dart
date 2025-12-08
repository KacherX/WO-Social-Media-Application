import 'package:geolocator/geolocator.dart';
import 'package:wo/home_screen.dart';
import 'package:wo/models/place_model.dart';

class GlobalPlaceData {
  List<Place> finalPlaces = [];
  bool searchDone = false;
  PlaceType? selectedPlaceType = PlaceType.restaurant;
  SortType? selectedSortType = SortType.distance;

  Position? userPosition;
  Place? selctedPlace;
  Place? selectedPostPlace;

  GlobalPlaceData();
}
