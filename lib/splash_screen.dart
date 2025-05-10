import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './views/auth/login_page.dart';
import './getStarted_page.dart';
import './views/home/home_page.dart'; // Importez votre page d'accueil

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Vérifier l'état d'authentification après l'animation
    Future.delayed(Duration(seconds: 5), () {
      checkAuth();
    });
  }

  void checkAuth() {
    // Vérifier si l'utilisateur est connecté
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // L'utilisateur est connecté, rediriger vers la page d'accueil
      print("Utilisateur déjà connecté: ${user.uid}");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => HomePage()), // Votre page d'accueil
      );
    } else {
      // L'utilisateur n'est pas connecté, rediriger vers la page de démarrage
      print("Aucun utilisateur connecté, redirection vers GetStartedPage");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => GetStartedPage()),
      );
    }
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
