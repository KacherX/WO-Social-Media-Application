import 'package:cloud_firestore/cloud_firestore.dart';

List<String> indexMonths = [
  "January",
  "February",
  "March",
  "April",
  "May",
  "June",
  "July",
  "August",
  "September",
  "October",
  "November",
  "December",
];

class GlobalFunctions {
  String formatTimeDifference(Timestamp timestamp) {
    // Convert the Timestamp to a DateTime
    final DateTime date = timestamp.toDate().toUtc();

    final Duration difference = DateTime.now().toUtc().difference(date);

    if (difference.inSeconds < 60) {
      return "${difference.inSeconds}s ago";
    } else if (difference.inMinutes < 60) {
      return "${difference.inMinutes}m ago";
    } else if (difference.inHours < 24) {
      return "${difference.inHours}h ago";
    } else if (difference.inDays < 30) {
      return "${difference.inDays}d ago";
    } else {
      return "${indexMonths[date.month - 1]} ${date.day}, ${date.year}"; // Fallback to date
    }
  }

  String formatDistance(double meters) {
    if (meters < 1000) {
      return "${meters.toStringAsFixed(0)} m"; // Example: "850 m"
    } else {
      return "${(meters / 1000).toStringAsFixed(1)} km"; // Example: "3.4 km"
    }
  }
}
