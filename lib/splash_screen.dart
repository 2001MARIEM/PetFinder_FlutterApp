import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
//import './views/auth/login_page.dart'; // <-- redirection vers la page de login
import './getStarted_page.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => GetStartedPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    print("SplashScreen loaded");
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Lottie.asset('assets/lottie/splash.json', width: 200),
      ),
    );
  }
}
