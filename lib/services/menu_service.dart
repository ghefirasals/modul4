import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/menu_item.dart';

class MenuService extends GetxService {
  static MenuService get to => Get.find();

  late Box<MenuItem> _menuBox;
  final RxList<MenuItem> _menuItems = <MenuItem>[].obs;
  final RxBool _isLoading = false.obs;

  // Getters
  List<MenuItem> get menuItems => _menuItems;
  bool get isLoading => _isLoading.value;

  List<MenuItem> getItemsByCategory(String category) {
    return _menuItems.where((item) => item.categoryName == category).toList();
  }

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initMenuBox();
    await loadMenuItems();
  }

  Future<void> _initMenuBox() async {
    try {
      _menuBox = await Hive.openBox<MenuItem>('menu_items');
      print('✅ Menu box initialized successfully');
    } catch (e) {
      print('❌ Error initializing menu box: $e');
    }
  }

  Future<void> loadMenuItems() async {
    try {
      _isLoading.value = true;

      // Try to load from local storage first
      if (_menuBox.isNotEmpty) {
        _menuItems.clear();
        _menuItems.addAll(_menuBox.values.toList());
        print('✅ Loaded ${_menuItems.length} menu items from local storage');
      } else {
        // Load default items if local storage is empty
        await _loadDefaultMenuItems();
      }

      // Try to sync with Supabase if available
      await _syncWithSupabase();

    } catch (e) {
      print('❌ Error loading menu items: $e');
      // Fallback to default items
      await _loadDefaultMenuItems();
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _loadDefaultMenuItems() async {
    try {
      _menuItems.clear();
      final defaultItems = MenuItem.getDefaultMenuItems();
      _menuItems.addAll(defaultItems);

      // Save to local storage
      await _menuBox.clear();
      for (var item in defaultItems) {
        await _menuBox.put(item.id, item);
      }

      print('✅ Loaded ${defaultItems.length} default menu items');
    } catch (e) {
      print('❌ Error loading default menu items: $e');
    }
  }

  Future<void> _syncWithSupabase() async {
    try {
      final response = await Supabase.instance.client
          .from('menu_items')
          .select()
          .eq('is_available', true);

      if (response.isNotEmpty) {
        final supabaseItems = response.map((json) => MenuItem.fromJson(json)).toList();

        // Update local storage with Supabase data
        await _menuBox.clear();
        _menuItems.clear();

        for (var item in supabaseItems) {
          await _menuBox.put(item.id, item);
          _menuItems.add(item);
        }

        print('✅ Synced ${supabaseItems.length} menu items from Supabase');
      }
    } catch (e) {
      print('⚠️ Could not sync with Supabase (using local data): $e');
    }
  }

  Future<void> refreshMenuItems() async {
    await loadMenuItems();
  }

  MenuItem? getMenuItemById(String? id) {
    if (id == null) return null;
    try {
      return _menuItems.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  List<String> getAvailableCategories() {
    final categories = _menuItems
        .map((item) => item.categoryName ?? 'Other')
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }

  // ========================================
  // CRUD OPERATIONS
  // ========================================

  // CREATE - Add new menu item
  Future<bool> createMenuItem(MenuItem menuItem) async {
    try {
      _isLoading.value = true;

      // Insert into Supabase
      final response = await Supabase.instance.client
          .from('menu_items')
          .insert({
            'name': menuItem.name,
            'description': menuItem.description,
            'price': menuItem.price,
            'category_name': menuItem.categoryName,
            'spicy_level': menuItem.spicyLevel,
            'is_available': menuItem.isAvailable,
            'image_url': menuItem.imageUrl,
          })
          .select()
          .single();

      // Create new MenuItem with returned ID
      final newMenuItem = MenuItem.fromJson(response);

      // Update local storage
      await _menuBox.put(newMenuItem.id, newMenuItem);
      _menuItems.add(newMenuItem);

      print('✅ Menu item created successfully: ${newMenuItem.name}');
      return true;
    } catch (e) {
      print('❌ Error creating menu item: $e');
      Get.snackbar('Error', 'Failed to create menu item: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // UPDATE - Update existing menu item
  Future<bool> updateMenuItem(MenuItem menuItem) async {
    try {
      _isLoading.value = true;

      if (menuItem.id == null) {
        throw Exception('Menu item ID is required for update');
      }

      // Update in Supabase
      final response = await Supabase.instance.client
          .from('menu_items')
          .update({
            'name': menuItem.name,
            'description': menuItem.description,
            'price': menuItem.price,
            'category_name': menuItem.categoryName,
            'spicy_level': menuItem.spicyLevel,
            'is_available': menuItem.isAvailable,
            'image_url': menuItem.imageUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', menuItem.id!)
          .select()
          .single();

      // Create updated MenuItem
      final updatedMenuItem = MenuItem.fromJson(response);

      // Update local storage
      await _menuBox.put(updatedMenuItem.id, updatedMenuItem);

      // Update in list
      final index = _menuItems.indexWhere((item) => item.id == menuItem.id);
      if (index != -1) {
        _menuItems[index] = updatedMenuItem;
      }

      print('✅ Menu item updated successfully: ${updatedMenuItem.name}');
      return true;
    } catch (e) {
      print('❌ Error updating menu item: $e');
      Get.snackbar('Error', 'Failed to update menu item: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // DELETE - Delete menu item
  Future<bool> deleteMenuItem(String menuItemId) async {
    try {
      _isLoading.value = true;

      // Delete from Supabase
      await Supabase.instance.client
          .from('menu_items')
          .delete()
          .eq('id', menuItemId);

      // Remove from local storage
      await _menuBox.delete(menuItemId);

      // Remove from list
      _menuItems.removeWhere((item) => item.id == menuItemId);

      print('✅ Menu item deleted successfully');
      Get.snackbar('Success', 'Menu item deleted successfully');
      return true;
    } catch (e) {
      print('❌ Error deleting menu item: $e');
      Get.snackbar('Error', 'Failed to delete menu item: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Toggle availability status
  Future<bool> toggleMenuItemAvailability(String menuItemId) async {
    try {
      final menuItem = getMenuItemById(menuItemId);
      if (menuItem == null) return false;

      final updatedMenuItem = menuItem.copyWith(
        isAvailable: !menuItem.isAvailable,
      );

      return await updateMenuItem(updatedMenuItem);
    } catch (e) {
      print('❌ Error toggling menu item availability: $e');
      return false;
    }
  }

  // Search menu items
  List<MenuItem> searchMenuItems(String query) {
    if (query.isEmpty) return _menuItems;

    final searchQuery = query.toLowerCase();
    return _menuItems.where((item)
        => item.name.toLowerCase().contains(searchQuery) ||
           (item.description?.toLowerCase().contains(searchQuery) ?? false) ||
           (item.categoryName?.toLowerCase().contains(searchQuery) ?? false)
    ).toList();
  }

  // Get menu items by availability status
  List<MenuItem> getItemsByAvailability(bool isAvailable) {
    return _menuItems.where((item) => item.isAvailable == isAvailable).toList();
  }

  // Get menu items by price range
  List<MenuItem> getItemsByPriceRange(double minPrice, double maxPrice) {
    return _menuItems.where((item)
        => item.price >= minPrice && item.price <= maxPrice
    ).toList();
  }
}