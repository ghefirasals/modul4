import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../services/todo_service.dart';
import '../services/note_service.dart';
import '../services/cart_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Core services
    Get.lazyPut<AuthService>(() => AuthService());
    Get.put(ThemeService(), permanent: true);
    Get.lazyPut<TodoService>(() => TodoService());
    Get.lazyPut<NoteService>(() => NoteService());
    Get.lazyPut<CartService>(() => CartService());
  }
}
