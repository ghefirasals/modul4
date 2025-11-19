import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../models/menu_item.dart';
import '../services/menu_service.dart';

class MenuCrudController extends GetxController {
  // Form variables
  final RxString name = ''.obs;
  final RxString description = ''.obs;
  final RxDouble price = 0.0.obs;
  final RxString categoryName = 'Nasi'.obs;
  final RxInt spicyLevel = 0.obs;
  final RxBool isAvailable = true.obs;
  final RxString imageUrl = ''.obs;
  final Rx<XFile?> selectedImage = Rx<XFile?>(null);

  // State variables
  final RxBool isLoading = false.obs;
  final RxBool isEditing = false.obs;
  final RxString editingId = ''.obs;

  // Available categories
  final RxList<String> categories = <String>[
    'Nasi',
    'Lauk',
    'Sayur',
    'Minuman',
    'Sambal',
    'Tambahan',
  ].obs;

  // Form validation
  bool get isFormValid =>
      name.value.isNotEmpty &&
      price.value > 0 &&
      categoryName.value.isNotEmpty;

  // Reset form
  void resetForm() {
    name.value = '';
    description.value = '';
    price.value = 0.0;
    categoryName.value = 'Nasi';
    spicyLevel.value = 0;
    isAvailable.value = true;
    imageUrl.value = '';
    selectedImage.value = null;
    isEditing.value = false;
    editingId.value = '';
  }

  // Set form for editing
  void setFormForEdit(MenuItem menuItem) {
    name.value = menuItem.name;
    description.value = menuItem.description ?? '';
    price.value = menuItem.price;
    categoryName.value = menuItem.categoryName ?? 'Nasi';
    spicyLevel.value = menuItem.spicyLevel;
    isAvailable.value = menuItem.isAvailable;
    imageUrl.value = menuItem.imageUrl ?? '';
    selectedImage.value = null;
    isEditing.value = true;
    editingId.value = menuItem.id ?? '';
  }

  // Pick image from gallery
  Future<void> pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      selectedImage.value = image;
      imageUrl.value = image.path;
    }
  }

  // Pick image from camera
  Future<void> pickImageFromCamera() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      selectedImage.value = image;
      imageUrl.value = image.path;
    }
  }

  // Remove selected image
  void removeSelectedImage() {
    selectedImage.value = null;
    imageUrl.value = '';
  }

  // Save/Create menu item
  Future<bool> saveMenuItem() async {
    if (!isFormValid) {
      Get.snackbar('Error', 'Please fill all required fields');
      return false;
    }

    try {
      isLoading.value = true;

      final menuItem = MenuItem(
        id: isEditing.value ? editingId.value : null,
        name: name.value.trim(),
        description: description.value.trim().isEmpty ? null : description.value.trim(),
        price: price.value,
        categoryName: categoryName.value.trim(),
        spicyLevel: spicyLevel.value,
        isAvailable: isAvailable.value,
        imageUrl: imageUrl.value.trim().isEmpty ? null : imageUrl.value.trim(),
      );

      bool success;
      if (isEditing.value) {
        success = await MenuService.to.updateMenuItem(menuItem);
        if (success) {
          Get.snackbar('Success', 'Menu item updated successfully');
        }
      } else {
        success = await MenuService.to.createMenuItem(menuItem);
        if (success) {
          Get.snackbar('Success', 'Menu item created successfully');
        }
      }

      if (success) {
        resetForm();
        Get.back(); // Go back to menu list
      }

      return success;
    } catch (e) {
      Get.snackbar('Error', 'Failed to save menu item: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Delete menu item
  Future<bool> deleteMenuItem(String menuItemId) async {
    try {
      // Show confirmation dialog
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this menu item?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirmed != true) return false;

      isLoading.value = true;
      final success = await MenuService.to.deleteMenuItem(menuItemId);

      if (success) {
        Get.snackbar('Success', 'Menu item deleted successfully');
      }

      return success;
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete menu item: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Toggle menu item availability
  Future<void> toggleAvailability(String menuItemId) async {
    await MenuService.to.toggleMenuItemAvailability(menuItemId);
  }

  // Search menu items
  List<MenuItem> searchMenuItems(String query) {
    return MenuService.to.searchMenuItems(query);
  }

  // Get spicy level text
  String getSpicyLevelText(int level) {
    switch (level) {
      case 0:
        return 'Tidak Pedas';
      case 1:
        return 'Sedikit Pedas';
      case 2:
        return 'Pedas';
      case 3:
        return 'Cukup Pedas';
      case 4:
        return 'Sangat Pedas';
      case 5:
        return 'Extremely Pedas';
      default:
        return 'Tidak Pedas';
    }
  }

  // Get spicy level color
  Color getSpicyLevelColor(int level) {
    switch (level) {
      case 0:
        return Colors.grey;
      case 1:
        return Colors.green;
      case 2:
        return Colors.yellow[700]!;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.red;
      case 5:
        return Colors.red[900]!;
      default:
        return Colors.grey;
    }
  }

  // Format price display
  String formatPrice(double price) {
    return 'Rp ${price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.'
    )}';
  }

  // Validate form fields
  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nama menu harus diisi';
    }
    if (value.trim().length < 3) {
      return 'Nama menu minimal 3 karakter';
    }
    return null;
  }

  String? validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Harga harus diisi';
    }

    final priceValue = double.tryParse(value);
    if (priceValue == null) {
      return 'Harga harus berupa angka';
    }
    if (priceValue <= 0) {
      return 'Harga harus lebih dari 0';
    }
    if (priceValue > 999999999) {
      return 'Harga terlalu besar';
    }
    return null;
  }

  String? validateCategory(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Kategori harus dipilih';
    }
    return null;
  }

  // Add new category
  void addNewCategory(String newCategory) {
    if (newCategory.trim().isNotEmpty && !categories.contains(newCategory.trim())) {
      categories.add(newCategory.trim());
      categories.sort();
    }
  }
}