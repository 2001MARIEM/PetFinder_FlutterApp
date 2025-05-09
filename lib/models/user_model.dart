class UserModel {
  final String uid;
  final String nom;
  final String prenom;
  final String telephone;
  final String email;
  final String photoUrl; // ✅ Change "image" → "photoUrl"

  UserModel({
    required this.uid,
    required this.nom,
    required this.prenom,
    required this.telephone,
    required this.email,
    required this.photoUrl,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: documentId,
      nom: map['nom'] ?? '',
      prenom: map['prenom'] ?? '',
      telephone: map['telephone'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'] ?? '', // ✅ CORRECT FIELD
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'prenom': prenom,
      'telephone': telephone,
      'email': email,
      'photoUrl': photoUrl,
    };
  }
}
