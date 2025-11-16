import 'package:get/get.dart';
import '../models/menu_item_model.dart';

class MenuController extends GetxController {
  var menus = <MenuItemModel>[].obs;
  var filteredMenu = <MenuItemModel>[].obs;
  var loading = false.obs;
  var query = "".obs;

  void setMenu(List<MenuItemModel> data) {
    menus.value = data;
    filteredMenu.value = data;
  }

  void setQuery(String q) {
    query.value = q;
    filteredMenu.value = menus
        .where((e) => e.name.toLowerCase().contains(q.toLowerCase()))
        .toList();
  }

  void toggleFavorite(String id) {
    final index = menus.indexWhere((e) => e.id == id);
    if (index != -1) {
      menus[index].favorite = !menus[index].favorite;
      menus.refresh();
      filteredMenu.refresh();
    }
  }
}
