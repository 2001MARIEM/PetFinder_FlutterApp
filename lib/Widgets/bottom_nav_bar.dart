// lib/widgets/bottom_nav_bar.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../views/home/home_page.dart';
import '../views/home/profile_page.dart';
import '../views/Chat/chats_list_page.dart';
import '../views/favorite/favorites_page.dart';

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
      // Notifications - désactivé
      return;
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
