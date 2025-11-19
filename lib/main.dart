import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'controllers/initial_binding.dart';
import 'views/main_navigation_view.dart';
import 'views/login_view.dart';
import 'services/theme_service.dart';
import 'models/menu_item.dart';
import 'models/cart_item.dart';
import 'models/todo_item.dart';
import 'services/environment.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Environment
    await Environment.init();

    // Initialize Hive
    await Hive.initFlutter();
    Hive.registerAdapter(MenuItemAdapter());
    Hive.registerAdapter(CartItemAdapter());
    Hive.registerAdapter(TodoItemAdapter());
    await Hive.openBox<MenuItem>('menu_items');
    await Hive.openBox<CartItem>('cart_items');
    await Hive.openBox<TodoItem>('todo_items');

    // Initialize Supabase
    await Supabase.initialize(
      url: Environment.supabaseUrl,
      anonKey: Environment.supabaseAnonKey,
    );

    // Initialize Theme Service
    await Get.putAsync(() async {
      final service = ThemeService();
      await service.init();
      return service;
    }, permanent: true);

    print('🚀 Nasi Padang App starting...');
    runApp(const NasiPadangApp());
  } catch (e) {
    print('❌ Error starting app: $e');
    runApp(ErrorApp(errorMessage: e.toString()));
  }
}

class NasiPadangApp extends StatelessWidget {
  const NasiPadangApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Nasi Padang',
      debugShowCheckedModeBanner: false,
      initialBinding: InitialBinding(),
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: ThemeMode.system,
      home: const AuthWrapper(),
      getPages: [
        GetPage(name: '/login', page: () => const LoginView()),
        GetPage(name: '/home', page: () => const MainNavigationView()),
      ],
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  User? currentUser;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
    // Listen to auth changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      setState(() {
        currentUser = data.session?.user;
      });
    });
  }

  void _checkAuthStatus() {
    setState(() {
      currentUser = Supabase.instance.client.auth.currentUser;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser != null) {
      return const MainNavigationView();
    } else {
      return const LoginView();
    }
  }
}

class ErrorApp extends StatelessWidget {
  final String errorMessage;

  const ErrorApp({super.key, required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Error - Nasi Padang',
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
              const Text(
                'Please check your .env file configuration',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// App Themes
class AppThemes {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFD84315), // Orange accent for Nasi Padang
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFD84315),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD84315),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFD84315),
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFBF360C),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD84315),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}