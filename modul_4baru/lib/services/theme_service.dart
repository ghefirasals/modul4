import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends GetxService {
  static ThemeService get to => Get.find();

  static const String _themeKey = 'theme_mode';
  static const String _material3Key = 'use_material3';

  final Rx<ThemeMode> _themeMode = ThemeMode.system.obs;
  final RxBool _useMaterial3 = true.obs;

  // Getters
  ThemeMode get themeMode => _themeMode.value;
  bool get isDarkMode => _themeMode.value == ThemeMode.dark;
  bool get useMaterial3 => _useMaterial3.value;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _loadThemeMode();
    await _loadMaterial3();
  }

  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt(_themeKey) ?? 0;
      _themeMode.value = ThemeMode.values[themeIndex];
    } catch (e) {
      print('Error loading theme mode: $e');
      _themeMode.value = ThemeMode.system;
    }
  }

  Future<void> _loadMaterial3() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _useMaterial3.value = prefs.getBool(_material3Key) ?? true;
    } catch (e) {
      print('Error loading material3 setting: $e');
      _useMaterial3.value = true;
    }
  }

  Future<void> changeThemeMode(ThemeMode themeMode) async {
    try {
      _themeMode.value = themeMode;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, themeMode.index);
      Get.changeThemeMode(themeMode);
    } catch (e) {
      print('Error changing theme mode: $e');
    }
  }

  Future<void> toggleTheme() async {
    final currentTheme = _themeMode.value;
    ThemeMode newTheme;
    switch (currentTheme) {
      case ThemeMode.light:
        newTheme = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        newTheme = ThemeMode.system;
        break;
      case ThemeMode.system:
        newTheme = ThemeMode.light;
        break;
    }
    await changeThemeMode(newTheme);
  }

  Future<void> toggleMaterial3() async {
    try {
      _useMaterial3.toggle();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_material3Key, _useMaterial3.value);
      Get.changeTheme(Get.isDarkMode ? AppThemes.darkTheme : AppThemes.lightTheme);
    } catch (e) {
      print('Error toggling material3: $e');
    }
  }

  static Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? 0;
    return ThemeMode.values[themeIndex];
  }

  static Future<void> setThemeMode(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, themeMode.index);
  }
}

class AppThemes {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFD84315), // Orange-red color for nasi padang theme
        brightness: Brightness.light,
        primary: const Color(0xFFD84315), // Deep orange
        secondary: const Color(0xFFFF6F00), // Orange
        tertiary: const Color(0xFF8BC34A), // Green for vegetables
        surface: Colors.white,
        background: const Color(0xFFFFF8F1), // Warm white
        error: const Color(0xFFD32F2F),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFD84315),
        foregroundColor: Colors.white,
        elevation: 2,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD84315),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 2,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFFF3E0), // Light orange
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD84315)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD84315), width: 2),
        ),
        labelStyle: const TextStyle(color: Color(0xFFD84315)),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Color(0xFFD84315),
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFFD84315),
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Color(0xFF212121),
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Color(0xFF424242),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFFF6F00), // Orange for dark theme
        brightness: Brightness.dark,
        primary: const Color(0xFFFF6F00), // Orange
        secondary: const Color(0xFFD84315), // Deep orange
        tertiary: const Color(0xFF8BC34A), // Green
        surface: const Color(0xFF1E1E1E),
        background: const Color(0xFF121212),
        error: const Color(0xFFCF6679),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF212121),
        foregroundColor: Colors.white,
        elevation: 2,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: const Color(0xFF2A2A2A),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6F00),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 2,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF6F00)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF6F00), width: 2),
        ),
        labelStyle: const TextStyle(color: Color(0xFFFF6F00)),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Color(0xFFFF6F00),
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFFFF6F00),
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Color(0xFFFFFFFF),
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Color(0xFFB0B0B0),
        ),
      ),
    );
  }
}