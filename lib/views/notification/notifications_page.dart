// lib/views/notifications/notifications_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_colors.dart';
import '../../Widgets/bottom_nav_bar.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final currentUserId = FirebaseAuth.instance.currentUser!.uid;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Mes notifications'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('userId', isEqualTo: currentUserId)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                      child: Text('Erreur: ${snapshot.error.toString()}'));
                }

                final notifications = snapshot.data?.docs ?? [];

                if (notifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_off,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Aucune notification',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Vous recevrez des notifications lorsque quelqu\'un\ninteragira avec vos annonces ou vos messages',
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

                return ListView.builder(
                  itemCount: notifications.length,
                  padding: EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final notification =
                        notifications[index].data() as Map<String, dynamic>;
                    final notificationId = notifications[index].id;

                    final title = notification['title'] ?? 'Notification';
                    final message = notification['message'] ?? '';
                    final timestamp = notification['createdAt'] as Timestamp?;
                    final isRead = notification['read'] ?? false;
                    final type = notification['type'] ?? 'general';
                    final relatedId = notification['relatedId'] ?? '';

                    // Formatage de la date
                    final date =
                        timestamp != null ? _formatTimestamp(timestamp) : '';

                    // Déterminer l'icône en fonction du type
                    IconData notificationIcon;
                    Color iconColor;

                    switch (type) {
                      case 'chat':
                        notificationIcon = Icons.chat;
                        iconColor = Colors.blue;
                        break;
                      case 'like':
                        notificationIcon = Icons.favorite;
                        iconColor = Colors.red;
                        break;
                      case 'adoption':
                        notificationIcon = Icons.pets;
                        iconColor = Colors.green;
                        break;
                      default:
                        notificationIcon = Icons.notifications;
                        iconColor = AppColors.primary;
                    }

                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () => _handleNotificationTap(
                          notificationId,
                          type,
                          relatedId,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: isRead
                                ? Colors.white
                                : Colors.blue.withOpacity(0.05),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Icône
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: iconColor.withOpacity(0.1),
                                ),
                                child: Icon(
                                  notificationIcon,
                                  size: 28,
                                  color: iconColor,
                                ),
                              ),
                              SizedBox(width: 16),

                              // Contenu
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: isRead
                                            ? FontWeight.normal
                                            : FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      message,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      date,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Bouton pour marquer comme lu ou supprimer
                              if (!isRead)
                                IconButton(
                                  icon: Icon(Icons.check_circle_outline),
                                  color: AppColors.primary,
                                  onPressed: () => _markAsRead(notificationId),
                                )
                              else
                                IconButton(
                                  icon: Icon(Icons.delete_outline),
                                  color: Colors.red,
                                  onPressed: () =>
                                      _deleteNotification(notificationId),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 2, // Index pour Notifications
        context: context,
      ),
    );
  }

  // Fonction pour formater la date
  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return 'À l\'instant';
    } else if (diff.inHours < 1) {
      final minutes = diff.inMinutes;
      return 'Il y a $minutes minute${minutes > 1 ? 's' : ''}';
    } else if (diff.inDays < 1) {
      final hours = diff.inHours;
      return 'Il y a $hours heure${hours > 1 ? 's' : ''}';
    } else if (diff.inDays == 1) {
      return 'Hier';
    } else if (diff.inDays < 7) {
      final days = diff.inDays;
      return 'Il y a $days jour${days > 1 ? 's' : ''}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Gérer le tap sur une notification
  void _handleNotificationTap(
      String notificationId, String type, String relatedId) async {
    // Marquer la notification comme lue
    await _markAsRead(notificationId);

    // Navuguer vers la page appropriée en fonction du type
    if (type == 'chat' && relatedId.isNotEmpty) {
      // Logique pour naviguer vers la conversation
      _navigateToChat(relatedId);
    } else if (type == 'adoption' && relatedId.isNotEmpty) {
      // Logique pour naviguer vers l'annonce d'adoption
      _navigateToAnimalDetails(relatedId);
    }
    // Ajouter d'autres types au besoin
  }

  // Marquer une notification comme lue
  Future<void> _markAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      print('Erreur lors du marquage de la notification: $e');
    }
  }

  // Supprimer une notification
  Future<void> _deleteNotification(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Notification supprimée'),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Erreur lors de la suppression de la notification: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la suppression'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Naviguer vers une conversation
  void _navigateToChat(String chatId) {
    // Implémentez la navigation vers la chat page avec l'ID spécifique
    // Cette fonction dépendra de votre structure de navigation
    print('Naviguer vers la conversation: $chatId');
  }

  // Naviguer vers les détails d'un animal
  void _navigateToAnimalDetails(String animalId) {
    // Implémentez la navigation vers la page de détails d'un animal
    // Cette fonction dépendra de votre structure de navigation
    print('Naviguer vers les détails de l\'animal: $animalId');
  }
}
