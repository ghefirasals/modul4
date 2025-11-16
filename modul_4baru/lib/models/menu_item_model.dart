class MenuItemModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String image;
  bool favorite;

  MenuItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.image,
    this.favorite = false,
  });

  factory MenuItemModel.fromMap(Map<String, dynamic> json) {
    return MenuItemModel(
      id: json['id'].toString(),
      name: json['name'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      image: json['image'],
      favorite: json['favorite'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'image': image,
      'favorite': favorite,
    };
  }
}
