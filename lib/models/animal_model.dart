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
    );
  }
}
