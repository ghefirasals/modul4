import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../models/cart_item.dart';
import '../models/menu_item.dart';

class CartService extends GetxService {
  static CartService get to => Get.find();

  late Box<CartItem> _cartBox;
  final RxList<CartItem> _cartItems = <CartItem>[].obs;
  final RxBool _isLoading = false.obs;

  // Getters
  List<CartItem> get cartItems => _cartItems;
  bool get isLoading => _isLoading.value;
  int get itemCount => _cartItems.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => _cartItems.fold(0, (sum, item) => sum + (item.menuItem.price * item.quantity));

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initCartBox();
    await loadCartItems();
  }

  Future<void> _initCartBox() async {
    try {
      _cartBox = await Hive.openBox<CartItem>('cart_items');
      print('✅ Cart box initialized successfully');
    } catch (e) {
      print('❌ Error initializing cart box: $e');
      throw Exception('Failed to initialize cart storage');
    }
  }

  Future<void> loadCartItems() async {
    try {
      _isLoading.value = true;
      _cartItems.clear();
      _cartItems.addAll(_cartBox.values.toList());
      print('✅ Loaded ${_cartItems.length} cart items');
    } catch (e) {
      print('❌ Error loading cart items: $e');
      Get.snackbar(
        'Error',
        'Failed to load cart items',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> addToCart(MenuItem menuItem, {int quantity = 1}) async {
    try {
      // Check if item already exists in cart
      final existingIndex = _cartItems.indexWhere(
        (item) => item.menuItemId == menuItem.id,
      );

      if (existingIndex != -1) {
        // Update quantity if item exists
        final existingItem = _cartItems[existingIndex];
        final updatedItem = existingItem.copyWith(
          quantity: existingItem.quantity + quantity,
        );
        _cartItems[existingIndex] = updatedItem;
        await _cartBox.put(existingItem.id, updatedItem);
      } else {
        // Add new item to cart
        final cartItem = CartItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: 'current_user', // TODO: Get actual user ID
          menuItemId: menuItem.id!,
          menuItem: menuItem,
          quantity: quantity,
        );
        _cartItems.add(cartItem);
        await _cartBox.put(cartItem.id, cartItem);
      }

      Get.snackbar(
        'Added to Cart',
        '${menuItem.name} (${quantity}x) added to cart',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      print('✅ Added $quantity x ${menuItem.name} to cart');
    } catch (e) {
      print('❌ Error adding to cart: $e');
      Get.snackbar(
        'Error',
        'Failed to add item to cart',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> updateQuantity(String cartItemId, int newQuantity) async {
    try {
      if (newQuantity <= 0) {
        await removeFromCart(cartItemId);
        return;
      }

      final index = _cartItems.indexWhere((item) => item.id == cartItemId);
      if (index != -1) {
        final updatedItem = _cartItems[index].copyWith(quantity: newQuantity);
        _cartItems[index] = updatedItem;
        await _cartBox.put(cartItemId, updatedItem);
        print('✅ Updated quantity for cart item: $cartItemId');
      }
    } catch (e) {
      print('❌ Error updating cart quantity: $e');
      Get.snackbar(
        'Error',
        'Failed to update item quantity',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> removeFromCart(String cartItemId) async {
    try {
      await _cartBox.delete(cartItemId);
      _cartItems.removeWhere((item) => item.id == cartItemId);

      Get.snackbar(
        'Removed from Cart',
        'Item removed from cart',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );

      print('✅ Removed item from cart: $cartItemId');
    } catch (e) {
      print('❌ Error removing from cart: $e');
      Get.snackbar(
        'Error',
        'Failed to remove item from cart',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> clearCart() async {
    try {
      await _cartBox.clear();
      _cartItems.clear();

      Get.snackbar(
        'Cart Cleared',
        'All items removed from cart',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );

      print('✅ Cart cleared');
    } catch (e) {
      print('❌ Error clearing cart: $e');
      Get.snackbar(
        'Error',
        'Failed to clear cart',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  double calculateTotal({
    double taxRate = 0.1, // 10% tax
    double deliveryFee = 5000, // Fixed delivery fee
  }) {
    final taxAmount = subtotal * taxRate;
    return subtotal + taxAmount + deliveryFee;
  }

  Map<String, dynamic> getCheckoutSummary({
    double taxRate = 0.1,
    double deliveryFee = 5000,
  }) {
    final taxAmount = subtotal * taxRate;
    final total = subtotal + taxAmount + deliveryFee;

    return {
      'subtotal': subtotal,
      'tax': taxAmount,
      'delivery_fee': deliveryFee,
      'total': total,
      'item_count': itemCount,
    };
  }
}