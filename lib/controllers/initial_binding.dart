import 'package:get/get.dart';
import '../services/theme_service.dart';
import '../services/cart_service.dart';
import '../services/menu_service.dart';
import '../services/todo_service.dart';
import '../services/location_service.dart';
import 'navigation_controller.dart';
import 'menu_crud_controller.dart';
import 'location_controller.dart';
import 'network_location_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Core services
    Get.put(ThemeService(), permanent: true);
    Get.lazyPut<CartService>(() => CartService());
    Get.lazyPut<MenuService>(() => MenuService());
    Get.put<TodoService>(TodoService());
    Get.lazyPut<LocationService>(() => LocationService(), fenix: true);

    // Controllers
    Get.lazyPut<NavigationController>(() => NavigationController());
    Get.lazyPut<MenuCrudController>(() => MenuCrudController());
    Get.lazyPut<LocationController>(() => LocationController(), fenix: true);
    Get.lazyPut<NetworkLocationController>(() => NetworkLocationController(), fenix: true);
  }
}
