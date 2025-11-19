import 'package:supabase_flutter/supabase_flutter.dart';
import 'environment.dart';

class SupabaseConfig {
  // URL dan Anon Key sekarang diambil dari environment
  static String get supabaseUrl => Environment.supabaseUrl;
  static String get supabaseAnonKey => Environment.supabaseAnonKey;

  // Initialize sudah dipindahkan ke main.dart
  // Method ini untuk compatibility jika diperlukan
  static Future<void> initialize() async {
    // Supabase sudah di-initialize di main.dart
    // Method ini untuk backward compatibility
  }

  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => Supabase.instance.client.auth;
}