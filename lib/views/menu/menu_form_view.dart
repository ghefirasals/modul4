import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/menu_crud_controller.dart';

class MenuFormView extends StatelessWidget {
  const MenuFormView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MenuCrudController>();

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(
          controller.isEditing.value ? 'Edit Menu Item' : 'Add New Menu Item'
        )),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Obx(() => controller.isLoading.value
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : TextButton(
                  onPressed: controller.saveMenuItem,
                  child: const Text(
                    'Save',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image section
              _buildImageSection(controller),

              const SizedBox(height: 24),

              // Basic information section
              _buildBasicInfoSection(controller),

              const SizedBox(height: 24),

              // Pricing and category section
              _buildPricingCategorySection(controller),

              const SizedBox(height: 24),

              // Additional settings section
              _buildAdditionalSettingsSection(controller),

              const SizedBox(height: 32),

              // Save button
              _buildSaveButton(controller),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(MenuCrudController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Menu Image',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        Obx(() {
          final hasImage = controller.selectedImage.value != null ||
                         controller.imageUrl.value.isNotEmpty;

          return Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[50],
            ),
            child: hasImage
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: controller.selectedImage.value != null
                            ? Image.file(
                                File(controller.selectedImage.value!.path),
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildPlaceholderImage();
                                },
                              )
                            : (controller.imageUrl.value.startsWith('http')
                                ? Image.network(
                                    controller.imageUrl.value,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildPlaceholderImage();
                                    },
                                  )
                                : _buildPlaceholderImage()),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: CircleAvatar(
                          backgroundColor: Colors.red,
                          radius: 16,
                          child: IconButton(
                            onPressed: controller.removeSelectedImage,
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  )
                : _buildImagePickerButtons(controller),
          );
        }),
      ],
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[200],
      child: const Icon(
        Icons.restaurant,
        size: 64,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildImagePickerButtons(MenuCrudController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          const Text(
            'Add Menu Image',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: controller.pickImageFromCamera,
                icon: const Icon(Icons.camera_alt, size: 16),
                label: const Text('Camera'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: controller.pickImageFromGallery,
                icon: const Icon(Icons.photo_library, size: 16),
                label: const Text('Gallery'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection(MenuCrudController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Basic Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // Name field
        Obx(() => TextFormField(
          initialValue: controller.name.value,
          onChanged: (value) => controller.name.value = value,
          validator: controller.validateName,
          decoration: const InputDecoration(
            labelText: 'Menu Name *',
            hintText: 'Enter menu name',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.restaurant_menu),
          ),
        )),

        const SizedBox(height: 16),

        // Description field
        Obx(() => TextFormField(
          initialValue: controller.description.value,
          onChanged: (value) => controller.description.value = value,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Description',
            hintText: 'Enter menu description',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.description),
          ),
        )),
      ],
    );
  }

  Widget _buildPricingCategorySection(MenuCrudController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pricing & Category',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // Price field
        Obx(() => TextFormField(
          initialValue: controller.price.value > 0
              ? controller.price.value.toString()
              : '',
          onChanged: (value) {
            final price = double.tryParse(value) ?? 0.0;
            controller.price.value = price;
          },
          validator: controller.validatePrice,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Price (IDR) *',
            hintText: 'Enter price',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.money),
            prefixText: 'Rp ',
          ),
        )),

        const SizedBox(height: 16),

        // Category dropdown
        Obx(() => DropdownButtonFormField<String>(
          value: controller.categories.contains(controller.categoryName.value)
              ? controller.categoryName.value
              : controller.categories.first,
          onChanged: (value) {
            if (value != null) {
              controller.categoryName.value = value;
            }
          },
          validator: controller.validateCategory,
          decoration: const InputDecoration(
            labelText: 'Category *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.category),
          ),
          items: controller.categories.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Text(category),
            );
          }).toList(),
        )),
      ],
    );
  }

  Widget _buildAdditionalSettingsSection(MenuCrudController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // Spicy level
        Obx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spicy Level: ${controller.getSpicyLevelText(controller.spicyLevel.value)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(
                6,
                (index) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(index == 0 ? 'None' : index.toString()),
                    selected: controller.spicyLevel.value == index,
                    onSelected: (selected) {
                      if (selected) {
                        controller.spicyLevel.value = index;
                      }
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: controller.getSpicyLevelColor(index),
                  ),
                ),
              ),
            ),
          ],
        )),

        const SizedBox(height: 16),

        // Availability switch
        Obx(() => SwitchListTile(
          title: const Text('Available'),
          subtitle: const Text('Show this item in the menu'),
          value: controller.isAvailable.value,
          onChanged: (value) {
            controller.isAvailable.value = value;
          },
          activeColor: Colors.orange[700],
        )),
      ],
    );
  }

  Widget _buildSaveButton(MenuCrudController controller) {
    return Obx(() => SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: controller.isFormValid && !controller.isLoading.value
            ? controller.saveMenuItem
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange[700],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: controller.isLoading.value
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text('Saving...'),
                ],
              )
            : Text(
                controller.isEditing.value ? 'Update Menu Item' : 'Create Menu Item',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    ),
    );
  }
}