import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'bindings/initial_binding.dart';
import 'views/auth/login_view.dart';
import 'views/home/home_view.dart';
import 'services/auth_service.dart';
import 'services/theme_service.dart';
import 'models/user_profile.dart';
import 'models/menu_item.dart';
import 'models/cart_item.dart';
import 'models/todo_item.dart';
import 'config/environment.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // ==== INIT ENVIRONMENT ====
    await Environment.init();
    Environment.printConfig();

    // ==== INIT HIVE ====
    await Hive.initFlutter();

    // Register Hive adapters
    Hive.registerAdapter(UserProfileAdapter());
    Hive.registerAdapter(MenuItemAdapter());
    Hive.registerAdapter(CartItemAdapter());
    Hive.registerAdapter(TodoItemAdapter());

    // Open Hive boxes
    await Hive.openBox<UserProfile>('user_profiles');
    await Hive.openBox<MenuItem>('menu_items');
    await Hive.openBox<CartItem>('cart_items');
    await Hive.openBox<TodoItem>('todo_items');

    // ==== INIT SUPABASE ====
    await Supabase.initialize(
      url: Environment.supabaseUrl,
      anonKey: Environment.supabaseAnonKey,
    );

    print('🚀 ${Environment.appName} v${Environment.appVersion} starting...');
    runApp(const MyApp());
  } catch (e) {
    print('❌ Error starting app: $e');
    runApp(ErrorApp(errorMessage: e.toString()));
  }
}

// Error handling widget untuk startup errors
class ErrorApp extends StatelessWidget {
  final String errorMessage;

  const ErrorApp({super.key, required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Error - Nasi Padang Online',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFFFF3E0),
        appBar: AppBar(
          title: const Text('⚠️ Configuration Error'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 100, color: Colors.red),
              const SizedBox(height: 24),
              const Text(
                'Configuration Error',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                errorMessage,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🔧 Cara Memperbaiki:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('1. Copy file .env.example ke .env'),
                    Text('2. Isi dengan Supabase credentials Anda'),
                    Text('3. Restart aplikasi'),
                    SizedBox(height: 8),
                    Text(
                      '📖 Lihat SETUP_INSTRUCTIONS.md untuk detail',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Nasi Padang Online',
      debugShowCheckedModeBanner: false,

      // Agar services otomatis aktif
      initialBinding: InitialBinding(),

      // Theme configuration
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: ThemeMode.system,

      // Halaman utama
      home: const ThemeInitializer(),
      getPages: [
        GetPage(name: '/login', page: () => const LoginView()),
        GetPage(name: '/home', page: () => const HomeView()),
      ],
    );
  }
}

class ThemeInitializer extends StatefulWidget {
  const ThemeInitializer({super.key});

  @override
  State<ThemeInitializer> createState() => _ThemeInitializerState();
}

class _ThemeInitializerState extends State<ThemeInitializer> {
  bool _themeApplied = false;

  @override
  void initState() {
    super.initState();
    _initializeTheme();
  }

  Future<void> _initializeTheme() async {
    // Tunggu GetInitializer selesai
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      // Coba ambil ThemeService, atau buat baru jika belum ada
      final themeService = Get.isRegistered<ThemeService>()
          ? Get.find<ThemeService>()
          : Get.put(ThemeService(), permanent: true);

      Get.changeThemeMode(themeService.themeMode);
    } catch (e) {
      print('⚠️ Error initializing theme: $e');
      // Jika gagal, gunakan system theme sebagai fallback
      Get.changeThemeMode(ThemeMode.system);
    }

    if (mounted) {
      setState(() {
        _themeApplied = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_themeApplied) {
      return Scaffold(
        body: Container(
          color: const Color(0xFFFFF3E0),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD84315)),
            ),
          ),
        ),
      );
    }

    return const AuthWrapper();
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      try {
        // Check if AuthService is initialized, create if not exists
        final authService = Get.isRegistered<AuthService>()
            ? Get.find<AuthService>()
            : Get.put(AuthService(), permanent: true);

        final isLoggedIn = authService.isLoggedIn;

        if (isLoggedIn) {
          return const HomeView();
        } else {
          return const LoginView();
        }
      } catch (e) {
        print('⚠️ Error in AuthWrapper: $e');
        // If there's any error, show login screen
        return const LoginView();
      }
    });
  }
}
