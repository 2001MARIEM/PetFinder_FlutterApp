import 'package:flutter/material.dart';
import '../../models/animal_model.dart';
import '../../theme/app_colors.dart';
import '../Chat/chat_page.dart';

class PetDetailPage extends StatelessWidget {
  final AnimalModel animal;

  const PetDetailPage({required this.animal, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppColors.darkRed.withOpacity(0.4), // Fond légèrement teinté
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
         
      ),
      body: Column(
        children: [
          // Section supérieure avec image
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    color: AppColors.primary
                        .withOpacity(0.2), // Couleur de fond selon la charte
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      animal.imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Section inférieure avec informations
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom et autres infos
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          animal.name,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                         
                      ],
                    ),

                    SizedBox(height: 8),

                    Text(
                      "1.2 km à proximité",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),

                    SizedBox(height: 24),

                    // Caractéristiques
                    Row(
                      children: [
                        Expanded(
                          child: _buildCharacteristicBox(
                            animal.age,
                            "Âge",
                             AppColors.primary.withOpacity(0.1),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildCharacteristicBox(
                            animal.sex,
                            "Sexe",
                            AppColors.accent.withOpacity(0.2),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildCharacteristicBox(
                            "${animal.weight} kg",
                            "Poids",
                            AppColors.primary.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 24),

                    // Informations supplémentaires
                    Row(
                      children: [
                        Expanded(
                          child: _buildCharacteristicBox(
                             "${animal.category.toString()}",
                            "Catégorie",
                            AppColors.accent.withOpacity(0.2),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildCharacteristicBox(
                            "${animal.health?.toString() ?? 'Non spécifiée'}",
                            "Santé",
                            AppColors.primary.withOpacity(0.1),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildCharacteristicBox(
                              "${animal.race?.toString() ?? 'Non spécifiée'}",
                            "Race",
                            AppColors.accent.withOpacity(0.2),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 24),

                    // À propos
                    Text(
                      "À propos de ${animal.name}",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    SizedBox(height: 12),

                    Text(
                      animal.description,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[800],
                        height: 1.6,
                      ),
                    ),

                    SizedBox(height: 30),

                    // Bouton Adopter et Chat
                    Row(
                      children: [
                        // Bouton Adopter
                        Expanded(
                          flex: 4,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Fonctionnalité à implémenter
                            },
                            icon: Icon(Icons.pets, color: Colors.white),
                            label: Text(
                              "Adopter ${animal.name}",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(width: 12),

                        // Bouton Chat
                       // Dans la partie du bouton de chat de PetDetailPage
                        Expanded(
                          flex: 1,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatPage(
                                    animal: animal,
                                    ownerId: animal.ownerId,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFD7572B),
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: Icon(
                              Icons.question_answer,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacteristicBox(String value, String label, Color bgColor) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
