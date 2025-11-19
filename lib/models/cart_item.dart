import 'package:hive/hive.dart';
import 'menu_item.dart';

part 'cart_item.g.dart';

@HiveType(typeId: 2)
class CartItem extends HiveObject {
  @HiveField(0)
  final String? id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String menuItemId;

  @HiveField(3)
  final MenuItem menuItem;

  @HiveField(4)
  int quantity;

  @HiveField(5)
  final String? specialInstructions;

  @HiveField(6)
  final DateTime createdAt;

  CartItem({
    this.id,
    required this.userId,
    required this.menuItemId,
    required this.menuItem,
    this.quantity = 1,
    this.specialInstructions,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  CartItem copyWith({
    String? id,
    String? userId,
    String? menuItemId,
    MenuItem? menuItem,
    int? quantity,
    String? specialInstructions,
    DateTime? createdAt,
  }) {
    return CartItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      menuItemId: menuItemId ?? this.menuItemId,
      menuItem: menuItem ?? this.menuItem,
      quantity: quantity ?? this.quantity,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  double get subtotal => menuItem.price * quantity;

  String get formattedSubtotal => 'Rp ${subtotal.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';

  void increaseQuantity() {
    quantity++;
  }

  void decreaseQuantity() {
    if (quantity > 1) {
      quantity--;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'menu_item_id': menuItemId,
      'menu_item': menuItem.toJson(),
      'quantity': quantity,
      'special_instructions': specialInstructions,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id']?.toString(),
      userId: json['user_id'] ?? '',
      menuItemId: json['menu_item_id'] ?? '',
      menuItem: MenuItem.fromJson(json['menu_item'] ?? {}),
      quantity: json['quantity'] ?? 1,
      specialInstructions: json['special_instructions'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}