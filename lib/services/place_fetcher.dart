import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

String AndroidapiKey = "AIzaSyBNrdIVnOygkbbj28YQz4kGwqmLL1ro2z0"; // Only Android
String webApiKey = "AIzaSyDHCOLV99lIoW8NVTKLP1N4AFRTB5ApKHM";

class PlaceFetcher {
  double calculateDistance(double startLatitude, double startLongitude, double endLatitude, double endLongitude) {
    return Geolocator.distanceBetween(startLatitude, startLongitude, endLatitude, endLongitude);
  }

  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Konum servisleri devre dışı.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        return Future.error('Konum izinleri reddedildi.');
      }
    }

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  Future<List<dynamic>> fetchNearbyPlaces({
    required double lat,
    required double lon,
    required int closenessSize, // metre cinsinden radius
  }) async {
    String keywords = 'restaurant|fast food|pub|bar|cafe';

    final url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=$lat,$lon'
        '&rankby=distance'
        '&keyword=${Uri.encodeComponent(keywords)}'
        '&key=$AndroidapiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        return data['results'];
      } else {
        throw Exception('Google Places API error: ${data['status']}');
      }
    } else {
      throw Exception('Mekan bilgileri alınamadı.');
    }
  }

  Future<List<dynamic>> fetchNearbyPlacesOSM({required double lat, required double lon, required int closenessSize}) async {
    String overpassQuery = '''
  [out:json];
  node
    [amenity~"restaurant|fast_food|pub|bar|cafe"]
    [name]
    (around:$closenessSize,$lat,$lon);
  out 200;
  ''';

    String url = 'https://overpass-api.de/api/interpreter?data=${Uri.encodeComponent(overpassQuery)}';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      String fixedBody = utf8.decode(response.bodyBytes);
      final data = json.decode(fixedBody);
      return data['elements'];
    } else {
      throw Exception('Mekan bilgileri alınamadı.');
    }
  }

  Future<String?> fetchNearbyPhoto(double lat, double long, String placeId) async {
    final url = 'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=$placeId'
        '&fields=photos'
        '&key=$AndroidapiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        final photos = data['result']['photos'];

        if (photos != null && photos is List) {
          // Fotoğraf URL'lerini oluşturuyoruz
          List<String> photoUrls = photos.map<String>((photo) {
            final photoRef = photo['photo_reference'];
            return 'https://maps.googleapis.com/maps/api/place/photo'
                '?maxwidth=400&photoreference=$photoRef&key=$AndroidapiKey';
          }).toList();

          return photoUrls[0];
        }
      } else {
        throw Exception('Place Details API error: ${data['status']}');
      }
    } else {
      throw Exception('Failed to fetch place details');
    }

    return null;
  }

  Future<String> getAddressFromOSM(double lat, double lon) async {
    String url = "https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      return data['display_name']; // Address as a string
    }
    return "Address not found";
  }

  Future<List<LatLng>> fetchRoute(double startLat, double startLon, double endLat, double endLon) async {
    String url = "https://router.project-osrm.org/route/v1/driving/$startLon,$startLat;$endLon,$endLat?geometries=geojson";

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List coordinates = data['routes'][0]['geometry']['coordinates'];

      return coordinates.map((point) => LatLng(point[1], point[0])).toList();
    } else {
      throw Exception('Rota alınamadı');
    }
  }
}
