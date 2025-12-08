import 'package:flutter/material.dart';

class Place {
  final String name;
  final String type;
  final String id;

  late String place_image;
  String? place_url = null;

  int totalStar = 0;
  int totalVote = 0;
  bool isFavourite = false;
  bool favouriteOperationDone = true;

  double lon = 0;
  double lat = 0;
  double distance = 0;

  double GetRatingAverage() {
    if (totalStar == 0 || totalVote == 0) {
      return 0;
    } else {
      return totalStar / totalVote;
    }
  }

  Place(this.name, this.type, this.id, String? cuisine) {
    if (type == "restaurant") {
      place_image = 'assets/images/restaurant.png';
    } else if (type == "fast_food") {
      place_image = 'assets/images/fast_food.png';
    } else if (type == "bar") {
      place_image = 'assets/images/bar.png';
    } else if (type == "pub") {
      place_image = 'assets/images/pub.png';
    } else {
      place_image = 'assets/images/coffee_shop.png';
    }

    if (cuisine != null) {
      if (cuisine.contains("pizza")) {
        place_image = 'assets/images/pizza_restaurant.png';
      } else if (cuisine.contains("burger")) {
        place_image = 'assets/images/burger_restaurant.png';
      } else if (cuisine.contains("chicken")) {
        place_image = 'assets/images/chicken_restaurant.png';
      } else if (cuisine.contains("fish") || cuisine.contains("seafood")) {
        place_image = 'assets/images/seafood_restaurant.png';
      } else if (cuisine.contains("dessert") || cuisine.contains("waffle")) {
        place_image = 'assets/images/dessert_shop.png';
      } else if (cuisine.contains("steak_house") || cuisine.contains("grill")) {
        place_image = 'assets/images/steak_house.png';
      } else if (cuisine.contains("turkish")) {
        place_image = 'assets/images/turkish_restaurant.png';
      } else if (cuisine.contains("chinese")) {
        place_image = 'assets/images/chinese_restaurant.png';
      } else if (cuisine.contains("indian")) {
        place_image = 'assets/images/indian_restaurant.png';
      } else if (cuisine.contains("regional")) {
        place_image = 'assets/images/regional_restaurant.png';
      }
    }
  }
}
