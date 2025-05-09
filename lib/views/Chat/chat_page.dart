import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/animal_model.dart';
import '../../theme/app_colors.dart';

class ChatPage extends StatefulWidget {
  final AnimalModel animal;
  final String ownerId; // ID du propriétaire de l'animal

  const ChatPage({
    Key? key,
    required this.animal,
    required this.ownerId,
  }) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  String? _currentUserId;
  String? _chatId;
  bool _isTyping = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _initChat().then((_) {
      _markMessagesAsRead();
    });
  }

  Future<void> _initChat() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Récupérer l'utilisateur actuel
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception("Utilisateur non connecté");
      }

      _currentUserId = currentUser.uid;

      // Créer ou récupérer l'ID unique du chat
      // Nous trions les IDs pour que le chatId soit toujours le même entre ces deux utilisateurs
      List<String> ids = [_currentUserId!, widget.ownerId];
      ids.sort(); // Tri pour garantir la cohérence
      _chatId = ids.join('_');

      // Vérifier si le chat existe déjà, sinon le créer
      final chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(_chatId)
          .get();

      if (!chatDoc.exists) {
        // Récupérer les informations des utilisateurs pour initialiser le chat
        final currentUserData = await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUserId)
            .get();

        final ownerData = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.ownerId)
            .get();

        // Créer le document de chat
        await FirebaseFirestore.instance.collection('chats').doc(_chatId).set({
          'participants': [_currentUserId, widget.ownerId],
          'participantNames': {
            _currentUserId:
                '${currentUserData['prenom']} ${currentUserData['nom']}',
            widget.ownerId: '${ownerData['prenom']} ${ownerData['nom']}',
          },
          'participantPhotos': {
            _currentUserId: currentUserData['photoUrl'] ?? '',
            widget.ownerId: ownerData['photoUrl'] ?? '',
          },
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastMessageSenderId': '', // Nouvel attribut
          'animalId': widget.animal.id,
          'animalName': widget.animal.name,
          'animalImage': widget.animal.imageUrl,
          'animalOwnerId': widget.animal.ownerId, // Nouvel attribut
          'initiatorId': _currentUserId, // Nouvel attribut
          'createdAt': FieldValue.serverTimestamp(),
          'unreadCount': {
            // Nouvel attribut
            _currentUserId: 0,
            widget.ownerId: 0,
          },
          'typingUsers': {
            // Nouvel attribut
            _currentUserId: false,
            widget.ownerId: false,
          },
        });
      }
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

  // Nouvelle méthode pour gérer l'état de frappe
  void _updateTypingStatus(bool isTyping) {
    if (_isTyping != isTyping) {
      setState(() {
        _isTyping = isTyping;
      });

      try {
        FirebaseFirestore.instance.collection('chats').doc(_chatId).update({
          'typingUsers.${_currentUserId}': isTyping,
        });
      } catch (e) {
        print(
            'Erreur lors de la mise à jour du statut de frappe: ${e.toString()}');
      }
    }
  }

  // Nouvelle méthode pour marquer les messages comme lus
  Future<void> _markMessagesAsRead() async {
    try {
      // Obtenir tous les messages non lus envoyés par l'autre utilisateur
      final unreadMessages = await FirebaseFirestore.instance
          .collection('chats')
          .doc(_chatId)
          .collection('messages')
          .where('senderId', isEqualTo: widget.ownerId)
          .where('read', isEqualTo: false)
          .get();

      // Marquer chaque message comme lu
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'read': true});
      }

      // Exécuter le batch
      await batch.commit();

      // Réinitialiser le compteur de messages non lus pour l'utilisateur actuel
      await FirebaseFirestore.instance.collection('chats').doc(_chatId).update({
        'unreadCount.${_currentUserId}': 0,
      });
    } catch (e) {
      print('Erreur lors du marquage des messages comme lus: ${e.toString()}');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final message = _messageController.text.trim();
    _messageController.clear();

    // Réinitialiser le statut de frappe
    _updateTypingStatus(false);
    _typingTimer?.cancel();

    try {
      // Ajouter le message à la collection des messages avec statut de lecture
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(_chatId)
          .collection('messages')
          .add({
        'text': message,
        'senderId': _currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false, // Nouveau champ
      });

      // Mettre à jour le dernier message dans le document de chat
      await FirebaseFirestore.instance.collection('chats').doc(_chatId).update({
        'lastMessage': message,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': _currentUserId, // Mise à jour
        'unreadCount.${widget.ownerId}': FieldValue.increment(1), // Mise à jour
      });

      // Faire défiler vers le dernier message
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }

  void _scrollToBottom() {
    // Attendre que la mise à jour du widget soit terminée
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    // Réinitialiser le statut de frappe lors de la fermeture de la page
    if (_isTyping) {
      FirebaseFirestore.instance.collection('chats').doc(_chatId).update({
        'typingUsers.${_currentUserId}': false,
      });
    }

    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(widget.animal.imageUrl),
              radius: 20,
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.animal.name,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(widget.ownerId)
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Text('Chargement...',
                          style: TextStyle(fontSize: 12));
                    }

                    if (snapshot.hasError || !snapshot.hasData) {
                      return Text('Propriétaire',
                          style: TextStyle(fontSize: 12));
                    }

                    final userData =
                        snapshot.data!.data() as Map<String, dynamic>?;
                    if (userData == null) {
                      return Text('Propriétaire',
                          style: TextStyle(fontSize: 12));
                    }

                    return Text(
                      '${userData['prenom'] ?? ''} ${userData['nom'] ?? ''}',
                      style: TextStyle(fontSize: 12),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Zone des messages
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('chats')
                        .doc(_chatId)
                        .collection('messages')
                        .orderBy('timestamp')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          !snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                            child: Text('Erreur de chargement des messages'));
                      }

                      final messages = snapshot.data?.docs ?? [];

                      if (messages.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.pets,
                                size: 60,
                                color: AppColors.primary.withOpacity(0.5),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Démarrez la conversation à propos de ${widget.animal.name}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Faire défiler vers le bas après le chargement des messages
                      _scrollToBottom();

                      return ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message =
                              messages[index].data() as Map<String, dynamic>;
                          final bool isMe =
                              message['senderId'] == _currentUserId;
                          final timestamp = message['timestamp'] as Timestamp?;
                          final isRead = message['read'] ?? false;

                          return _buildMessageBubble(
                            message: message['text'] ?? '',
                            isMe: isMe,
                            timestamp: timestamp,
                            isRead: isRead,
                          );
                        },
                      );
                    },
                  ),
                ),

                // Indicateur de frappe (nouveau)
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('chats')
                      .doc(_chatId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      final chatData =
                          snapshot.data!.data() as Map<String, dynamic>?;
                      final typingUsers =
                          chatData?['typingUsers'] as Map<String, dynamic>? ??
                              {};
                      final isOtherUserTyping =
                          typingUsers[widget.ownerId] == true;

                      if (isOtherUserTyping) {
                        return Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              Text(
                                'En train d\'écrire...',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              SizedBox(width: 8),
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    }

                    return SizedBox.shrink();
                  },
                ),

                // Zone de saisie du message
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Bouton pour ajouter une image (optionnel)
                      IconButton(
                        icon: Icon(Icons.photo, color: AppColors.primary),
                        onPressed: () {
                          // Implémentation future: ajouter des images
                        },
                      ),
                      // Champ de texte avec détection de frappe
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Votre message...',
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[200],
                          ),
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                          onChanged: (text) {
                            // Réinitialiser le timer à chaque frappe
                            _typingTimer?.cancel();

                            if (text.isNotEmpty && !_isTyping) {
                              _updateTypingStatus(true);
                            }

                            // Définir un timer pour arrêter l'état de frappe après 2 secondes d'inactivité
                            _typingTimer = Timer(Duration(seconds: 2), () {
                              if (_isTyping) {
                                _updateTypingStatus(false);
                              }
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 8),
                      // Bouton d'envoi
                      Material(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(30),
                        child: InkWell(
                          onTap: _sendMessage,
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            padding: EdgeInsets.all(10),
                            child: Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMessageBubble({
    required String message,
    required bool isMe,
    Timestamp? timestamp,
    bool isRead = false,
  }) {
    final time =
        timestamp != null ? DateFormat('HH:mm').format(timestamp.toDate()) : '';

    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.ownerId)
                  .get(),
              builder: (context, snapshot) {
                String? photoUrl;
                if (snapshot.hasData && snapshot.data != null) {
                  final userData =
                      snapshot.data!.data() as Map<String, dynamic>?;
                  photoUrl = userData?['photoUrl'];
                }

                return CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.accent,
                  backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                      ? NetworkImage(photoUrl)
                      : null,
                  child: photoUrl == null || photoUrl.isEmpty
                      ? Icon(Icons.person, size: 16, color: Colors.white)
                      : null,
                );
              },
            ),
          SizedBox(width: isMe ? 0 : 8),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? AppColors.primary : Colors.grey[200],
                    borderRadius: BorderRadius.circular(18).copyWith(
                      bottomRight: isMe ? Radius.circular(0) : null,
                      bottomLeft: !isMe ? Radius.circular(0) : null,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message,
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.black,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            time,
                            style: TextStyle(
                              color: isMe
                                  ? Colors.white.withOpacity(0.7)
                                  : Colors.grey[600],
                              fontSize: 10,
                            ),
                          ),
                          if (isMe) ...[
                            SizedBox(width: 4),
                            Icon(
                              isRead ? Icons.done_all : Icons.done,
                              size: 12,
                              color: isMe
                                  ? Colors.white.withOpacity(0.7)
                                  : Colors.grey[600],
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: isMe ? 8 : 0),
          if (isMe)
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(_currentUserId)
                  .get(),
              builder: (context, snapshot) {
                String? photoUrl;
                if (snapshot.hasData && snapshot.data != null) {
                  final userData =
                      snapshot.data!.data() as Map<String, dynamic>?;
                  photoUrl = userData?['photoUrl'];
                }

                return CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary,
                  backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                      ? NetworkImage(photoUrl)
                      : null,
                  child: photoUrl == null || photoUrl.isEmpty
                      ? Icon(Icons.person, size: 16, color: Colors.white)
                      : null,
                );
              },
            ),
        ],
      ),
    );
  }
}
