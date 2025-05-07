import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Ajouter un animal"),
      ),
      body: Center(
        child: Text("Formulaire d'ajout d'animal ici"),
      ),
    );
  }
}
