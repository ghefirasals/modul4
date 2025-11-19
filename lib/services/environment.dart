import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {
  static Future<void> init() async {
    try {
      // Coba load .env dulu
      await dotenv.load(fileName: ".env");
      print('✅ Environment loaded successfully');
    } catch (e) {
      print('❌ Error loading .env: $e');

      try {
        // Fallback ke .env.example
        await dotenv.load(fileName: ".env.example");
        print('⚠️ Using .env.example as fallback');
      } catch (e2) {
        print('❌ Error loading .env.example: $e2');

        // Jika kedua file tidak ada, set minimal default values
        dotenv.env.addAll({
          'APP_NAME': 'Nasi Padang Online',
          'APP_VERSION': '1.0.0',
          'APP_ENV': 'development',
          'DEBUG_MODE': 'true',
          'SUPABASE_URL': 'https://YOUR-PROJECT-ID.supabase.co',
          'SUPABASE_ANON_KEY': 'YOUR_SUPABASE_ANON_KEY',
        });
        print('⚠️ Using default environment values');
      }
    }
  }

  // Supabase Configuration
  static String get supabaseUrl {
    final url = dotenv.env['SUPABASE_URL'] ?? '';
    if (url.isEmpty || url == 'https://YOUR-PROJECT-ID.supabase.co') {
      throw Exception(
        '⚠️ SUPABASE_URL tidak dikonfigurasi!\n'
        '1. Copy .env.example ke .env\n'
        '2. Isi dengan Supabase URL Anda\n'
        '3. Restart aplikasi',
      );
    }
    return url;
  }

  static String get supabaseAnonKey {
    final key = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
    if (key.isEmpty || key == 'YOUR_SUPABASE_ANON_KEY') {
      throw Exception(
        '⚠️ SUPABASE_ANON_KEY tidak dikonfigurasi!\n'
        '1. Copy .env.example ke .env\n'
        '2. Isi dengan Supabase Anon Key Anda\n'
        '3. Restart aplikasi',
      );
    }
    return key;
  }

  // App Configuration
  static String get appName => dotenv.env['APP_NAME'] ?? 'Nasi Padang Online';
  static String get appVersion => dotenv.env['APP_VERSION'] ?? '1.0.0';
  static String get appEnv => dotenv.env['APP_ENV'] ?? 'development';
  static bool get isDebugMode => dotenv.env['DEBUG_MODE']?.toLowerCase() == 'true';

  // Helper Methods
  static bool get isDevelopment => appEnv == 'development';
  static bool get isProduction => appEnv == 'production';
  static bool get isStaging => appEnv == 'staging';

  // Print Configuration (untuk debugging)
  static void printConfig() {
    if (isDebugMode) {
      print('🔧 Environment Configuration:');
      print('   App Name: $appName');
      print('   Version: $appVersion');
      print('   Environment: $appEnv');
      print('   Debug Mode: $isDebugMode');
      print('   Supabase URL: ${supabaseUrl.replaceFirst('https://', 'https://***')}' );
      print('   Supabase Key: ${supabaseAnonKey.substring(0, 10)}...');
    }
  }
}