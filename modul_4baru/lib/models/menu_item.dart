import 'package:hive/hive.dart';

part 'menu_item.g.dart';

@HiveType(typeId: 1)
class MenuItem extends HiveObject {
  @HiveField(0)
  final String? id;

  @HiveField(1)
  final String? categoryId;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String? description;

  @HiveField(4)
  final double price;

  @HiveField(5)
  final String? imageUrl;

  @HiveField(6)
  final bool isAvailable;

  @HiveField(7)
  final int spicyLevel;

  @HiveField(8)
  final String? categoryName;

  @HiveField(9)
  final String? categoryIcon;

  @HiveField(10)
  final DateTime createdAt;

  @HiveField(11)
  final DateTime? updatedAt;

  MenuItem({
    this.id,
    this.categoryId,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    this.isAvailable = true,
    this.spicyLevel = 0,
    this.categoryName,
    this.categoryIcon,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  MenuItem copyWith({
    String? id,
    String? categoryId,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    bool? isAvailable,
    int? spicyLevel,
    String? categoryName,
    String? categoryIcon,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MenuItem(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      spicyLevel: spicyLevel ?? this.spicyLevel,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get formattedPrice => 'Rp ${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';

  String get spicyIndicator => '🌶️' * spicyLevel;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'is_available': isAvailable,
      'spicy_level': spicyLevel,
      'category_name': categoryName,
      'category_icon': categoryIcon,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id']?.toString(),
      categoryId: json['category_id']?.toString(),
      name: json['name'] ?? '',
      description: json['description'],
      price: (json['price'] ?? 0.0).toDouble(),
      imageUrl: json['image_url'],
      isAvailable: json['is_available'] ?? true,
      spicyLevel: json['spicy_level'] ?? 0,
      categoryName: json['category_name'],
      categoryIcon: json['category_icon'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }
}