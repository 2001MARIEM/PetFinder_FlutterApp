class UserModel {
  final String uid;
  final String nom;
  final String prenom;
  final String telephone;
  final String email;
  final String image;

  UserModel({
    required this.uid,
    required this.nom,
    required this.prenom,
    required this.telephone,
    required this.email,
    required this.image,
  });

  // Convertir une Map (Firestore) en UserModel
  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: documentId,
      nom: map['nom'] ?? '',
      prenom: map['prenom'] ?? '',
      telephone: map['telephone'] ?? '',
      email: map['email'] ?? '',
      image: map['image'] ?? '',
    );
  }

  // Convertir UserModel en Map (pour Firestore)
  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'prenom': prenom,
      'telephone': telephone,
      'email': email,
      'image': image,
    };
  }
}
