import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_colors.dart';
import '../home/home_page.dart';
class AddPetPage extends StatefulWidget {
  @override
  _AddPetPageState createState() => _AddPetPageState();
}

class _AddPetPageState extends State<AddPetPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _raceController = TextEditingController();
  final _weightController = TextEditingController();
  String? _selectedHealth;
  final List<String> _healthOptions = [
    'Excellente',
    'Bonne',
    'Moyenne',
    'Nécessite des soins'
  ];

  Uint8List? _imageBytes;
  String? _selectedSex;
  String? _selectedCategory;
  String _ageUnit = 'mois';
  bool _isLoading = false;

  final List<String> _categories = ['Chat', 'Chien', 'Poisson', 'Tortue'];
  final List<String> _sexes = ['Mâle', 'Femelle'];
  final List<String> _ageUnits = ['mois', 'ans'];

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      _imageBytes = await picked.readAsBytes();
      setState(() {});
    }
  }

  Future<String?> _uploadImageToImgBB() async {
    if (_imageBytes == null) return null;
    final String apiKey = 'c9eb9d416995a95e2687b3d7c72016f5';
    final String base64Image = base64Encode(_imageBytes!);

    final response = await http.post(
      Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey'),
      body: {'image': base64Image},
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data']['url'];
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() ||
        _selectedCategory == null ||
        _selectedSex == null ||
        _imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Veuillez remplir tous les champs.")),
      );
      return;
    }

    setState(() => _isLoading = true);
    final imageUrl = await _uploadImageToImgBB();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || imageUrl == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final latitude = userDoc['latitude'];
    final longitude = userDoc['longitude'];
     // Convertir le poids en double
    double weight = 0.0;
    if (_weightController.text.isNotEmpty) {
      weight = double.tryParse(_weightController.text.trim()) ?? 0.0;
    }

    await FirebaseFirestore.instance.collection('animals').add({
      'ownerId': user.uid,
      'name': _nameController.text.trim(),
      'age': '${_ageController.text.trim()} $_ageUnit',
      'sex': _selectedSex,
      'description': _descriptionController.text.trim(),
      'imageUrl': imageUrl,
      'category': _selectedCategory,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': Timestamp.now(),
       // Nouveaux champs
      'health': _selectedHealth,
      'race': _raceController.text.trim(),
      'weight': weight,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Animal ajouté avec succès !"),
        backgroundColor: AppColors.primary,
      ),
    );

  Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
    );
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Ajouter un animal",
          style: TextStyle(
            color: Colors.white, // Texte blanc
            fontWeight: FontWeight.bold, // Texte en gras
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: _imageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(_imageBytes!, height: 180),
                      )
                    : Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: Center(
                          child: Icon(Icons.camera_alt, size: 40),
                        ),
                      ),
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
                items: _sexes
                    .map(
                        (sex) => DropdownMenuItem(value: sex, child: Text(sex)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedSex = val),
                validator: (value) =>
                    value == null ? 'Veuillez sélectionner un sexe' : null,
              ),
              SizedBox(height: 15),

              // Catégorie
              DropdownButtonFormField<String>(
                decoration: _buildInputDecoration("Catégorie", Icons.category),
                items: _categories
                    .map(
                        (cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
                validator: (value) =>
                    value == null ? 'Veuillez choisir une catégorie' : null,
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
                          .map((unit) =>
                              DropdownMenuItem(value: unit, child: Text(unit)))
                          .toList(),
                      onChanged: (val) => setState(() => _ageUnit = val!),
                    ),
                  ),
                ],
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
              // Après le champ Description et avant le bouton de soumission
              SizedBox(height: 15),

// Race
              TextFormField(
                controller: _raceController,
                decoration: _buildInputDecoration("Race", Icons.pets_outlined),
                validator: (value) =>
                    value!.isEmpty ? 'Ce champ est requis' : null,
              ),
              SizedBox(height: 15),

// Santé
              DropdownButtonFormField<String>(
                decoration: _buildInputDecoration(
                    "État de santé", Icons.health_and_safety),
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
              SizedBox(height: 25),


              ElevatedButton.icon(
                icon: Icon(Icons.check, color: Colors.white),
                label: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        "Enregistrer l'animal",
                        style: TextStyle(color: Colors.white),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(horizontal: 25, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isLoading ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
