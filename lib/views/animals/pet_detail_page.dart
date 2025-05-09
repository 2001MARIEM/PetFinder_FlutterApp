import 'package:flutter/material.dart';
import '../../models/animal_model.dart';
import '../../theme/app_colors.dart';
import '../Chat/chat_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PetDetailPage extends StatefulWidget {
  final AnimalModel animal;

  const PetDetailPage({required this.animal, Key? key}) : super(key: key);

  @override
  _PetDetailPageState createState() => _PetDetailPageState();
}

class _PetDetailPageState extends State<PetDetailPage> {
  bool _isOwner = false;

  @override
  void initState() {
    super.initState();
    _checkIfOwner();
  }

  void _checkIfOwner() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      setState(() {
        _isOwner = widget.animal.ownerId == currentUser.uid;
      });
    }
  }

  void _showEditPetDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return EditPetDialog(animal: widget.animal);
      },
    );

    if (result == true) {
      try {
        // Récupérer les nouvelles données de l'animal depuis Firestore
        final docSnap = await FirebaseFirestore.instance
            .collection('animals')
            .doc(widget.animal.id)
            .get();

        if (docSnap.exists && mounted) {
          // Créer un nouvel objet animal avec les données mises à jour
          final updatedAnimal =
              AnimalModel.fromMap(docSnap.data()!, widget.animal.id);

          // Option 1: Remplacer la page actuelle par une nouvelle instance avec l'animal mis à jour
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PetDetailPage(animal: updatedAnimal),
            ),
          );
        }
      } catch (e) {
        print('Erreur lors du rechargement des données: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "Les modifications ont été enregistrées mais l'affichage n'a pas pu être mis à jour."),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  } // <-- Cette accolade était manquante

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary.withOpacity(0.5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: _isOwner
            ? [
                // Bouton de modification visible uniquement pour le propriétaire
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.black),
                  onPressed: _showEditPetDialog,
                ),
              ]
            : [],
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
                    color: AppColors.primary.withOpacity(0.2),
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
                      widget.animal.imageUrl,
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
                          widget.animal.name,
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
                            widget.animal.age,
                            "Âge",
                            AppColors.primary.withOpacity(0.1),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildCharacteristicBox(
                            widget.animal.sex,
                            "Sexe",
                            AppColors.accent.withOpacity(0.2),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildCharacteristicBox(
                            "${widget.animal.weight} kg",
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
                            "${widget.animal.category.toString()}",
                            "Catégorie",
                            AppColors.accent.withOpacity(0.2),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildCharacteristicBox(
                            "${widget.animal.health?.toString() ?? 'Non spécifiée'}",
                            "Santé",
                            AppColors.primary.withOpacity(0.1),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildCharacteristicBox(
                            "${widget.animal.race?.toString() ?? 'Non spécifiée'}",
                            "Race",
                            AppColors.accent.withOpacity(0.2),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 24),

                    // À propos
                    Text(
                      "À propos de ${widget.animal.name}",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    SizedBox(height: 12),

                    Text(
                      widget.animal.description,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[800],
                        height: 1.6,
                      ),
                    ),

                    SizedBox(height: 30),

                    // Boutons - différents selon que l'utilisateur est propriétaire ou non
                    _isOwner
                        ? _buildOwnerActions()
                        : _buildAdopterActions(context),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerActions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _showEditPetDialog,
            icon: Icon(Icons.edit, color: Colors.white),
            label: Text(
              "Modifier ${widget.animal.name}",
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
      ],
    );
  }

  Widget _buildAdopterActions(BuildContext context) {
    return Row(
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
              "Adopter ${widget.animal.name}",
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
        Expanded(
          flex: 1,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(
                    animal: widget.animal,
                    ownerId: widget.animal.ownerId,
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

// Classe du formulaire d'édition
class EditPetDialog extends StatefulWidget {
  final AnimalModel animal;

  const EditPetDialog({required this.animal, Key? key}) : super(key: key);

  @override
  _EditPetDialogState createState() => _EditPetDialogState();
}

class _EditPetDialogState extends State<EditPetDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _descriptionController;
  late TextEditingController _raceController;
  late TextEditingController _weightController;

  String? _selectedSex;
  String? _selectedCategory;
  String? _selectedHealth;
  String _ageUnit = 'mois';
  bool _isLoading = false;

  final List<String> _categories = ['Chat', 'Chien', 'Poisson', 'Tortue'];
  final List<String> _sexes = ['Mâle', 'Femelle'];
  final List<String> _ageUnits = ['mois', 'ans'];
  final List<String> _healthOptions = [
    'Excellente',
    'Bonne',
    'Moyenne',
    'Nécessite des soins'
  ];

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    // Initialiser les contrôleurs avec les valeurs actuelles de l'animal
    _nameController = TextEditingController(text: widget.animal.name);

    // Extraire l'âge numérique et l'unité
    final ageParts = widget.animal.age.split(' ');
    _ageController = TextEditingController(text: ageParts[0]);
    if (ageParts.length > 1) {
      _ageUnit = ageParts[1];
    }

    _descriptionController =
        TextEditingController(text: widget.animal.description);
    _raceController = TextEditingController(text: widget.animal.race ?? '');
    _weightController =
        TextEditingController(text: widget.animal.weight?.toString() ?? '0.0');

    _selectedSex = widget.animal.sex;
    _selectedCategory = widget.animal.category;
    _selectedHealth = widget.animal.health;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _descriptionController.dispose();
    _raceController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _updatePet() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Convertir le poids en double
      double weight = double.tryParse(_weightController.text.trim()) ?? 0.0;

      // Mettre à jour dans Firestore
      await FirebaseFirestore.instance
          .collection('animals')
          .doc(widget.animal.id)
          .update({
        'name': _nameController.text.trim(),
        'age': '${_ageController.text.trim()} $_ageUnit',
        'sex': _selectedSex,
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'health': _selectedHealth,
        'race': _raceController.text.trim(),
        'weight': weight,
      });

      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Animal mis à jour avec succès !"),
          backgroundColor: AppColors.primary,
        ),
      );

      // Fermer le dialogue
      Navigator.of(context)
          .pop(true); // true indique que la mise à jour a réussi
    } catch (e) {
      print('Erreur lors de la mise à jour: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de la mise à jour: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.primary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.primary),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: Colors.white,
      child: Container(
        padding: EdgeInsets.all(20),
        constraints: BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre du dialogue
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Modifier ${widget.animal.name}",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),

                SizedBox(height: 20),

                // Nom
                TextFormField(
                  controller: _nameController,
                  decoration:
                      _buildInputDecoration("Nom de l'animal", Icons.pets),
                  validator: (value) =>
                      value!.isEmpty ? 'Ce champ est requis' : null,
                ),
                SizedBox(height: 15),

                // Sexe
                DropdownButtonFormField<String>(
                  decoration: _buildInputDecoration("Sexe", Icons.transgender),
                  value: _selectedSex,
                  items: _sexes
                      .map((sex) =>
                          DropdownMenuItem(value: sex, child: Text(sex)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedSex = val),
                  validator: (value) =>
                      value == null ? 'Veuillez sélectionner un sexe' : null,
                ),
                SizedBox(height: 15),

                // Catégorie
                DropdownButtonFormField<String>(
                  decoration:
                      _buildInputDecoration("Catégorie", Icons.category),
                  value: _selectedCategory,
                  items: _categories
                      .map((cat) =>
                          DropdownMenuItem(value: cat, child: Text(cat)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedCategory = val),
                  validator: (value) =>
                      value == null ? 'Veuillez choisir une catégorie' : null,
                ),
                SizedBox(height: 15),

                // Race
                TextFormField(
                  controller: _raceController,
                  decoration:
                      _buildInputDecoration("Race", Icons.pets_outlined),
                  validator: (value) =>
                      value!.isEmpty ? 'Ce champ est requis' : null,
                ),
                SizedBox(height: 15),

                // Âge (nombre + unité)
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration: _buildInputDecoration("Âge", Icons.cake),
                        validator: (value) =>
                            value!.isEmpty ? 'Champ requis' : null,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        value: _ageUnit,
                        items: _ageUnits
                            .map((unit) => DropdownMenuItem(
                                value: unit, child: Text(unit)))
                            .toList(),
                        onChanged: (val) => setState(() => _ageUnit = val!),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15),

                // Santé
                DropdownButtonFormField<String>(
                  decoration: _buildInputDecoration(
                      "État de santé", Icons.health_and_safety),
                  value: _selectedHealth,
                  items: _healthOptions
                      .map((health) =>
                          DropdownMenuItem(value: health, child: Text(health)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedHealth = val),
                  validator: (value) => value == null
                      ? 'Veuillez sélectionner un état de santé'
                      : null,
                ),
                SizedBox(height: 15),

                // Poids
                TextFormField(
                  controller: _weightController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      _buildInputDecoration("Poids (kg)", Icons.monitor_weight),
                  validator: (value) {
                    if (value!.isEmpty) return 'Ce champ est requis';
                    if (double.tryParse(value) == null)
                      return 'Entrez un nombre valide';
                    return null;
                  },
                ),
                SizedBox(height: 15),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration:
                      _buildInputDecoration("Description", Icons.description),
                  validator: (value) =>
                      value!.isEmpty ? 'Ce champ est requis' : null,
                ),
                SizedBox(height: 25),

                // Boutons d'action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        "Annuler",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _updatePet,
                      icon: _isLoading
                          ? Container(
                              width: 24,
                              height: 24,
                              padding: EdgeInsets.all(2),
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : Icon(Icons.save, color: Colors.white),
                      label: Text(
                        "Enregistrer",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
    );
  }
}
