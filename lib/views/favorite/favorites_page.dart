import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/animal_model.dart';
import '../../theme/app_colors.dart';
import '../animals/pet_detail_page.dart';
import 'package:geolocator/geolocator.dart';
import '../../Widgets/bottom_nav_bar.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({Key? key}) : super(key: key);

  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  Position? _currentPosition;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur lors de la récupération de la position: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Future<List<AnimalModel>> _fetchFavoriteAnimals() async {
  //   final uid = FirebaseAuth.instance.currentUser!.uid;
    
  //   // Récupération des IDs des animaux favoris
  //   final favoritesSnapshot = await FirebaseFirestore.instance
  //       .collection('users')
  //       .doc(uid)
  //       .collection('favorites')
  //       .orderBy('addedAt', descending: true)
  //       .get();
    
  //   final animalIds = favoritesSnapshot.docs.map((doc) => doc.id).toList();
    
  //   if (animalIds.isEmpty) {
  //     return [];
  //   }
    
  //   // Récupération des détails de chaque animal favori
  //   List<AnimalModel> favoriteAnimals = [];
    
  //   // Firebase ne permet pas directement "where id in [...]" pour un grand nombre d'IDs
  //   // Nous devons donc faire plusieurs requêtes par lots si nécessaire
  //   const batchSize = 10;
  //   for (var i = 0; i < animalIds.length; i += batchSize) {
  //     final end = (i + batchSize < animalIds.length) ? i + batchSize : animalIds.length;
  //     final batch = animalIds.sublist(i, end);
      
  //     final animalsSnapshot = await FirebaseFirestore.instance
  //         .collection('animals')
  //         .where(FieldPath.documentId, whereIn: batch)
  //         .get();
          
  //     final batchAnimals = animalsSnapshot.docs
  //         .map((doc) => AnimalModel.fromMap(doc.data(), doc.id))
  //         .toList();
          
  //     favoriteAnimals.addAll(batchAnimals);
  //   }
    
  //   return favoriteAnimals;
  // }
Future<List<AnimalModel>> _fetchFavoriteAnimals() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    print("Récupération des favoris pour l'utilisateur $uid");

    // Récupération des IDs des animaux favoris
    final favoritesSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .orderBy('addedAt', descending: true)
        .get();

    final animalIds = favoritesSnapshot.docs.map((doc) => doc.id).toList();
    print("IDs des animaux favoris trouvés: $animalIds");

    if (animalIds.isEmpty) {
      return [];
    }

    // Récupération des détails de chaque animal favori
    List<AnimalModel> favoriteAnimals = [];

    // Firebase ne permet pas directement "where id in [...]" pour un grand nombre d'IDs
    // Nous devons donc faire plusieurs requêtes par lots si nécessaire
    const batchSize = 10;
    for (var i = 0; i < animalIds.length; i += batchSize) {
      final end =
          (i + batchSize < animalIds.length) ? i + batchSize : animalIds.length;
      final batch = animalIds.sublist(i, end);

      final animalsSnapshot = await FirebaseFirestore.instance
          .collection('animals')
          .where(FieldPath.documentId, whereIn: batch)
          .get();

      final batchAnimals = animalsSnapshot.docs
          .map((doc) => AnimalModel.fromMap(doc.data(), doc.id))
          .toList();

      favoriteAnimals.addAll(batchAnimals);
    }

    return favoriteAnimals;
  }
  Future<void> _removeFavorite(String animalId) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('favorites')
          .doc(animalId)
          .delete();
      
      // Rafraîchir la page
      setState(() {});
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Retiré des favoris'),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du retrait des favoris'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Mes favoris'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : FutureBuilder<List<AnimalModel>>(
              future: _fetchFavoriteAnimals(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                  
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Erreur lors du chargement des favoris',
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
                          Icons.favorite_border,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text( "Vous n'avez pas encore d'animaux favoris",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Ajoutez des animaux à vos favoris en cliquant sur le cœur",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                final animals = snapshot.data!;
                
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView.builder(
                    itemCount: animals.length,
                    itemBuilder: (context, index) {
                      final animal = animals[index];
                      
                      // Calcul de la distance
                      String distanceText = "Distance inconnue";
                      if (_currentPosition != null &&
                          animal.latitude != null &&
                          animal.longitude != null) {
                        double distanceInMeters = Geolocator.distanceBetween(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                          animal.latitude!,
                          animal.longitude!,
                        );
                        double distanceInKm = distanceInMeters / 1000;
                        distanceText = "à ${distanceInKm.toStringAsFixed(1)} km";
                      }
                      
                      return Dismissible(
                        key: Key(animal.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          color: Colors.red,
                          child: Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                        ),
                        onDismissed: (direction) {
                          _removeFavorite(animal.id);
                        },
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text("Supprimer des favoris"),
                                content: Text(
                                  "Êtes-vous sûr de vouloir retirer ${animal.name} de vos favoris ?",
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: Text("Annuler"),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: Text(
                                      "Supprimer",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PetDetailPage(animal: animal),
                              ),
                            ).then((_) {
                              // Rafraîchir les favoris après retour de la page de détails
                              setState(() {});
                            });
                          },
                          child: Container(
                            margin: EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  blurRadius: 6,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(16)),
                                  child: Image.network(
                                    animal.imageUrl,
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 200,
                                        color: Colors.grey[300],
                                        child: Icon(
                                          Icons.pets,
                                          size: 50,
                                          color: Colors.grey[500],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        animal.name,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.location_on,
                                              size: 18,
                                              color: AppColors.primary
                                                  .withOpacity(0.8)),
                                          SizedBox(width: 4),
                                          Text(
                                            distanceText,
                                            style: TextStyle(
                                              color: AppColors.primary
                                                  .withOpacity(0.8),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Spacer(),
                                          IconButton(
                                            icon: Icon(
                                              Icons.favorite,
                                              color: Colors.red,
                                            ),
                                            onPressed: () => _removeFavorite(animal.id),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.pets,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            animal.category,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Icon(
                                            animal.sex == 'Mâle'
                                                ? Icons.male
                                                : Icons.female,
                                            size: 16,
                                            color: animal.sex == 'Mâle'
                                                ? Colors.blue
                                                : Colors.pink,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            animal.sex,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),

                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
                
              },
            ),
            bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 1, // Index pour Favoris
        context: context,
      ),
    );
  }
}