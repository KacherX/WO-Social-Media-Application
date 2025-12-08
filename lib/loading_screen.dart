import 'package:flutter/material.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LoadingAnimation(),
    );
  }

  Center LoadingAnimation() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "WO",
            style: TextStyle(
                fontFamily: "Pacifico",
                fontSize: 50,
                fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
