import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/menu_item.dart';
import '../../models/cart_item.dart';
import '../../services/cart_service.dart';

class RestaurantView extends StatefulWidget {
  const RestaurantView({super.key});

  @override
  State<RestaurantView> createState() => _RestaurantViewState();
}

class _RestaurantViewState extends State<RestaurantView> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final RxString _searchQuery = ''.obs;
  late CartService _cartService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _cartService = Get.find<CartService>();
    _searchController.addListener(() {
      _searchQuery.value = _searchController.text;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<MenuItem> get _sampleMenu => [
    MenuItem(
      id: '1',
      name: 'Nasi Putih',
      description: 'Nasi putih hangat',
      price: 8000,
      categoryName: 'Nasi',
      spicyLevel: 0,
      isAvailable: true,
      imageUrl: null,
    ),
    MenuItem(
      id: '2',
      name: 'Rendang Padang',
      description: 'Rendang daging sapi empuk',
      price: 35000,
      categoryName: 'Lauk',
      spicyLevel: 3,
      isAvailable: true,
      imageUrl: null,
    ),
    MenuItem(
      id: '3',
      name: 'Ayam Pop',
      description: 'Ayam goreng khas Padang',
      price: 25000,
      categoryName: 'Lauk',
      spicyLevel: 0,
      isAvailable: true,
      imageUrl: null,
    ),
    MenuItem(
      id: '4',
      name: 'Gulai Kambing',
      description: 'Gulai kambing dengan bumbu khas',
      price: 40000,
      categoryName: 'Lauk',
      spicyLevel: 4,
      isAvailable: true,
      imageUrl: null,
    ),
    MenuItem(
      id: '5',
      name: 'Telur Balado',
      description: 'Telur dengan sambal merah',
      price: 15000,
      categoryName: 'Lauk',
      spicyLevel: 3,
      isAvailable: true,
      imageUrl: null,
    ),
    MenuItem(
      id: '6',
      name: 'Sayur Ubi',
      description: 'Sayur ubi dengan santan',
      price: 12000,
      categoryName: 'Sayur',
      spicyLevel: 0,
      isAvailable: true,
      imageUrl: null,
    ),
    MenuItem(
      id: '7',
      name: 'Daun Singkong',
      description: 'Daun singkong tumis',
      price: 10000,
      categoryName: 'Sayur',
      spicyLevel: 2,
      isAvailable: true,
      imageUrl: null,
    ),
    MenuItem(
      id: '8',
      name: 'Teh Manis',
      description: 'Teh manis dingin',
      price: 5000,
      categoryName: 'Minuman',
      spicyLevel: 0,
      isAvailable: true,
      imageUrl: null,
    ),
    MenuItem(
      id: '9',
      name: 'Sambal Hijau',
      description: 'Sambal cabai hijau',
      price: 3000,
      categoryName: 'Sambal',
      spicyLevel: 4,
      isAvailable: true,
      imageUrl: null,
    ),
    MenuItem(
      id: '10',
      name: 'Sambal Merah',
      description: 'Sambal cabai merah',
      price: 3000,
      categoryName: 'Sambal',
      spicyLevel: 3,
      isAvailable: true,
      imageUrl: null,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown[50],
      appBar: AppBar(
        title: const Text(
          '🍛 Nasi Padang Online',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.brown[700],
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
          tooltip: 'Kembali',
        ),
      ),
      body: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.brown[700]!,
                  Colors.brown[500]!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                // Restaurant Header
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.restaurant,
                        size: 32,
                        color: Colors.brown,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nasi Padang Sedap',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '🍛 Authentic Padang Cuisine',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 16),
                              Text(
                                ' 4.8 (2.3k reviews)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Obx(() => Stack(
                      children: [
                        IconButton(
                          onPressed: () => _showCart(),
                          icon: const Icon(
                            Icons.shopping_cart,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        if (_cartService.itemCount > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                '${_cartService.itemCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    )),
                  ],
                ),
                const SizedBox(height: 16),

                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search menu...',
                    hintStyle: TextStyle(color: Colors.brown[200]),
                    prefixIcon: Icon(Icons.search, color: Colors.brown[200]),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Category Tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Colors.brown[700],
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.brown[700],
              tabs: const [
                Tab(text: '🍚 Nasi'),
                Tab(text: '🥩 Lauk'),
                Tab(text: '🥬 Sayur'),
                Tab(text: '🥤 Minuman'),
                Tab(text: '🌶️ Sambal'),
              ],
            ),
          ),

          // Menu List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMenuList('Nasi'),
                _buildMenuList('Lauk'),
                _buildMenuList('Sayur'),
                _buildMenuList('Minuman'),
                _buildMenuList('Sambal'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuList(String category) {
    return Obx(() {
      final filteredMenu = _sampleMenu.where((item) {
        final matchesCategory = item.categoryName == category;
        final matchesSearch = _searchQuery.value.isEmpty ||
            item.name.toLowerCase().contains(_searchQuery.value.toLowerCase()) ||
            (item.description?.toLowerCase().contains(_searchQuery.value.toLowerCase()) ?? false);
        return matchesCategory && matchesSearch;
      }).toList();

      if (filteredMenu.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.restaurant_menu,
                size: 64,
                color: Colors.brown[300],
              ),
              const SizedBox(height: 16),
              Text(
                'No $category items found',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.brown[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.value.isEmpty
                    ? 'Check back later for more options'
                    : 'Try a different search term',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.brown[400],
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredMenu.length,
        itemBuilder: (context, index) {
          final item = filteredMenu[index];
          return _buildMenuItemCard(item);
        },
      );
    });
  }

  Widget _buildMenuItemCard(MenuItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image placeholder
            Container(
              width: 100,
              decoration: BoxDecoration(
                color: Colors.brown[100],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              child: Center(
                child: Icon(
                  _getCategoryIcon(item.categoryName!),
                  size: 40,
                  color: Colors.brown[400],
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Item details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and spicy level
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (item.spicyLevel > 0) ...[
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                              5,
                              (index) => Icon(
                                Icons.whatshot,
                                size: 14,
                                color: index < item.spicyLevel
                                    ? _getSpicyColor(index)
                                    : Colors.grey[300],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Description
                    Text(
                      item.description ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // Price and add button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Rp ${item.price.toString()}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.brown[700],
                          ),
                        ),
                        if (item.isAvailable)
                          ElevatedButton(
                            onPressed: () => _addToCart(item),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.brown[600],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            child: const Text('Add'),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Sold Out',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Nasi':
        return Icons.rice_bowl;
      case 'Lauk':
        return Icons.lunch_dining;
      case 'Sayur':
        return Icons.eco;
      case 'Minuman':
        return Icons.local_cafe;
      case 'Sambal':
        return Icons.local_fire_department;
      default:
        return Icons.restaurant;
    }
  }

  Color _getSpicyColor(int level) {
    switch (level) {
      case 0:
        return Colors.grey[300]!;
      case 1:
        return Colors.yellow[600]!;
      case 2:
        return Colors.orange[400]!;
      case 3:
        return Colors.orange[600]!;
      case 4:
        return Colors.red[400]!;
      case 5:
        return Colors.red[700]!;
      default:
        return Colors.grey[300]!;
    }
  }

  void _addToCart(MenuItem item) {
    _cartService.addToCart(item);
  }

  void _showCart() {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.shopping_cart),
            const SizedBox(width: 8),
            const Text('Your Cart'),
            const Spacer(),
            TextButton(
              onPressed: () => _cartService.clearCart(),
              child: const Text('Clear All'),
            ),
          ],
        ),
        content: SizedBox(
          width: Get.width * 0.9,
          height: Get.height * 0.7,
          child: Obx(() {
            if (_cartService.cartItems.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Your cart is empty',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Add some delicious items!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                // Cart items
                Expanded(
                  child: ListView.builder(
                    itemCount: _cartService.cartItems.length,
                    itemBuilder: (context, index) {
                      final cartItem = _cartService.cartItems[index];
                      return _buildCartItemCard(cartItem);
                    },
                  ),
                ),
                const Divider(height: 32),
                // Summary
                _buildCheckoutSummary(),
              ],
            );
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
          Obx(() => ElevatedButton(
            onPressed: _cartService.cartItems.isEmpty
                ? null
                : () {
                    Get.back();
                    _showCheckout();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Checkout'),
          )),
        ],
      ),
    );
  }

  Widget _buildCartItemCard(CartItem cartItem) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Item info
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cartItem.menuItem.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    cartItem.menuItem.description ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Rp ${cartItem.menuItem.price.toString()}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.brown[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // Quantity controls
            Expanded(
              flex: 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () {
                      if (cartItem.quantity > 1) {
                        _cartService.updateQuantity(cartItem.id ?? '', cartItem.quantity - 1);
                      }
                    },
                    icon: const Icon(Icons.remove_circle_outline),
                    iconSize: 28,
                    color: Colors.brown[600],
                  ),
                  Container(
                    width: 40,
                    alignment: Alignment.center,
                    child: Text(
                      cartItem.quantity.toString(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      _cartService.updateQuantity(cartItem.id ?? '', cartItem.quantity + 1);
                    },
                    icon: const Icon(Icons.add_circle_outline),
                    iconSize: 28,
                    color: Colors.brown[600],
                  ),
                  IconButton(
                    onPressed: () {
                      _cartService.removeFromCart(cartItem.id ?? '');
                    },
                    icon: const Icon(Icons.delete_outline),
                    iconSize: 24,
                    color: Colors.red[400],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutSummary() {
    final summary = _cartService.getCheckoutSummary();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.brown[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.brown[200]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal (${_cartService.itemCount} items):'),
              Text('Rp ${summary['subtotal'].toStringAsFixed(0)}'),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tax (10%):'),
              Text('Rp ${summary['tax'].toStringAsFixed(0)}'),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Delivery Fee:'),
              Text('Rp ${summary['delivery_fee'].toStringAsFixed(0)}'),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                'Rp ${summary['total'].toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.brown[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCheckout() {
    final summary = _cartService.getCheckoutSummary();

    Get.dialog(
      AlertDialog(
        title: const Text('Checkout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order Summary:'),
            const SizedBox(height: 8),
            ..._cartService.cartItems.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text('${item.quantity}x ${item.menuItem.name}'),
                  ),
                  Text('Rp ${(item.menuItem.price * item.quantity).toString()}'),
                ],
              ),
            )),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Rp ${summary['total'].toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _cartService.clearCart();
              Get.back();
              Get.snackbar(
                'Order Placed!',
                'Your order has been placed successfully',
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Place Order'),
          ),
        ],
      ),
    );
  }
}