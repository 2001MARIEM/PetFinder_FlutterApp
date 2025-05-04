import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Accueil'),
        backgroundColor:
            Colors
                .deepOrange, // ou utilise AppColors.primary si tu veux rester cohérent
      ),
      body: Center(
        child: Text(
          'Hello',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
