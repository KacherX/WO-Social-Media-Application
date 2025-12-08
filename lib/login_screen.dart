import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ntp/ntp.dart';
import 'package:wo/first_join_screen.dart';
import 'package:wo/loading_screen.dart';
import 'package:wo/main_screen1.dart';
import 'package:wo/models/global_place_data.dart';
import 'package:wo/models/global_user_data.dart';
import 'package:wo/models/place_model.dart';
import 'package:wo/services/firestore.dart';
import 'package:wo/services/place_fetcher.dart';
import 'services/auth.dart';

class ScreenController extends StatefulWidget {
  const ScreenController({super.key});

  @override
  State<ScreenController> createState() => ScreenControllerState();
}

class ScreenControllerState extends State<ScreenController> {
  late Widget _CurrentScreen;
  GlobalPlaceData globalPlaceData = GlobalPlaceData();

  void _ChangeScreen(Widget scrn) {
    setState(() {
      _CurrentScreen = scrn;
    });
  }

  void sortWithCloseness(List<Place> placeList) {
    placeList.sort((a, b) {
      return a.distance.compareTo(b.distance); // Sort ascending (closest first)
    });
  }

  void getNearbyPlaces() async {
    globalPlaceData.userPosition = await PlaceFetcher().getCurrentLocation();
    if (globalPlaceData.userPosition != null) {
      List<Future> futures = [];

      double currentLat = 38.452863;
      double currentLon = 27.215973;
      globalPlaceData.userPosition = new Position(
          longitude: currentLon,
          latitude: currentLat,
          timestamp: globalPlaceData.userPosition!.timestamp,
          accuracy: globalPlaceData.userPosition!.accuracy,
          altitude: globalPlaceData.userPosition!.altitude,
          altitudeAccuracy: globalPlaceData.userPosition!.altitudeAccuracy,
          heading: globalPlaceData.userPosition!.heading,
          headingAccuracy: globalPlaceData.userPosition!.headingAccuracy,
          speed: globalPlaceData.userPosition!.speed,
          speedAccuracy: globalPlaceData.userPosition!.speedAccuracy);

      List<Future<List<dynamic>>> firstFutures = [
        PlaceFetcher()
            .fetchNearbyPlaces(lat: globalPlaceData.userPosition!.latitude, lon: globalPlaceData.userPosition!.longitude, closenessSize: 2500),
        PlaceFetcher().fetchNearbyPlaces(
            lat: globalPlaceData.userPosition!.latitude + 0.005, lon: globalPlaceData.userPosition!.longitude + 0.005, closenessSize: 2500),
        PlaceFetcher().fetchNearbyPlaces(
            lat: globalPlaceData.userPosition!.latitude + 0.005, lon: globalPlaceData.userPosition!.longitude - 0.005, closenessSize: 2500),
        PlaceFetcher().fetchNearbyPlaces(
            lat: globalPlaceData.userPosition!.latitude - 0.005, lon: globalPlaceData.userPosition!.longitude + 0.005, closenessSize: 2500),
        PlaceFetcher().fetchNearbyPlaces(
            lat: globalPlaceData.userPosition!.latitude - 0.005, lon: globalPlaceData.userPosition!.longitude - 0.005, closenessSize: 2500)
      ];

      List<List<dynamic>> initialNerbyPlaces = await Future.wait(firstFutures);
      List<dynamic> allPlaces = initialNerbyPlaces.expand((e) => e).toList();
      // place_id'ye göre filtrele
      Set<String> seenPlaceIds = {};
      List<dynamic> uniquePlaces = [];

      for (var place in allPlaces) {
        String placeId = place["place_id"];
        if (!seenPlaceIds.contains(placeId)) {
          seenPlaceIds.add(placeId);
          uniquePlaces.add(place);
        }
      }
      for (var place in uniquePlaces) {
        String name = place['name'] ?? 'Bilinmiyor';
        String amenity = (place['types'] != null && place['types'].isNotEmpty) ? place['types'][0] : 'unknown';
        String placeId = place['place_id'];
        String? cuisine; // Google Places API'de yok, boş bırakıyoruz.

        Place pl = Place(name, amenity, placeId, cuisine);
        pl.lat = place['geometry']['location']['lat'];
        pl.lon = place['geometry']['location']['lng'];

        pl.distance = PlaceFetcher().calculateDistance(
          globalPlaceData.userPosition!.latitude,
          globalPlaceData.userPosition!.longitude,
          pl.lat,
          pl.lon,
        );

        globalPlaceData.finalPlaces.add(pl);

        futures.add(PlaceFetcher().fetchNearbyPhoto(pl.lat, pl.lon, placeId).then((onValue) {
          if (onValue != null) {
            pl.place_url = onValue;
          }
        }));
        futures.add(Firestore().checkAndCreatePlace(place: pl).then((onValue) {
          pl.totalStar = onValue["totalStars"];
          pl.totalVote = onValue["totalVotes"];
        }));
      }
      sortWithCloseness(globalPlaceData.finalPlaces);

      await Future.wait(futures);
    }

    globalPlaceData.searchDone = true;
    if (mounted) {
      setState(() {});
    }

    userAlreadyLogin();
  }

  Future<bool> checkDateTimeIsCorrect() async {
    DateTime serverTime = await NTP.now();
    DateTime deviceTime = DateTime.now();

    Duration difference = serverTime.difference(deviceTime).abs();
    if (difference.inMinutes <= 5) {
      return true;
    } else {
      return false;
    }
  }

  void userAlreadyLogin() async {
    User? user = Auth().currentUser;
    bool deviceTimeIsCorrect = await checkDateTimeIsCorrect();
    if (deviceTimeIsCorrect) {
      if (user != null && user.emailVerified) {
        Map<String, dynamic> userData = await Firestore().getUserData(uid: user.uid);
        GlobalUserData globalUserData = GlobalUserData(user.uid, userData);
        if (userData.containsKey("birthday")) {
          _ChangeScreen(MainScreen1(globalUserData: globalUserData, globalPlaceData: globalPlaceData, changeScreenFunction: _ChangeScreen));
        } else {
          _ChangeScreen(FirstJoinScreen(changeScreenFunction: _ChangeScreen, globalPlaceData: globalPlaceData));
        }
      } else {
        _ChangeScreen(LoginScreen(changeScreenFunction: _ChangeScreen, globalPlaceData: globalPlaceData));
      }
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _CurrentScreen = const LoadingScreen();
    getNearbyPlaces();
  }

  @override
  Widget build(BuildContext context) {
    return _CurrentScreen;
  }
}

class LoginScreen extends StatefulWidget {
  final Function changeScreenFunction;
  final GlobalPlaceData globalPlaceData;
  const LoginScreen({Key? key, required this.changeScreenFunction, required this.globalPlaceData}) : super(key: key);

  @override
  State<LoginScreen> createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  late Function _changeScreenFunction;
  late GlobalPlaceData globalPlaceData;
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  static const checkIcon = Icon(
    Icons.check,
    color: Colors.green,
  );
  static const closeIcon = Icon(
    Icons.close,
    color: Colors.red,
  );

  Icon? _emailIcon;
  Icon? _usernameIcon;
  Icon? _passwordIcon;

  Widget _emailErrorText = const SizedBox(height: 0);
  Widget _usernameErrorText = const SizedBox(height: 0);
  Widget _passwordErrorText = const SizedBox(height: 0);

  Widget _buttonErrorMessage = const SizedBox(height: 0);
  bool isLogin = true;
  bool isResetPassword = false;

  Map<String, dynamic> errorMessages = {
    "channel-error": "Invalid email address.",
    "invalid-email": "Invalid email address.",
    "invalid-credential": "Email or password is incorrect.",
    "email-already-in-use": "Email address is already used by another account.",
    "missing-email": "Email is missing.",
    "missing-password": "Password is missing.",
    "weak-password": "Password is weak.",
  };

  Future<void> createUser() async {
    setState(() {
      _buttonErrorMessage = const SizedBox(height: 0);
    });
    try {
      bool usernameIsUnq = await Firestore().usernameIsUnique(username: _usernameController.text);
      if (usernameIsUnq) {
        User? user = await Auth()
            .createUser(email: _emailController.text.trim(), password: _passwordController.text, username: _usernameController.text.trim());
        if (user != null) {
          Firestore().setUser(username: user.displayName!, uid: user.uid);
          setState(() {
            _buttonErrorMessage = ErrorText("Email verification code sent! Verify your email then log in.", Colors.green);
          });
        }
      } else {
        setState(() {
          _buttonErrorMessage = ErrorText("Username is used by someone else.", Colors.red);
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _buttonErrorMessage = ErrorText((errorMessages[e.code] ?? e.message) ?? "", Colors.red);
      });
    }
  }

  Future<void> login() async {
    setState(() {
      _buttonErrorMessage = const SizedBox(height: 0);
    });
    try {
      if (_emailController.text.trim().isNotEmpty && _passwordController.text.trim().isNotEmpty) {
        User? user = await Auth().login(email: _emailController.text, password: _passwordController.text);
        if (user != null) {
          if (user.emailVerified == true) {
            Map<String, dynamic> userData = await Firestore().getUserData(uid: user.uid);
            GlobalUserData globalUserData = GlobalUserData(user.uid, userData);
            if (userData.containsKey("birthday")) {
              _changeScreenFunction(
                  MainScreen1(globalUserData: globalUserData, globalPlaceData: globalPlaceData, changeScreenFunction: _changeScreenFunction));
            } else {
              _changeScreenFunction(FirstJoinScreen(changeScreenFunction: _changeScreenFunction, globalPlaceData: globalPlaceData));
            }
          } else {
            sendEmailVerification();
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _buttonErrorMessage = ErrorText((errorMessages[e.code] ?? e.message) ?? "", Colors.red);
      });
    }
  }

  Future<void> sendEmailVerification() async {
    setState(() {
      _buttonErrorMessage = const SizedBox(height: 0);
    });
    try {
      await Auth().sendEmailVerification();
      setState(() {
        _buttonErrorMessage = ErrorText("Email verification link sent! Verify your email then log in.", Colors.green);
      });
    } catch (e) {
      setState(() {
        _buttonErrorMessage = ErrorText("You already have a pending email verification link.", Colors.red);
      });
    }
  }

  Future<void> sendPasswordResetEmail() async {
    try {
      if (_emailController.text.trim().isNotEmpty) {
        await Auth().resetPassword(email: _emailController.text);
        setState(() {
          _emailController.text = "";
          _buttonErrorMessage = ErrorText("Password reset link sent to the given email!", Colors.green);
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _buttonErrorMessage = ErrorText((errorMessages[e.code] ?? e.message) ?? "", Colors.red);
      });
    }
  }

  void _SwitchLoginRegister(bool resetPassword) {
    setState(() {
      if (resetPassword) {
        isResetPassword = !isResetPassword;
      } else {
        isLogin = !isLogin;
      }
      _emailController.text = "";
      _passwordController.text = "";
      _usernameController.text = "";
      _buttonErrorMessage = const SizedBox(height: 0);
      _emailErrorText = const SizedBox(height: 0);
      _usernameErrorText = const SizedBox(height: 0);
      _passwordErrorText = const SizedBox(height: 0);
      _emailIcon = null;
      _usernameIcon = null;
      _passwordIcon = null;
    });
  }

  bool containsSpecialCharacters(String input) {
    RegExp specialCharRegExp = RegExp(r'[~ !@#$%^&*()_+`{}|<>?;:./,=\-\[\]]');
    return specialCharRegExp.hasMatch(input);
  }

  void _emailChanged(String txt) {
    setState(() {
      if (txt.trim().isEmpty) {
        _emailIcon = null;
        _emailErrorText = const SizedBox(height: 0);
      } else if (txt.length > 60) {
        _emailIcon = closeIcon;
        _emailErrorText = ErrorText("Email is too long.", Colors.red);
      } else if (!txt.contains("@")) {
        _emailIcon = closeIcon;
        _emailErrorText = ErrorText("Invalid email.", Colors.red);
      } else {
        _emailIcon = checkIcon;
        _emailErrorText = const SizedBox(height: 0);
      }
    });
  }

  void _usernameChanged(String txt) {
    setState(() {
      if (txt.trim().isEmpty) {
        _usernameIcon = null;
        _usernameErrorText = const SizedBox(height: 0);
      } else if (txt.length > 30) {
        _usernameIcon = closeIcon;
        _usernameErrorText = ErrorText("Username cant contain over 30 characters.", Colors.red);
      } else if (containsSpecialCharacters(txt)) {
        _usernameIcon = closeIcon;
        _usernameErrorText = ErrorText("Username cant contain special characters", Colors.red);
      } else {
        _usernameIcon = checkIcon;
        _usernameErrorText = const SizedBox(height: 0);
      }
    });
  }

  void _passwordChanged(String txt) {
    setState(() {
      if (txt.length == 0) {
        _passwordIcon = null;
        _passwordErrorText = const SizedBox(height: 0);
      } else if (txt.length < 6) {
        _passwordIcon = closeIcon;
        _passwordErrorText = ErrorText("Password should contains minimum 6 characters.", Colors.red);
      } else if (txt.length > 50) {
        _passwordIcon = closeIcon;
        _passwordErrorText = ErrorText("Password cant contain over 50 characters.", Colors.red);
      } else {
        _passwordIcon = checkIcon;
        _passwordErrorText = const SizedBox(height: 0);
      }
    });
  }

  void onTabTapped(int index) {
    if (index == 0) {
      if (isLogin == false) {
        _SwitchLoginRegister(false);
      }
    } else {
      if (isLogin == true) {
        _SwitchLoginRegister(false);
      }
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _changeScreenFunction = widget.changeScreenFunction;
    globalPlaceData = widget.globalPlaceData;
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
                    DefaultTabController(
                      length: isResetPassword ? 1 : 2,
                      child: TabBar(
                        onTap: onTabTapped,
                        indicatorColor: Colors.deepPurple,
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: Colors.black, // Color of selected tab text
                        labelStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        unselectedLabelColor: Colors.grey, // Color of unselected tab text
                        tabs: isResetPassword
                            ? const <Widget>[
                                Tab(
                                  text: "Reset Password",
                                ),
                              ]
                            : const <Widget>[
                                Tab(
                                  text: "Login",
                                ),
                                Tab(
                                  text: "Sign up",
                                ),
                              ],
                      ),
                    ),
                    Card(
                      color: Colors.white,
                      margin: const EdgeInsets.only(left: 20, right: 20, top: 20),
                      child: TextField(
                        onChanged: (String txt) {
                          _emailChanged(txt);
                        },
                        controller: _emailController,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: 'Email',
                          suffixIcon: isLogin ? null : _emailIcon,
                        ),
                      ),
                    ),
                    isLogin ? const SizedBox(height: 0) : _emailErrorText,
                    isLogin
                        ? const SizedBox(height: 0)
                        : Card(
                            color: Colors.white,
                            margin: const EdgeInsets.only(left: 20, right: 20, top: 15),
                            child: TextField(
                              onChanged: (String txt) {
                                _usernameChanged(txt);
                              },
                              controller: _usernameController,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: 'Username',
                                suffixIcon: _usernameIcon,
                              ),
                            ),
                          ),
                    _usernameErrorText,
                    isResetPassword
                        ? const SizedBox(height: 0)
                        : Card(
                            color: Colors.white,
                            margin: const EdgeInsets.only(left: 20, right: 20, top: 15),
                            child: TextField(
                              onChanged: (String txt) {
                                _passwordChanged(txt);
                              },
                              controller: _passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: 'Password',
                                suffixIcon: isLogin ? null : _passwordIcon,
                              ),
                            ),
                          ),
                    isLogin ? const SizedBox(height: 0) : _passwordErrorText,
                    _buttonErrorMessage,
                    const SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: () {
                        if (isResetPassword == true) {
                          sendPasswordResetEmail();
                        } else if (isLogin == true) {
                          login();
                        } else {
                          if (_emailIcon == checkIcon && _usernameIcon == checkIcon && _passwordIcon == checkIcon) {
                            createUser();
                          }
                        }
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
                      child: Text(
                        isResetPassword
                            ? "Reset password"
                            : isLogin
                                ? "Log in"
                                : "Sign up",
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54),
                      ),
                    ),
                    const SizedBox(height: 15),
                    isLogin
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isResetPassword ? "Have an account?" : "Forget your password?",
                                style: const TextStyle(color: Colors.black87),
                              ),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: () {
                                  _SwitchLoginRegister(true);
                                },
                                child: Text(
                                  isResetPassword ? "Log in" : "Reset password",
                                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
                                ),
                              ),
                            ],
                          )
                        : const SizedBox(height: 0),
                    (isLogin) ? const SizedBox(height: 15) : const SizedBox(height: 0),
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
      padding: const EdgeInsets.only(left: 20, right: 20, top: 5),
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
