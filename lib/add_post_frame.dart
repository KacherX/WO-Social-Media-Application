import 'dart:collection';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wo/models/global_place_data.dart';
import 'package:wo/models/global_user_data.dart';
import 'package:wo/models/place_model.dart';
import 'package:wo/services/firestore.dart';
import 'package:wo/services/imagePicker_service.dart';
import 'package:wo/services/place_fetcher.dart';
import 'package:wo/services/storage.dart';

class AddPostFrame extends StatefulWidget {
  final GlobalUserData globalUserData;
  final GlobalPlaceData globalPlaceData;
  const AddPostFrame({Key? key, required this.globalUserData, required this.globalPlaceData}) : super(key: key);

  @override
  State<AddPostFrame> createState() => _AddPostFrameState();
}

class _AddPostFrameState extends State<AddPostFrame> {
  late GlobalUserData globalUserData;
  late GlobalPlaceData globalPlaceData;

  final _captionController = TextEditingController();
  final _placeCommentController = TextEditingController();

  File? _postPhotoFile = null;
  String? _postPhotoUrl = null;

  bool _shareButtonClicked = false;
  Widget _buttonErrorMessage = const SizedBox(height: 0);
  Widget _placeErrorMessage = const SizedBox(height: 0);

  int page = 0;
  int star = 0;

  bool checkInputs() {
    bool returnBool = true;

    if (_captionController.text.length > 300) {
      returnBool = false;
      setState(() {
        _buttonErrorMessage = ErrorText("Caption is too long.", Colors.red);
      });
    } else if (_postPhotoFile == null) {
      returnBool = false;
      setState(() {
        _buttonErrorMessage = ErrorText("You cant post empty image.", Colors.red);
      });
    } else if (_shareButtonClicked == true) {
      returnBool = false;
    }

    return returnBool;
  }

  bool checkPlaceInputs() {
    bool returnBool = true;

    if (_placeCommentController.text.length > 150) {
      returnBool = false;
      setState(() {
        _placeErrorMessage = ErrorText("Your comment is too long.", Colors.red);
      });
    } else if (globalPlaceData.selectedPostPlace == null) {
      returnBool = false;
      setState(() {
        _placeErrorMessage = ErrorText("You must select a place to share post.", Colors.red);
      });
    } else if (PlaceFetcher().calculateDistance(globalPlaceData.userPosition!.longitude, globalPlaceData.userPosition!.latitude,
            globalPlaceData.selectedPostPlace!.lon, globalPlaceData.selectedPostPlace!.lat) >
        100) {
      returnBool = false;
      setState(() {
        _placeErrorMessage = ErrorText("You must be in that place to share post.", Colors.red);
      });
    } else if (star == 0) {
      returnBool = false;
      setState(() {
        _placeErrorMessage = ErrorText("You must rate that place", Colors.red);
      });
    }

    return returnBool;
  }

  Future<void> changePostPhoto(String Mode) async {
    File? file;
    if (Mode == "Gallery") {
      file = await imagePicker_service().takePhotoFromGallery();
    } else if (Mode == "Camera") {
      file = await imagePicker_service().takePhoto();
    }
    if (mounted) {
      setState(() {
        _postPhotoFile = file;
      });
    }
  }

  Future<void> shareButtonClicked() async {
    try {
      if (checkInputs()) {
        _shareButtonClicked = true;
        setState(() {
          _buttonErrorMessage = ErrorText("Your post is uploading please wait a second.", Colors.green);
        });
        if (_postPhotoFile!.existsSync()) {
          String uid = globalUserData.uid;
          String randomPostId = Firestore().getRandomPostId(uid: uid);
          _postPhotoUrl = await Storage().uploadPost(userId: uid, postId: randomPostId, file: _postPhotoFile!);
          Firestore().addPost(
              uid: uid,
              postid: randomPostId,
              photoUrl: _postPhotoUrl!,
              caption: _captionController.text.trim(),
              selectedPlace: globalPlaceData.selectedPostPlace!,
              star: star,
              placeComment: _placeCommentController.text.trim());
          Navigator.pop(context);
        }
        _shareButtonClicked = false;
      }
    } catch (e) {
      print(e);
    }
  }

  void changeStar(int num) {
    star = num;
    if (mounted) {
      setState(() {});
    }
  }

  void goPreviousPage() {
    page = 0;
    if (mounted) {
      setState(() {});
    }
  }

  void goNextPage() {
    if (checkPlaceInputs()) {
      page = 1;
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _captionController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    globalUserData = widget.globalUserData;
    globalPlaceData = widget.globalPlaceData;
    globalPlaceData.selectedPostPlace = null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      height: MediaQuery.of(context).size.height * 0.95,
      child: Column(
        children: [
          Stack(
            children: [
              Padding(
                padding: EdgeInsets.only(left: 5, top: 2.5),
                child: TextButton(
                  onPressed: () {
                    if (page == 0) {
                      if (_shareButtonClicked == false) {
                        Navigator.pop(context);
                      }
                    } else {
                      goPreviousPage();
                    }
                  },
                  child: Text(
                    page == 0 ? "Cancel" : "Back",
                    style: TextStyle(
                        color: Colors.deepPurple,
                        fontSize: 15,
                        fontFamily: "Arial",
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none,
                        letterSpacing: 0),
                  ),
                ),
              ),
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 15),
                  child: Text(
                    "New post",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontFamily: "Arial",
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none,
                        letterSpacing: 0),
                  ),
                ),
              ),
              Align(
                alignment: Alignment(1, 0),
                child: Padding(
                  padding: EdgeInsets.only(right: 5, top: 2.5),
                  child: TextButton(
                    onPressed: () {
                      if (page == 0) {
                        goNextPage();
                      } else {
                        shareButtonClicked();
                      }
                    },
                    child: Text(
                      page == 0 ? "Next" : "Share",
                      style: TextStyle(
                          color: Colors.deepPurple,
                          fontSize: 15,
                          fontFamily: "Arial",
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none,
                          letterSpacing: 0),
                    ),
                  ),
                ),
              ),
            ],
          ),
          page == 0
              ? Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Card(
                          color: Colors.white,
                          child: DropdownMenu<Place>(
                            initialSelection: globalPlaceData.selectedPostPlace,
                            requestFocusOnTap: true,
                            label: const Text('Choose Place'),
                            menuHeight: 250,
                            leadingIcon: Icon(Icons.business),
                            onSelected: (Place? pl) {
                              setState(() {
                                FocusScope.of(context).unfocus();
                                star = 0;
                                globalPlaceData.selectedPostPlace = pl;
                              });
                            },
                            dropdownMenuEntries: UnmodifiableListView<DropdownMenuEntry<Place>>(
                              globalPlaceData.finalPlaces.map<DropdownMenuEntry<Place>>(
                                (Place place) => DropdownMenuEntry<Place>(
                                    value: place, label: place.name, style: MenuItemButton.styleFrom(backgroundColor: Colors.grey[200])),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: globalPlaceData.selectedPostPlace != null ? 20 : 0),
                        globalPlaceData.selectedPostPlace != null
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      changeStar(1);
                                    },
                                    child: star > 0
                                        ? Icon(
                                            Icons.star,
                                            size: 32,
                                          )
                                        : Icon(
                                            Icons.star_outline,
                                            size: 32,
                                          ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      changeStar(2);
                                    },
                                    child: star > 1
                                        ? Icon(
                                            Icons.star,
                                            size: 32,
                                          )
                                        : Icon(
                                            Icons.star_outline,
                                            size: 32,
                                          ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      changeStar(3);
                                    },
                                    child: star > 2
                                        ? Icon(
                                            Icons.star,
                                            size: 32,
                                          )
                                        : Icon(
                                            Icons.star_outline,
                                            size: 32,
                                          ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      changeStar(4);
                                    },
                                    child: star > 3
                                        ? Icon(
                                            Icons.star,
                                            size: 32,
                                          )
                                        : Icon(
                                            Icons.star_outline,
                                            size: 32,
                                          ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      changeStar(5);
                                    },
                                    child: star > 4
                                        ? Icon(
                                            Icons.star,
                                            size: 32,
                                          )
                                        : Icon(
                                            Icons.star_outline,
                                            size: 32,
                                          ),
                                  ),
                                ],
                              )
                            : const SizedBox(height: 0),
                        SizedBox(height: star == 0 ? 0 : 20),
                        star == 0
                            ? const SizedBox(height: 0)
                            : Card(
                                color: Colors.white,
                                margin: const EdgeInsets.only(left: 20, right: 20, top: 5),
                                elevation: 3,
                                child: TextField(
                                  controller: _placeCommentController,
                                  maxLines: 3,
                                  decoration: const InputDecoration(
                                    border: const OutlineInputBorder(),
                                    labelText: 'What do you think about this place?',
                                  ),
                                ),
                              ),
                        const SizedBox(height: 10),
                        Center(
                          child: _placeErrorMessage,
                        ),
                      ],
                    ),
                  ),
                )
              : Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (_shareButtonClicked == false) {
                                  showModalBottomSheet(
                                    context: context,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(16),
                                      ),
                                    ),
                                    backgroundColor: Colors.transparent,
                                    builder: (BuildContext context) {
                                      return Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: ListView(
                                            shrinkWrap: true,
                                            children: [
                                              _buildMenuItem(Icons.collections, 'Gallery'),
                                              const Divider(
                                                color: Colors.black26,
                                                thickness: 0.75,
                                                height: 0,
                                              ),
                                              _buildMenuItem(Icons.camera_alt, 'Camera'),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }
                              },
                              child: Card(
                                elevation: 3,
                                child: Container(
                                  height: MediaQuery.of(context).size.width * 1.1,
                                  width: MediaQuery.of(context).size.width,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    border: Border.all(
                                      color: Colors.grey[600]!, // Border color
                                      width: 2.0, // Border width
                                    ),
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                  child: Stack(
                                    children: [
                                      _postPhotoFile != null
                                          ? Image.file(_postPhotoFile!,
                                              width: MediaQuery.of(context).size.width,
                                              height: MediaQuery.of(context).size.width * 1.1,
                                              fit: BoxFit.cover)
                                          : SizedBox(
                                              height: 0,
                                            ),
                                      Align(
                                        alignment: Alignment(0, 0),
                                        child: Icon(Icons.photo_camera_outlined, color: _postPhotoFile == null ? Colors.black87 : Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Card(
                          color: Colors.white,
                          margin: const EdgeInsets.only(left: 20, right: 20, top: 10),
                          elevation: 3,
                          child: TextField(
                            controller: _captionController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: 'Write a caption..',
                            ),
                          ),
                        ),
                        Center(
                          child: _buttonErrorMessage,
                        ),
                        SizedBox(height: 10),
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom, // Adjust for keyboard
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String text) {
    return ListTile(
      leading: Icon(icon, color: text == "Delete" ? Colors.red : Colors.black87),
      title: Text(
        text,
        style: TextStyle(
          color: text == "Delete" ? Colors.red : Colors.black87,
          fontSize: 16,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        changePostPhoto(text);
      },
    );
  }

  Padding ErrorText(String t, txtColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, right: 5, top: 5),
      child: Text(
        t,
        maxLines: 3,
        style: TextStyle(
          color: txtColor,
          fontSize: 12.5,
          decoration: TextDecoration.none,
          fontWeight: FontWeight.w600,
          fontFamily: "Arial",
          letterSpacing: 0,
        ),
      ),
    );
  }
}
