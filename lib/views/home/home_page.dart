import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../animals/add_pet_page.dart';
import '../animals/pet_detail_page.dart';
import './profile_page.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../models/animal_model.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  UserModel? currentUser;
  String selectedCategory = 'Chat';
  String? _currentAddress;
  Position? _currentPosition;

  final List<String> categories = ['Chat', 'Chien', 'Poisson', 'Tortue'];

  final Map<String, IconData> categoryIcons = {
    'Chat': Icons.pets,
    'Chien': Icons.pets,
    'Poisson': Icons.water,
    'Tortue': Icons.emoji_nature,
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _getCurrentLocation();
  }

  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      setState(() {
        currentUser = UserModel.fromMap(doc.data()!, doc.id);
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _currentAddress = "Service désactivé";
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _currentAddress = "Permission refusée";
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _currentAddress = "Permission refusée définitivement";
      });
      return;
    }

    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = position;
    });

    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .update({
      'latitude': position.latitude,
      'longitude': position.longitude,
    });

    await _getAddressFromLatLng();
  }

  Future<void> _getAddressFromLatLng() async {
    if (_currentPosition == null) return;

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      Placemark place = placemarks[0];
      setState(() {
        _currentAddress = '${place.locality}, ${place.country}';
      });
    } catch (e) {
      print(e);
    }
  }

  Future<List<AnimalModel>> _fetchAnimals() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('animals')
        .where('category', isEqualTo: selectedCategory)
        .get();

    return snapshot.docs
        .map((doc) => AnimalModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<bool> _isFavorite(String animalId) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(animalId)
        .get();

    return doc.exists;
  }

  Future<void> _toggleFavorite(String animalId) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final favRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(animalId);

    final isFav = await favRef.get();
    if (isFav.exists) {
      await favRef.delete();
    } else {
      await favRef.set({'addedAt': Timestamp.now()});
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            currentUser != null && currentUser!.photoUrl.isNotEmpty
                ? CircleAvatar(
                    backgroundImage: NetworkImage(currentUser!.photoUrl),
                    radius: 25,
                  )
                : CircleAvatar(
                    backgroundColor: Colors.grey[300],
                    radius: 25,
                    child: Icon(Icons.person, color: Colors.grey),
                  ),
            Spacer(),
            Column(
              children: [
                Text(
                  "Localisation",
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 12),
                ),
                Text(
                  _currentAddress ?? "Chargement...",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            Spacer(),
            IconButton(
              icon: Icon(Icons.add_circle, size: 30, color: AppColors.primary),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddPetPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Catégorie",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 12),

            // ✅ Liste des catégories avec icônes
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((cat) {
                  final isSelected = selectedCategory == cat;
                  final icon = categoryIcons[cat] ?? Icons.pets;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedCategory = cat;
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.only(right: 12),
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? AppColors.primary : Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            icon,
                            size: 18,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                          SizedBox(width: 6),
                          Text(
                            cat,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 20),

            Expanded(
              child: FutureBuilder<List<AnimalModel>>(
                future: _fetchAnimals(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text("Aucun animal trouvé"));
                  }

                  final animals = snapshot.data!;
                  return ListView.builder(
                    itemCount: animals.length,
                    itemBuilder: (context, index) {
                      final animal = animals[index];

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
                        distanceText =
                            "à ${distanceInKm.toStringAsFixed(1)} km";
                      }

                      return FutureBuilder<bool>(
                        future: _isFavorite(animal.id),
                        builder: (context, favSnapshot) {
                          final isFav = favSnapshot.data ?? false;

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PetDetailPage(animal: animal),
                                ),
                              );
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
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                                isFav
                                                    ? Icons.favorite
                                                    : Icons.favorite_border,
                                                color: isFav
                                                    ? Colors.red
                                                    : Colors.grey,
                                              ),
                                              onPressed: () =>
                                                  _toggleFavorite(animal.id),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProfilePage()),
            );
          }
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Accueil"),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications), label: "Notifications"),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Chats"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Compte"),
        ],
      ),
    );
  }
}
