import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../../theme/app_colors.dart';
import '../auth/login_page.dart';
import 'package:provider/provider.dart';
 
import '../../Widgets/bottom_nav_bar.dart';
import '../animals/pet_detail_page.dart';
import '../../models/animal_model.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  Uint8List? _imageBytes;
  bool _isLoading = false;
  bool _isLoadingData = true;

  // Stockage des données originales pour comparaison
  Map<String, dynamic> _userData = {};

  // Contrôleurs pour le formulaire de modification
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  // État pour l'affichage des mots de passe
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;

  String? _imageUrl;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Chargement des données de l'utilisateur depuis Firestore
  Future<void> _loadUserData() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        final userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userData.exists) {
          final data = userData.data() as Map<String, dynamic>;

          setState(() {
            _userData = data;
            _imageUrl = data['photoUrl'];
          });
        }
      }
    } catch (e) {
      print('Erreur lors du chargement des données: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors du chargement du profil')),
      );
    } finally {
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  // Initialise les contrôleurs pour le popup de modification
  void _initEditControllers() {
    _nameController.text =
        '${_userData['prenom'] ?? ''} ${_userData['nom'] ?? ''}';
    _emailController.text = _userData['email'] ?? '';
    _phoneController.text = _userData['telephone'] ?? '';
    _oldPasswordController.clear();
    _newPasswordController.clear();
    _imageBytes = null;
  }

   Future<List<Map<String, dynamic>>> _fetchUserPets() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final snapshot = await FirebaseFirestore.instance
        .collection('animals')
        .where('ownerId', isEqualTo: uid)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'],
        'imageUrl': data['imageUrl'],
        'category': data['category'],
      };
    }).toList();
  }

  Future<void> _deletePet(String petId) async {
    try {
      await FirebaseFirestore.instance
          .collection('animals')
          .doc(petId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Animal supprimé avec succès'),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      print('Erreur lors de la suppression: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la suppression'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showMyPetsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: MediaQuery.of(context).size.width,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Mes Animaux',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Divider(),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _fetchUserPets(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Erreur lors du chargement',
                            style: TextStyle(color: Colors.red),
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.pets,
                                size: 60,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 16),
                              Text(
                                "Vous n'avez pas encore d'animaux",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final pets = snapshot.data!;

                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: pets.length,
                        itemBuilder: (context, index) {
                          final pet = pets[index];

                          return Container(
                            margin: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(pet['imageUrl']),
                                radius: 24,
                                backgroundColor: Colors.grey[200],
                                onBackgroundImageError: (_, __) {},
                              ),
                              title: Text(
                                pet['name'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Text(
                                'Catégorie: ${pet['category']}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              trailing: TextButton(
                                onPressed: () async {
                                  // Confirmation de suppression
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('Confirmer la suppression'),
                                      content: Text(
                                          'Êtes-vous sûr de vouloir supprimer ${pet['name']} ?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(false),
                                          child: Text('Annuler'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(true),
                                          child: Text(
                                            'Supprimer',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    await _deletePet(pet['id']);
                                    Navigator.of(context)
                                        .pop(); // Fermer le dialog
                                    _showMyPetsDialog(); // Rouvrir avec la liste mise à jour
                                  }
                                },
                                child: Text(
                                  'Supprimer',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                                  onTap: () async {
                                    // Stocker l'ID de l'animal
                                final petId = pet['id'];
                                final BuildContext mainContext = context;

                                // Utiliser Future.microtask pour s'assurer que le dialogue est complètement fermé
                                Future.microtask(() async {
                                  try {
                                    // Récupérer l'animal complet depuis Firestore
                                    final animalDoc = await FirebaseFirestore
                                        .instance
                                        .collection('animals')
                                        .doc(petId)
                                        .get();

                                    if (animalDoc.exists) {
                                      // Créer un objet AnimalModel
                                      final animal = AnimalModel.fromMap(
                                          animalDoc.data()!, animalDoc.id);

                                      // Vérifier que le contexte est toujours valide avant de naviguer
                                      if (mainContext.mounted) {
                                        // Naviguer vers la page de détails en utilisant le contexte principal
                                        Navigator.of(mainContext).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                PetDetailPage(animal: animal),
                                          ),
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    print('Erreur lors de la navigation: $e');
                                  }
                                });
                              },
                                  
                            ),
                          );

                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Fermer',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
 // Déconnexion de l'utilisateur
  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
       // Naviguer vers LoginPage en effaçant toute la pile de navigation
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginPage()),
          (route) => false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Déconnexion réussie'),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      print('Erreur lors de la déconnexion: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la déconnexion'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _imageBytes = bytes;
      });
    }
  }

  Future<String?> _uploadImageToImgBB() async {
    if (_imageBytes == null) return _imageUrl; // Utiliser l'image existante

    final String apiKey = 'c9eb9d416995a95e2687b3d7c72016f5';
    final String base64Image = base64Encode(_imageBytes!);

    try {
      final response = await http.post(
        Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey'),
        body: {'image': base64Image},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['data']['url'];
      } else {
        throw Exception("Échec de l'upload de l'image.");
      }
    } catch (e) {
      print('Erreur lors de l\'upload de l\'image: $e');
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final User? currentUser = FirebaseAuth.instance.currentUser;

        if (currentUser != null) {
          // Mise à jour du mot de passe si nécessaire
          if (_oldPasswordController.text.isNotEmpty &&
              _newPasswordController.text.isNotEmpty) {
            try {
              // Réauthentification de l'utilisateur avant de changer le mot de passe
              AuthCredential credential = EmailAuthProvider.credential(
                email: currentUser.email!,
                password: _oldPasswordController.text,
              );

              await currentUser.reauthenticateWithCredential(credential);
              await currentUser.updatePassword(_newPasswordController.text);
            } catch (e) {
              setState(() {
                _isLoading = false;
                _errorMessage = "Erreur de mot de passe: ${e.toString()}";
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(_errorMessage ?? "Erreur de mot de passe")),
              );
              return;
            }
          }

          // Upload de la nouvelle image si nécessaire
          String? updatedImageUrl =
              _imageBytes != null ? await _uploadImageToImgBB() : _imageUrl;

          // Parse le nom et prénom depuis le champ
          List<String> nameParts = _nameController.text.trim().split(' ');
          String prenom = nameParts.isNotEmpty ? nameParts[0] : '';
          String nom =
              nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

          // Mise à jour des données dans Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .update({
            'nom': nom,
            'prenom': prenom,
            'email': _emailController.text.trim(),
            'telephone': _phoneController.text.trim(),
            'photoUrl': updatedImageUrl,
          });

          // Mise à jour de l'email dans FirebaseAuth si modifié
          if (_emailController.text != currentUser.email) {
            await currentUser.updateEmail(_emailController.text.trim());
          }

          // Rafraîchissement des données
          await _loadUserData();

          Navigator.of(context).pop(); // Fermer le popup

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Profil mis à jour avec succès !"),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      } catch (e) {
        print('Erreur lors de la mise à jour du profil: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Erreur lors de la mise à jour du profil: ${e.toString()}')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }
 
  void _showEditProfileDialog() {
    _initEditControllers();
    _errorMessage = null;
    // Réinitialiser _isLoading au début
    setState(() {
      _isLoading = false;
    });
    showDialog(
      context: context,
       barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
             void updateDialogState() {
              setDialogState(() {
                // Force le dialogue à se reconstruire
              });
            }
            // InputDecoration réutilisable
            InputDecoration _buildInputDecoration(String label, IconData icon,
                {Widget? customSuffixIcon}) {
              return InputDecoration(
                labelText: label,
                prefixIcon: Icon(icon, color: AppColors.primary),
                suffixIcon: customSuffixIcon,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary),
                  borderRadius: BorderRadius.circular(12),
                ),
              );
            }

            return Dialog(
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Modifier le profil',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Photo de profil
                        Center(
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 55,
                                backgroundImage: _imageBytes != null
                                    ? MemoryImage(_imageBytes!)
                                    : (_imageUrl != null &&
                                            _imageUrl!.isNotEmpty)
                                        ? NetworkImage(_imageUrl!)
                                            as ImageProvider
                                        : const NetworkImage(
                                            'https://i.postimg.cc/cCsYDjvj/user-2.png',
                                          ) as ImageProvider,
                              ),
                              InkWell(
                                onTap: () async {
                                  await _pickImage();
                                  setDialogState(() {});
                                },
                                child: const CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AppColors.primary,
                                  child: Icon(Icons.camera_alt,
                                      color: Colors.white, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Informations personnelles
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  blurRadius: 4)
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Informations personnelles',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _nameController,
                                decoration:
                                    _buildInputDecoration("Nom", Icons.person),
                                validator: (value) =>
                                    value!.isEmpty ? "Nom requis" : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _emailController,
                                decoration:
                                    _buildInputDecoration("Email", Icons.email),
                                validator: (value) =>
                                    value!.isEmpty ? "Email requis" : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _phoneController,
                                decoration: _buildInputDecoration(
                                    "Téléphone", Icons.phone),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Sécurité
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  blurRadius: 4)
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Sécurité',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _oldPasswordController,
                                decoration: _buildInputDecoration(
                                  "Ancien mot de passe",
                                  Icons.lock,
                                  customSuffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureOldPassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: AppColors.primary,
                                    ),
                                    onPressed: () {
                                      setDialogState(() {
                                        _obscureOldPassword =
                                            !_obscureOldPassword;
                                      });
                                    },
                                  ),
                                ),
                                obscureText: _obscureOldPassword,
                                validator: (value) {
                                  if (_oldPasswordController.text.isNotEmpty ||
                                      _newPasswordController.text.isNotEmpty) {
                                    return value!.isEmpty
                                        ? "Ancien mot de passe requis"
                                        : null;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _newPasswordController,
                                decoration: _buildInputDecoration(
                                  "Nouveau mot de passe",
                                  Icons.lock,
                                  customSuffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureNewPassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: AppColors.primary,
                                    ),
                                    onPressed: () {
                                      setDialogState(() {
                                        _obscureNewPassword =
                                            !_obscureNewPassword;
                                      });
                                    },
                                  ),
                                ),
                                obscureText: _obscureNewPassword,
                                validator: (value) {
                                  if (_oldPasswordController.text.isNotEmpty) {
                                    return value!.isEmpty
                                        ? "Nouveau mot de passe requis"
                                        : null;
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        if (_errorMessage != null) ...[
                          Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Boutons Sauvegarder et Annuler
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton.icon(
                              icon:
                                  const Icon(Icons.cancel, color: Colors.white),
                              label: const Text("Annuler",
                                  style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 25, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.save, color: Colors.white),
                              label: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : const Text("Sauvegarder",
                                      style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 25, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _isLoading
                                  ? null
                                  : () async {
                                      setState(() {
                                        _isLoading = true;
                                      });
                                      updateDialogState();
                                      await _saveProfile();
                                     if (context.mounted) {
                                        updateDialogState();
                                      }
                                    },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
        
      },
      
    );
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Bouton de déconnexion dans l'AppBar
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: _isLoadingData
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Photo de profil
                  Center(
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage:
                          (_imageUrl != null && _imageUrl!.isNotEmpty)
                              ? NetworkImage(_imageUrl!) as ImageProvider
                              : const NetworkImage(
                                  'https://i.postimg.cc/cCsYDjvj/user-2.png',
                                ) as ImageProvider,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Bouton Modifier juste au-dessus du cadre des informations
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(bottom: 16),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      label: const Text("Modifier le profil",
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _showEditProfileDialog,
                    ),
                  ),

                  // Informations personnelles - Cadre
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.grey.withOpacity(0.2), blurRadius: 4)
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Informations personnelles',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        _buildInfoRow(Icons.person, "Nom",
                            "${_userData['prenom'] ?? ''} ${_userData['nom'] ?? ''}"),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                            Icons.email, "Email", _userData['email'] ?? ''),
                        const SizedBox(height: 12),
                        _buildInfoRow(Icons.phone, "Téléphone",
                            _userData['telephone'] ?? ''),
                      ],
                    ),
                  ),
                  // Après le conteneur des informations personnelles
                  const SizedBox(height: 24),
                  // Mes Pets - Cadre
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 6,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: InkWell(
                      onTap: _showMyPetsDialog,
                      child: Row(
                        children: [
                          Icon(
                            Icons.pets,
                            color: AppColors.primary,
                            size: 28,
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mes Pets',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Gérer vos animaux',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.grey,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

// Apparence - Cadre pour le thème
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:   Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                         BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 6,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Apparence',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color:Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Option mode sombre
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons
                                      .dark_mode, // Icône fixe pour le mode sombre
                                  color: AppColors.primary,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Mode sombre',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                             Switch(
                              value: false, // Valeur fixe (toujours désactivé)
                              onChanged:
                                  null, // null signifie que le switch est désactivé
                              activeColor: AppColors.primary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                ],
              ),
            ),
            bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 4, // Index pour Chats
        context: context,
      ),
      
    );
  }

  // Méthode pour construire une ligne d'information
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
