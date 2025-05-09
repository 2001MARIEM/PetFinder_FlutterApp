// lib/widgets/bottom_nav_bar.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';
import '../views/home/home_page.dart';
import '../views/home/profile_page.dart';
import '../views/Chat/chats_list_page.dart';
import '../views/favorite/favorites_page.dart';
import '../views/notification/notifications_page.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final BuildContext context;

  const CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.context,
  }) : super(key: key);

  void _handleNavigation(int index) {
    if (index == currentIndex) return;

    if (index == 0) {
      // Home
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => HomePage()),
        (route) => false,
      );
    } else if (index == 1) {
      // Favoris
      if (currentIndex != 1) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => FavoritesPage()),
        );
      }
    } else if (index == 2) {
      // Notifications - activer la navigation
      if (currentIndex != 2) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NotificationsPage()),
        );
      }
    } else if (index == 3) {
      // Chats
      if (currentIndex != 3) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChatsListPage()),
        );
      }
    } else if (index == 4) {
      // Profil
      if (currentIndex != 4) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProfilePage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        // Si l'utilisateur n'est pas connecté, retourner une barre de navigation simple
        return _buildSimpleNavBar();
      }

      // Seulement écouter les notifications non lues pour utilisateurs connectés
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: currentUser.uid)
            .where('read', isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          int unreadNotifications = 0;

          // Compter les notifications non lues
          if (snapshot.hasData) {
            unreadNotifications = snapshot.data!.docs.length;
          }

          return BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: Colors.grey,
            currentIndex: currentIndex,
            onTap: _handleNavigation,
            items: [
              // Accueil
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: "Accueil",
              ),

              // Favoris
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite),
                label: "Favoris",
              ),

              // Notifications avec badge
              BottomNavigationBarItem(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(Icons.notifications),
                    if (unreadNotifications > 0)
                      Positioned(
                        top: -3,
                        right: -3,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                label: "Notifications",
              ),

              // Chats (sans badge)
              BottomNavigationBarItem(
                icon: Icon(Icons.chat),
                label: "Chats",
              ),

              // Compte
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: "Compte",
              ),
            ],
          );
        },
      );
    } catch (e) {
      // En cas d'erreur, retourner une barre de navigation simple
      print("Erreur dans la barre de navigation: $e");
      return _buildSimpleNavBar();
    }
  }

  // Méthode pour construire une barre de navigation simple sans badge
  Widget _buildSimpleNavBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey,
      currentIndex: currentIndex,
      onTap: _handleNavigation,
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Accueil"),
        BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Favoris"),
        BottomNavigationBarItem(
            icon: Icon(Icons.notifications), label: "Notifications"),
        BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Chats"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Compte"),
      ],
    );
  }
}
