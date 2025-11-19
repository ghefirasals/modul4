import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/menu_service.dart';
import '../services/cart_service.dart';
import '../services/theme_service.dart';
import '../models/menu_item.dart';
import 'cart_view.dart';

class HomeContentView extends StatefulWidget {
  const HomeContentView({super.key});

  @override
  State<HomeContentView> createState() => _HomeContentViewViewState();
}

class _HomeContentViewViewState extends State<HomeContentView> {
  final MenuService menuService = Get.find<MenuService>();
  final CartService cartService = Get.find<CartService>();
  final ThemeService themeService = Get.find<ThemeService>();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Custom AppBar
        SliverAppBar(
          floating: true,
          pinned: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
          elevation: 0,
          title: const Text('🍛 Nasi Padang'),
          actions: [
            // User info & logout
            UserMenuButton(onLogout: _handleLogout),

            // Theme toggle
            ThemeToggleButton(themeService: themeService),

            // Cart
            CartButton(cartService: cartService),
          ],
        ),

        // Header section
        SliverToBoxAdapter(
          child: _buildHeader(),
        ),

        // Categories section
        SliverToBoxAdapter(
          child: _buildCategories(),
        ),

        // Menu Grid
        SliverFillRemaining(
          child: _buildMenuGrid(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
      child: StreamBuilder(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          final user = Supabase.instance.client.auth.currentUser;
          final userName = user?.userMetadata?['display_name'] ??
                          user?.email?.split('@')[0] ??
                          'Pengunjung';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selamat Datang, $userName!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Silakan pilih menu favorit Anda',
                style: TextStyle(fontSize: 16),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategories() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Obx(() {
        final categories = ['Semua', ...menuService.getAvailableCategories()];
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: FilterChip(
                label: Text(category),
                selected: false,
                onSelected: (bool value) {},
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildMenuGrid() {
    return Obx(() {
      if (menuService.menuItems.isEmpty) {
        return const Center(
          child: Text('Tidak ada menu tersedia'),
        );
      }

      return GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: menuService.menuItems.length,
        itemBuilder: (context, index) {
          final menuItem = menuService.menuItems[index];
          return MenuItemCard(
            menuItem: menuItem,
            onAddToCart: () {
              cartService.addToCart(menuItem);
            },
          );
        },
      );
    });
  }

  Future<void> _handleLogout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      Get.snackbar(
        '✅ Berhasil',
        'Logout berhasil!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      Get.offAllNamed('/login');
    } catch (e) {
      Get.snackbar(
        '❌ Error',
        'Gagal logout',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}

// Separate Widget for User Menu
class UserMenuButton extends StatelessWidget {
  final VoidCallback onLogout;

  const UserMenuButton({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final userName = user?.userMetadata?['display_name'] ??
                    user?.email?.split('@')[0] ??
                    'User';
    final userEmail = user?.email ?? '';

    return PopupMenuButton<String>(
      icon: CircleAvatar(
        radius: 16,
        backgroundColor: Colors.white,
        child: Text(
          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
          style: const TextStyle(
            color: Color(0xFFD84315),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
      onSelected: (value) {
        if (value == 'logout') {
          onLogout();
        }
      },
      itemBuilder: (BuildContext context) {
        return [
          PopupMenuItem<String>(
            enabled: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD84315),
                  ),
                ),
                Text(
                  userEmail,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem<String>(
            value: 'logout',
            child: Row(
              children: const [
                Icon(Icons.logout, color: Colors.red),
                SizedBox(width: 8),
                Text('Logout'),
              ],
            ),
          ),
        ];
      },
    );
  }
}

// Separate Widget for Theme Toggle
class ThemeToggleButton extends StatelessWidget {
  final ThemeService themeService;

  const ThemeToggleButton({super.key, required this.themeService});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return IconButton(
        icon: Icon(
          themeService.isDarkMode ? Icons.light_mode : Icons.dark_mode,
        ),
        onPressed: () => themeService.toggleTheme(),
      );
    });
  }
}

// Separate Widget for Cart Button
class CartButton extends StatelessWidget {
  final CartService cartService;

  const CartButton({super.key, required this.cartService});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Stack(
        children: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () => Get.to(() => const CartView()),
          ),
          if (cartService.itemCount > 0)
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
                  '${cartService.itemCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      );
    });
  }
}

class MenuItemCard extends StatelessWidget {
  final MenuItem menuItem;
  final VoidCallback onAddToCart;

  const MenuItemCard({
    super.key,
    required this.menuItem,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                color: Colors.grey[300],
              ),
              child: const Icon(
                Icons.restaurant,
                size: 48,
                color: Colors.grey,
              ),
            ),
          ),

          // Menu info
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    menuItem.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Spicy indicator
                  Text(
                    menuItem.spicyIndicator,
                    style: const TextStyle(fontSize: 12),
                  ),

                  // Category
                  Text(
                    menuItem.categoryName ?? 'Lainnya',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),

                  const Spacer(),

                  // Price and Add button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        menuItem.formattedPrice,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD84315),
                        ),
                      ),
                      IconButton(
                        onPressed: onAddToCart,
                        icon: const Icon(
                          Icons.add_shopping_cart,
                          color: Color(0xFFD84315),
                        ),
                        iconSize: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}