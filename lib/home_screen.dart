import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:wo/models/global_place_data.dart';
import 'package:wo/models/global_user_data.dart';
import 'package:wo/models/place_model.dart';
import 'package:wo/services/firestore.dart';
import 'package:wo/services/global_functions.dart';

typedef PlaceTypeEntry = DropdownMenuEntry<PlaceType>;
typedef SortTypeEntry = DropdownMenuEntry<SortType>;

enum PlaceType {
  restaurant('Restaurant', 'restaurant'),
  cafe('Cafe', 'cafe'),
  bar('Bar & Pub', 'bar');

  const PlaceType(this.label, this.dataLabel);
  final String label;
  final String dataLabel;

  static final List<PlaceTypeEntry> entries = UnmodifiableListView<PlaceTypeEntry>(
    values.map<PlaceTypeEntry>(
      (PlaceType placeType) =>
          PlaceTypeEntry(value: placeType, label: placeType.label, style: MenuItemButton.styleFrom(backgroundColor: Colors.grey[200])),
    ),
  );
}

enum SortType {
  popularity('Popularity'),
  rating('Rating'),
  distance('Distance');

  const SortType(this.label);
  final String label;

  static final List<SortTypeEntry> entries = UnmodifiableListView<SortTypeEntry>(
    values.map<SortTypeEntry>(
      (SortType sortType) => SortTypeEntry(
        value: sortType,
        label: sortType.label,
        style: MenuItemButton.styleFrom(backgroundColor: Colors.grey[200]),
      ),
    ),
  );
}

class HomeScreen extends StatefulWidget {
  final GlobalUserData globalUserData;
  final GlobalPlaceData globalPlaceData;
  final Function onMapViewFunction;
  const HomeScreen({Key? key, required this.globalUserData, required this.globalPlaceData, required this.onMapViewFunction}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late GlobalUserData globalUserData;
  late GlobalPlaceData globalPlaceData;
  late Function onMapViewFunction;

  late AnimationController _loadingAnimationController;
  late AnimationController _likeAnimationController;
  late Animation<double> _likeScaleAnimation;
  late Animation<double> _likeOpacityAnimation;
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> placeCommentsData = [];
  Place? selectedFavouritePlace;
  bool commentsLoading = false;
  bool initialFavouritesSet = false;

  void sortWithCloseness(List<Place> placeList) {
    placeList.sort((a, b) {
      return a.distance.compareTo(b.distance); // Sort ascending (closest first)
    });
  }

  void sortWithPopularity(List<Place> placeList) {
    placeList.sort((a, b) {
      return b.totalVote.compareTo(a.totalVote); // Sort ascending (closest first)
    });
  }

  void sortWithRating(List<Place> placeList) {
    placeList.sort((a, b) {
      return b.GetRatingAverage().compareTo(a.GetRatingAverage()); // Sort ascending (closest first)
    });
  }

  void togglePlaceFavourite(Place pl) async {
    if (pl.favouriteOperationDone) {
      pl.favouriteOperationDone = false;
      pl.isFavourite = !pl.isFavourite;
      if (mounted) {
        setState(() {});
      }
      await Firestore().togglePlaceFavourite(globalUserData.uid, "${pl.id}");
      pl.favouriteOperationDone = true;
      if (mounted) {
        setState(() {});
      }
    }
  }

  void setInitialFavourites() async {
    List<String> favouritePlaceIDs = await Firestore().getUserFavouritePlaceIDs(globalUserData.uid);
    Set<String> favouriteIDsSet = favouritePlaceIDs.toSet();
    List<Place> updatedPlaces = globalPlaceData.finalPlaces.map((place) {
      place.isFavourite = favouriteIDsSet.contains(place.id.toString());
      return place;
    }).toList();
    globalPlaceData.finalPlaces = updatedPlaces;

    initialFavouritesSet = true;

    if (mounted) {
      setState(() {});
    }
  }

  void loadComments(Place pl) async {
    if (mounted) {
      setState(() {
        commentsLoading = true;
      });
    }

    placeCommentsData = await Firestore().getPlaceCommentsWithUserDetails(placeId: "${pl.id}", lastCommentDate: Timestamp.fromDate(DateTime(2100)));

    if (mounted) {
      setState(() {
        commentsLoading = false;
      });
    }
  }

  void onPlaceClick(Place pl) {
    if (globalPlaceData.selctedPlace == pl) {
      globalPlaceData.selctedPlace = null;
    } else {
      globalPlaceData.selctedPlace = pl;
      loadComments(pl);
    }

    if (mounted) {
      setState(() {});
    }
  }

  void onOpenMapClick(Place pl) {
    globalPlaceData.selctedPlace = pl;
    onMapViewFunction("Map");

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _loadingAnimationController.dispose();
    _likeAnimationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    globalUserData = widget.globalUserData;
    globalPlaceData = widget.globalPlaceData;
    onMapViewFunction = widget.onMapViewFunction;

    setInitialFavourites();

    _loadingAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _likeAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _likeScaleAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _likeAnimationController, curve: Curves.easeOut),
    );
    _likeOpacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _likeAnimationController, curve: Curves.easeOut),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 7),
            child: Material(
              color: Colors.transparent,
              child: TextField(
                controller: _searchController,
                maxLines: 1, // Allow multiline input
                onChanged: (String txt) {
                  globalPlaceData.selctedPlace = null;
                  if (mounted) {
                    setState(() {});
                  }
                },
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: "Where you want to go?",
                  hintStyle: const TextStyle(color: Colors.grey),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 7),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Card(
                    color: Colors.white,
                    child: DropdownMenu<PlaceType>(
                      initialSelection: globalPlaceData.selectedPlaceType,
                      requestFocusOnTap: false,
                      label: const Text('Type'),
                      leadingIcon: Icon(Icons.business),
                      onSelected: (PlaceType? placeType) {
                        setState(() {
                          globalPlaceData.selctedPlace = null;
                          globalPlaceData.selectedPlaceType = placeType;
                        });
                      },
                      dropdownMenuEntries: PlaceType.entries,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Align(
                    alignment: Alignment(1, 0),
                    child: Card(
                      color: Colors.white,
                      child: DropdownMenu<SortType>(
                        initialSelection: globalPlaceData.selectedSortType,
                        requestFocusOnTap: false,
                        label: const Text('Sort by'),
                        leadingIcon: Icon(Icons.sort),
                        onSelected: (SortType? sortType) {
                          setState(() {
                            globalPlaceData.selctedPlace = null;
                            globalPlaceData.selectedSortType = sortType;
                            if (sortType == SortType.distance) {
                              sortWithCloseness(globalPlaceData.finalPlaces);
                            } else if (sortType == SortType.popularity) {
                              sortWithPopularity(globalPlaceData.finalPlaces);
                            } else if (sortType == SortType.rating) {
                              sortWithRating(globalPlaceData.finalPlaces);
                            }
                          });
                        },
                        dropdownMenuEntries: SortType.entries,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          globalPlaceData.searchDone && initialFavouritesSet
              ? globalPlaceData.finalPlaces.isNotEmpty
                  ? ListView.builder(
                      primary: false,
                      shrinkWrap: true,
                      itemCount: globalPlaceData.finalPlaces.length, // Total number of posts
                      itemBuilder: (context, index) {
                        final placeData = globalPlaceData.finalPlaces[index];
                        if (placeData.type == globalPlaceData.selectedPlaceType!.dataLabel) {
                          String trimTxt = _searchController.text.trim().toLowerCase();
                          if (trimTxt.isNotEmpty && placeData.name.toLowerCase().contains(trimTxt) || trimTxt.isEmpty) {
                            return PlaceCard(placeData, globalPlaceData.selctedPlace == placeData);
                          } else {
                            return const SizedBox(height: 0);
                          }
                        } else {
                          return const SizedBox(height: 0);
                        }
                      },
                    )
                  : NoPlacesText()
              : PlacesLoadingAnimation()
        ],
      ),
    );
  }

  Widget PlaceCard(Place pl, bool isSelected) {
    return SizedBox(
      height: isSelected ? 450 : 150,
      child: Stack(
        children: [
          isSelected
              ? Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Align(
                    alignment: Alignment(0, 1),
                    child: SizedBox(
                      height: 330,
                      child: Card(
                        color: Colors.grey[100],
                        elevation: 3,
                        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 5),
                          child: Align(
                              alignment: Alignment(0, 1),
                              child: commentsLoading == false
                                  ? placeCommentsData.isNotEmpty
                                      ? ListView.builder(
                                          primary: false,
                                          shrinkWrap: true,
                                          itemCount: placeCommentsData.length, // Total number of posts
                                          itemBuilder: (context, index) {
                                            Map<String, dynamic> placeCommentData = placeCommentsData[index];
                                            return placeCommentWidget(placeCommentData);
                                          },
                                        )
                                      : NoCommentsTabBar()
                                  : CommentsLoadingAnimation()),
                        ),
                      ),
                    ),
                  ),
                )
              : SizedBox(height: 0),
          SizedBox(
            height: 150,
            child: GestureDetector(
              onTap: () {
                onPlaceClick(pl);
              },
              child: Card(
                color: Colors.grey[100],
                elevation: 3,
                margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12), // Image border
                        child: SizedBox.fromSize(
                          size: Size.fromRadius(55), // Image radius
                          child:
                              pl.place_url != null ? Image.network(pl.place_url!, fit: BoxFit.cover) : Image.asset(pl.place_image, fit: BoxFit.cover),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: EdgeInsets.only(left: 10, top: 6, bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pl.name,
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                            pl.totalVote > 0
                                ? Row(
                                    children: [
                                      const Icon(Icons.star),
                                      Text(
                                        pl.GetRatingAverage().toStringAsFixed(1),
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        " (" + pl.totalVote.toString() + "+)",
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  )
                                : const SizedBox(height: 0),
                            //const Spacer(),
                            //SizedBox(
                            //  width: 2000,
                            //  child: Stack(children: [
                            //    Positioned(
                            //      child: profilePhotoCircle(true),
                            //      left: 50,
                            //    ),
                            //    Positioned(
                            //      child: profilePhotoCircle(true),
                            //      left: 37.5,
                            //    ),
                            //    Positioned(
                            //      child: profilePhotoCircle(true),
                            //      left: 25,
                            //    ),
                            //    Positioned(
                            //      child: profilePhotoCircle(true),
                            //      left: 12.5,
                            //    ),
                            //    Positioned(
                            //      child: profilePhotoCircle(true),
                            //    ),
                            //  ]),
                            //),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 20),
                    Align(
                      alignment: Alignment(1, 0),
                      child: Padding(
                        padding: EdgeInsets.only(top: 10, right: 10, bottom: 8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Stack(
                                  children: [
                                    selectedFavouritePlace == pl
                                        ? AnimatedBuilder(
                                            animation: _likeAnimationController,
                                            builder: (context, child) {
                                              return Transform.scale(
                                                scale: _likeScaleAnimation.value,
                                                child: Opacity(
                                                  opacity: _likeOpacityAnimation.value,
                                                  child: pl.isFavourite
                                                      ? const Icon(Icons.favorite, color: Colors.deepPurple)
                                                      : const Icon(Icons.favorite_border),
                                                ),
                                              );
                                            },
                                          )
                                        : SizedBox(),
                                    GestureDetector(
                                      onTap: () {
                                        selectedFavouritePlace = pl;
                                        togglePlaceFavourite(pl);
                                        _likeAnimationController.forward(from: 0);
                                        setState(() {});
                                      },
                                      child:
                                          pl.isFavourite ? const Icon(Icons.favorite, color: Colors.deepPurple) : const Icon(Icons.favorite_border),
                                    ),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: () {
                                    onOpenMapClick(pl);
                                  },
                                  child: const Icon(Icons.location_on_outlined),
                                ),
                              ],
                            ),
                            Text(GlobalFunctions().formatDistance(pl.distance), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget placeCommentWidget(Map<String, dynamic> placeCommentData) {
    return Container(
      child: Column(
        children: [
          const Divider(
            color: Colors.black26,
            thickness: 0.3,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  print("Tiklandim");
                },
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 20,
                  child: ClipOval(
                      child: (placeCommentData["profilePhotoUrl"] != null)
                          ? Image.network(
                              placeCommentData["profilePhotoUrl"],
                              width: 150,
                              height: 150,
                              fit: BoxFit.cover,
                            )
                          : Icon(
                              Icons.account_circle,
                              size: 40,
                              color: Colors.grey[300],
                            )),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "@${placeCommentData["username"]}",
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              decoration: TextDecoration.none,
                              fontWeight: FontWeight.w900,
                              fontFamily: "Arial",
                              letterSpacing: 0,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        Icon(
                          placeCommentData["star"] > 0 ? Icons.star : Icons.star_outline,
                          size: 16,
                        ),
                        Icon(
                          placeCommentData["star"] > 1 ? Icons.star : Icons.star_outline,
                          size: 16,
                        ),
                        Icon(
                          placeCommentData["star"] > 2 ? Icons.star : Icons.star_outline,
                          size: 16,
                        ),
                        Icon(
                          placeCommentData["star"] > 3 ? Icons.star : Icons.star_outline,
                          size: 16,
                        ),
                        Icon(
                          placeCommentData["star"] > 4 ? Icons.star : Icons.star_outline,
                          size: 16,
                        ),
                        Align(
                          alignment: Alignment(1, 0),
                          child: Padding(
                            padding: EdgeInsets.only(right: 10),
                            child: Text(
                              " ${GlobalFunctions().formatTimeDifference(placeCommentData["commentDate"])}",
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 14,
                                decoration: TextDecoration.none,
                                fontWeight: FontWeight.w500,
                                fontFamily: "Arial",
                                letterSpacing: 0,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      placeCommentData["comment"],
                      maxLines: 4,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        decoration: TextDecoration.none,
                        fontWeight: FontWeight.w500,
                        fontFamily: "Arial",
                        letterSpacing: 0,
                        overflow: TextOverflow.clip,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget profilePhotoCircle(bool asd) {
    return asd
        ? CircleAvatar(
            radius: 17.5,
            backgroundColor: Colors.transparent,
            child: Padding(
              padding: EdgeInsets.all(2), // Border radius
              child: ClipOval(
                  child: Image.network(
                globalUserData.userData["profilePhotoUrl"],
                width: 150,
                height: 150,
                fit: BoxFit.cover,
              )),
            ),
          )
        : CircleAvatar(
            radius: 17.5,
            backgroundColor: Colors.transparent,
            child: Padding(
              padding: EdgeInsets.all(0), // Border radius
              child: Icon(
                Icons.account_circle,
                size: 35,
                color: Colors.grey[300],
              ),
            ),
          );
  }

  Container miniLoadingAnimation() {
    return Container(
      child: RotationTransition(
        turns: _loadingAnimationController,
        child: const Icon(
          Icons.refresh,
          size: 25,
        ),
      ),
    );
  }

  Center PlacesLoadingAnimation() {
    return Center(
        child: Column(
      children: [
        SizedBox(
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
          "Places loading",
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

  Center NoPlacesText() {
    return const Center(
      child: Column(
        children: [
          SizedBox(
            height: 75,
          ),
          Icon(
            Icons.map_outlined,
            size: 60,
          ),
          Text(
            "No places found!",
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

  Center CommentsLoadingAnimation() {
    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        RotationTransition(
          turns: _loadingAnimationController,
          child: const Icon(
            Icons.refresh,
            size: 60,
          ),
        ),
        Text(
          "Comments loading",
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

  Center NoCommentsTabBar() {
    return const Center(
      child: Column(
        children: [
          SizedBox(
            height: 110,
          ),
          Icon(
            Icons.comment_outlined,
            size: 60,
          ),
          Text(
            "No comments",
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
