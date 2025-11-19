import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/menu_item.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => Supabase.instance.client.auth;

  // Authentication
  static Future<bool> signIn(String email, String password) async {
    try {
      final response = await auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response.session != null;
    } catch (e) {
      print('❌ Sign in error: $e');
      return false;
    }
  }

  static Future<bool> signUp(String email, String password) async {
    try {
      final response = await auth.signUp(
        email: email,
        password: password,
      );
      return response.user != null;
    } catch (e) {
      print('❌ Sign up error: $e');
      return false;
    }
  }

  static Future<void> signOut() async {
    try {
      await auth.signOut();
    } catch (e) {
      print('❌ Sign out error: $e');
    }
  }

  static bool get isLoggedIn => auth.currentUser != null;

  // Menu Items
  static Future<List<MenuItem>> getMenuItems() async {
    try {
      final response = await client
          .from('menu_items')
          .select()
          .eq('is_available', true);

      return response.map((json) => MenuItem.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error fetching menu items: $e');
      return [];
    }
  }

  static Future<bool> saveMenuItem(MenuItem menuItem) async {
    try {
      await client.from('menu_items').upsert(menuItem.toJson());
      return true;
    } catch (e) {
      print('❌ Error saving menu item: $e');
      return false;
    }
  }

  static Future<bool> deleteMenuItem(String id) async {
    try {
      await client.from('menu_items').delete().eq('id', id);
      return true;
    } catch (e) {
      print('❌ Error deleting menu item: $e');
      return false;
    }
  }
}
