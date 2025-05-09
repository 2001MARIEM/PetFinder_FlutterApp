import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import './chat_page.dart';
import '../../models/animal_model.dart';
import '../../Widgets/bottom_nav_bar.dart';

class ChatsListPage extends StatefulWidget {
  const ChatsListPage({Key? key}) : super(key: key);

  @override
  _ChatsListPageState createState() => _ChatsListPageState();
}

class _ChatsListPageState extends State<ChatsListPage> {
  final currentUserId = FirebaseAuth.instance.currentUser!.uid;
  bool _isLoading = false;
void _showDeleteConfirmation(
      BuildContext context, String chatId, String animalName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Supprimer la discussion'),
          content: Text(
              'Voulez-vous vraiment supprimer votre discussion avec $animalName ?'),
          actions: <Widget>[
            TextButton(
              child: Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                'Supprimer',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteChat(chatId);
              },
            ),
          ],
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Mes discussions'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .where('participants', arrayContains: currentUserId)
                  .orderBy('lastMessageTime', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                      child: Text('Erreur: ${snapshot.error.toString()}'));
                }

                final chatDocs = snapshot.data?.docs ?? [];

                if (chatDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Aucune discussion en cours',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Discutez avec des propriétaires d\'animaux\nen cliquant sur l\'icône de chat sur la page des détails',
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
                  itemCount: chatDocs.length,
                  itemBuilder: (context, index) {
                    final chatDoc =
                        chatDocs[index].data() as Map<String, dynamic>;
                    final chatId = chatDocs[index].id;

                    // Obtenir les infos de l'autre participant
                    final participants =
                        List<String>.from(chatDoc['participants'] ?? []);
                    final otherParticipantId = participants.firstWhere(
                      (id) => id != currentUserId,
                      orElse: () => 'unknown',
                    );

                    final participantNames =
                        chatDoc['participantNames'] as Map<String, dynamic>?;
                    final otherParticipantName =
                        participantNames?[otherParticipantId] ?? 'Utilisateur';

                    final participantPhotos =
                        chatDoc['participantPhotos'] as Map<String, dynamic>?;
                    final otherParticipantPhoto =
                        participantPhotos?[otherParticipantId] ?? '';

                    final lastMessage = chatDoc['lastMessage'] ?? '';
                    final lastMessageSenderId =
                        chatDoc['lastMessageSenderId'] ?? '';
                    final isLastMessageMine =
                        lastMessageSenderId == currentUserId;

                    final timestamp = chatDoc['lastMessageTime'] as Timestamp?;
                    final formattedTime =
                        timestamp != null ? _formatTimestamp(timestamp) : '';

                    final animalId = chatDoc['animalId'] ?? '';
                    final animalName = chatDoc['animalName'] ?? 'Animal';
                    final animalImage = chatDoc['animalImage'] ?? '';

                    // Obtenir le nombre de messages non lus
                    final unreadCounts =
                        chatDoc['unreadCount'] as Map<String, dynamic>? ?? {};
                    final unreadCount = unreadCounts[currentUserId] ?? 0;

                    // Vérifier si l'autre utilisateur est en train d'écrire
                    final typingUsers =
                        chatDoc['typingUsers'] as Map<String, dynamic>? ?? {};
                    final isOtherUserTyping =
                        typingUsers[otherParticipantId] == true;

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () =>
                            _navigateToChat(animalId, otherParticipantId),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Image de l'animal avec badge pour messages non lus
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(30),
                                    child: Image.network(
                                      animalImage,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          width: 60,
                                          height: 60,
                                          color: Colors.grey[300],
                                          child: Icon(
                                            Icons.pets,
                                            color: Colors.grey[500],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  if (unreadCount > 0)
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: Container(
                                        padding: EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: BoxConstraints(
                                          minWidth: 20,
                                          minHeight: 20,
                                        ),
                                        child: Center(
                                          child: Text(
                                            unreadCount.toString(),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(width: 16),
                              // Infos de la conversation
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                   Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          animalName,
                                          style: TextStyle(
                                            fontWeight: unreadCount > 0
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              formattedTime,
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            // Bouton de suppression carré rouge
                                            Container(
                                              width: 26,
                                              height: 26,
                                              decoration: BoxDecoration(
                                                color: Colors.red,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  onTap: () =>
                                                      _showDeleteConfirmation(
                                                          context,
                                                          chatId,
                                                          animalName),
                                                  child: Icon(
                                                    Icons.delete_outline,
                                                    size: 16,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        // Text(
                                        //   formattedTime,
                                        //   style: TextStyle(
                                        //     color: Colors.grey[600],
                                        //     fontSize: 12,
                                        //   ),
                                        // ),
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                    // Photo et nom de l'autre participant
                                    Row(
                                      children: [
                                        if (otherParticipantPhoto.isNotEmpty)
                                          CircleAvatar(
                                            radius: 10,
                                            backgroundImage: NetworkImage(
                                                otherParticipantPhoto),
                                          )
                                        else
                                          CircleAvatar(
                                            radius: 10,
                                            backgroundColor: AppColors.accent,
                                            child: Icon(
                                              Icons.person,
                                              size: 10,
                                              color: Colors.white,
                                            ),
                                          ),
                                        SizedBox(width: 8),
                                        Text(
                                          otherParticipantName,
                                          style: TextStyle(
                                            fontWeight: unreadCount > 0
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                            color: AppColors.accent,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    // Indicateur de frappe ou dernier message
                                    isOtherUserTyping
                                        ? Row(
                                            children: [
                                              Text(
                                                'En train d\'écrire...',
                                                style: TextStyle(
                                                  fontStyle: FontStyle.italic,
                                                  color: AppColors.primary,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              SizedBox(width: 4),
                                              SizedBox(
                                                width: 12,
                                                height: 12,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation
                                                          <Color>(
                                                    AppColors.primary ),
                                                ),
                                              ),
                                            ],
                                          )
                                        : Row(
                                            children: [
                                              if (isLastMessageMine)
                                                Padding(
                                                  padding:
                                                      EdgeInsets.only(right: 4),
                                                  child: Icon(
                                                    Icons.done_all,
                                                    size: 14,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              Expanded(
                                                child: Text(
                                                  lastMessage,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: unreadCount > 0
                                                        ? AppColors.textPrimary
                                                        : Colors.grey[600],
                                                    fontWeight: unreadCount > 0
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                  ),
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
                );
              },
            ),
            bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 3, // Index pour Chats
        context: context,
      ),
            
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      // Aujourd'hui, afficher l'heure
      return DateFormat('HH:mm').format(date);
    } else if (diff.inDays == 1) {
      // Hier
      return 'Hier';
    } else if (diff.inDays < 7) {
      // Cette semaine
      final frenchLocale = 'fr';
      try {
        return DateFormat('EEEE', frenchLocale).format(date);
      } catch (e) {
        // Fallback si le locale français n'est pas disponible
        return DateFormat('EEEE').format(date);
      }
    } else {
      // Plus ancien
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }
Future<void> _deleteChat(String chatId) async {
    try {
      // On commence par récupérer tous les messages de cette conversation
      final messagesSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();

      // On utilise une transaction pour s'assurer que tout est supprimé correctement
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Supprimer tous les messages dans la sous-collection
        for (final doc in messagesSnapshot.docs) {
          transaction.delete(doc.reference);
        }

        // Supprimer le document principal de la conversation
        transaction
            .delete(FirebaseFirestore.instance.collection('chats').doc(chatId));
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Discussion supprimée'),
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
  Future<void> _navigateToChat(String animalId, String ownerId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Récupérer les détails de l'animal
      final animalDoc = await FirebaseFirestore.instance
          .collection('animals')
          .doc(animalId)
          .get();

      if (!animalDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Animal introuvable')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final animalData = animalDoc.data()!;
      final animal = AnimalModel.fromMap(animalData, animalId);

      // Naviguer vers la page de chat
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPage(
            animal: animal,
            ownerId: ownerId,
          ),
        ),
      ).then((_) {
        // Rafraîchir l'état après retour de la page de chat
        setState(() {});
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}