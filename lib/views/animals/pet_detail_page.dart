import 'package:flutter/material.dart';
import '../../models/animal_model.dart';

class PetDetailPage extends StatelessWidget {
  final AnimalModel animal;

  const PetDetailPage({required this.animal, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(animal.name)),
      body: Column(
        children: [
          Image.network(animal.imageUrl),
          Text("Âge : ${animal.age}"),
          // Autres infos...
        ],
      ),
    );
  }
}
