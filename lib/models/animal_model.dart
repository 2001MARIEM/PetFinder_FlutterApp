class AnimalModel {
  final String id;
  final String name;
  final String age;
  final String sex;
  final String description;
  final String imageUrl;
  final String ownerId;
  final String category;
  final double latitude;
  final double longitude;
   // Nouveaux champs
  final String? health; // Ajout du ? pour indiquer que c'est nullable
  final String? race; // Ajout du ? pour indiquer que c'est nullable
  final double? weight;
  AnimalModel({
    required this.id,
    required this.name,
    required this.age,
    required this.sex,
    required this.description,
    required this.imageUrl,
    required this.ownerId,
    required this.category,
    required this.latitude,
    required this.longitude,
    this.health,
    this.race,
    this.weight,
  });

  factory AnimalModel.fromMap(Map<String, dynamic> map, String id) {
    return AnimalModel(
      id: id,
      name: map['name'],
      age: map['age'],
      sex: map['sex'],
      description: map['description'],
      imageUrl: map['imageUrl'],
      ownerId: map['ownerId'],
      category: map['category'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      
    health: map['health'] ,
    race: map['race'] ,
    weight: (map['weight'] ?? 0.0).toDouble(),
    );
  }
}
