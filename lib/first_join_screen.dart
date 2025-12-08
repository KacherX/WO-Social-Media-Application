import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wo/main_screen1.dart';
import 'package:wo/models/global_place_data.dart';
import 'package:wo/models/global_user_data.dart';
import 'package:wo/services/auth.dart';
import 'package:wo/services/firestore.dart';

class FirstJoinScreen extends StatefulWidget {
  final Function changeScreenFunction;
  final GlobalPlaceData globalPlaceData;
  const FirstJoinScreen({Key? key, required this.changeScreenFunction, required this.globalPlaceData}) : super(key: key);

  @override
  State<FirstJoinScreen> createState() => _FirstJoinScreenState();
}

class _FirstJoinScreenState extends State<FirstJoinScreen> {
  late Function _changeScreenFunction;
  late GlobalPlaceData globalPlaceData;

  final _nameController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  DateTime _birthdayDate = DateTime.now();

  bool _doneButtonClicked = false;

  Widget _buttonErrorMessage = const SizedBox(height: 0);

  bool checkInputs() {
    bool returnBool = true;

    if (_birthdayController.text == "") {
      returnBool = false;
      setState(() {
        _buttonErrorMessage = ErrorText("Birthday date must be enter.", Colors.red);
      });
    } else if (_nameController.text.length > 30) {
      returnBool = false;
      setState(() {
        _buttonErrorMessage = ErrorText("Name cant contain more than 30 characters.", Colors.red);
      });
    } else if (_doneButtonClicked == true) {
      returnBool = false;
    }

    return returnBool;
  }

  Future<void> doneButtonClicked() async {
    try {
      if (checkInputs()) {
        _doneButtonClicked = true;
        setState(() {
          _buttonErrorMessage = ErrorText("Your profile is creating please wait a second.", Colors.green);
        });
        String? uid = Auth().getUserUid();
        if (uid != null) {
          Firestore().updateUserAfterFirstJoin(
              uid: uid, name: _nameController.text.trim(), phoneNumber: _phoneNumberController.text.trim(), birthday: _birthdayDate);
          Map<String, dynamic> userData = await Firestore().getUserData(uid: uid);
          GlobalUserData globalUserData = GlobalUserData(uid, userData);
          _changeScreenFunction(
              MainScreen1(globalUserData: globalUserData, globalPlaceData: globalPlaceData, changeScreenFunction: _changeScreenFunction));
        }
        _doneButtonClicked = false;
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _changeScreenFunction = widget.changeScreenFunction;
    globalPlaceData = widget.globalPlaceData;
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _nameController.dispose();
    _phoneNumberController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("WO", style: TextStyle(fontFamily: "Pacifico", fontSize: 45, fontWeight: FontWeight.w900, color: Colors.deepPurple)),
              Card(
                color: Colors.white,
                margin: const EdgeInsets.only(left: 40, right: 40, top: 20),
                elevation: 10,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const DefaultTabController(
                      length: 1,
                      child: TabBar(
                          indicatorColor: Colors.deepPurple,
                          indicatorSize: TabBarIndicatorSize.tab,
                          labelColor: Colors.black, // Color of selected tab text
                          unselectedLabelColor: Colors.grey, // Color of unselected tab text
                          tabs: const <Widget>[
                            Tab(
                              text: "Create Profile",
                            ),
                          ]),
                    ),
                    Card(
                      color: Colors.white,
                      margin: const EdgeInsets.only(left: 20, right: 20, top: 20),
                      child: TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Name',
                        ),
                      ),
                    ),
                    Card(
                      color: Colors.white,
                      margin: const EdgeInsets.only(left: 20, right: 20, top: 15),
                      child: TextField(
                        controller: _phoneNumberController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Phone Number',
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                          ),
                          backgroundColor: Colors.white,
                          builder: (BuildContext context) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: Text("Done")),
                                Expanded(
                                  child: CupertinoDatePicker(
                                    onDateTimeChanged: (date) {
                                      _birthdayDate = date;
                                      _birthdayController.text = "${date.month}/${date.day}/${date.year}";
                                    },
                                    initialDateTime: _birthdayDate,
                                    mode: CupertinoDatePickerMode.date,
                                    minimumDate: DateTime(1900),
                                    maximumDate: DateTime.now(),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Card(
                        color: Colors.white,
                        margin: const EdgeInsets.only(left: 20, right: 20, top: 15),
                        child: TextField(
                          controller: _birthdayController,
                          enabled: false,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(
                              // Same border for enabled state
                              borderSide: BorderSide(color: Colors.black54, width: 1.0),
                            ),
                            disabledBorder: OutlineInputBorder(
                              // Override border for disabled state
                              borderSide: BorderSide(color: Colors.black54, width: 1.0),
                            ),
                            labelStyle: TextStyle(
                              color: Colors.black87, // Maintain same label color
                            ),
                            labelText: 'Birthday',
                          ),
                          style: const TextStyle(
                            color: Colors.black87, // Maintain same label color
                          ),
                        ),
                      ),
                    ),
                    _buttonErrorMessage,
                    const SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: () {
                        doneButtonClicked();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        side: const BorderSide(
                          color: Colors.black54, // Border color
                          width: 1, // Border width
                        ),
                      ),
                      child: const Text(
                        "Done",
                        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54),
                      ),
                    ),
                    const SizedBox(height: 15),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
          fontWeight: FontWeight.w600,
          fontFamily: "Arial",
          letterSpacing: 0,
        ),
      ),
    );
  }
}
