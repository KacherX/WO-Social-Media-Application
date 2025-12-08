import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wo/models/global_place_data.dart';
import 'package:wo/models/global_user_data.dart';
import 'package:wo/models/place_model.dart';
import 'package:wo/services/firestore.dart';
import 'package:wo/services/global_functions.dart';

class FavouritesScreen extends StatefulWidget {
  final GlobalUserData globalUserData;
  final GlobalPlaceData globalPlaceData;
  final Function onMapViewFunction;
  const FavouritesScreen({Key? key, required this.globalUserData, required this.globalPlaceData, required this.onMapViewFunction}) : super(key: key);

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> with TickerProviderStateMixin {
  late GlobalUserData globalUserData;
  late GlobalPlaceData globalPlaceData;
  late Function onMapViewFunction;

  late AnimationController _loadingAnimationController;
  late AnimationController _likeAnimationController;
  late Animation<double> _likeScaleAnimation;
  late Animation<double> _likeOpacityAnimation;

  List<Place> favouritePlaces = [];

  Place? selectedFavouritePlace;
  bool initialFavouritesSet = false;

  void onOpenMapClick(Place pl) {
    globalPlaceData.selctedPlace = pl;
    onMapViewFunction("Map");

    if (mounted) {
      setState(() {});
    }
  }

  void togglePlaceFavourite(Place pl) async {
    if (pl.favouriteOperationDone) {
      pl.favouriteOperationDone = false;
      pl.isFavourite = !pl.isFavourite;
      if (pl.isFavourite == false) {
        favouritePlaces.remove(pl);
      }
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

    favouritePlaces = globalPlaceData.finalPlaces.where((place) {
      return favouriteIDsSet.contains(place.id.toString());
    }).toList();

    initialFavouritesSet = true;

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
          initialFavouritesSet
              ? favouritePlaces.isNotEmpty
                  ? ListView.builder(
                      primary: false,
                      shrinkWrap: true,
                      itemCount: favouritePlaces.length, // Total number of posts
                      itemBuilder: (context, index) {
                        final placeData = favouritePlaces[index];
                        return PlaceCard(placeData);
                      },
                    )
                  : NoFavouritesText()
              : FavouritesLoadingAnimation()
        ],
      ),
    );
  }

  Widget PlaceCard(Place pl) {
    return SizedBox(
      height: 100,
      child: Stack(
        children: [
          SizedBox(
            height: 100,
            child: GestureDetector(
              onTap: () {
                //onPlaceClick(pl);
              },
              child: Card(
                color: Colors.grey[100],
                elevation: 3,
                margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 5),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12), // Image border
                        child: SizedBox.fromSize(
                          size: Size.fromRadius(35), // Image radius
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

  Center FavouritesLoadingAnimation() {
    return Center(
        child: Column(
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
          "Favourites loading",
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

  Center NoFavouritesText() {
    return const Center(
      child: Column(
        children: [
          SizedBox(
            height: 75,
          ),
          Icon(
            Icons.favorite_outline,
            size: 60,
          ),
          Text(
            "No favourites added!",
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
