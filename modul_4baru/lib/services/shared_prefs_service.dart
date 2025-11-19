import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsService {
  static const _keyThemeDark = 'is_dark_theme';

  static Future<void> setDarkTheme(bool value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_keyThemeDark, value);
  }

  static Future<bool> isDarkTheme() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_keyThemeDark) ?? false;
  }
}
