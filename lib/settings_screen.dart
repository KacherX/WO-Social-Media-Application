import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wo/models/global_place_data.dart';
import 'package:wo/models/global_user_data.dart';

class SettingsScreen extends StatefulWidget {
  final GlobalUserData globalUserData;
  final GlobalPlaceData globalPlaceData;
  final Function onMapViewFunction;

  const SettingsScreen({Key? key, required this.globalUserData, required this.globalPlaceData, required this.onMapViewFunction}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late GlobalUserData globalUserData;
  late GlobalPlaceData globalPlaceData;
  late Function onMapViewFunction;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    globalUserData = widget.globalUserData;
    globalPlaceData = widget.globalPlaceData;
    onMapViewFunction = widget.onMapViewFunction;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 25),
          SettingsFrame(Icon(Icons.person), "Account Information",
              "Update your personal details and manage your profile settings, including your birthday, phone number, and password."),
          const SizedBox(height: 25),
          SettingsFrame(Icon(Icons.privacy_tip), "Privacy and Security",
              "Control who can see your profile, location, and manage your blocked accounts to customize your privacy experience."),
          const SizedBox(height: 25),
          SettingsFrame(Icon(Icons.language), "Accessability and Language",
              "Customize your experience to suit your needs. Change language, adjust text size or enable high-contrast mode.")
        ],
      ),
    );
  }

  Widget SettingsFrame(Icon icon, String settingName, String settingInfo) {
    return GestureDetector(
      onTap: () {
        print("qwe");
      },
      child: Row(
        children: [
          const SizedBox(width: 15),
          icon,
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(settingName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                Text(settingInfo, style: TextStyle(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}
