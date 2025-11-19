import 'package:get/get.dart';
import '../services/theme_service.dart';
import '../services/cart_service.dart';
import '../services/menu_service.dart';
import '../services/todo_service.dart';
import 'navigation_controller.dart';
import 'menu_crud_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Core services
    Get.put(ThemeService(), permanent: true);
    Get.lazyPut<CartService>(() => CartService());
    Get.lazyPut<MenuService>(() => MenuService());
    Get.put<TodoService>(TodoService());

    // Controllers
    Get.lazyPut<NavigationController>(() => NavigationController());
    Get.lazyPut<MenuCrudController>(() => MenuCrudController());
  }
}
