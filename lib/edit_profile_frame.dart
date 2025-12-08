import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wo/models/global_user_data.dart';
import 'package:wo/services/firestore.dart';
import 'package:wo/services/imagePicker_service.dart';
import 'package:wo/services/storage.dart';

class EditProfileFrame extends StatefulWidget {
  final GlobalUserData globalUserData;
  const EditProfileFrame({Key? key, required this.globalUserData})
      : super(key: key);

  @override
  State<EditProfileFrame> createState() => _EditProfileFrameState();
}

class _EditProfileFrameState extends State<EditProfileFrame> {
  late GlobalUserData globalUserData;
  final _nameController = TextEditingController();
  final _biographyController = TextEditingController();
  String? _profilePhotoUrl = null;
  File? _profilePhotoFile = null;
  bool _profilePhotoClear = false;

  String? _profileCoverPhotoUrl = null;
  File? _profileCoverPhotoFile = null;
  bool _profileCoverPhotoClear = false;

  bool _doneButtonClicked = false;

  Widget _buttonErrorMessage = const SizedBox(height: 0);

  bool checkInputs() {
    bool returnBool = true;

    if (_nameController.text.length > 30) {
      returnBool = false;
      setState(() {
        _buttonErrorMessage =
            ErrorText("Name cant contain more than 30 characters.", Colors.red);
      });
    } else if (_biographyController.text.length > 150) {
      returnBool = false;
      setState(() {
        _buttonErrorMessage =
            ErrorText("About me section is too long.", Colors.red);
      });
    } else if (globalUserData.userData.containsKey("previousEditDate") &&
        globalUserData.userData["previousEditDate"].seconds + 3600 >=
            Timestamp.now().seconds) {
      returnBool = false;
      setState(() {
        _buttonErrorMessage = ErrorText(
            "You can only change your profile once an hour.", Colors.red);
      });
    } else if (_doneButtonClicked == true) {
      returnBool = false;
    }

    return returnBool;
  }

  Future<void> changeProfilePhoto(String Mode) async {
    File? file;
    if (Mode == "Gallery") {
      file = await imagePicker_service().takePhotoFromGallery();
    } else if (Mode == "Camera") {
      file = await imagePicker_service().takePhoto();
    } else if (Mode == "Delete" &&
        (_profilePhotoFile != null || _profilePhotoUrl != null)) {
      if (_profilePhotoUrl != null) {
        _profilePhotoClear = true;
      }
      if (mounted) {
        setState(() {
          _profilePhotoUrl = null;
          _profilePhotoFile = null;
        });
      }
    }
    if (mounted) {
      setState(() {
        _profilePhotoFile = file;
      });
    }
  }

  Future<void> changeProfileCoverPhoto(String Mode) async {
    File? file;
    if (Mode == "Gallery") {
      file = await imagePicker_service().takePhotoFromGallery();
    } else if (Mode == "Camera") {
      file = await imagePicker_service().takePhoto();
    } else if (Mode == "Delete" &&
        (_profileCoverPhotoFile != null || _profileCoverPhotoUrl != null)) {
      if (_profileCoverPhotoUrl != null) {
        _profileCoverPhotoClear = true;
      }
      if (mounted) {
        setState(() {
          _profileCoverPhotoUrl = null;
          _profileCoverPhotoFile = null;
        });
      }
    }
    if (mounted) {
      setState(() {
        _profileCoverPhotoFile = file;
      });
    }
  }

  Future<void> doneButtonClicked() async {
    try {
      if (checkInputs()) {
        _doneButtonClicked = true;
        setState(() {
          _buttonErrorMessage = ErrorText(
              "Your profile is updating please wait a second.", Colors.green);
        });
        String uid = globalUserData.uid;
        if (_profilePhotoFile != null && _profilePhotoFile!.existsSync()) {
          _profilePhotoUrl = await Storage()
              .uploadProfilePhoto(userId: uid, file: _profilePhotoFile!);
        } else if (_profilePhotoFile == null && _profilePhotoClear == true) {
          await Storage().deleteProfilePhoto(userId: uid);
        }
        if (_profileCoverPhotoFile != null &&
            _profileCoverPhotoFile!.existsSync()) {
          _profileCoverPhotoUrl = await Storage().uploadProfileCoverPhoto(
              userId: uid, file: _profileCoverPhotoFile!);
        } else if (_profileCoverPhotoFile == null &&
            _profileCoverPhotoClear == true) {
          await Storage().deleteProfileCoverPhoto(userId: uid);
        }
        Firestore().editProfile(
            uid: uid,
            name: _nameController.text.trim(),
            bio: _biographyController.text.trim(),
            profilePhotoUrl: _profilePhotoUrl,
            profileCoverPhotoUrl: _profileCoverPhotoUrl);
        Navigator.pop(context);
        _doneButtonClicked = false;
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _nameController.dispose();
    _biographyController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    globalUserData = widget.globalUserData;
    _nameController.text = globalUserData.userData["name"];
    _biographyController.text = globalUserData.userData["bio"];
    _profilePhotoUrl = globalUserData.userData["profilePhotoUrl"];
    _profileCoverPhotoUrl = globalUserData.userData["profileCoverPhotoUrl"];
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
                    if (_doneButtonClicked == false) {
                      Navigator.pop(context);
                    }
                  },
                  child: Text("Cancel"),
                ),
              ),
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 15),
                  child: Text(
                    "Edit profile",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontFamily: "Arial",
                        fontWeight: FontWeight.w600,
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
                      doneButtonClicked();
                    },
                    child: Text("Done"),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: () {
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
                                      _buildMenuItem(Icons.collections,
                                          'Gallery', "CoverPhoto"),
                                      const Divider(
                                        color: Colors.black26,
                                        thickness: 0.75,
                                        height: 0,
                                      ),
                                      _buildMenuItem(Icons.camera_alt, 'Camera',
                                          "CoverPhoto"),
                                      const Divider(
                                        color: Colors.black26,
                                        thickness: 0.75,
                                        height: 0,
                                      ),
                                      _buildMenuItem(
                                          Icons.delete, 'Delete', "CoverPhoto"),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        child: Card(
                          elevation: 3,
                          child: Container(
                            height: 100,
                            width: 5000,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: Colors.grey[600]!, // Border color
                                width: 2.0, // Border width
                              ),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Stack(
                              children: [
                                _profileCoverPhotoFile != null
                                    ? Image.file(_profileCoverPhotoFile!,
                                        width: 5000,
                                        height: 100,
                                        fit: BoxFit.cover)
                                    : _profileCoverPhotoUrl != null
                                        ? Image.network(
                                            _profileCoverPhotoUrl!,
                                            width: 5000,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          )
                                        : SizedBox(
                                            height: 0,
                                          ),
                                Align(
                                  alignment: Alignment(0, 0),
                                  child: Icon(Icons.photo_camera_outlined,
                                      color: (_profileCoverPhotoUrl == null &&
                                              _profileCoverPhotoFile == null)
                                          ? Colors.black87
                                          : Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 65, left: 25),
                        child: GestureDetector(
                          onTap: () {
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
                                        _buildMenuItem(Icons.collections,
                                            'Gallery', "ProfilePhoto"),
                                        const Divider(
                                          color: Colors.black26,
                                          thickness: 0.75,
                                          height: 0,
                                        ),
                                        _buildMenuItem(Icons.camera_alt,
                                            'Camera', "ProfilePhoto"),
                                        const Divider(
                                          color: Colors.black26,
                                          thickness: 0.75,
                                          height: 0,
                                        ),
                                        _buildMenuItem(Icons.delete, 'Delete',
                                            "ProfilePhoto"),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          child: Card(
                            shape:
                                CircleBorder(), // Ensures the card maintains a circular shape
                            elevation: 3, // Adds elevation for the card
                            child: CircleAvatar(
                              radius: 35,
                              backgroundColor: (_profilePhotoFile != null ||
                                      _profilePhotoUrl != null)
                                  ? Colors.grey[600]
                                  : Colors.white,
                              child: Padding(
                                padding: (_profilePhotoFile != null ||
                                        _profilePhotoUrl != null)
                                    ? EdgeInsets.all(2.5)
                                    : EdgeInsets.all(0), // Border radius
                                child: ClipOval(
                                    child: Stack(
                                  children: [
                                    _profilePhotoFile != null
                                        ? Image.file(_profilePhotoFile!,
                                            width: 150,
                                            height: 150,
                                            fit: BoxFit.cover)
                                        : _profilePhotoUrl != null
                                            ? Image.network(
                                                _profilePhotoUrl!,
                                                width: 150,
                                                height: 150,
                                                fit: BoxFit.cover,
                                              )
                                            : Icon(
                                                Icons.account_circle,
                                                size: 70,
                                                color: Colors.grey[300],
                                              ),
                                    Align(
                                      alignment: Alignment(0, 0),
                                      child: Icon(Icons.photo_camera_outlined,
                                          color: (_profilePhotoUrl == null &&
                                                  _profilePhotoFile == null)
                                              ? Colors.black87
                                              : Colors.white),
                                    ),
                                  ],
                                )),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Card(
                    margin: const EdgeInsets.only(left: 5, right: 5, top: 10),
                    elevation: 3,
                    child: TextField(
                      controller: _nameController,
                      maxLines: 1,
                      decoration: const InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: 'Name',
                      ),
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.only(left: 5, right: 5, top: 10),
                    elevation: 3,
                    child: TextField(
                      controller: _biographyController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: 'About me..',
                      ),
                    ),
                  ),
                  Center(
                    child: _buttonErrorMessage,
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context)
                          .viewInsets
                          .bottom, // Adjust for keyboard
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

  Widget _buildMenuItem(IconData icon, String text, String Mode) {
    return ListTile(
      leading:
          Icon(icon, color: text == "Delete" ? Colors.red : Colors.black87),
      title: Text(
        text,
        style: TextStyle(
          color: text == "Delete" ? Colors.red : Colors.black87,
          fontSize: 16,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        if (Mode == "ProfilePhoto") {
          changeProfilePhoto(text);
        } else {
          changeProfileCoverPhoto(text);
        }
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
