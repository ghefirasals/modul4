import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/menu_item_model.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> init({required String url, required String anonKey}) async {
    await Supabase.initialize(url: url, anonKey: anonKey);
  }

  static Future<List<MenuItemModel>> fetchMenuItems() async {
    final response = await client.from('menu_items').select();
    // response is dynamic: list of maps
    final List data = response as List;
    return data.map((e) => MenuItemModel.fromMap(Map<String, dynamic>.from(e))).toList();
  }

  static Future<void> upsertMenuItem(MenuItemModel item) async {
    await client.from('menu_items').upsert(item.toMap());
  }
}
