import 'package:hive/hive.dart';

class HiveService {
  static const _boxName = 'menu_box';

  static Future<void> init() async {
    // Hive.initFlutter() harus dipanggil di main.dart sebelum runApp
  }

  static Future<void> saveMenuList(List<Map<String, dynamic>> items) async {
    final box = await Hive.openBox(_boxName);
    await box.put('menus', items);
    await box.close();
  }

  static Future<List<Map<String, dynamic>>> loadMenuList() async {
    final box = await Hive.openBox(_boxName);
    final list = box.get('menus', defaultValue: <Map<String, dynamic>>[]);
    await box.close();
    // Ensure it's List<Map>
    return List<Map<String, dynamic>>.from(list ?? []);
  }

  static Future<void> clear() async {
    final box = await Hive.openBox(_boxName);
    await box.clear();
    await box.close();
  }
}
